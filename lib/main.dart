import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import 'homepage.dart'; // Import your homepage
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart';
import 'services/medication_service.dart';
import 'services/blood_pressure_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Firestore settings for offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize notification services
  await NotificationService().initialize();
  await BloodPressureNotificationService().initialize();

  // Get medications and check/reschedule notifications
  final medications = await MedicationService().loadMedications();
  await NotificationService().checkAndRescheduleNotifications(medications);

  // Check and reschedule blood pressure reminders
  await BloodPressureNotificationService().checkAndRescheduleReminders();

  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('showOnboarding') ?? true;
  runApp(MainApp(showOnboarding: showOnboarding));
}

class MainApp extends StatelessWidget {
  final bool showOnboarding;

  const MainApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: showOnboarding ? OnBoardingScreen() : const HomePage(),
    );
  }
}
