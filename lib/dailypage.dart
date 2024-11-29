import 'package:flutter/material.dart';

class DailyPage extends StatefulWidget {
  @override
  _DailyPageState createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  late DateTime _selectedDay;
  late int _initialMonthIndex;
  final double itemHeight = 360.0;
  late ScrollController _scrollController;

  double _containerHeight = 708.0; // Set a default height for the container

  final double weekHeight = 52.0; // Height of a single week row
  final double headerHeight = 70.0; // Height of the weekday header

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _initialMonthIndex = _calculateInitialMonthIndex();
    _scrollController = ScrollController();

    // Only scroll to the initial month, not the week
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_initialMonthIndex * itemHeight);
    });
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
                  final monthOffset = index % 12;
                  final yearOffset = index ~/ 12;
                  final adjustedMonth =
                      DateTime(2024 + yearOffset, 1 + monthOffset);

                  return Container(
                    height: itemHeight,
                    margin: EdgeInsets.only(bottom: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Month Header with Year
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 0.0),
                          child: Text(
                            '${_getMonthName(adjustedMonth)} ${adjustedMonth.year}',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // Calendar Grid
                        Expanded(
                          child: Padding(
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
                                mainAxisExtent:
                                    weekHeight, // Use fixed height for rows
                              ),
                              itemCount: _calculateGridItemCount(adjustedMonth),
                              itemBuilder: (context, index) {
                                final firstWeekday =
                                    _getFirstWeekdayOfMonth(adjustedMonth);
                                if (index < firstWeekday) {
                                  return Container(); // Empty space for beginning of month
                                }

                                final dayIndex = index - firstWeekday;
                                final daysInMonth =
                                    _getDaysInMonth(adjustedMonth);

                                // Check if we've exceeded the days in the month
                                if (dayIndex >= daysInMonth) {
                                  return Container(); // Empty space for end of month
                                }

                                final date = DateTime(
                                  adjustedMonth.year,
                                  adjustedMonth.month,
                                  dayIndex + 1,
                                );
                                final isSelected =
                                    _selectedDay.year == date.year &&
                                        _selectedDay.month == date.month &&
                                        _selectedDay.day == date.day;
                                final isToday = date.year ==
                                        DateTime.now().year &&
                                    date.month == DateTime.now().month &&
                                    date.day ==
                                        DateTime.now()
                                            .day; // Check if the date is today

                                return GestureDetector(
                                  onTap: () => _onDateSelected(date),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Color(
                                              0xFF4CAF50) // Selected date color
                                          : isToday
                                              ? const Color.fromARGB(
                                                  255,
                                                  204,
                                                  204,
                                                  204) // Current date color
                                              : Colors
                                                  .white, // Other dates color
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
                        ),
                      ],
                    ),
                  );
                },
                itemCount: (2026 - 2024 + 1) * 12,
              ),
            ),

            // Today text and add button
            Padding(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Animated Container for Today text and add button
                  Stack(
                    children: [
                      AnimatedContainer(
                        duration: Duration(
                            milliseconds: 800), // Duration of the animation
                        height: _containerHeight, // Use a variable for height
                        color: Colors.white, // Set the color to white
                        curve: Curves.easeInOut, // Animation curve
                        child: Column(
                          // Use Column to position elements
                          children: [
                            // Add padding for the swipe indicator
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 8.0), // Adjust the top padding as needed
                              child: GestureDetector(
                                onVerticalDragUpdate: (details) {
                                  if (details.delta.dy > 0) {
                                    // Swipe down
                                    setState(() {
                                      _containerHeight = 65.0;
                                    });
                                  } else if (details.delta.dy < 0 &&
                                      _containerHeight == 65.0) {
                                    // Swipe up
                                    setState(() {
                                      _containerHeight = 708.0;
                                      _scrollToSelectedWeek();
                                    });
                                  }
                                },
                                child: Container(
                                  width: 28, // Width of the horizontal line
                                  height: 6, // Height of the horizontal line
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 199, 199,
                                        199), // Color of the line
                                    borderRadius: BorderRadius.circular(
                                        10), // Rounded edges
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceBetween, // Distribute space between children
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16.0, top: 0.0),
                                      child: Text(
                                        _getDateStatus(), // Displays "Today"
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14, // Adjusted font size
                                          fontWeight: FontWeight
                                              .bold, // Adjusted font weight
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 16.0),
                                      child: Text(
                                        '${_getDayName(_selectedDay)}, ${_getMonthName(_selectedDay)} ${_selectedDay.day}', // Displays "Friday, November 1"
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16, // Adjusted font size
                                          fontWeight: FontWeight
                                              .w600, // Adjusted font weight
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        // Position the add button
                        bottom: 8, // Adjust to align with the bottom
                        right: 16, // Set to 0 to remove right padding
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF4CAF50), // Button color
                            ),
                            child: IconButton(
                              icon: Icon(Icons.add,
                                  color: Colors.white), // "+" icon
                              onPressed: () {
                                // Add your onPressed functionality here
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    // Adjust weekday to make Monday = 0, Sunday = 6
    return firstDayOfMonth.weekday % 7;
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
    // Calculate months since January 2024
    return (now.year - 2024) * 12 + (now.month - 1);
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDay = date;
    });

    // Only scroll to center the week if the container is expanded
    if (_containerHeight > 65.0) {
      _scrollToSelectedWeek();
    }
  }

  void _scrollToSelectedWeek() {
    final monthStart = DateTime(_selectedDay.year, _selectedDay.month, 1);
    final firstWeekday = _getFirstWeekdayOfMonth(monthStart);

    final dayOfMonth = _selectedDay.day;
    final adjustedDay = dayOfMonth + firstWeekday - 1;
    final weekNumber = (adjustedDay - 1) ~/ 7;

    final monthIndex =
        (_selectedDay.year - 2024) * 12 + (_selectedDay.month - 1);

    // Fine-tuned measurements
    final monthHeaderHeight = 32.0;
    final weekSpacing = 8.0;
    final gridPadding = 16.0;
    final monthSpacing = 32.0;

    // Calculate total height of each month including spacing
    final totalMonthHeight = itemHeight + monthSpacing;

    // Calculate week position within the month
    final weekPositionInMonth = (weekNumber * (weekHeight + weekSpacing)) +
        monthHeaderHeight +
        gridPadding;

    // Calculate base scroll position
    final basePosition = (monthIndex * totalMonthHeight) + weekPositionInMonth;

    // Calculate visible area
    final visibleHeight = MediaQuery.of(context).size.height -
        headerHeight -
        _containerHeight -
        MediaQuery.of(context).padding.top;

    // Adjust the position to show the selected week at a better position
    final targetPosition =
        basePosition - (visibleHeight * 0.25); // Changed from 0.3 to 0.25

    print('Day of Month: $dayOfMonth');
    print('Week Number: $weekNumber');
    print('Base Position: $basePosition');
    print('Visible Height: $visibleHeight');
    print('Target Position: $targetPosition');

    _scrollController.animateTo(
      targetPosition,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  int _calculateGridItemCount(DateTime month) {
    final daysInMonth = _getDaysInMonth(month);
    final firstWeekday = _getFirstWeekdayOfMonth(month);
    final totalDays = daysInMonth + firstWeekday;

    // Calculate the number of rows needed and ensure we have enough space
    final rows = ((totalDays + 6) / 7).ceil(); // Add 6 to ensure we round up

    // Return total grid spaces (7 columns × number of rows)
    return rows * 7;
  }
}
