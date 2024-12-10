import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _key = 'medications';

  // Save medications to SharedPreferences
  Future<void> saveMedications(List<Medication> medications) async {
    final prefs = await SharedPreferences.getInstance();
    final medicationList = medications.map((med) => med.toJson()).toList();
    await prefs.setString(_key, jsonEncode(medicationList));
  }

  // Load medications from SharedPreferences
  Future<List<Medication>> loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final medicationJson = prefs.getString(_key);

    if (medicationJson == null) return [];

    final medicationList = jsonDecode(medicationJson) as List;
    return medicationList.map((med) => Medication.fromJson(med)).toList();
  }

  // Clear medications from SharedPreferences
  Future<void> clearMedications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<List<Medication>> getMedications() async {
    try {
      final snapshot = await _firestore.collection('medications').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Medication(
          name: data['name'] ?? '',
          date: (data['date'] as Timestamp).toDate(),
          endDate: data['endDate'] != null
              ? (data['endDate'] as Timestamp).toDate()
              : null,
          time: data['time'] ?? '',
          doseTimes: data['doseTimes'] != null
              ? List<TimeOfDay>.from((data['doseTimes'] as List).map(
                  (timeMap) => TimeOfDay(
                      hour: timeMap['hour'] as int,
                      minute: timeMap['minute'] as int)))
              : null,
          daysTaken: data['daysTaken'] ?? 'everyday',
          selectedDays: data['selectedDays'] != null
              ? List<String>.from(data['selectedDays'])
              : null,
          selectedEndOption: data['selectedEndOption'] ?? 'date',
          daysAmount: data['daysAmount'],
          supplyAmount: data['supplyAmount'],
          type: data['type'],
          per: data['per'],
          every: data['every'],
          amount: data['amount'],
          color: Color(data['color'] ?? 0xFF000000),
        );
      }).toList();
    } catch (e) {
      print('Error getting medications: $e');
      return [];
    }
  }
}
