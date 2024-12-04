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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMedications();
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

    // Filter medications based on active/completed status
    final filteredMeds = _medications.where((med) {
      final startDate = DateTime(med.date.year, med.date.month, med.date.day);
      final endDate = med.endDate != null
          ? DateTime(med.endDate!.year, med.endDate!.month, med.endDate!.day)
          : startDate;

      if (isActiveTab) {
        return !todayDate.isBefore(startDate) && !todayDate.isAfter(endDate);
      } else {
        return todayDate.isAfter(endDate);
      }
    }).toList();

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4CAF50),
        ),
      );
    }

    // Use ListView even for empty state to ensure scrollability
    return ListView.builder(
      padding: EdgeInsets.all(16),
      // Always allow scrolling even when empty
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: filteredMeds.isEmpty ? 1 : filteredMeds.length,
      itemBuilder: (context, index) {
        if (filteredMeds.isEmpty) {
          return Container(
            height: MediaQuery.of(context).size.height *
                0.7, // Take up most of the screen
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
                      medication.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      isActiveTab
                          ? _getMedicationStatus(medication)
                          : _getCompletionReason(medication),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Time: ${medication.time}',
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
      },
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
