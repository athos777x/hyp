import 'package:flutter/material.dart';

class Medication {
  final String name;
  final DateTime date;
  DateTime? endDate;
  final String time;
  final Color color;
  bool taken;
  final List<String>? selectedDays;
  final String daysTaken;
  final String? selectedEndOption;
  final String? daysAmount;
  final String? supplyAmount;
  final List<TimeOfDay>? doseTimes;
  final String? type;
  final String? per;
  final String? every;
  final String? amount;

  Medication({
    required this.name,
    required this.date,
    this.endDate,
    required this.time,
    required this.color,
    this.taken = false,
    this.selectedDays,
    this.daysTaken = 'everyday',
    this.selectedEndOption,
    this.daysAmount,
    this.supplyAmount,
    this.doseTimes,
    this.type,
    this.per,
    this.every,
    this.amount,
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
        'selectedEndOption': selectedEndOption,
        'daysAmount': daysAmount,
        'supplyAmount': supplyAmount,
        'doseTimes':
            doseTimes?.map((time) => '${time.hour}:${time.minute}').toList(),
        'type': type,
        'per': per,
        'every': every,
        'amount': amount,
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
        selectedEndOption: json['selectedEndOption'],
        daysAmount: json['daysAmount'],
        supplyAmount: json['supplyAmount'],
        doseTimes: json['doseTimes'] != null
            ? (json['doseTimes'] as List).map((timeStr) {
                final parts = timeStr.split(':');
                return TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );
              }).toList()
            : null,
        type: json['type'],
        per: json['per'],
        every: json['every'],
        amount: json['amount'],
      );
}
