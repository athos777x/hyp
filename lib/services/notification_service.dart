import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/medication.dart';
import 'package:shared_preferences/shared_preferences.dart' as prefs;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _lastRescheduleKey = 'last_notification_reschedule';

  Future<void> initialize() async {
    tz.initializeTimeZones();

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
      payload: payload,
    );
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

  Future<void> cancelMedicationNotifications(String medicationName) async {
    final notifications = await _notifications.pendingNotificationRequests();
    for (var notification in notifications) {
      if (notification.payload == medicationName) {
        await _notifications.cancel(notification.id);
      }
    }
  }
}
