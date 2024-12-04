import 'package:flutter/material.dart';

class Medication {
  final String name;
  final DateTime date;
  final DateTime? endDate;
  final String time;
  final Color color;
  bool taken;
  final List<String>? selectedDays;
  final String daysTaken;

  Medication({
    required this.name,
    required this.date,
    this.endDate,
    required this.time,
    required this.color,
    this.taken = false,
    this.selectedDays,
    this.daysTaken = 'everyday',
  });

  String get formattedTime => time;

  Map<String, dynamic> toJson() => {
        'name': name,
        'date': date.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'time': time,
        'color': color.value,
        'taken': taken,
        'selectedDays': selectedDays,
        'daysTaken': daysTaken,
      };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        name: json['name'],
        date: DateTime.parse(json['date']),
        endDate:
            json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        time: json['time'],
        color: Color(json['color']),
        taken: json['taken'] ?? false,
        selectedDays: json['selectedDays'] != null
            ? List<String>.from(json['selectedDays'])
            : null,
        daysTaken: json['daysTaken'] ?? 'everyday',
      );
}
