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

  // Save measurements to SharedPreferences and Firebase if online
  Future<void> saveMeasurements(List<BloodPressure> measurements) async {
    // Save locally
    final prefs = await SharedPreferences.getInstance();
    final measurementsList = measurements.map((bp) => bp.toJson()).toList();
    await prefs.setString(_key, jsonEncode(measurementsList));

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none &&
        _authService.currentUser != null) {
      // Save to Firebase
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
  }

  // Load measurements from SharedPreferences and sync with Firebase if online
  Future<List<BloodPressure>> loadMeasurements() async {
    final prefs = await SharedPreferences.getInstance();
    List<BloodPressure> localMeasurements = [];

    // Load local data
    final measurementsJson = prefs.getString(_key);
    if (measurementsJson != null) {
      final measurementsList = jsonDecode(measurementsJson) as List;
      localMeasurements =
          measurementsList.map((bp) => BloodPressure.fromJson(bp)).toList();
    }

    // Check connectivity and sync with Firebase if online
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
          final measurements = snapshot.docs.map((doc) {
            final data = doc.data();
            return BloodPressure.fromJson(data);
          }).toList();

          // Update local storage with Firebase data
          await saveMeasurements(measurements);
          return measurements;
        }
      } catch (e) {
        print('Error syncing with Firebase: $e');
      }
    }

    return localMeasurements;
  }

  // Clear measurements from SharedPreferences and Firebase if online
  Future<void> clearMeasurements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);

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
      }
    }
  }

  // Sync local data with Firebase
  Future<void> syncWithFirebase() async {
    if (_authService.currentUser == null) return;

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
  }
}
