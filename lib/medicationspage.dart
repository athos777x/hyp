import 'package:flutter/material.dart';
import 'models/medication.dart';
import 'services/medication_service.dart';

class MedicationsPage extends StatefulWidget {
  @override
  _MedicationsPageState createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  bool isActiveTab = true;
  final MedicationService _medicationService = MedicationService();
  List<Medication> _medications = [];

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    final medications = await _medicationService.loadMedications();
    setState(() {
      _medications = medications;
    });
  }

  List<Widget> _buildActiveMedications() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final activeMeds = _medications.where((med) {
      final startDate = DateTime(med.date.year, med.date.month, med.date.day);
      final endDate = med.endDate != null
          ? DateTime(med.endDate!.year, med.endDate!.month, med.endDate!.day)
          : startDate;

      return !todayDate.isBefore(startDate) && !todayDate.isAfter(endDate);
    }).toList();

    if (activeMeds.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No active medications',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
        ),
      ];
    }

    return activeMeds.map((medication) {
      return _buildMedicationCard(
        icon: '💊',
        name: medication.name,
        subtitle: _getMedicationStatus(medication),
        medication: medication,
      );
    }).toList();
  }

  List<Widget> _buildCompletedMedications() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final completedMeds = _medications.where((med) {
      final endDate = med.endDate != null
          ? DateTime(med.endDate!.year, med.endDate!.month, med.endDate!.day)
          : DateTime(med.date.year, med.date.month, med.date.day);

      return todayDate.isAfter(endDate);
    }).toList();

    if (completedMeds.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No completed medications',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
        ),
      ];
    }

    return completedMeds.map((medication) {
      return _buildMedicationCard(
        icon: '💊',
        name: medication.name,
        subtitle: _getCompletionReason(medication),
        medication: medication,
      );
    }).toList();
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

  Widget _buildMedicationCard({
    required String icon,
    required String name,
    required String subtitle,
    required Medication medication,
  }) {
    return Container(
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
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
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
    );
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

            // Medication List
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: isActiveTab
                    ? _buildActiveMedications()
                    : _buildCompletedMedications(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
