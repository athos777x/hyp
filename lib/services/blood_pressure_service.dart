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

  // Save measurements to SharedPreferences and Firebase if online
  Future<void> saveMeasurements(List<BloodPressure> measurements) async {
    try {
      // Always save locally first
      final prefs = await SharedPreferences.getInstance();
      final measurementsList = measurements.map((bp) => bp.toJson()).toList();
      await prefs.setString(_key, jsonEncode(measurementsList));

      // Try to save to Firebase if online and authenticated
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none &&
          _authService.currentUser != null) {
        try {
          final batch = _firestore.batch();
          final userBPRef = _firestore
              .collection('users')
              .doc(_authService.currentUser!.uid)
              .collection('blood_pressure');

          // Get existing measurements from Firebase
          final existingMeasurements = await userBPRef.get();

          // Create a map of existing measurements by ID
          Map<String, DocumentSnapshot> existingMeasurementsMap = {};
          for (var doc in existingMeasurements.docs) {
            final measurement =
                BloodPressure.fromJson(doc.data() as Map<String, dynamic>);
            existingMeasurementsMap[measurement.id] = doc;
          }

          // Update or add measurements
          for (var measurement in measurements) {
            if (existingMeasurementsMap.containsKey(measurement.id)) {
              // Update existing measurement
              batch.update(existingMeasurementsMap[measurement.id]!.reference,
                  measurement.toJson());
              existingMeasurementsMap.remove(measurement.id);
            } else {
              // Add new measurement
              final docRef = userBPRef.doc();
              batch.set(docRef, measurement.toJson());
            }
          }

          // Delete measurements that no longer exist locally
          for (var doc in existingMeasurementsMap.values) {
            batch.delete(doc.reference);
          }

          await batch.commit();
        } catch (e) {
          print('Error saving to Firebase: $e');
          // Continue even if Firebase save fails
        }
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
              // Only update if measurement doesn't exist locally
              if (!measurementsMap.containsKey(measurement.id)) {
                measurementsMap[measurement.id] = measurement;
              }
            }

            // Convert map back to list and sort by timestamp
            final mergedMeasurements = measurementsMap.values.toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

            // Save merged data back to local storage
            await saveMeasurements(mergedMeasurements);

            // Clear deleted measurements list if sync successful
            if (deletedMeasurements.isNotEmpty) {
              await prefs.setStringList(_deletedKey, []);
            }

            return mergedMeasurements;
          }
        } catch (e) {
          print('Error syncing with Firebase: $e');
          // Return local data if Firebase sync fails
        }
      }

      return localMeasurements;
    } catch (e) {
      print('Error in loadMeasurements: $e');
      return [];
    }
  }

  // Track deleted measurement
  Future<void> deleteMeasurement(String measurementId) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedMeasurements =
        Set<String>.from(prefs.getStringList(_deletedKey) ?? []);

    deletedMeasurements.add(measurementId);
    await prefs.setStringList(_deletedKey, deletedMeasurements.toList());
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

        // Delete existing measurements
        final existingMeasurements = await userBPRef.get();
        for (var doc in existingMeasurements.docs) {
          batch.delete(doc.reference);
        }

        // Add new measurements
        for (var measurement in measurements) {
          final docRef = userBPRef.doc();
          batch.set(docRef, measurement.toJson());
        }

        await batch.commit();
      }
    } catch (e) {
      print('Error in syncWithFirebase: $e');
      // Continue even if sync fails
    }
  }
}
