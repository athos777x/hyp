import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

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
      'Blood Pressure Reminder',
      'Time to measure your blood pressure',
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
}
