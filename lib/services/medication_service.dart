import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  static const String _key = 'medications';
  static const String _deletedKey = 'deleted_medications';
  static const String _offlineCreatedKey = 'offline_medications_created';

  MedicationService() {
    // Listen for connectivity changes
    Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      if (result != ConnectivityResult.none) {
        // When connection is restored, wait for auth sync first
        final prefs = await SharedPreferences.getInstance();
        final authOffline = prefs.getBool('offline_created') ?? false;

        if (authOffline) {
          // Wait for auth to sync first
          await Future.delayed(Duration(seconds: 2));
        }

        // Then try to sync medication data
        syncWithFirebase();
      }
    });

    // Also listen for auth state changes
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        // When user becomes available (after offline auth sync), try to sync data
        syncWithFirebase();
      }
    });
  }

  // Mark medications as created offline
  Future<void> markOfflineCreated(bool created) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineCreatedKey, created);
  }

  // Check if medications were created offline
  Future<bool> _wasCreatedOffline() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offlineCreatedKey) ?? false;
  }

  // Save medications to SharedPreferences and Firebase if online
  Future<void> saveMedications(List<Medication> medications) async {
    try {
      // Save locally first
      final prefs = await SharedPreferences.getInstance();
      final medicationList = medications.map((med) => med.toJson()).toList();
      await prefs.setString(_key, jsonEncode(medicationList));

      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none &&
          _authService.currentUser != null) {
        try {
          final batch = _firestore.batch();
          final userMedicationsRef = _firestore
              .collection('users')
              .doc(_authService.currentUser!.uid)
              .collection('medications');

          // Get existing medications
          final existingMeds = await userMedicationsRef.get();
          Map<String, DocumentSnapshot> existingMedsMap = {};
          for (var doc in existingMeds.docs) {
            final data = doc.data();
            existingMedsMap[data['name']] = doc;
          }

          // Update or add medications
          for (var medication in medications) {
            if (medication.originalName != null &&
                medication.originalName != medication.name) {
              // Handle name change: delete old document and create new one
              if (existingMedsMap.containsKey(medication.originalName)) {
                batch.delete(
                    existingMedsMap[medication.originalName]!.reference);
              }
              final docRef = userMedicationsRef.doc(medication.name);
              batch.set(docRef, medication.toMap());
            } else if (existingMedsMap.containsKey(medication.name)) {
              // Update existing medication
              batch.update(existingMedsMap[medication.name]!.reference,
                  medication.toMap());
            } else {
              // Create new medication
              final docRef = userMedicationsRef.doc(medication.name);
              batch.set(docRef, medication.toMap());
            }
          }

          await batch.commit();
          await markOfflineCreated(false);
        } catch (e) {
          print('Error saving to Firebase: $e');
          await markOfflineCreated(true);
        }
      } else {
        // Mark as created offline
        await markOfflineCreated(true);
      }
    } catch (e) {
      print('Error in saveMedications: $e');
      rethrow;
    }
  }

  // Load medications from SharedPreferences and merge with Firebase if online
  Future<List<Medication>> loadMedications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Medication> localMedications = [];
      Map<String, Medication> medicationsMap = {};
      Set<String> deletedMedications =
          Set<String>.from(prefs.getStringList(_deletedKey) ?? []);

      // Load local data
      final medicationJson = prefs.getString(_key);
      if (medicationJson != null) {
        final medicationList = jsonDecode(medicationJson) as List;
        localMedications =
            medicationList.map((med) => Medication.fromJson(med)).toList();
        // Add local medications to map
        for (var medication in localMedications) {
          medicationsMap[medication.name] = medication;
        }
      }

      // Check connectivity and sync with Firebase if online
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none &&
          _authService.currentUser != null) {
        try {
          // First, process any pending deletions
          if (deletedMedications.isNotEmpty) {
            final batch = _firestore.batch();
            for (var name in deletedMedications) {
              final docRef = _firestore
                  .collection('users')
                  .doc(_authService.currentUser!.uid)
                  .collection('medications')
                  .doc(name);
              batch.delete(docRef);
            }
            await batch.commit();
            // Clear deleted medications list after successful deletion
            await prefs.setStringList(_deletedKey, []);
            deletedMedications.clear();
          }

          // Then fetch current Firebase data
          final snapshot = await _firestore
              .collection('users')
              .doc(_authService.currentUser!.uid)
              .collection('medications')
              .get();

          if (snapshot.docs.isNotEmpty) {
            // Merge Firebase data with local data
            for (var doc in snapshot.docs) {
              final medication = Medication.fromMap(doc.data());
              // Skip if medication was deleted locally
              if (deletedMedications.contains(medication.name)) {
                continue;
              }
              // Update medication if it exists locally or add if it doesn't
              medicationsMap[medication.name] = medication;
            }

            // Convert map back to list
            final mergedMedications = medicationsMap.values.toList();

            // Save merged data back to local storage
            await saveMedications(mergedMedications);

            return mergedMedications;
          }
        } catch (e) {
          print('Error syncing with Firebase: $e');
          // Return local data if Firebase sync fails
        }
      }

      return localMedications;
    } catch (e) {
      print('Error in loadMedications: $e');
      return [];
    }
  }

  // Clear medications from SharedPreferences and Firebase if online
  Future<void> clearMedications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none &&
        _authService.currentUser != null) {
      try {
        final userMedicationsRef = _firestore
            .collection('users')
            .doc(_authService.currentUser!.uid)
            .collection('medications');

        final snapshot = await userMedicationsRef.get();
        final batch = _firestore.batch();

        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      } catch (e) {
        print('Error clearing Firebase medications: $e');
      }
    }
  }

  // Sync local data with Firebase
  Future<void> syncWithFirebase() async {
    if (_authService.currentUser == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final wasOffline = await _wasCreatedOffline();
      final deletedMedications =
          Set<String>.from(prefs.getStringList(_deletedKey) ?? []);

      // Only proceed if we have offline changes or pending deletions
      if (!wasOffline && deletedMedications.isEmpty) return;

      // First handle any pending deletions
      if (deletedMedications.isNotEmpty) {
        final batch = _firestore.batch();
        for (var name in deletedMedications) {
          final docRef = _firestore
              .collection('users')
              .doc(_authService.currentUser!.uid)
              .collection('medications')
              .doc(name);
          batch.delete(docRef);
        }
        await batch.commit();
        // Clear deleted medications list after successful deletion
        await prefs.setStringList(_deletedKey, []);
      }

      // Then handle any offline created/modified data
      final medicationJson = prefs.getString(_key);
      if (medicationJson != null) {
        final medicationList = jsonDecode(medicationJson) as List;
        final medications =
            medicationList.map((med) => Medication.fromJson(med)).toList();

        final batch = _firestore.batch();
        final userMedicationsRef = _firestore
            .collection('users')
            .doc(_authService.currentUser!.uid)
            .collection('medications');

        // Get existing medications
        final existingMeds = await userMedicationsRef.get();

        // Create a map of existing medications by name
        Map<String, DocumentSnapshot> existingMedsMap = {};
        for (var doc in existingMeds.docs) {
          final data = doc.data();
          if (!deletedMedications.contains(data['name'])) {
            existingMedsMap[data['name']] = doc;
          }
        }

        // Update or add medications
        for (var medication in medications) {
          if (medication.originalName != null &&
              medication.originalName != medication.name) {
            // Handle renamed medication
            if (existingMedsMap.containsKey(medication.originalName)) {
              // Delete the old document
              batch.delete(existingMedsMap[medication.originalName]!.reference);
            }
            // Create new document with updated name
            final docRef = userMedicationsRef.doc(medication.name);
            batch.set(docRef, medication.toMap());
          } else if (existingMedsMap.containsKey(medication.name)) {
            // Update existing medication
            batch.update(existingMedsMap[medication.name]!.reference,
                medication.toMap());
            existingMedsMap.remove(medication.name);
          } else {
            // Create new medication
            final docRef = userMedicationsRef.doc(medication.name);
            batch.set(docRef, medication.toMap());
          }
        }

        await batch.commit();
      }

      // Clear offline flags
      await markOfflineCreated(false);
    } catch (e) {
      print('Error syncing with Firebase: $e');
      rethrow;
    }
  }

  // Delete medication and handle online/offline state
  Future<void> deleteMedication(String medicationName) async {
    try {
      // Add to deleted list
      final prefs = await SharedPreferences.getInstance();
      final deletedMedications =
          Set<String>.from(prefs.getStringList(_deletedKey) ?? []);
      deletedMedications.add(medicationName);
      await prefs.setStringList(_deletedKey, deletedMedications.toList());

      // Remove from local storage
      final medicationJson = prefs.getString(_key);
      if (medicationJson != null) {
        final medicationList = jsonDecode(medicationJson) as List;
        final medications = medicationList
            .map((med) => Medication.fromJson(med))
            .where((med) => med.name != medicationName)
            .toList();
        await prefs.setString(
            _key, jsonEncode(medications.map((med) => med.toJson()).toList()));
      }

      // Try to delete from Firebase if online
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none &&
          _authService.currentUser != null) {
        try {
          await _firestore
              .collection('users')
              .doc(_authService.currentUser!.uid)
              .collection('medications')
              .doc(medicationName)
              .delete();

          // Clear from deleted list since we successfully deleted from Firebase
          deletedMedications.remove(medicationName);
          await prefs.setStringList(_deletedKey, deletedMedications.toList());
        } catch (e) {
          print('Error deleting from Firebase: $e');
          // Keep in deleted list for future sync
        }
      }
    } catch (e) {
      print('Error in deleteMedication: $e');
      rethrow;
    }
  }
}
