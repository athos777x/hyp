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
          // Save to Firebase
          final batch = _firestore.batch();
          final userMedicationsRef = _firestore
              .collection('users')
              .doc(_authService.currentUser!.uid)
              .collection('medications');

          // Get existing medications from Firebase
          final existingMeds = await userMedicationsRef.get();

          // Create a map of existing medications by name
          Map<String, DocumentSnapshot> existingMedsMap = {};
          for (var doc in existingMeds.docs) {
            final data = doc.data();
            existingMedsMap[data['name']] = doc;
          }

          // Update or add medications
          for (var medication in medications) {
            if (existingMedsMap.containsKey(medication.name)) {
              // Update existing medication
              batch.update(existingMedsMap[medication.name]!.reference,
                  medication.toMap());
              existingMedsMap.remove(medication.name);
            } else {
              // Add new medication
              final docRef = userMedicationsRef.doc();
              batch.set(docRef, medication.toMap());
            }
          }

          // Delete medications that no longer exist locally
          for (var doc in existingMedsMap.values) {
            batch.delete(doc.reference);
          }

          await batch.commit();
        } catch (e) {
          print('Error saving to Firebase: $e');
          // Continue even if Firebase save fails
        }
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
          Set<String>.from(prefs.getStringList('deleted_medications') ?? []);

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
              // Only update if medication doesn't exist locally
              if (!medicationsMap.containsKey(medication.name)) {
                medicationsMap[medication.name] = medication;
              }
            }

            // Convert map back to list
            final mergedMedications = medicationsMap.values.toList();

            // Save merged data back to local storage
            await saveMedications(mergedMedications);

            // Clear deleted medications list if sync successful
            if (deletedMedications.isNotEmpty) {
              await prefs.setStringList('deleted_medications', []);
            }

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

    final prefs = await SharedPreferences.getInstance();
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

      // Delete existing medications
      final existingMeds = await userMedicationsRef.get();
      for (var doc in existingMeds.docs) {
        batch.delete(doc.reference);
      }

      // Add new medications
      for (var medication in medications) {
        final docRef = userMedicationsRef.doc();
        batch.set(docRef, medication.toMap());
      }

      await batch.commit();
    }
  }

  // Update the delete functionality to track deleted medications
  Future<void> deleteMedication(String medicationName) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedMedications =
        Set<String>.from(prefs.getStringList('deleted_medications') ?? []);

    deletedMedications.add(medicationName);
    await prefs.setStringList(
        'deleted_medications', deletedMedications.toList());
  }
}
