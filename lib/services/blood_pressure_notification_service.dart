import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class BloodPressureNotificationService {
  static final BloodPressureNotificationService _instance =
      BloodPressureNotificationService._internal();
  factory BloodPressureNotificationService() => _instance;
  BloodPressureNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _notificationChannelId = 'blood_pressure_reminders';
  static const String _notificationChannelName = 'Blood Pressure Reminders';
  static const String _lastRescheduleKey = 'last_bp_notification_reschedule';
  static const String _highBPReminderKey = 'high_bp_reminder_active';

  Future<void> initialize() async {
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
        print('Blood pressure notification tapped: ${details.payload}');
      },
    );
  }

  Future<void> scheduleReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindToMeasure = prefs.getBool('remindToMeasure') ?? false;

    print(
        'Scheduling blood pressure reminders. Remind to measure: $remindToMeasure');

    if (!remindToMeasure) {
      print('Reminders disabled, cancelling all existing reminders');
      await cancelAllReminders();
      return;
    }

    final selectedDays =
        Set<String>.from(prefs.getStringList('selectedDays') ?? []);
    final reminderTimesStr = prefs.getStringList('reminderTimes') ?? [];

    if (selectedDays.isEmpty || reminderTimesStr.isEmpty) {
      return;
    }

    // Cancel existing reminders before scheduling new ones
    await cancelAllReminders();

    // Schedule for the next 90 days
    final now = DateTime.now();
    final endDate = now.add(Duration(days: 90));

    for (var timeStr in reminderTimesStr) {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      var currentDate = now;
      while (currentDate.isBefore(endDate)) {
        final dayAbbr = _getDayAbbreviation(currentDate);
        if (selectedDays.contains(dayAbbr)) {
          final scheduledTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            hour,
            minute,
          );

          if (scheduledTime.isAfter(now)) {
            await _scheduleNotification(
              id: _generateNotificationId(scheduledTime),
              scheduledTime: scheduledTime,
            );
          }
        }
        currentDate = currentDate.add(Duration(days: 1));
      }
    }
  }

  String _getDayAbbreviation(DateTime date) {
    final days = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];
    return days[date.weekday % 7];
  }

  Future<void> _scheduleNotification({
    required int id,
    required DateTime scheduledTime,
    String title = 'Blood Pressure Reminder',
    String body = 'Time to measure your blood pressure',
    bool isHighBPAlert = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: 'Reminders to measure blood pressure',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
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

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  int _generateNotificationId(DateTime scheduledTime) {
    // Create a unique ID based on scheduled time
    final timeHash =
        scheduledTime.millisecondsSinceEpoch ~/ 60000; // Convert to minutes
    return (timeHash % 100000 + 500000)
        .abs(); // Use different range than medication notifications
  }

  Future<void> cancelAllReminders() async {
    final notifications = await _notifications.pendingNotificationRequests();
    for (var notification in notifications) {
      if (notification.id >= 500000 && notification.id < 600000) {
        await _notifications.cancel(notification.id);
      }
    }
  }

  Future<void> checkAndRescheduleReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReschedule = prefs.getInt(_lastRescheduleKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if it's been at least 30 days since last reschedule
    if (now - lastReschedule >= const Duration(days: 30).inMilliseconds) {
      await scheduleReminders();
      // Update last reschedule time
      await prefs.setInt(_lastRescheduleKey, now);
    }
  }

  Future<void> scheduleHighBPReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highBPReminderKey, true);

    // Cancel any existing reminders first
    await cancelAllReminders();

    // Show immediate notification about scheduled reminders
    await _notifications.show(
      888888, // Special ID for schedule notification
      'Blood Pressure Monitoring',
      'Due to high blood pressure reading, reminders have been set to measure every 4 hours for the next 24 hours.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _notificationChannelId,
          _notificationChannelName,
          channelDescription: 'Blood pressure monitoring alerts',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    // Schedule reminders every 4 hours for the next 24 hours
    final now = DateTime.now();
    for (int i = 1; i <= 6; i++) {
      final scheduledTime = now.add(Duration(hours: 4 * i));
      await _scheduleNotification(
        id: _generateNotificationId(scheduledTime),
        scheduledTime: scheduledTime,
        title: 'High Blood Pressure Alert',
        body: 'Please measure your blood pressure again',
        isHighBPAlert: true,
      );
    }
  }

  Future<void> cancelHighBPReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highBPReminderKey, false);
    await cancelAllReminders();
  }

  Future<void> checkAndHandleHighBP(int systolic, int diastolic) async {
    try {
      if (systolic >= 180 || diastolic >= 110) {
        // Show immediate emergency notification
        await _notifications
            .show(
          999999, // Special ID for emergency notification
          'EMERGENCY: Critical Blood Pressure',
          'Your blood pressure is critically high! Please call emergency hotline 117 immediately.',
          NotificationDetails(
            android: AndroidNotificationDetails(
              _notificationChannelId,
              _notificationChannelName,
              channelDescription: 'Emergency blood pressure alerts',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              color: const Color(0xFFFF0000),
              fullScreenIntent: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        )
            .catchError((e) {
          print('Error showing emergency notification: $e');
        });
      } else if (systolic >= 140 || diastolic >= 90) {
        try {
          await scheduleHighBPReminders();
        } catch (e) {
          print('Error scheduling high BP reminders: $e');
        }
      }
    } catch (e) {
      print('Error in checkAndHandleHighBP: $e');
      // Don't rethrow - allow the measurement to be saved even if notifications fail
    }
  }
}
