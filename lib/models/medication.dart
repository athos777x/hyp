import 'package:flutter/material.dart';

class Medication {
  final String name;
  final DateTime date;
  final DateTime? endDate;
  final String time;
  final Color color;
  bool taken;

  Medication({
    required this.name,
    required this.date,
    this.endDate,
    required this.time,
    required this.color,
    this.taken = false,
  });

  String get formattedTime => time;

  Map<String, dynamic> toJson() => {
        'name': name,
        'date': date.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'time': time,
        'color': color.value,
        'taken': taken,
      };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        name: json['name'],
        date: DateTime.parse(json['date']),
        endDate:
            json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        time: json['time'],
        color: Color(json['color']),
        taken: json['taken'] ?? false,
      );
}
