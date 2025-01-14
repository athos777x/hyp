class BloodPressure {
  final String id;
  final int systolic;
  final int diastolic;
  final DateTime timestamp;

  BloodPressure({
    String? id,
    required this.systolic,
    required this.diastolic,
    required this.timestamp,
  }) : this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'systolic': systolic,
      'diastolic': diastolic,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BloodPressure.fromJson(Map<String, dynamic> json) {
    return BloodPressure(
      id: json['id'],
      systolic: json['systolic'],
      diastolic: json['diastolic'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
