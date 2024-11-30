import 'package:flutter/material.dart';

class MedicationsPage extends StatefulWidget {
  @override
  _MedicationsPageState createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  bool isActiveTab = true;

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

  List<Widget> _buildActiveMedications() {
    return [
      _buildMedicationCard(
        icon: '💊',
        name: 'Omega 3',
        subtitle: 'Use of this medicine',
      ),
      _buildMedicationCard(
        icon: '💊',
        name: 'Comlivit',
        subtitle: 'Use of this medicine',
      ),
      _buildMedicationCard(
        icon: '💊',
        name: '5-HTP',
        subtitle: 'Use of this medicine',
      ),
      _buildMedicationCard(
        icon: '💊',
        name: 'Omega 1',
        subtitle: 'Use of this medicine',
      ),
    ];
  }

  List<Widget> _buildCompletedMedications() {
    return [
      _buildMedicationCard(
        icon: '💊',
        name: 'Capsule 1',
        subtitle: 'Use of this medicine',
      ),
      _buildMedicationCard(
        icon: '💊',
        name: 'Capsule 2',
        subtitle: 'Use of this medicine',
      ),
    ];
  }

  Widget _buildMedicationCard({
    required String icon,
    required String name,
    required String subtitle,
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
          Text(
            icon,
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(width: 16),
          Column(
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
        ],
      ),
    );
  }
}
