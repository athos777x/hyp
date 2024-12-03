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
