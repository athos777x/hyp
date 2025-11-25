import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/blood_pressure.dart';
import 'screens/add_measurement_screen.dart';
import 'screens/blood_pressure_histogram_screen.dart';
import 'services/blood_pressure_service.dart';
import 'services/event_bus_service.dart';

class HealthPage extends StatefulWidget {
  static Future<void> clearMeasurements() async {
    await BloodPressureService().clearMeasurements();
  }

  @override
  _HealthPageState createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  static const bool _showTestingActions =
      false; // TODO: Change to false before deploying
  List<BloodPressure> measurements = [];
  bool _isLoading = false;
  final BloodPressureService _bloodPressureService = BloodPressureService();
  late StreamSubscription _bloodPressureUpdateSubscription;

  @override
  void initState() {
    super.initState();

    // Add subscription to blood pressure updates
    _bloodPressureUpdateSubscription = EventBusService()
        .bloodPressureUpdateStream
        .listen((_) => _loadMeasurements());

    _loadMeasurements();
  }

  @override
  void dispose() {
    _bloodPressureUpdateSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadMeasurements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final loadedMeasurements = await _bloodPressureService.loadMeasurements();
      setState(() {
        measurements = loadedMeasurements;
      });
    } catch (e) {
      print('Error loading measurements: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveMeasurements() async {
    await _bloodPressureService.saveMeasurements(measurements);
    EventBusService().notifyBloodPressureUpdate();
  }

  Future<void> _generateSampleData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final random = Random();
      final now = DateTime.now();
      final earliestTargetMonth = DateTime(now.year, now.month - 11, 1);
      final monthKeyFormatter = DateFormat('yyyy-MM');

      String buildSampleId(DateTime timestamp, int entryIndex) {
        final monthKey = monthKeyFormatter.format(timestamp);
        final salt = random.nextInt(1 << 30);
        return 'sample_${monthKey}_${timestamp.microsecondsSinceEpoch}_'
            '${entryIndex}_$salt';
      }

      final preservedMeasurements = measurements
          .where((bp) => bp.timestamp.isBefore(earliestTargetMonth))
          .toList();
      final generated = List<BloodPressure>.from(preservedMeasurements);

      final monthsDescending = List<DateTime>.generate(
        12,
        (index) => DateTime(now.year, now.month - index, 1),
      );

      for (final monthDate in monthsDescending) {
        final daysInMonth =
            DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
        final entriesForMonth = 1 + random.nextInt(5); // 1-5 entries

        for (int entry = 0; entry < entriesForMonth; entry++) {
          final day = random.nextInt(daysInMonth) + 1;
          final timestamp = DateTime(
            monthDate.year,
            monthDate.month,
            day,
            random.nextInt(24),
            random.nextInt(60),
          );
          final systolic = 110 + random.nextInt(45); // 110-154
          int diastolic = 65 + random.nextInt(25); // 65-89
          if (diastolic >= systolic) {
            diastolic = systolic - 5;
          }

          generated.add(
            BloodPressure(
              id: buildSampleId(timestamp, entry),
              systolic: systolic,
              diastolic: diastolic,
              timestamp: timestamp,
            ),
          );
        }
      }

      // Ensure every month is represented at least once with a deterministic entry.
      final monthsAscending = monthsDescending.reversed.toList();
      for (final monthDate in monthsAscending) {
        final monthKey = monthKeyFormatter.format(monthDate);
        final hasMeasurementsForMonth = generated.any(
          (bp) => monthKeyFormatter.format(bp.timestamp) == monthKey,
        );

        if (!hasMeasurementsForMonth) {
          final timestamp = DateTime(
            monthDate.year,
            monthDate.month,
            15,
            9 + random.nextInt(8),
            random.nextInt(60),
          );
          generated.add(
            BloodPressure(
              id: buildSampleId(timestamp, 9999),
              systolic: 120 + random.nextInt(20),
              diastolic: 75 + random.nextInt(10),
              timestamp: timestamp,
            ),
          );
        }
      }

      generated.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await _bloodPressureService.saveMeasurements(generated);
      if (!mounted) return;

      setState(() {
        measurements = generated;
      });

      EventBusService().notifyBloodPressureUpdate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Replaced the last 12 months with generated sample measurements.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate samples: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmAndClearMeasurements() async {
    final shouldClear = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reset measurements?'),
            content: const Text(
              'This will delete the last 12 months of data plus any unsynced readings. '
              'Use only for local testing.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldClear) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _bloodPressureService.clearMeasurements();
      EventBusService().notifyBloodPressureUpdate();
      if (!mounted) return;
      setState(() {
        measurements = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All measurements deleted.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear measurements: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                  final updatedMeasurements =
                      List<BloodPressure>.from(measurements);
                  final indexToUpdate = updatedMeasurements
                      .indexWhere((m) => m.id == measurement.id);
                  if (indexToUpdate != -1) {
                    updatedMeasurements[indexToUpdate] = result;
                    await _bloodPressureService
                        .saveMeasurements(updatedMeasurements);
                    EventBusService().notifyBloodPressureUpdate();
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete measurement'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  // Update local state first
                  final updatedMeasurements =
                      List<BloodPressure>.from(measurements);
                  updatedMeasurements
                      .removeWhere((m) => m.id == measurement.id);

                  // Track the deleted measurement
                  await _bloodPressureService.deleteMeasurement(measurement.id);

                  // Save changes
                  await _bloodPressureService
                      .saveMeasurements(updatedMeasurements);
                  EventBusService().notifyBloodPressureUpdate();
                } catch (e) {
                  print('Error deleting measurement: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Changes saved locally. Will sync when online.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 22.0, right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: 'View histogram',
                  icon: const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    if (measurements.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Add a measurement to see the histogram.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BloodPressureHistogramScreen(
                          measurements: List<BloodPressure>.from(measurements),
                        ),
                      ),
                    );
                  },
                ),
                if (_showTestingActions) ...[
                  IconButton(
                    tooltip: 'Generate sample data',
                    icon: const Icon(
                      Icons.auto_graph_rounded,
                      color: Colors.green,
                    ),
                    onPressed: _isLoading ? null : _generateSampleData,
                  ),
                  IconButton(
                    tooltip: 'Clear all measurements',
                    icon: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.redAccent,
                    ),
                    onPressed: _isLoading ? null : _confirmAndClearMeasurements,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            )
          : Padding(
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
                                                measurements[0].diastolic >=
                                                    110)
                                            ? Colors.red
                                            : (measurements[0].systolic >=
                                                        140 ||
                                                    measurements[0].diastolic >=
                                                        90)
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
                                      builder: (context) =>
                                          AddMeasurementScreen()),
                                );
                                if (result != null && result is BloodPressure) {
                                  final updatedMeasurements =
                                      List<BloodPressure>.from(measurements);
                                  updatedMeasurements.insert(0, result);
                                  await _bloodPressureService
                                      .saveMeasurements(updatedMeasurements);
                                  EventBusService().notifyBloodPressureUpdate();
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

                  // History items with RefreshIndicator
                  Expanded(
                    child: RefreshIndicator(
                      color: Color(0xFF4CAF50),
                      onRefresh: _loadMeasurements,
                      child: measurements.isEmpty
                          ? ListView(
                              children: [
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.4,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.monitor_heart_outlined,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No measurements recorded',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: measurements.length,
                              itemBuilder: (context, index) {
                                final measurement = measurements[index];
                                return GestureDetector(
                                  onTap: () => _showMeasurementOptions(
                                      index, measurement),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${measurement.systolic}/${measurement.diastolic}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: (measurement.systolic >=
                                                        180 ||
                                                    measurement.diastolic >=
                                                        110)
                                                ? Colors.red
                                                : (measurement.systolic >=
                                                            140 ||
                                                        measurement.diastolic >=
                                                            90)
                                                    ? Colors.amber[700]
                                                    : null,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              DateFormat('MMM d, yyyy, h:mm a')
                                                  .format(
                                                      measurement.timestamp),
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
                  ),
                ],
              ),
            ),
    );
  }
}
