import 'package:flutter/material.dart';
import '../models/medication.dart';
import 'dart:math';

class AddMedicationScreen extends StatefulWidget {
  @override
  _AddMedicationScreenState createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  int _currentStep = 1;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'Tablets';
  String _selectedPer = 'piece';
  String _selectedEvery = 'Before meals';
  List<TimeOfDay> _doseTimes = [TimeOfDay.now()];

  // Add this map for medication type to per options
  final Map<String, List<String>> _perOptionsMap = {
    'Tablets': ['pill', 'piece', 'mg', 'gr'],
    'Capsules': ['capsule', 'piece', 'mg', 'gr'],
    'Injection': [
      'piece',
      'ampoule',
      'syringe',
      'pen',
      'ml',
      'cub. cm.',
      'mg',
      'gr'
    ],
    'Procedures': ['time', 'inhalation', 'dose', 'suppository', 'enema'],
    'Drops': ['drop', 'time', 'piece'],
    'Liquid': ['cup', 'bottle', 'teaspoon', 'ml'],
    'Ointment/Cream/Gel': ['dose', 'time', 'piece'],
    'Spray': ['time', 'injection'],
  };

  @override
  void initState() {
    super.initState();
    // Set initial per option based on default medication type
    _selectedPer = _perOptionsMap[_selectedType]!.first;
  }

  // Add this method to update _selectedPer when medication type changes
  void _updatePerOptions(String? medicationType) {
    if (medicationType != null) {
      setState(() {
        _selectedType = medicationType;
        // Set to first option of new medication type
        _selectedPer = _perOptionsMap[medicationType]!.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() {
                _currentStep--;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: _currentStep / 3,
                backgroundColor: Color(0xFFE0E0E0),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add medication',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              if (_currentStep == 1) ...[
                _buildStep1(),
              ] else if (_currentStep == 2) ...[
                _buildStep2(),
              ] else ...[
                _buildStep3(),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4CAF50),
            minimumSize: Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _handleNext(),
          child: Text(
            'Next',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medication',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        DropdownButtonFormField<String>(
          value: _selectedType,
          decoration: InputDecoration(
            border: UnderlineInputBorder(),
          ),
          items: [
            'Tablets',
            'Capsules',
            'Injection',
            'Procedures',
            'Drops',
            'Liquid',
            'Ointment/Cream/Gel',
            'Spray'
          ]
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
              .toList(),
          onChanged: _updatePerOptions,
        ),
        SizedBox(height: 24),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Name (e.g: 1000mg)',
            border: UnderlineInputBorder(),
          ),
        ),
        SizedBox(height: 24),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Single dose',
            border: UnderlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 24),
        Text(
          'Per',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        DropdownButtonFormField<String>(
          value: _selectedPer,
          decoration: InputDecoration(
            border: UnderlineInputBorder(),
          ),
          items: _perOptionsMap[_selectedType]!
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedPer = value!;
            });
          },
        ),
        SizedBox(height: 24),
        Text(
          'Every',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        DropdownButtonFormField<String>(
          value: _selectedEvery,
          decoration: InputDecoration(
            border: UnderlineInputBorder(),
          ),
          items: ['Before meals', 'After meals', 'With meals']
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedEvery = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    // Sort the dose times
    _doseTimes.sort((a, b) {
      int aMinutes = a.hour * 60 + a.minute;
      int bMinutes = b.hour * 60 + b.minute;
      return aMinutes.compareTo(bMinutes);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _doseTimes.length + 1,
          itemBuilder: (context, index) {
            if (index == _doseTimes.length) {
              return TextButton(
                onPressed: () {
                  setState(() {
                    _doseTimes.add(TimeOfDay.now());
                    // Sort after adding new time
                    _doseTimes.sort((a, b) {
                      int aMinutes = a.hour * 60 + a.minute;
                      int bMinutes = b.hour * 60 + b.minute;
                      return aMinutes.compareTo(bMinutes);
                    });
                  });
                },
                child: Text('+ More'),
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF4CAF50),
                ),
              );
            }
            return ListTile(
              title: Text('Dose ${index + 1}'),
              trailing: Text(
                _doseTimes[index].format(context),
                style: TextStyle(color: Colors.grey[600]),
              ),
              onTap: () async {
                final TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: _doseTimes[index],
                );
                if (time != null) {
                  setState(() {
                    _doseTimes[index] = time;
                    // Sort after updating time
                    _doseTimes.sort((a, b) {
                      int aMinutes = a.hour * 60 + a.minute;
                      int bMinutes = b.hour * 60 + b.minute;
                      return aMinutes.compareTo(bMinutes);
                    });
                  });
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text('Days taken'),
          trailing: Text('everyday'),
          onTap: () {
            // Handle days selection
          },
        ),
        ListTile(
          title: Text('Start'),
          trailing: Text('today'),
          onTap: () {
            // Handle start date selection
          },
        ),
        ListTile(
          title: Text('End'),
          trailing: Text('date'),
          onTap: () {
            // Handle end date selection
          },
        ),
      ],
    );
  }

  void _handleNext() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Create and return the medication
      if (_formKey.currentState!.validate()) {
        Navigator.pop(
          context,
          Medication(
            name: _nameController.text,
            time: _doseTimes.first.format(context),
            taken: false,
            color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
