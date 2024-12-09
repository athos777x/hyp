import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/medication.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

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

  Future<void> scheduleMedicationReminders(List<Medication> medications) async {
    for (var medication in medications) {
      if (medication.doseTimes == null) continue;

      // Calculate end date based on medication settings
      DateTime endDate;
      if (medication.selectedEndOption == 'consistently') {
        endDate =
            DateTime.now().add(Duration(days: 365)); // Schedule for a year
      } else if (medication.selectedEndOption == 'date') {
        endDate = medication.endDate ?? medication.date;
      } else if (medication.selectedEndOption == 'amount of days' &&
          medication.daysAmount != null) {
        final days = int.tryParse(medication.daysAmount!) ?? 0;
        endDate = medication.date.add(Duration(days: days));
      } else if (medication.selectedEndOption == 'medication supply' &&
          medication.supplyAmount != null) {
        final supply = int.tryParse(medication.supplyAmount!) ?? 0;
        final dosesPerDay = medication.doseTimes!.length;
        final days = (supply / dosesPerDay).ceil();
        endDate = medication.date.add(Duration(days: days));
      } else {
        endDate = medication.date;
      }

      // Schedule notifications for each dose time until the end date
      for (var doseTime in medication.doseTimes!) {
        DateTime currentDate = medication.date;
        while (!currentDate.isAfter(endDate)) {
          if (medication.daysTaken == 'everyday' ||
              (medication.daysTaken == 'selected days' &&
                  medication.selectedDays
                          ?.contains(_getDayAbbreviation(currentDate)) ==
                      true)) {
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
            }
          }
          currentDate = currentDate.add(Duration(days: 1));
        }
      }
    }
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
