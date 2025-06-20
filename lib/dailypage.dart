import 'package:flutter/material.dart';
import 'dart:math';
import 'screens/add_medication_screen.dart';
import 'services/medication_service.dart';
import 'models/medication.dart';
import 'services/event_bus_service.dart';
import 'dart:async';

class DailyPage extends StatefulWidget {
  @override
  _DailyPageState createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  late DateTime _selectedDay;
  final double itemHeight = 360.0;
  late ScrollController _scrollController;

  late double _containerHeight;

  final double weekHeight = 52.0; // Height of a single week row
  final double headerHeight = 70.0; // Height of the weekday header

  late int _startYear;
  late int _endYear;

  final MedicationService _medicationService = MedicationService();
  List<Medication> _medications = [];

  late StreamSubscription _medicationUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _scrollController = ScrollController();
    _containerHeight = 65.0;

    // Initialize the year range
    _startYear = 2024;
    _endYear = max(
        2026, DateTime.now().year + 1); // Always show at least one year ahead

    // Wait for the first frame to be rendered before scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedWeek();
    });

    _loadMedications();

    // Add subscription to medication updates
    _medicationUpdateSubscription = EventBusService()
        .medicationUpdateStream
        .listen((_) => _loadMedications());
  }

  Future<void> _loadMedications() async {
    final medications = await _medicationService.loadMedications();
    setState(() {
      _medications = medications;
    });
  }

  Future<void> _refreshMedications() async {
    final medications = await _medicationService.loadMedications();
    setState(() {
      _medications = medications;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate dynamic container heights based on screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final maxExpandedHeight = screenHeight * 0.7; // 70% of screen height
    final minExpandedHeight = screenHeight * 0.4; // 40% of screen height
    final expandedHeight = maxExpandedHeight.clamp(minExpandedHeight, 708.0);

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
                children: ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA']
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
                      DateTime(_startYear + yearOffset, 1 + monthOffset);

                  return Container(
                    height: _calculateMonthHeight(adjustedMonth),
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
                                  final prevMonth = DateTime(adjustedMonth.year,
                                      adjustedMonth.month - 1);
                                  final daysInPrevMonth =
                                      _getDaysInMonth(prevMonth);
                                  final prevMonthDay = daysInPrevMonth -
                                      (firstWeekday - index - 1);
                                  final prevDate = DateTime(
                                    prevMonth.year,
                                    prevMonth.month,
                                    prevMonthDay,
                                  );
                                  final isSelected = _selectedDay.year ==
                                          prevDate.year &&
                                      _selectedDay.month == prevDate.month &&
                                      _selectedDay.day == prevDate.day;
                                  final isToday = prevDate.year ==
                                          DateTime.now().year &&
                                      prevDate.month == DateTime.now().month &&
                                      prevDate.day == DateTime.now().day;

                                  return GestureDetector(
                                    onTap: () => _onDateSelected(prevDate),
                                    child: _buildDayContainer(prevMonthDay,
                                        isSelected, isToday, Colors.grey[800]),
                                  );
                                }

                                final dayIndex = index - firstWeekday;
                                final daysInMonth =
                                    _getDaysInMonth(adjustedMonth);

                                if (dayIndex >= daysInMonth) {
                                  final nextMonth = DateTime(adjustedMonth.year,
                                      adjustedMonth.month + 1);
                                  final nextMonthDay =
                                      dayIndex - daysInMonth + 1;
                                  final nextDate = DateTime(
                                    nextMonth.year,
                                    nextMonth.month,
                                    nextMonthDay,
                                  );
                                  final isSelected = _selectedDay.year ==
                                          nextDate.year &&
                                      _selectedDay.month == nextDate.month &&
                                      _selectedDay.day == nextDate.day;
                                  final isToday = nextDate.year ==
                                          DateTime.now().year &&
                                      nextDate.month == DateTime.now().month &&
                                      nextDate.day == DateTime.now().day;

                                  return GestureDetector(
                                    onTap: () => _onDateSelected(nextDate),
                                    child: _buildDayContainer(nextMonthDay,
                                        isSelected, isToday, Colors.grey[800]),
                                  );
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
                                  child: _buildDayContainer(
                                      dayIndex + 1, isSelected, isToday, null),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                itemCount:
                    (_endYear - _startYear + 1) * 12, // Dynamic item count
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
                        duration: Duration(milliseconds: 500),
                        height:
                            _containerHeight == 65.0 ? 65.0 : expandedHeight,
                        color: Colors.white,
                        curve: Curves.easeInOut,
                        child: Column(
                          children: [
                            GestureDetector(
                              onVerticalDragUpdate: (details) {
                                if (details.delta.dy > 0) {
                                  // Swipe down
                                  _handleContainerHeightChange(65.0);
                                } else if (details.delta.dy < 0 &&
                                    _containerHeight == 65.0) {
                                  // Swipe up
                                  _handleContainerHeightChange(708.0);
                                  _scrollToSelectedWeek();
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: double.infinity,
                                color: Colors.transparent,
                                padding: const EdgeInsets.only(
                                    top: 8.0, bottom: 8.0),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 199, 199, 199),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16.0, top: 0.0),
                                      child: Text(
                                        _getDateStatus(),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 16.0),
                                      child: Text(
                                        '${_getDayName(_selectedDay)}, ${_getMonthName(_selectedDay)} ${_selectedDay.day}',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Add this - Medication List
                            if (_containerHeight > 65.0) ...[
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    // Filter medications for selected date
                                    final selectedDate = DateTime(
                                      _selectedDay.year,
                                      _selectedDay.month,
                                      _selectedDay.day,
                                    );

                                    final medicationsForDay =
                                        _medications.where((med) {
                                      final startDate = DateTime(
                                        med.date.year,
                                        med.date.month,
                                        med.date.day,
                                      );

                                      // For medication supply, calculate the end date based on supply and doses
                                      DateTime? endDate;
                                      if (med.selectedEndOption ==
                                              'medication supply' &&
                                          med.supplyAmount != null) {
                                        final totalSupply =
                                            int.parse(med.supplyAmount!);
                                        final dosesPerDay =
                                            med.doseTimes?.length ?? 1;
                                        int daysPerWeek =
                                            med.daysTaken == 'everyday'
                                                ? 7
                                                : med.selectedDays?.length ?? 7;

                                        final totalDays = (totalSupply /
                                                dosesPerDay *
                                                7 /
                                                daysPerWeek)
                                            .ceil();
                                        endDate = startDate
                                            .add(Duration(days: totalDays - 1));
                                      } else {
                                        endDate = med.endDate ?? startDate;
                                      }

                                      // Check if the date is within range
                                      final isWithinDateRange =
                                          !selectedDate.isBefore(startDate) &&
                                              !selectedDate.isAfter(endDate);

                                      // Check if it should be shown on this day of the week
                                      final isCorrectDay = med.daysTaken ==
                                              'everyday' ||
                                          (med.daysTaken == 'selected days' &&
                                              med.selectedDays?.contains(
                                                      _getDayAbbreviation(
                                                          selectedDate)) ==
                                                  true);

                                      return isWithinDateRange && isCorrectDay;
                                    }).expand((med) {
                                      // Create a medication instance for each dose time
                                      // If doseTimes is available, use it; otherwise fall back to the single time
                                      final doseTimes = med.doseTimes != null &&
                                              med.doseTimes!.isNotEmpty
                                          ? med.doseTimes!
                                          : [
                                              TimeOfDay(
                                                  hour: int.parse(
                                                      med.time.split(':')[0]),
                                                  minute: int.parse(
                                                      med.time.split(':')[1]))
                                            ];
                                      return doseTimes
                                          .map((doseTime) => Medication(
                                                name: med.name,
                                                date: selectedDate,
                                                endDate: med.endDate,
                                                time: doseTime.format(context),
                                                color: med.color,
                                                statusMap: med.statusMap,
                                                selectedDays: med.selectedDays,
                                                daysTaken: med.daysTaken,
                                                selectedEndOption:
                                                    med.selectedEndOption,
                                                daysAmount: med.daysAmount,
                                                supplyAmount: med.supplyAmount,
                                                doseTimes: med.doseTimes,
                                                type: med.type,
                                                per: med.per,
                                                every: med.every,
                                                amount: med.amount,
                                                finalDayDoses:
                                                    med.finalDayDoses,
                                              ));
                                    }).toList();

                                    // Sort medications by time
                                    medicationsForDay.sort((a, b) {
                                      final aTime =
                                          _timeStringToDateTime(a.time);
                                      final bTime =
                                          _timeStringToDateTime(b.time);
                                      return aTime.compareTo(bTime);
                                    });

                                    // Add auto-skip check here, after medications are filtered and sorted
                                    _checkAndAutoSkipMedications(
                                        medicationsForDay);

                                    if (medicationsForDay.isEmpty) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.medication_outlined,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'No medications for this day',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      itemCount: medicationsForDay.length,
                                      itemBuilder: (context, index) {
                                        final medication =
                                            medicationsForDay[index];

                                        final currentTime =
                                            _timeStringToDateTime(
                                                medication.time);
                                        final currentPeriod =
                                            _getTimePeriod(currentTime);

                                        final showDivider = index == 0 ||
                                            _getTimePeriod(
                                                    _timeStringToDateTime(
                                                        medicationsForDay[
                                                                index - 1]
                                                            .time)) !=
                                                currentPeriod;

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (showDivider) ...[
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 8.0,
                                                  top: 16.0,
                                                  bottom: 8.0,
                                                ),
                                                child: Text(
                                                  currentPeriod,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            Container(
                                              margin:
                                                  EdgeInsets.only(bottom: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.05),
                                                    blurRadius: 2,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: ListTile(
                                                leading: Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: medication.color,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                    Icons.medication,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                title: Text(
                                                  medication.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  medication.formattedTime,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                trailing: GestureDetector(
                                                  onTap: () async {
                                                    // Show a modal bottom sheet with options
                                                    showModalBottomSheet(
                                                      context: context,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.vertical(
                                                                top: Radius
                                                                    .circular(
                                                                        15)),
                                                      ),
                                                      builder: (BuildContext
                                                          context) {
                                                        return Container(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  vertical: 20),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              ListTile(
                                                                leading: Icon(
                                                                  Icons
                                                                      .check_circle,
                                                                  color: Color(
                                                                      0xFF4CAF50),
                                                                ),
                                                                title: Text(
                                                                    'Mark as taken'),
                                                                onTap:
                                                                    () async {
                                                                  Navigator.pop(
                                                                      context);
                                                                  await _updateMedicationStatus(
                                                                      medication,
                                                                      true,
                                                                      false);
                                                                  setState(
                                                                      () {});
                                                                },
                                                              ),
                                                              ListTile(
                                                                leading: Icon(
                                                                  Icons.close,
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                                title: Text(
                                                                    'Mark as skipped'),
                                                                onTap:
                                                                    () async {
                                                                  Navigator.pop(
                                                                      context);
                                                                  await _updateMedicationStatus(
                                                                      medication,
                                                                      false,
                                                                      true);
                                                                  setState(
                                                                      () {});
                                                                },
                                                              ),
                                                              if (medication
                                                                      .taken ||
                                                                  medication
                                                                      .skipped)
                                                                ListTile(
                                                                  leading: Icon(
                                                                    Icons
                                                                        .radio_button_unchecked,
                                                                    color: Colors
                                                                            .grey[
                                                                        400],
                                                                  ),
                                                                  title: Text(
                                                                      'Mark as unchecked'),
                                                                  onTap:
                                                                      () async {
                                                                    Navigator.pop(
                                                                        context);
                                                                    await _updateMedicationStatus(
                                                                        medication,
                                                                        false,
                                                                        false);
                                                                    setState(
                                                                        () {});
                                                                  },
                                                                ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                  child: medication.taken
                                                      ? Icon(
                                                          Icons.check_circle,
                                                          color:
                                                              Color(0xFF4CAF50),
                                                        )
                                                      : medication.skipped
                                                          ? Icon(
                                                              Icons.close,
                                                              color: Colors.red,
                                                            )
                                                          : Icon(
                                                              Icons
                                                                  .circle_outlined,
                                                              color: Colors
                                                                  .grey[400],
                                                            ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
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
                              onPressed:
                                  _addMedication, // Use the new method here
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
    _medicationUpdateSubscription.cancel();
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
    // Convert to Sunday = 0, Saturday = 6
    return firstDayOfMonth.weekday % 7;
  }

  String _getDayName(DateTime date) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    // Adjust for Sunday being 7 in DateTime.weekday
    return days[date.weekday == 7 ? 6 : date.weekday - 1];
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

  void _onDateSelected(DateTime date) {
    _updateYearRange(); // Check if we need to extend the range
    setState(() {
      _selectedDay = date;
    });

    if (_containerHeight > 65.0) {
      _scrollToSelectedWeek();
    }
  }

  void _scrollToSelectedWeek() {
    final monthStart = DateTime(_selectedDay.year, _selectedDay.month, 1);
    final firstWeekday = _getFirstWeekdayOfMonth(monthStart);

    // Calculate which week the selected day belongs to
    final dayOfMonth = _selectedDay.day;
    // Changed this line to properly calculate the week
    final weekNumber = ((dayOfMonth + firstWeekday - 1) / 7).floor();

    final monthIndex =
        (_selectedDay.year - _startYear) * 12 + (_selectedDay.month - 1);

    // Fine-tuned measurements
    final monthHeaderHeight = 32.0;
    final weekSpacing = 8.0;
    final gridPadding = 16.0;
    final monthSpacing = 32.0;
    final adjustmentOffset = 8.0;

    // Calculate accumulated height of previous months
    double accumulatedHeight = 0;
    for (int i = 0; i < monthIndex; i++) {
      final currentMonth = DateTime(_startYear + (i ~/ 12), 1 + (i % 12));
      accumulatedHeight += _calculateMonthHeight(currentMonth) + monthSpacing;
    }

    // Calculate week position within the current month
    final weekPositionInMonth = (weekNumber * (weekHeight + weekSpacing)) +
        monthHeaderHeight +
        gridPadding -
        adjustmentOffset;

    // Calculate base scroll position
    final basePosition = accumulatedHeight + weekPositionInMonth;

    // Calculate visible area
    final visibleHeight = MediaQuery.of(context).size.height -
        headerHeight -
        _containerHeight -
        MediaQuery.of(context).padding.top;

    // Adjust the position to show the selected week at a better position
    final targetPosition = basePosition - (visibleHeight * 0.04);

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

    // Calculate the exact number of rows needed without extra padding
    final rows = (totalDays / 7).ceil();

    // Return total grid spaces (7 columns × number of rows)
    return rows * 7;
  }

  Widget _buildDayContainer(
      int day, bool isSelected, bool isToday, Color? textColor) {
    final bool isCollapsed = _containerHeight == 65.0;
    final bool isRemainingDay = textColor != null;

    if (isRemainingDay) {
      return AnimatedOpacity(
        duration: Duration(milliseconds: 1200), // Quick fade in
        curve: Curves.easeIn,
        opacity: isCollapsed ? 0 : 1,
        onEnd: () {
          // We can't return a widget here, so we just use the callback for state changes if needed
        },
        child: isCollapsed
            ? SizedBox()
            : Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Color(0xFF4CAF50)
                      : isToday
                          ? const Color.fromARGB(255, 204, 204, 204)
                          : Color.fromARGB(255, 235, 235, 235),
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
                    '$day',
                    style: TextStyle(
                      color: isSelected ? Colors.white : textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
      );
    }

    // Regular day container (non-remaining days)
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? Color(0xFF4CAF50)
            : isToday
                ? const Color.fromARGB(255, 204, 204, 204)
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
          '$day',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  double _calculateMonthHeight(DateTime month) {
    final daysInMonth = _getDaysInMonth(month);
    final firstWeekday = _getFirstWeekdayOfMonth(month);
    final totalDays = daysInMonth + firstWeekday;
    final rows = (totalDays / 7).ceil();

    final monthHeaderHeight = 32.0;
    final gridPadding = 48.0;
    final totalRowsHeight = rows * weekHeight;
    final totalSpacingHeight = (rows - 1) * 8.0;

    return totalRowsHeight +
        totalSpacingHeight +
        monthHeaderHeight +
        gridPadding;
  }

  void _updateYearRange() {
    final currentYear = DateTime.now().year;
    if (currentYear >= _endYear) {
      setState(() {
        _endYear = currentYear + 1; // Always show one year ahead
      });
    }
  }

  void _handleContainerHeightChange(double newHeight) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxExpandedHeight = screenHeight * 0.7;
    final minExpandedHeight = screenHeight * 0.4;
    final expandedHeight = maxExpandedHeight.clamp(minExpandedHeight, 708.0);

    setState(() {
      _containerHeight = newHeight == 708.0 ? expandedHeight : newHeight;
    });

    // If expanding, wait for container animation to complete before showing remaining days
    if (newHeight > 65.0) {
      Future.delayed(Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            // Trigger rebuild to show remaining days
          });
        }
      });
    }
  }

  void _addMedication() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(selectedDate: _selectedDay),
      ),
    );

    if (result != null) {
      setState(() {
        // result is now a List<Medication>
        _medications.addAll(result);
      });
      await _medicationService.saveMedications(_medications);
    }
  }

  // Add this method to convert time string to comparable DateTime
  DateTime _timeStringToDateTime(String timeStr) {
    final now = DateTime.now();
    final timeParts = timeStr.split(' ');
    final time = timeParts[0].split(':');
    int hour = int.parse(time[0]);
    int minute = int.parse(time[1]);

    // Handle AM/PM
    if (timeParts.length > 1) {
      if (timeParts[1] == 'PM' && hour != 12) {
        hour += 12;
      } else if (timeParts[1] == 'AM' && hour == 12) {
        hour = 0;
      }
    }

    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  // Update this method to use the new time ranges
  String _getTimePeriod(DateTime time) {
    final hour = time.hour;
    if (hour >= 0 && hour < 12) {
      return 'Morning';
    } else if (hour >= 12 && hour < 18) {
      return 'Afternoon';
    } else {
      return 'Evening';
    }
  }

  String _getDayAbbreviation(DateTime date) {
    final days = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];
    return days[date.weekday % 7];
  }

  void _showMedicationOptions(Medication medication) {
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
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMedicationScreen(
                      selectedDate: medication.date,
                      medicationToEdit: medication,
                    ),
                  ),
                );

                if (result != null && result is List<Medication>) {
                  // Remove old medication instances
                  _medications.removeWhere((m) => m.name == medication.name);
                  // Add new medication instances
                  _medications.addAll(result);
                  // Save changes
                  await _medicationService.saveMedications(_medications);
                  // Refresh the list
                  await _refreshMedications();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete medication'),
              onTap: () async {
                Navigator.pop(context);
                setState(() {
                  _medications.removeWhere((m) => m.name == medication.name);
                });
                await _medicationService.saveMedications(_medications);
                await _refreshMedications();
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
          selectedDate: _selectedDay,
        ),
      ),
    );

    if (result != null && result is List<Medication>) {
      setState(() {
        _medications.addAll(result);
      });
      await _medicationService.saveMedications(_medications);
      await _refreshMedications();
    }
  }

  void _checkAndAutoSkipMedications(List<Medication> medications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

    // Only check for auto-skip on the current day
    if (selectedDay.isAtSameMomentAs(today)) {
      bool needsUpdate = false;
      for (var medication in medications) {
        final dateKey =
            '${medication.date.year}-${medication.date.month}-${medication.date.day}';

        // Only auto-skip if the medication hasn't had any status set yet
        if (medication.statusMap == null ||
            !medication.statusMap!.containsKey(dateKey)) {
          final medicationTime = _timeStringToDateTime(medication.time);
          final cutoffTime = DateTime(
            now.year,
            now.month,
            now.day,
            medicationTime.hour,
            medicationTime.minute,
          ).add(Duration(minutes: 30));

          if (now.isAfter(cutoffTime)) {
            _updateMedicationStatus(medication, false, true);
            needsUpdate = true;
          }
        }
      }

      if (needsUpdate) {
        Future.microtask(() {
          setState(() {});
        });
      }
    }
  }

  // Add this method to update the original medication's status for the specific date
  Future<void> _updateMedicationStatus(
      Medication displayMedication, bool taken, bool skipped) async {
    // Find the original medication in the list
    final originalMedication = _medications.firstWhere(
      (med) => med.name == displayMedication.name,
      orElse: () => displayMedication,
    );

    if (originalMedication.statusMap == null) {
      originalMedication.statusMap = {};
    }

    // Store the status for this specific date and time
    final dateKey =
        '${displayMedication.date.year}-${displayMedication.date.month}-${displayMedication.date.day}';

    if (!originalMedication.statusMap!.containsKey(dateKey)) {
      originalMedication.statusMap![dateKey] = {};
    }

    // Use the specific time for this dose
    final timeKey = displayMedication.time;
    originalMedication.statusMap![dateKey]!['$timeKey-taken'] = taken;
    originalMedication.statusMap![dateKey]!['$timeKey-skipped'] = skipped;

    // Save to storage
    await _medicationService.saveMedications(_medications);
    setState(() {});
  }
}
