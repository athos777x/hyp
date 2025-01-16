import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blood_pressure.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class BloodPressureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  static const String _key = 'blood_pressure_measurements';
  static const String _deletedKey = 'deleted_blood_pressure_measurements';
  static const String _offlineCreatedKey = 'offline_bp_created';

  BloodPressureService() {
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

        // Then try to sync blood pressure data
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

  // Mark measurements as created offline
  Future<void> markOfflineCreated(bool created) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineCreatedKey, created);
  }

  // Check if measurements were created offline
  Future<bool> _wasCreatedOffline() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offlineCreatedKey) ?? false;
  }

  // Save measurements to SharedPreferences and Firebase if online
  Future<void> saveMeasurements(List<BloodPressure> measurements) async {
    try {
      // Always save locally first
      final prefs = await SharedPreferences.getInstance();
      final measurementsList = measurements.map((bp) => bp.toJson()).toList();
      await prefs.setString(_key, jsonEncode(measurementsList));

      // Try to save to Firebase if online
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none &&
          _authService.currentUser != null) {
        try {
          final batch = _firestore.batch();
          final userBPRef = _firestore
              .collection('users')
              .doc(_authService.currentUser!.uid)
              .collection('blood_pressure');

          // Get existing measurements
          final existingMeasurements = await userBPRef.get();
          Map<String, DocumentSnapshot> existingMeasurementsMap = {};
          for (var doc in existingMeasurements.docs) {
            final measurement =
                BloodPressure.fromJson(doc.data() as Map<String, dynamic>);
            existingMeasurementsMap[measurement.id] = doc;
          }

          // Update or add measurements
          for (var measurement in measurements) {
            if (existingMeasurementsMap.containsKey(measurement.id)) {
              batch.update(existingMeasurementsMap[measurement.id]!.reference,
                  measurement.toJson());
            } else {
              final docRef = userBPRef.doc(measurement.id);
              batch.set(docRef, measurement.toJson());
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
      print('Error in saveMeasurements: $e');
      rethrow;
    }
  }

  // Load measurements from SharedPreferences and merge with Firebase if online
  Future<List<BloodPressure>> loadMeasurements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<BloodPressure> localMeasurements = [];
      Map<String, BloodPressure> measurementsMap = {};
      Set<String> deletedMeasurements =
          Set<String>.from(prefs.getStringList(_deletedKey) ?? []);

      // Load local data
      final measurementsJson = prefs.getString(_key);
      if (measurementsJson != null) {
        final measurementsList = jsonDecode(measurementsJson) as List;
        localMeasurements =
            measurementsList.map((bp) => BloodPressure.fromJson(bp)).toList();
        // Add local measurements to map
        for (var measurement in localMeasurements) {
          measurementsMap[measurement.id] = measurement;
        }
      }

      // Try to sync with Firebase if online
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none &&
          _authService.currentUser != null) {
        try {
          // First, process any pending deletions
          if (deletedMeasurements.isNotEmpty) {
            final batch = _firestore.batch();
            for (var id in deletedMeasurements) {
              final docRef = _firestore
                  .collection('users')
                  .doc(_authService.currentUser!.uid)
                  .collection('blood_pressure')
                  .doc(id);
              batch.delete(docRef);
            }
            await batch.commit();
            // Clear deleted measurements list after successful deletion
            await prefs.setStringList(_deletedKey, []);
            deletedMeasurements.clear();
          }

          // Then fetch current Firebase data
          final snapshot = await _firestore
              .collection('users')
              .doc(_authService.currentUser!.uid)
              .collection('blood_pressure')
              .get();

          if (snapshot.docs.isNotEmpty) {
            // Merge Firebase data with local data
            for (var doc in snapshot.docs) {
              final measurement = BloodPressure.fromJson(doc.data());
              // Skip if measurement was deleted locally
              if (deletedMeasurements.contains(measurement.id)) {
                continue;
              }
              // Update measurement if it exists locally or add if it doesn't
              measurementsMap[measurement.id] = measurement;
            }

            // Convert map back to list and sort by timestamp
            final mergedMeasurements = measurementsMap.values.toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

            // Save merged data back to local storage
            await saveMeasurements(mergedMeasurements);

            return mergedMeasurements;
          }
        } catch (e) {
          print('Error syncing with Firebase: $e');
          // Return local data if Firebase sync fails
        }
      }

      // Sort local measurements by timestamp before returning
      localMeasurements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return localMeasurements;
    } catch (e) {
      print('Error in loadMeasurements: $e');
      return [];
    }
  }

  // Track deleted measurement and remove from storage/Firebase
  Future<void> deleteMeasurement(String measurementId) async {
    try {
      // Add to deleted list
      final prefs = await SharedPreferences.getInstance();
      final deletedMeasurements =
          Set<String>.from(prefs.getStringList(_deletedKey) ?? []);
      deletedMeasurements.add(measurementId);
      await prefs.setStringList(_deletedKey, deletedMeasurements.toList());

      // Remove from local storage
      final measurementsJson = prefs.getString(_key);
      if (measurementsJson != null) {
        final measurementsList = jsonDecode(measurementsJson) as List;
        final measurements = measurementsList
            .map((bp) => BloodPressure.fromJson(bp))
            .where((bp) => bp.id != measurementId)
            .toList();
        await prefs.setString(
            _key, jsonEncode(measurements.map((bp) => bp.toJson()).toList()));
      }

      // Try to delete from Firebase if online
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none &&
          _authService.currentUser != null) {
        try {
          await _firestore
              .collection('users')
              .doc(_authService.currentUser!.uid)
              .collection('blood_pressure')
              .doc(measurementId)
              .delete();

          // Clear from deleted list since we successfully deleted from Firebase
          deletedMeasurements.remove(measurementId);
          await prefs.setStringList(_deletedKey, deletedMeasurements.toList());
        } catch (e) {
          print('Error deleting from Firebase: $e');
          // Keep in deleted list for future sync
        }
      }
    } catch (e) {
      print('Error in deleteMeasurement: $e');
      rethrow;
    }
  }

  // Clear measurements from SharedPreferences and Firebase if online
  Future<void> clearMeasurements() async {
    try {
      // Clear local data first
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);

      // Try to clear Firebase data if online
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none &&
          _authService.currentUser != null) {
        try {
          final userBPRef = _firestore
              .collection('users')
              .doc(_authService.currentUser!.uid)
              .collection('blood_pressure');

          final snapshot = await userBPRef.get();
          final batch = _firestore.batch();

          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
          }

          await batch.commit();
        } catch (e) {
          print('Error clearing Firebase blood pressure measurements: $e');
          // Continue even if Firebase clear fails
        }
      }
    } catch (e) {
      print('Error in clearMeasurements: $e');
      rethrow;
    }
  }

  // Sync local data with Firebase
  Future<void> syncWithFirebase() async {
    if (_authService.currentUser == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final wasOffline = await _wasCreatedOffline();
      final deletedMeasurements =
          Set<String>.from(prefs.getStringList(_deletedKey) ?? []);

      // Only proceed if we have offline changes or pending deletions
      if (!wasOffline && deletedMeasurements.isEmpty) return;

      // First handle any pending deletions
      if (deletedMeasurements.isNotEmpty) {
        final batch = _firestore.batch();
        for (var id in deletedMeasurements) {
          final docRef = _firestore
              .collection('users')
              .doc(_authService.currentUser!.uid)
              .collection('blood_pressure')
              .doc(id);
          batch.delete(docRef);
        }
        await batch.commit();
        // Clear deleted measurements list after successful deletion
        await prefs.setStringList(_deletedKey, []);
      }

      // Then handle any offline created/modified data
      final measurementsJson = prefs.getString(_key);
      if (measurementsJson != null) {
        final measurementsList = jsonDecode(measurementsJson) as List;
        final measurements =
            measurementsList.map((bp) => BloodPressure.fromJson(bp)).toList();

        final batch = _firestore.batch();
        final userBPRef = _firestore
            .collection('users')
            .doc(_authService.currentUser!.uid)
            .collection('blood_pressure');

        // Get existing measurements
        final existingMeasurements = await userBPRef.get();

        // Create a map of existing measurements by ID
        Map<String, DocumentSnapshot> existingMeasurementsMap = {};
        for (var doc in existingMeasurements.docs) {
          final measurement =
              BloodPressure.fromJson(doc.data() as Map<String, dynamic>);
          if (!deletedMeasurements.contains(measurement.id)) {
            existingMeasurementsMap[measurement.id] = doc;
          }
        }

        // Update or add measurements
        for (var measurement in measurements) {
          if (existingMeasurementsMap.containsKey(measurement.id)) {
            batch.update(existingMeasurementsMap[measurement.id]!.reference,
                measurement.toJson());
            existingMeasurementsMap.remove(measurement.id);
          } else {
            final docRef = userBPRef.doc(measurement.id);
            batch.set(docRef, measurement.toJson());
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
}
