import 'package:flutter/material.dart';

class Medication {
  final String name;
  final DateTime date;
  DateTime? endDate;
  final String time;
  final Color color;
  bool taken;
  bool skipped;
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
  final List<TimeOfDay>? finalDayDoses;

  Medication({
    required this.name,
    required this.date,
    this.endDate,
    required this.time,
    required this.color,
    this.taken = false,
    this.skipped = false,
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
    this.finalDayDoses,
  });

  String get formattedTime => time;

  Map<String, dynamic> toJson() => {
        'name': name,
        'date': date.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'time': time,
        'color': color.value,
        'taken': taken,
        'skipped': skipped,
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
        'finalDayDoses':
            finalDayDoses?.map((t) => '${t.hour}:${t.minute}').toList(),
      };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        name: json['name'],
        date: DateTime.parse(json['date']),
        endDate:
            json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        time: json['time'],
        color: Color(json['color']),
        taken: json['taken'] ?? false,
        skipped: json['skipped'] ?? false,
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
        finalDayDoses: json['finalDayDoses'] != null
            ? (json['finalDayDoses'] as List).map((t) {
                final parts = t.split(':');
                return TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );
              }).toList()
            : null,
      );

  Medication copyWith({
    String? name,
    DateTime? date,
    DateTime? endDate,
    String? time,
    Color? color,
    bool? taken,
    bool? skipped,
    List<String>? selectedDays,
    String? daysTaken,
    String? selectedEndOption,
    String? daysAmount,
    String? supplyAmount,
    List<TimeOfDay>? doseTimes,
    String? type,
    String? per,
    String? every,
    String? amount,
    List<TimeOfDay>? finalDayDoses,
  }) {
    return Medication(
      name: name ?? this.name,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      time: time ?? this.time,
      color: color ?? this.color,
      taken: taken ?? this.taken,
      skipped: skipped ?? this.skipped,
      selectedDays: selectedDays ?? this.selectedDays,
      daysTaken: daysTaken ?? this.daysTaken,
      selectedEndOption: selectedEndOption ?? this.selectedEndOption,
      daysAmount: daysAmount ?? this.daysAmount,
      supplyAmount: supplyAmount ?? this.supplyAmount,
      doseTimes: doseTimes ?? this.doseTimes,
      type: type ?? this.type,
      per: per ?? this.per,
      every: every ?? this.every,
      amount: amount ?? this.amount,
      finalDayDoses: finalDayDoses ?? this.finalDayDoses,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': date.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'time': time,
      'color': color.value,
      'taken': taken,
      'skipped': skipped,
      'selectedDays': selectedDays,
      'daysTaken': daysTaken,
      'selectedEndOption': selectedEndOption,
      'daysAmount': daysAmount,
      'supplyAmount': supplyAmount,
      'doseTimes': doseTimes?.map((t) => '${t.hour}:${t.minute}').toList(),
      'type': type,
      'per': per,
      'every': every,
      'amount': amount,
      'finalDayDoses':
          finalDayDoses?.map((t) => '${t.hour}:${t.minute}').toList(),
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      name: map['name'],
      date: DateTime.parse(map['date']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      time: map['time'],
      color: Color(map['color']),
      taken: map['taken'] ?? false,
      skipped: map['skipped'] ?? false,
      selectedDays: map['selectedDays'] != null
          ? List<String>.from(map['selectedDays'])
          : null,
      daysTaken: map['daysTaken'] ?? 'everyday',
      selectedEndOption: map['selectedEndOption'],
      daysAmount: map['daysAmount'],
      supplyAmount: map['supplyAmount'],
      doseTimes: map['doseTimes'] != null
          ? (map['doseTimes'] as List).map((t) {
              final parts = t.split(':');
              return TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            }).toList()
          : null,
      type: map['type'],
      per: map['per'],
      every: map['every'],
      amount: map['amount'],
      finalDayDoses: map['finalDayDoses'] != null
          ? (map['finalDayDoses'] as List).map((t) {
              final parts = t.split(':');
              return TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            }).toList()
          : null,
    );
  }
}
