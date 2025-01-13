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
    // Save locally
    final prefs = await SharedPreferences.getInstance();
    final medicationList = medications.map((med) => med.toJson()).toList();
    await prefs.setString(_key, jsonEncode(medicationList));

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none &&
        _authService.currentUser != null) {
      // Save to Firebase
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

      // Create a map to group medications by name
      final Map<String, Medication> uniqueMedications = {};
      for (var medication in medications) {
        // Use the name as the key to ensure uniqueness
        uniqueMedications[medication.name] = medication;
      }

      // Add medications to Firebase (one document per unique medication)
      for (var medication in uniqueMedications.values) {
        final docRef = userMedicationsRef.doc();
        batch.set(docRef, medication.toMap());
      }

      await batch.commit();
    }
  }

  // Load medications from SharedPreferences and sync with Firebase if online
  Future<List<Medication>> loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    List<Medication> localMedications = [];

    // Load local data
    final medicationJson = prefs.getString(_key);
    if (medicationJson != null) {
      final medicationList = jsonDecode(medicationJson) as List;
      localMedications =
          medicationList.map((med) => Medication.fromJson(med)).toList();
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
          final medications = snapshot.docs.map((doc) {
            final data = doc.data();
            return Medication.fromMap(data);
          }).toList();

          // Update local storage with Firebase data
          await saveMedications(medications);
          return medications;
        }
      } catch (e) {
        print('Error syncing with Firebase: $e');
      }
    }

    return localMedications;
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
}
