import 'package:flutter/material.dart';
import 'models/medication.dart';
import 'services/medication_service.dart';
import 'screens/add_medication_screen.dart';
import 'services/event_bus_service.dart';
import 'dart:async';
import 'services/notification_service.dart';

class MedicationsPage extends StatefulWidget {
  @override
  _MedicationsPageState createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  bool isActiveTab = true;
  final MedicationService _medicationService = MedicationService();
  List<Medication> _medications = [];
  bool _isLoading = false;
  late StreamSubscription _medicationUpdateSubscription;

  @override
  void initState() {
    super.initState();

    // Add subscription to medication updates
    _medicationUpdateSubscription = EventBusService()
        .medicationUpdateStream
        .listen((_) => _loadMedications());

    _loadMedications();
  }

  @override
  void dispose() {
    _medicationUpdateSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
    });

    final medications = await _medicationService.loadMedications();
    setState(() {
      _medications = medications;
      _isLoading = false;
    });
  }

  String _getMedicationStatus(Medication medication) {
    final now = DateTime.now();
    final medicationDate = DateTime(
      medication.date.year,
      medication.date.month,
      medication.date.day,
    );
    final todayDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    if (medicationDate.isAtSameMomentAs(todayDate)) {
      return medication.taken ? 'Taken' : 'Not taken';
    } else if (medicationDate.isBefore(todayDate)) {
      return 'Past medication';
    } else {
      return 'Future medication';
    }
  }

  String _getCompletionReason(Medication medication) {
    final now = DateTime.now();
    final medicationDate = DateTime(
      medication.date.year,
      medication.date.month,
      medication.date.day,
    );
    final todayDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    if (medicationDate.isBefore(todayDate)) {
      return medication.taken ? 'Completed' : 'Missed';
    } else if (medicationDate.isAfter(todayDate)) {
      return 'Scheduled';
    } else {
      return medication.taken ? 'Taken today' : 'Not taken yet';
    }
  }

  Widget _buildMedicationsList() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Group medications by name
    Map<String, Medication> uniqueMeds = {};

    for (var med in _medications) {
      // Only add if not already present, keeping the first instance of each medication
      if (!uniqueMeds.containsKey(med.name)) {
        uniqueMeds[med.name] = med;
      }
    }

    // Filter medications based on active/completed status
    final filteredMeds = uniqueMeds.values.where((med) {
      final startDate = DateTime(med.date.year, med.date.month, med.date.day);
      final endDate = med.endDate != null
          ? DateTime(med.endDate!.year, med.endDate!.month, med.endDate!.day)
          : startDate;

      if (isActiveTab) {
        // Active medications
        if (med.daysTaken == 'consistently') {
          return true; // Always show consistently taken medications in active
        }
        return !todayDate.isAfter(endDate); // Show if not past end date
      } else {
        // Completed medications
        if (med.daysTaken == 'consistently') {
          return false; // Never show consistently taken medications in completed
        }
        return todayDate.isAfter(endDate); // Show if past end date
      }
    }).toList();

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4CAF50),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: filteredMeds.isEmpty ? 1 : filteredMeds.length,
      itemBuilder: (context, index) {
        if (filteredMeds.isEmpty) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    isActiveTab
                        ? 'No active medications'
                        : 'No completed medications',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final medication = filteredMeds[index];
        return GestureDetector(
          onTap: () => _showMedicationOptions(medication.name, filteredMeds),
          child: Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(16),
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
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: medication.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _getMedicationRule(medication),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getMedicationRule(Medication medication) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final startDate = DateTime(
      medication.date.year,
      medication.date.month,
      medication.date.day,
    );

    // For consistently taken medications (maintenance)
    if (medication.daysTaken == 'consistently') {
      return 'Maintenance medication (taken daily)';
    }

    // For medications with specific end options
    switch (medication.selectedEndOption) {
      case 'date':
        if (medication.endDate != null) {
          final endDate = DateTime(
            medication.endDate!.year,
            medication.endDate!.month,
            medication.endDate!.day,
          );
          if (todayDate.isAfter(endDate)) {
            return 'Completed on ${endDate.day}/${endDate.month}/${endDate.year}';
          } else {
            return 'Until ${endDate.day}/${endDate.month}/${endDate.year}';
          }
        }
        break;

      case 'amount of days':
        if (medication.daysAmount != null) {
          final totalDays = int.parse(medication.daysAmount!);
          final endDate = startDate.add(Duration(days: totalDays - 1));

          if (todayDate.isAfter(endDate)) {
            return 'Completed after $totalDays days';
          } else {
            final remainingDays = endDate.difference(todayDate).inDays + 1;
            return '$remainingDays days remaining of $totalDays days';
          }
        }
        break;

      case 'medication supply':
        if (medication.supplyAmount != null) {
          final totalSupply = int.parse(medication.supplyAmount!);
          final dosesPerDay = medication.doseTimes?.length ?? 1;
          int daysPerWeek = medication.daysTaken == 'everyday'
              ? 7
              : medication.selectedDays?.length ?? 7;

          // Calculate total days needed
          final totalDays =
              (totalSupply / dosesPerDay * 7 / daysPerWeek).ceil();
          final endDate = startDate.add(Duration(days: totalDays - 1));

          if (todayDate.isAfter(endDate)) {
            return 'Completed (supply exhausted)';
          } else {
            // Calculate days since start
            final daysSinceStart = todayDate.difference(startDate).inDays;

            // Calculate how many doses have been used
            final weeksElapsed = daysSinceStart ~/ 7;
            final remainingDaysInWeek = daysSinceStart % 7;

            // Count doses used in complete weeks
            int dosesUsed = weeksElapsed * daysPerWeek * dosesPerDay;

            // Add doses used in remaining days
            for (int i = 0; i < remainingDaysInWeek; i++) {
              final checkDate =
                  startDate.add(Duration(days: weeksElapsed * 7 + i));
              if (medication.daysTaken == 'everyday' ||
                  (medication.selectedDays
                          ?.contains(_getDayAbbreviation(checkDate)) ??
                      false)) {
                dosesUsed += dosesPerDay;
              }
            }

            final remainingDoses = totalSupply - dosesUsed;
            return '$remainingDoses doses remaining of $totalSupply';
          }
        }
        break;
    }

    // For medications with specific days
    if (medication.daysTaken == 'selected days' &&
        medication.selectedDays != null) {
      final days = medication.selectedDays!.join(', ');
      return 'Taken on: $days';
    }

    // Default case for everyday medications
    return 'Taken daily';
  }

  void _showMedicationOptions(
      String medicationName, List<Medication> medications) {
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
              title: const Text('Edit medication'),
              onTap: () async {
                Navigator.pop(context);
                // Get all instances of this medication to edit
                final medicationsToEdit = _medications
                    .where((m) => m.name == medicationName)
                    .toList();
                if (medicationsToEdit.isNotEmpty) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMedicationScreen(
                        selectedDate: medicationsToEdit[0].date,
                        medicationToEdit: medicationsToEdit[0],
                      ),
                    ),
                  );

                  if (result != null && result is List<Medication>) {
                    try {
                      // Update local state first
                      setState(() {
                        _medications
                            .removeWhere((m) => m.name == medicationName);
                        _medications.addAll(result);
                      });
                      // Try to save changes
                      await _medicationService.saveMedications(_medications);
                      EventBusService().notifyMedicationUpdate();
                    } catch (e) {
                      print('Error saving medication edit: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Changes saved locally. Will sync when online.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete medication'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  // Update local state first
                  setState(() {
                    _medications.removeWhere((m) => m.name == medicationName);
                  });

                  // Track the deleted medication
                  await _medicationService.deleteMedication(medicationName);

                  // Try to save changes and cancel notifications
                  await Future.wait([
                    _medicationService.saveMedications(_medications),
                    NotificationService()
                        .cancelMedicationNotifications(medicationName),
                  ]);

                  EventBusService().notifyMedicationUpdate();
                  _loadMedications();
                } catch (e) {
                  print('Error deleting medication: $e');
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

  void _addNewMedication() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(
          selectedDate: DateTime.now(),
        ),
      ),
    );

    if (result != null && result is List<Medication>) {
      setState(() {
        _medications.addAll(result);
      });
      await _medicationService.saveMedications(_medications);
      EventBusService().notifyMedicationUpdate();
    }
  }

  String _getDayAbbreviation(DateTime date) {
    final days = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];
    return days[date.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Segmented Control
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 16.0),
              child: Container(
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
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isActiveTab = true),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isActiveTab
                                ? Color(0xFF4CAF50)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Active',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  isActiveTab ? Colors.white : Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isActiveTab = false),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isActiveTab
                                ? Color(0xFF4CAF50)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Completed',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !isActiveTab
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Medication List with RefreshIndicator
            Expanded(
              child: RefreshIndicator(
                color: Color(0xFF4CAF50),
                onRefresh: _loadMedications,
                child: _buildMedicationsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
