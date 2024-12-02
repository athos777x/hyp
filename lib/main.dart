import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import 'homepage.dart'; // Import your homepage
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
