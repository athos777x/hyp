import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

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
  int _selectedIndex = 0; // Track the selected index
  double _containerHeight = 708.0; // Set a default height for the container

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
                  final displayMonth = DateTime(2024, 1).add(
                      Duration(days: 30 * index)); // Start from January 2024
                  // Adjust the calculation to ensure it doesn't exceed December 2026
                  final monthOffset = index % 12; // Get the month offset
                  final yearOffset = index ~/ 12; // Get the year offset
                  final adjustedMonth =
                      DateTime(2024 + yearOffset, 1 + monthOffset);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          itemCount: _getDaysInMonth(adjustedMonth) +
                              _getFirstWeekdayOfMonth(adjustedMonth),
                          itemBuilder: (context, index) {
                            // Skip empty spaces at the beginning of the month
                            final firstWeekday =
                                _getFirstWeekdayOfMonth(adjustedMonth);
                            if (index < firstWeekday) {
                              return Container(); // Empty space
                            }

                            final dayIndex = index - firstWeekday;
                            final date = DateTime(adjustedMonth.year,
                                adjustedMonth.month, dayIndex + 1);
                            final isSelected = _selectedDay.year == date.year &&
                                _selectedDay.month == date.month &&
                                _selectedDay.day == date.day;
                            final isToday = date.year == DateTime.now().year &&
                                date.month == DateTime.now().month &&
                                date.day ==
                                    DateTime.now()
                                        .day; // Check if the date is today

                            return GestureDetector(
                              onTap: () => setState(() => _selectedDay = date),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Color(0xFF4CAF50) // Selected date color
                                      : isToday
                                          ? const Color.fromARGB(255, 204, 204,
                                              204) // Current date color
                                          : Colors.white, // Other dates color
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
                itemCount: (2026 - 2024 + 1) *
                    12, // Total months from Jan 2024 to Dec 2026
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
                                      // Collapse the height to a smaller value
                                      _containerHeight =
                                          65.0; // Set to a minimum height instead of 0
                                    });
                                  } else if (details.delta.dy < 0 &&
                                      _containerHeight == 65.0) {
                                    // Swipe up
                                    setState(() {
                                      // Expand the height back to the original value
                                      _containerHeight =
                                          708.0; // Set to original height
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
                                          left: 16.0, top: 8.0),
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
            // Bottom Navigation Bar
            Container(
              color: Colors.white, // Set your desired background color here
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Container(
                  width: MediaQuery.of(context).size.width, // Ensure full width
                  padding: EdgeInsets.all(8),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Distribute space evenly
                    children: [
                      Expanded(
                        child: GNav(
                          gap: 4,
                          activeColor: Color(0xFF4CAF50),
                          iconSize: 17,
                          backgroundColor: Color.fromARGB(255, 255, 255, 255),
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          tabMargin: EdgeInsets.symmetric(
                              horizontal: 4), // Reduced margin
                          tabBackgroundColor: Color(0xFF4CAF50).withOpacity(
                              0.1), // Selected tab background color
                          color: Colors.grey,
                          tabs: [
                            GButton(
                              icon: Icons.calendar_today,
                              text: 'Daily',
                            ),
                            GButton(
                              icon: Icons.health_and_safety,
                              text: 'Health',
                            ),
                            GButton(
                              icon: Icons.medication,
                              text: 'Medications',
                            ),
                            GButton(
                              icon: Icons.book,
                              text: 'Definitions',
                            ),
                            GButton(
                              icon: Icons.warning,
                              text: 'S/Sx',
                            ),
                            GButton(
                              icon: Icons.local_hospital,
                              text: 'Hospitals',
                            ),
                            GButton(
                              icon: Icons.settings,
                              text: 'Settings',
                            ),
                          ],
                          selectedIndex: _selectedIndex,
                          onTabChange: (index) {
                            setState(() {
                              _selectedIndex =
                                  index; // Update the selected index
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
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
