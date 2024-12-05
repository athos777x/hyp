class BloodPressure {
  final int systolic;
  final int diastolic;
  final DateTime timestamp;

  BloodPressure({
    required this.systolic,
    required this.diastolic,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'systolic': systolic,
      'diastolic': diastolic,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BloodPressure.fromJson(Map<String, dynamic> json) {
    return BloodPressure(
      systolic: json['systolic'],
      diastolic: json['diastolic'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
