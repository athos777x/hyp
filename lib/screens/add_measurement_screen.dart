import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/blood_pressure.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/blood_pressure_notification_service.dart';

class AddMeasurementScreen extends StatefulWidget {
  final BloodPressure? measurement;

  const AddMeasurementScreen({Key? key, this.measurement}) : super(key: key);

  @override
  _AddMeasurementScreenState createState() => _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends State<AddMeasurementScreen> {
  TimeOfDay selectedTime = TimeOfDay.now();
  DateTime selectedDate = DateTime.now();
  bool remindToMeasure = false;
  TextEditingController sysController = TextEditingController();
  TextEditingController diaController = TextEditingController();
  Set<String> _selectedDays = {};
  final List<String> _daysOfWeek = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];
  List<TimeOfDay> _reminderTimes = [TimeOfDay.now()];

  @override
  void initState() {
    super.initState();
    if (widget.measurement != null) {
      sysController.text = widget.measurement!.systolic.toString();
      diaController.text = widget.measurement!.diastolic.toString();
      selectedTime = TimeOfDay.fromDateTime(widget.measurement!.timestamp);
      selectedDate = widget.measurement!.timestamp;
    }
    _loadReminderPreferences();
  }

  Future<void> _loadReminderPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      remindToMeasure = prefs.getBool('remindToMeasure') ?? false;
      _selectedDays =
          Set<String>.from(prefs.getStringList('selectedDays') ?? []);

      // Load reminder times
      final savedTimes = prefs.getStringList('reminderTimes') ?? [];
      _reminderTimes = savedTimes.map((timeStr) {
        final parts = timeStr.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList();

      if (_reminderTimes.isEmpty) {
        _reminderTimes = [TimeOfDay.now()];
      }
    });
  }

  Future<void> _saveReminderPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remindToMeasure', remindToMeasure);
    await prefs.setStringList('selectedDays', _selectedDays.toList());

    // Save reminder times
    final timeStrings =
        _reminderTimes.map((time) => '${time.hour}:${time.minute}').toList();
    await prefs.setStringList('reminderTimes', timeStrings);

    // Schedule notifications
    await BloodPressureNotificationService().scheduleReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        leadingWidth: 48,
        leading: Padding(
          padding: EdgeInsets.only(top: 16.0),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: Padding(
          padding: EdgeInsets.only(top: 16.0),
          child: Text(
            widget.measurement != null ? 'Edit measurement' : 'Blood pressure',
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildTimeSelector(),
                          SizedBox(height: 24),
                          _buildMeasurementInputs(),
                          SizedBox(height: 24),
                          _buildDateSelector(),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildReminder(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: _buildAddButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final TimeOfDay? time = await showTimePicker(
              context: context,
              initialTime: selectedTime,
            );
            if (time != null) {
              setState(() => selectedTime = time);
            }
          },
          child: Container(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedTime.hour == TimeOfDay.now().hour &&
                          selectedTime.minute == TimeOfDay.now().minute
                      ? 'Now'
                      : selectedTime.format(context),
                  style: TextStyle(fontSize: 16),
                ),
                Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add measurement',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        SizedBox(height: 8),
        // SYS TextField
        Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  controller: sysController,
                  keyboardType: TextInputType.number,
                  autofocus: false,
                  enableInteractiveSelection: true,
                  enabled: true,
                  style: TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    hintText: '120',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  'SYS',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        // DIA TextField
        Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  controller: diaController,
                  keyboardType: TextInputType.number,
                  autofocus: false,
                  enableInteractiveSelection: true,
                  enabled: true,
                  style: TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    hintText: '80',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  'DIA',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    String formatDate(DateTime date) {
      if (date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day) {
        return 'Today';
      }
      return '${date.day}/${date.month}/${date.year}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? date = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() => selectedDate = date);
            }
          },
          child: Container(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDate(selectedDate),
                  style: TextStyle(fontSize: 16),
                ),
                Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Remind to measure',
              style: TextStyle(fontSize: 16),
            ),
            Switch.adaptive(
              value: remindToMeasure,
              onChanged: (value) {
                setState(() => remindToMeasure = value);
                _saveReminderPreferences();
              },
              activeColor: Colors.green,
            ),
          ],
        ),
        if (remindToMeasure) ...[
          SizedBox(height: 16),
          Row(
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
                  _saveReminderPreferences();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Color(0xFF4CAF50) : Colors.grey[300],
                  ),
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount:
                _reminderTimes.length + (_reminderTimes.length < 5 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _reminderTimes.length) {
                return TextButton(
                  onPressed: () {
                    if (_reminderTimes.length < 5) {
                      setState(() {
                        _reminderTimes.add(TimeOfDay.now());
                        // Sort times
                        _reminderTimes.sort((a, b) {
                          int aMinutes = a.hour * 60 + a.minute;
                          int bMinutes = b.hour * 60 + b.minute;
                          return aMinutes.compareTo(bMinutes);
                        });
                      });
                      _saveReminderPreferences();
                    }
                  },
                  child: Text('+ Add time'),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF4CAF50),
                    padding: EdgeInsets.zero,
                  ),
                );
              }
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: _reminderTimes[index],
                          );
                          if (time != null) {
                            setState(() {
                              _reminderTimes[index] = time;
                              // Sort times after updating
                              _reminderTimes.sort((a, b) {
                                int aMinutes = a.hour * 60 + a.minute;
                                int bMinutes = b.hour * 60 + b.minute;
                                return aMinutes.compareTo(bMinutes);
                              });
                            });
                            _saveReminderPreferences();
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _reminderTimes[index].hour ==
                                          TimeOfDay.now().hour &&
                                      _reminderTimes[index].minute ==
                                          TimeOfDay.now().minute
                                  ? 'Now'
                                  : _reminderTimes[index].format(context),
                              style: TextStyle(fontSize: 16),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    if (_reminderTimes.length > 1) ...[
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _reminderTimes.removeAt(index);
                          });
                          _saveReminderPreferences();
                        },
                        child: Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          // Validate inputs
          final sys = int.tryParse(sysController.text);
          final dia = int.tryParse(diaController.text);

          if (sys == null || dia == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter valid measurements'),
              ),
            );
            return;
          }

          // Create and return the measurement
          final measurement = BloodPressure(
            systolic: sys,
            diastolic: dia,
            timestamp: DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            ),
          );

          // Check for high blood pressure and schedule reminders if needed
          await BloodPressureNotificationService()
              .checkAndHandleHighBP(sys, dia);

          Navigator.pop(context, measurement);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF4CAF50),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Text(
          widget.measurement != null ? 'Save' : 'Add',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
