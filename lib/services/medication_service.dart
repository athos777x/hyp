import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication.dart';

class MedicationService {
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
}
