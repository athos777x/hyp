import 'package:flutter/material.dart';

class Medication {
  final String name;
  final String time;
  bool taken;
  final Color color;

  Medication({
    required this.name,
    required this.time,
    required this.taken,
    required this.color,
  });

  // Add this method to get formatted time for display
  String get formattedTime {
    final timeParts = time.split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);

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
    };
  }

  // Create Medication from JSON
  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'],
      time: json['time'],
      taken: json['taken'],
      color: Color(json['color']),
    );
  }
}
