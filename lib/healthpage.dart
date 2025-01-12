import 'package:flutter/material.dart';
import 'screens/add_measurement_screen.dart';
import 'models/blood_pressure.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class HealthPage extends StatefulWidget {
  static Future<void> clearMeasurements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('measurements');
  }

  @override
  _HealthPageState createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  List<BloodPressure> measurements = [];

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    final prefs = await SharedPreferences.getInstance();
    final measurementsJson = prefs.getStringList('measurements') ?? [];

    setState(() {
      measurements = measurementsJson.map((json) {
        final map = jsonDecode(json);
        return BloodPressure(
          systolic: map['systolic'],
          diastolic: map['diastolic'],
          timestamp: DateTime.parse(map['timestamp']),
        );
      }).toList();
    });
  }

  Future<void> _saveMeasurements() async {
    final prefs = await SharedPreferences.getInstance();
    final measurementsJson = measurements.map((measurement) {
      return jsonEncode({
        'systolic': measurement.systolic,
        'diastolic': measurement.diastolic,
        'timestamp': measurement.timestamp.toIso8601String(),
      });
    }).toList();

    await prefs.setStringList('measurements', measurementsJson);
  }

  void _showMeasurementOptions(int index, BloodPressure measurement) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit measurement'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMeasurementScreen(
                      measurement: measurement,
                    ),
                  ),
                );
                if (result != null && result is BloodPressure) {
                  setState(() {
                    measurements[index] = result;
                  });
                  _saveMeasurements();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete measurement'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  measurements.removeAt(index);
                });
                _saveMeasurements();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(top: 30.0),
          child: Text(
            'Health monitoring',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blood pressure card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Blood pressure',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            measurements.isEmpty
                                ? '-/-'
                                : '${measurements[0].systolic}/${measurements[0].diastolic}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: measurements.isNotEmpty
                                  ? (measurements[0].systolic >= 180 ||
                                          measurements[0].diastolic >= 110)
                                      ? Colors.red
                                      : (measurements[0].systolic >= 140 ||
                                              measurements[0].diastolic >= 90)
                                          ? Colors.amber[700]
                                          : null
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'SYS/DIA',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddMeasurementScreen()),
                          );
                          if (result != null && result is BloodPressure) {
                            setState(() {
                              measurements.insert(0, result);
                            });
                            _saveMeasurements();
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Add measurement',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // History section
            const Text(
              'History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // History items
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: measurements.length,
                itemBuilder: (context, index) {
                  final measurement = measurements[index];
                  return GestureDetector(
                    onTap: () => _showMeasurementOptions(index, measurement),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${measurement.systolic}/${measurement.diastolic}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: (measurement.systolic >= 180 ||
                                      measurement.diastolic >= 110)
                                  ? Colors.red
                                  : (measurement.systolic >= 140 ||
                                          measurement.diastolic >= 90)
                                      ? Colors.amber[700]
                                      : null,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                DateFormat('MMM d, h:mm a')
                                    .format(measurement.timestamp),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
