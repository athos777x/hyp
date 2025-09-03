import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/medication.dart';
import 'package:shared_preferences/shared_preferences.dart' as prefs;
import 'dart:convert';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _lastRescheduleKey = 'last_notification_reschedule';
  static const String _pendingRemindersKey = 'pending_medication_reminders';

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        print('Notification tapped: ${details.payload}');
      },
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const androidNotificationChannel = AndroidNotificationChannel(
      'medication_reminders',
      'Medication Reminders',
      description: 'Reminders to take your medication',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  Future<void> checkAndRescheduleNotifications(
      List<Medication> medications) async {
    final sharedPrefs = await prefs.SharedPreferences.getInstance();
    final lastReschedule = sharedPrefs.getInt(_lastRescheduleKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if it's been at least 30 days since last reschedule
    if (now - lastReschedule >= const Duration(days: 30).inMilliseconds) {
      // Cancel all existing future notifications
      final pendingNotifications =
          await _notifications.pendingNotificationRequests();
      for (var notification in pendingNotifications) {
        await _notifications.cancel(notification.id);
      }

      // Reschedule notifications for all medications
      await scheduleMedicationReminders(medications);

      // Update last reschedule time
      await sharedPrefs.setInt(_lastRescheduleKey, now);
    }
  }

  Future<void> scheduleMedicationReminders(List<Medication> medications) async {
    // First cancel any existing notifications for these medications
    for (var medication in medications) {
      await cancelMedicationNotifications(medication.name);
    }

    // Then schedule new notifications
    for (var medication in medications) {
      if (medication.doseTimes == null) continue;

      DateTime endDate;
      if (medication.selectedEndOption == 'consistently' ||
          medication.endDate?.isAfter(DateTime.now().add(Duration(days: 90))) ==
              true) {
        // For 'consistently' option or far-future end dates, schedule for next 90 days
        endDate = DateTime.now().add(Duration(days: 90));
      } else {
        // For other cases, use the calculated end date
        endDate = _calculateEndDate(medication);
      }

      // Limit the scheduling window to avoid exceeding alarm limits
      final maxSchedulingDate = DateTime.now().add(Duration(days: 90));
      if (endDate.isAfter(maxSchedulingDate)) {
        endDate = maxSchedulingDate;
      }

      await _scheduleNotificationsForMedication(medication, endDate);
    }
  }

  DateTime _calculateEndDate(Medication medication) {
    if (medication.selectedEndOption == 'date') {
      return medication.endDate ?? medication.date;
    } else if (medication.selectedEndOption == 'amount of days' &&
        medication.daysAmount != null) {
      final days = int.tryParse(medication.daysAmount!) ?? 0;
      return medication.date.add(Duration(days: days));
    } else if (medication.selectedEndOption == 'medication supply' &&
        medication.supplyAmount != null) {
      final supply = int.tryParse(medication.supplyAmount!) ?? 0;
      final dosesPerDay = medication.doseTimes!.length;
      final days = (supply / dosesPerDay).ceil();
      return medication.date.add(Duration(days: days));
    }
    return medication.date;
  }

  Future<void> _scheduleNotificationsForMedication(
    Medication medication,
    DateTime endDate,
  ) async {
    int scheduledCount = 0;
    final maxNotifications = 450; // Keep buffer below 500 limit

    for (var doseTime in medication.doseTimes!) {
      DateTime currentDate = medication.date;
      while (
          !currentDate.isAfter(endDate) && scheduledCount < maxNotifications) {
        if (_shouldScheduleForDate(medication, currentDate)) {
          final scheduledTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            doseTime.hour,
            doseTime.minute,
          );

          if (scheduledTime.isAfter(DateTime.now())) {
            await _scheduleNotification(
              id: _generateNotificationId(medication, scheduledTime),
              title: 'Medication Reminder',
              body:
                  'Time to take ${medication.amount ?? ''} ${medication.name}',
              scheduledTime: scheduledTime,
              payload: medication.name,
            );

            // Calculate next dose time
            DateTime? nextDoseTime =
                _calculateNextDoseTime(medication, scheduledTime);

            // Schedule reminder notification for 15 minutes later
            await scheduleReminderNotification(
              medicationName: medication.name,
              originalTime: scheduledTime,
              amount: medication.amount ?? '',
              nextDoseTime: nextDoseTime,
            );

            scheduledCount++;
          }
        }
        currentDate = currentDate.add(Duration(days: 1));
      }
    }
  }

  bool _shouldScheduleForDate(Medication medication, DateTime date) {
    return medication.daysTaken == 'everyday' ||
        (medication.daysTaken == 'selected days' &&
            medication.selectedDays?.contains(_getDayAbbreviation(date)) ==
                true);
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders to take your medication',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      autoCancel: false,
      ongoing: false,
      styleInformation: const DefaultStyleInformation(true, true),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      print(
          'Successfully scheduled notification for $scheduledTime with ID: $id');
    } catch (e) {
      print('Error scheduling notification: $e');
      // For fallback, we could show immediate notification instead
      // but for medication reminders, we want scheduled notifications to work
      rethrow;
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  int _generateNotificationId(Medication medication, DateTime scheduledTime) {
    // Create a unique ID based on medication name and scheduled time
    final nameHash = medication.name.hashCode;
    final timeHash =
        scheduledTime.millisecondsSinceEpoch ~/ 60000; // Convert to minutes
    return (nameHash + timeHash).abs() %
        2147483647; // Ensure within 32-bit integer range
  }

  String _getDayAbbreviation(DateTime date) {
    final days = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];
    return days[date.weekday % 7];
  }

  /// Calculate the next dose time for a medication after the current scheduled time
  DateTime? _calculateNextDoseTime(
      Medication medication, DateTime currentScheduledTime) {
    if (medication.doseTimes == null || medication.doseTimes!.isEmpty) {
      return null;
    }

    final currentTime = TimeOfDay.fromDateTime(currentScheduledTime);
    final currentDate = DateTime(currentScheduledTime.year,
        currentScheduledTime.month, currentScheduledTime.day);

    // Find the next dose time on the same day
    for (var doseTime in medication.doseTimes!) {
      if (doseTime.hour > currentTime.hour ||
          (doseTime.hour == currentTime.hour &&
              doseTime.minute > currentTime.minute)) {
        final nextDoseToday = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          doseTime.hour,
          doseTime.minute,
        );

        // Check if this day should have doses scheduled
        if (_shouldScheduleForDate(medication, currentDate)) {
          return nextDoseToday;
        }
      }
    }

    // If no dose found today, find the first dose of the next scheduled day
    DateTime nextDate = currentDate.add(Duration(days: 1));
    for (int i = 0; i < 7; i++) {
      // Check up to 7 days ahead
      if (_shouldScheduleForDate(medication, nextDate)) {
        final firstDoseTime = medication.doseTimes!.first;
        return DateTime(
          nextDate.year,
          nextDate.month,
          nextDate.day,
          firstDoseTime.hour,
          firstDoseTime.minute,
        );
      }
      nextDate = nextDate.add(Duration(days: 1));
    }

    return null; // No next dose found within a week
  }

  Future<void> cancelMedicationNotifications(String medicationName) async {
    final notifications = await _notifications.pendingNotificationRequests();
    for (var notification in notifications) {
      if (notification.payload == medicationName) {
        await _notifications.cancel(notification.id);
      }
    }

    // Also cancel all reminder notifications for this medication
    await cancelAllRemindersForMedication(medicationName);
  }

  /// Test method to show immediate medication notification with reminder
  Future<void> showTestMedicationNotificationWithReminder() async {
    final now = DateTime.now();

    // Show immediate notification
    await _notifications.show(
      999997, // Special test ID for immediate notification
      'Test Medication Reminder',
      'This is a test notification - reminder will follow in 15 minutes (even if skipped)',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Reminders to take your medication',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'test_medication',
    );

    // Schedule reminder notification
    await scheduleReminderNotification(
      medicationName: 'Test Medication',
      originalTime: now,
      amount: '1 pill',
    );

    print('Test notification sent with recurring reminders every 15 minutes');
    print(
        'Note: Reminders will only be cancelled if medication is marked as TAKEN, not if skipped');
    print(
        'Reminders will continue until medication is taken or for up to 5 hours (20 reminders)');
  }

  /// Test method to show immediate medication notification
  Future<void> showTestMedicationNotification() async {
    await _notifications.show(
      999998, // Special test ID
      'Test Medication Reminder',
      'This is a test notification to verify medication reminders are working',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Reminders to take your medication',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'test_medication',
    );
  }

  /// Get pending notification count for debugging
  Future<int> getPendingNotificationCount() async {
    final notifications = await _notifications.pendingNotificationRequests();
    return notifications.length;
  }

  /// Get all pending notifications for debugging
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Schedule a reminder notification 15 minutes after the original notification
  Future<void> scheduleReminderNotification({
    required String medicationName,
    required DateTime originalTime,
    required String amount,
    DateTime? nextDoseTime,
  }) async {
    // Calculate when to stop reminders (next dose time or 24 hours later if no next dose)
    final stopTime = nextDoseTime ?? originalTime.add(Duration(hours: 24));

    // Schedule multiple reminders every 15 minutes
    int reminderCount = 1;
    DateTime currentReminderTime = originalTime.add(Duration(minutes: 15));

    while (currentReminderTime.isBefore(stopTime) && reminderCount <= 20) {
      // Max 20 reminders (5 hours)
      // Don't schedule if the reminder time is in the past
      if (currentReminderTime.isAfter(DateTime.now())) {
        final reminderId =
            _generateReminderId(medicationName, originalTime, reminderCount);

        // Store the pending reminder
        await _storePendingReminder(
            medicationName, originalTime, reminderId, reminderCount);

        await _scheduleNotification(
          id: reminderId,
          title: 'Medication Reminder - Follow Up #$reminderCount',
          body: 'Important: Please take your $amount $medicationName',
          scheduledTime: currentReminderTime,
          payload: 'reminder_${medicationName}_$reminderCount',
        );

        print(
            'Scheduled reminder #$reminderCount for $medicationName at $currentReminderTime with ID: $reminderId');
      }

      reminderCount++;
      currentReminderTime = currentReminderTime.add(Duration(minutes: 15));
    }

    print(
        'Scheduled ${reminderCount - 1} reminder notifications for $medicationName until $stopTime');
  }

  /// Cancel all reminder notifications for a specific medication and time
  Future<void> cancelReminderNotification(
      String medicationName, DateTime originalTime) async {
    final pendingReminders = await _getPendingReminders();
    final baseKey = '${medicationName}_${originalTime.millisecondsSinceEpoch}';
    final toRemove = <String>[];
    int cancelledCount = 0;

    for (var key in pendingReminders.keys) {
      if (key.startsWith(baseKey)) {
        final reminderId = pendingReminders[key]!;
        await _notifications.cancel(reminderId);
        toRemove.add(key);
        cancelledCount++;
        print('Cancelled reminder notification with ID: $reminderId');
      }
    }

    // Remove from storage
    for (var key in toRemove) {
      pendingReminders.remove(key);
    }
    await _savePendingReminders(pendingReminders);

    print(
        'Cancelled $cancelledCount reminder notifications for $medicationName');
  }

  /// Cancel all reminder notifications for a medication
  Future<void> cancelAllRemindersForMedication(String medicationName) async {
    final pendingReminders = await _getPendingReminders();
    final toRemove = <String>[];

    for (var key in pendingReminders.keys) {
      if (key.startsWith('${medicationName}_')) {
        final reminderId = pendingReminders[key]!;
        await _notifications.cancel(reminderId);
        toRemove.add(key);
        print('Cancelled reminder notification with ID: $reminderId');
      }
    }

    // Remove from storage
    for (var key in toRemove) {
      pendingReminders.remove(key);
    }
    await _savePendingReminders(pendingReminders);
  }

  /// Generate unique reminder notification ID
  int _generateReminderId(String medicationName, DateTime originalTime,
      [int reminderCount = 1]) {
    final nameHash = medicationName.hashCode;
    final timeHash = originalTime.millisecondsSinceEpoch ~/ 60000;
    // Add a large offset to distinguish from regular medication notifications
    // Include reminderCount to make each reminder unique
    return ((nameHash + timeHash + reminderCount).abs() % 1000000) + 2000000;
  }

  /// Store pending reminder in SharedPreferences
  Future<void> _storePendingReminder(
      String medicationName, DateTime originalTime, int reminderId,
      [int reminderCount = 1]) async {
    final pendingReminders = await _getPendingReminders();
    final key =
        '${medicationName}_${originalTime.millisecondsSinceEpoch}_$reminderCount';
    pendingReminders[key] = reminderId;
    await _savePendingReminders(pendingReminders);
  }

  /// Remove pending reminder from SharedPreferences (deprecated - use cancelReminderNotification)
  @deprecated
  Future<void> _removePendingReminder(
      String medicationName, DateTime originalTime) async {
    // This method is deprecated in favor of cancelReminderNotification
    // which handles multiple reminders properly
    await cancelReminderNotification(medicationName, originalTime);
  }

  /// Get pending reminders from SharedPreferences
  Future<Map<String, int>> _getPendingReminders() async {
    final sharedPrefs = await prefs.SharedPreferences.getInstance();
    final remindersJson = sharedPrefs.getString(_pendingRemindersKey);
    if (remindersJson != null) {
      final decoded = jsonDecode(remindersJson) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as int));
    }
    return {};
  }

  /// Save pending reminders to SharedPreferences
  Future<void> _savePendingReminders(Map<String, int> reminders) async {
    final sharedPrefs = await prefs.SharedPreferences.getInstance();
    await sharedPrefs.setString(_pendingRemindersKey, jsonEncode(reminders));
  }

  /// Clean up expired reminders from storage
  Future<void> cleanupExpiredReminders() async {
    final pendingReminders = await _getPendingReminders();
    final now = DateTime.now();
    final toRemove = <String>[];

    for (var key in pendingReminders.keys) {
      final parts = key.split('_');
      if (parts.length >= 3) {
        final timestamp = int.tryParse(
            parts[parts.length - 2]); // Second to last part is timestamp
        final reminderCount =
            int.tryParse(parts.last); // Last part is reminder count
        if (timestamp != null && reminderCount != null) {
          final originalTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final reminderTime =
              originalTime.add(Duration(minutes: 15 * reminderCount));

          // If reminder time has passed, remove it
          if (reminderTime.isBefore(now)) {
            toRemove.add(key);
          }
        }
      }
    }

    // Remove expired reminders
    for (var key in toRemove) {
      pendingReminders.remove(key);
    }

    if (toRemove.isNotEmpty) {
      await _savePendingReminders(pendingReminders);
      print('Cleaned up ${toRemove.length} expired reminders');
    }
  }
}
