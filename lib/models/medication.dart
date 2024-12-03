import 'package:flutter/material.dart';

class Medication {
  final String name;
  final String time;
  bool taken;
  final Color color;
  final DateTime? endDate; // Optional end date
  int? remainingSupply; // Optional remaining supply count
  int? remainingDays; // Optional remaining days
  final DateTime startDate; // When the medication was added

  Medication({
    required this.name,
    required this.time,
    required this.taken,
    required this.color,
    this.endDate,
    this.remainingSupply,
    this.remainingDays,
    DateTime? startDate,
  }) : startDate = startDate ?? DateTime.now();

  bool get isActive {
    final now = DateTime.now();

    // Check end date if it exists
    if (endDate != null && now.isAfter(endDate!)) {
      return false;
    }

    // Check remaining supply if it exists
    if (remainingSupply != null && remainingSupply! <= 0) {
      return false;
    }

    // Check remaining days if it exists
    if (remainingDays != null) {
      final daysElapsed = now.difference(startDate).inDays;
      if (daysElapsed >= remainingDays!) {
        return false;
      }
    }

    return true;
  }

  // Updated method to handle both 24-hour and 12-hour time formats
  String get formattedTime {
    // First check if the time string already contains AM/PM
    if (time.toUpperCase().contains('AM') ||
        time.toUpperCase().contains('PM')) {
      return time; // Return as-is if it's already in 12-hour format
    }

    // Handle 24-hour format
    final timeParts = time.split(':');
    int hour = int.parse(timeParts[0]);
    int minute =
        int.parse(timeParts[1].split(' ')[0]); // Remove any AM/PM if present

    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : hour;
    hour = hour == 0 ? 12 : hour;

    return '$hour:${minute.toString().padLeft(2, '0')} $period';
  }

  // Convert Medication to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'time': time,
      'taken': taken,
      'color': color.value, // Convert Color to integer
      'endDate': endDate?.toIso8601String(),
      'remainingSupply': remainingSupply,
      'remainingDays': remainingDays,
      'startDate': startDate.toIso8601String(),
    };
  }

  // Create Medication from JSON
  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'],
      time: json['time'],
      taken: json['taken'],
      color: Color(json['color']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      remainingSupply: json['remainingSupply'],
      remainingDays: json['remainingDays'],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
    );
  }
}
