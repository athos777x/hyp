import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DateTime _selectedDay;
  late int _initialMonthIndex;
  final double itemHeight =
      375.0; // Set an estimated height for each month item
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now(); // Set default to current date
    _initialMonthIndex =
        _calculateInitialMonthIndex(); // Calculate initial month index
    _scrollController =
        ScrollController(initialScrollOffset: _initialMonthIndex * itemHeight);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Days of Week Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 0.0),
              child: GridView.count(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU']
                    .map((day) => Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

            // Scrollable Calendar
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemBuilder: (context, index) {
                  // Calculate the month to display based on the index
                  final displayMonth = DateTime(2023, 1).add(
                      Duration(days: 30 * index)); // Start from January 2023

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month Header with Year
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 0.0),
                        child: Text(
                          '${_getMonthName(displayMonth)} ${displayMonth.year}',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Calendar Grid
                      Padding(
                        padding: const EdgeInsets.only(top: 0.0),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 32),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: _getDaysInMonth(displayMonth) +
                              _getFirstWeekdayOfMonth(displayMonth),
                          itemBuilder: (context, index) {
                            // Skip empty spaces at the beginning of the month
                            final firstWeekday =
                                _getFirstWeekdayOfMonth(displayMonth);
                            if (index < firstWeekday) {
                              return Container(); // Empty space
                            }

                            final dayIndex = index - firstWeekday;
                            final date = DateTime(displayMonth.year,
                                displayMonth.month, dayIndex + 1);
                            final isSelected = _selectedDay.year == date.year &&
                                _selectedDay.month == date.month &&
                                _selectedDay.day == date.day;

                            return GestureDetector(
                              onTap: () => setState(() => _selectedDay = date),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Color(0xFF4CAF50)
                                      : Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 1,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${dayIndex + 1}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                itemCount: (2040 - 2023 + 1) *
                    12, // Total months from Jan 2023 to Dec 2040
              ),
            ),

            // Today text
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDateStatus(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${_getDayName(_selectedDay)}, ${_getMonthName(_selectedDay)} ${_selectedDay.day}',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Navigation
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Color(0xFF4CAF50)),
                      SizedBox(width: 4),
                      Text(
                        'Daily',
                        style: TextStyle(color: Color(0xFF4CAF50)),
                      ),
                    ],
                  ),
                  Icon(Icons.favorite_border, color: Colors.grey[600]),
                  Icon(Icons.star_border, color: Colors.grey[600]),
                  Icon(Icons.person_outline, color: Colors.grey[600]),
                  Icon(Icons.more_horiz, color: Colors.grey[600]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[date.month - 1];
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _getFirstWeekdayOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    // Convert Sunday (7) to 6 and shift all days by -1 to match Monday-based week
    return (firstDayOfMonth.weekday - 1) % 7;
  }

  String _getDayName(DateTime date) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[date.weekday - 1];
  }

  String _getDateStatus() {
    final now = DateTime.now();
    final selectedDate =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final currentDate = DateTime(now.year, now.month, now.day);

    if (selectedDate.isBefore(currentDate)) {
      return 'Earlier';
    } else if (selectedDate.isAfter(currentDate)) {
      return 'Later';
    } else {
      return 'Today';
    }
  }

  int _calculateInitialMonthIndex() {
    final now = DateTime.now();
    return (now.year - 2023) * 12 + now.month - 1;
  }
}
