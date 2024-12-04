import 'package:flutter/material.dart';
import '../models/medication.dart';
import 'dart:math';

class AddMedicationScreen extends StatefulWidget {
  final DateTime selectedDate;

  const AddMedicationScreen({
    Key? key,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _AddMedicationScreenState createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  int _currentStep = 1;
  final _formKey = GlobalKey<FormState>();
  late DateTime _startDate;

  // Form controllers
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'Tablets';
  String _selectedPer = 'piece';
  String _selectedEvery = 'Before meals';
  List<TimeOfDay> _doseTimes = [TimeOfDay.now()];
  String _selectedDaysTaken = 'everyday';
  String _selectedEndOption = 'date';

  // Add these to your state variables
  Set<String> _selectedDays = {};
  final List<String> _daysOfWeek = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];
  DateTime _endDate =
      DateTime.now().add(Duration(days: 1)); // Tomorrow by default

  // Add these to your state variables
  TextEditingController _daysAmountController = TextEditingController();
  TextEditingController _supplyAmountController = TextEditingController();

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
    // Initialize _startDate with the selectedDate from daily page
    _startDate = widget.selectedDate;
    // Set _endDate to be one day after start date by default
    _endDate = _startDate.add(Duration(days: 1));

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

  // Add this method to show days taken options
  void _showDaysTakenOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('everyday'),
                trailing: _selectedDaysTaken == 'everyday'
                    ? Icon(Icons.check, color: Color(0xFF4CAF50))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedDaysTaken = 'everyday';
                    _selectedDays.clear(); // Clear selected days
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('selected days'),
                trailing: _selectedDaysTaken == 'selected days'
                    ? Icon(Icons.check, color: Color(0xFF4CAF50))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedDaysTaken = 'selected days';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Add these methods to handle each dropdown
  void _showMedicationTypeOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              'Tablets',
              'Capsules',
              'Injection',
              'Procedures',
              'Drops',
              'Liquid',
              'Ointment/Cream/Gel',
              'Spray'
            ]
                .map((type) => ListTile(
                      title: Text(type),
                      trailing: _selectedType == type
                          ? Icon(Icons.check, color: Color(0xFF4CAF50))
                          : null,
                      onTap: () {
                        _updatePerOptions(type);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  void _showPerOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _perOptionsMap[_selectedType]!
                .map((type) => ListTile(
                      title: Text(type),
                      trailing: _selectedPer == type
                          ? Icon(Icons.check, color: Color(0xFF4CAF50))
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedPer = type;
                        });
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  void _showEveryOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Before meals', 'After meals', 'With meals']
                .map((type) => ListTile(
                      title: Text(type),
                      trailing: _selectedEvery == type
                          ? Icon(Icons.check, color: Color(0xFF4CAF50))
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedEvery = type;
                        });
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  void _showEndOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                ['date', 'amount of days', 'medication supply', 'consistently']
                    .map((type) => ListTile(
                          title: Text(type),
                          trailing: _selectedEndOption == type
                              ? Icon(Icons.check, color: Color(0xFF4CAF50))
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedEndOption = type;
                            });
                            Navigator.pop(context);
                          },
                        ))
                    .toList(),
          ),
        );
      },
    );
  }

  // Add this method to handle start date selection
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4CAF50), // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Calendar text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  // Add this method to handle end date selection
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate, // Can't end before start date
      lastDate: DateTime.now().add(Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
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
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_selectedType),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
          onTap: _showMedicationTypeOptions,
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
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_selectedPer),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
          onTap: _showPerOptions,
        ),
        SizedBox(height: 24),
        Text(
          'Every',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_selectedEvery),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
          onTap: _showEveryOptions,
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
          itemCount: _doseTimes.length + (_doseTimes.length < 10 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _doseTimes.length) {
              return TextButton(
                onPressed: () {
                  if (_doseTimes.length < 10) {
                    setState(() {
                      _doseTimes.add(TimeOfDay.now());
                      // Sort after adding new time
                      _doseTimes.sort((a, b) {
                        int aMinutes = a.hour * 60 + a.minute;
                        int bMinutes = b.hour * 60 + b.minute;
                        return aMinutes.compareTo(bMinutes);
                      });
                    });
                  } else {
                    // Show a message when trying to add more than 10 doses
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Maximum 10 doses allowed'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text('+ More'),
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF4CAF50),
                ),
              );
            }
            return ListTile(
              title: Text('Dose ${index + 1}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _doseTimes[index].format(context),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  // Only show delete button if there's more than one dose
                  if (_doseTimes.length > 1) ...[
                    SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _doseTimes.removeAt(index);
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ],
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedDaysTaken,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
          onTap: _showDaysTakenOptions,
        ),
        if (_selectedDaysTaken == 'selected days') ...[
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _daysOfWeek.map((day) {
                final isSelected = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDays.remove(day);
                      } else {
                        _selectedDays.add(day);
                      }
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Color(0xFF4CAF50) : Colors.grey[300],
                    ),
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            'Course duration',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        ListTile(
          title: Text('Start'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _startDate == DateTime.now()
                    ? 'today'
                    : '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
          onTap: _selectStartDate,
        ),
        ListTile(
          title: Text('End'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedEndOption,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
          onTap: _showEndOptions,
        ),
        if (_selectedEndOption == 'amount of days') ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextFormField(
              controller: _daysAmountController,
              decoration: InputDecoration(
                labelText: 'Number of days',
                border: UnderlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ] else if (_selectedEndOption == 'medication supply') ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _supplyAmountController,
                  decoration: InputDecoration(
                    labelText: 'Supply amount',
                    border: UnderlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 8),
                Text(
                  'The total cannot be less than one dose of medicine',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ] else if (_selectedEndOption == 'date') ...[
          ListTile(
            title: Text('Date'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _endDate.difference(DateTime.now()).inDays <= 1
                      ? 'tomorrow'
                      : '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
            onTap: _selectEndDate,
          ),
        ],
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
        // Get the end date based on selected option
        DateTime? endDate;
        if (_selectedEndOption == 'date') {
          endDate = _endDate;
        } else if (_selectedEndOption == 'amount of days' &&
            _daysAmountController.text.isNotEmpty) {
          if (_selectedDaysTaken == 'selected days' &&
              _selectedDays.isNotEmpty) {
            // Calculate how many weeks needed to get the required doses
            int requiredDoses = int.parse(_daysAmountController.text);
            int dosesPerWeek = _selectedDays.length;

            // Calculate full weeks needed
            int fullWeeksNeeded = (requiredDoses / dosesPerWeek).floor();
            // Calculate remaining doses
            int remainingDoses = requiredDoses % dosesPerWeek;

            // Calculate total days needed (7 days per full week + days for remaining doses)
            int daysNeeded = (fullWeeksNeeded * 7);

            if (remainingDoses > 0) {
              // For remaining doses, find how many additional days needed
              List<String> sortedDays = _selectedDays.toList()..sort();
              int startDayIndex = _daysOfWeek.indexOf(sortedDays.first);
              int lastDoseIndex = -1;

              // Find the day index of the last required dose
              int doseCount = 0;
              for (int i = 0; i < 7 && doseCount < remainingDoses; i++) {
                int currentDayIndex = (startDayIndex + i) % 7;
                if (_selectedDays.contains(_daysOfWeek[currentDayIndex])) {
                  lastDoseIndex = currentDayIndex;
                  doseCount++;
                }
              }

              if (lastDoseIndex >= startDayIndex) {
                daysNeeded += (lastDoseIndex - startDayIndex + 1);
              } else {
                daysNeeded += (7 - startDayIndex + lastDoseIndex + 1);
              }
            }

            endDate = _startDate.add(Duration(days: daysNeeded - 1));
          } else {
            // For 'everyday' option, simply add the number of days minus 1
            endDate = _startDate
                .add(Duration(days: int.parse(_daysAmountController.text) - 1));
          }
        } else if (_selectedEndOption == 'consistently') {
          endDate = DateTime(_startDate.year + 10);
        }

        // Create a list of medications, one for each dose time
        final medications = _doseTimes.map((doseTime) {
          return Medication(
            name: _nameController.text,
            time: doseTime.format(context),
            color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
            date: _startDate,
            endDate: endDate,
            daysTaken: _selectedDaysTaken,
            selectedDays: _selectedDaysTaken == 'selected days'
                ? _selectedDays.toList()
                : null,
          );
        }).toList();

        Navigator.pop(context, medications);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _daysAmountController.dispose();
    _supplyAmountController.dispose();
    super.dispose();
  }
}
