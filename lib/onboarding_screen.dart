import 'package:flutter/material.dart';
import '/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'services/auth_service.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnBoardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isLoading = false;
  bool _isGoogleSignedIn = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to HYP',
      description: 'Choose how you want to continue',
      showAuthOptions: true,
      buttonText: 'Continue as Guest',
    ),
    OnboardingPage(
      title: 'Welcome! May I know your name?',
      hasTextField: true,
      buttonText: 'Next',
    ),
    OnboardingPage(
      title:
          'Facts: Lorem ipsum dolor sit amet. Est possimus natus ab consequatur iusto sed vitae animi ea quis facilis.',
      buttonText: 'Next',
    ),
    OnboardingPage(
      title: "We'll help you take your medication on time!",
      buttonText: 'Allow',
      showNotificationRequest: true,
    ),
    OnboardingPage(
      title: 'Help us find nearby hospitals',
      buttonText: 'Allow Location',
      showLocationRequest: true,
    ),
    OnboardingPage(
      title: 'Great!',
      buttonText: 'Start',
    ),
  ];

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential? userCredential =
          await _authService.signInWithGoogle();

      if (userCredential != null) {
        setState(() {
          _isGoogleSignedIn = true;
          _nameController.text = userCredential.user?.displayName ?? '';
        });

        // Skip to the next page after name
        _pageController.animateToPage(
          2, // Skip the name input page
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to sign in with Google. Continuing as guest.')),
      );
      // Continue as guest if Google sign-in fails
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInAnonymously() async {
    try {
      final UserCredential userCredential =
          await _authService.signInAnonymously();

      print('Signing in with name: ${_nameController.text}');

      if (_nameController.text.isNotEmpty) {
        await _authService.createUserInFirestore(
          userCredential.user!.uid,
          _nameController.text.trim(),
          '', // No email for anonymous users
        );
        print('Successfully saved name locally and to Firestore if online');
      }
    } catch (e) {
      print('Error signing in anonymously: $e');
      // Create offline user with temporary ID
      if (_nameController.text.isNotEmpty) {
        final offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
        await _authService.createUserInFirestore(
          offlineId,
          _nameController.text.trim(),
          '', // No email for anonymous users
        );
        // Mark as created offline so it will be synced when online
        await _authService.markOfflineCreated(true);
        print('Saved user data locally due to offline/error state');
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', false);
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );
  }

  Future<void> _requestNotificationPermissions() async {
    // For Android 13 and above
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // For iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Show a test notification
    await _showTestNotification();
  }

  Future<void> _showTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders to take your medication',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Notifications Enabled',
      'You will now receive medication reminders',
      platformChannelSpecifics,
    );
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      // Show a dialog explaining why location is needed and how to enable it
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
                'Location permission is needed to find nearby hospitals. Please enable it in your device settings.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Open Settings'),
                onPressed: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Skip'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / _pages.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: _isLoading ? NeverScrollableScrollPhysics() : null,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Spacer(),
                        // Placeholder for image
                        Container(
                          width: 100,
                          height: 100,
                          color: Colors.green.withOpacity(0.1),
                          child: const Icon(Icons.image, color: Colors.green),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _pages[index].title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_pages[index].description != null)
                          Text(
                            _pages[index].description!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        const SizedBox(height: 20),
                        if (_pages[index].hasTextField)
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Your name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        if (_pages[index].showAuthOptions) ...[
                          const SizedBox(height: 30),
                          _buildGoogleSignInButton(),
                          const SizedBox(height: 20),
                          const Text(
                            'or',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (_pages[index].showNotificationRequest)
                          const Text(
                            'Allow us to send notifications',
                            style: TextStyle(color: Colors.grey),
                          ),
                        if (_pages[index].showLocationRequest)
                          const Text(
                            'Allow us to access your location to find nearby hospitals',
                            style: TextStyle(color: Colors.grey),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (_currentPage < _pages.length - 1) {
                                      if (_currentPage == 0) {
                                        // First page - continue as guest
                                        _pageController.nextPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      } else if (_currentPage == 1) {
                                        // Name page
                                        if (_nameController.text
                                            .trim()
                                            .isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Please enter your name')),
                                          );
                                          return;
                                        }
                                        FocusScope.of(context).unfocus();
                                        _signInAnonymously();
                                        _pageController.nextPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      } else if (_pages[_currentPage]
                                          .showNotificationRequest) {
                                        _requestNotificationPermissions();
                                        _pageController.nextPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      } else if (_pages[_currentPage]
                                          .showLocationRequest) {
                                        _requestLocationPermission();
                                        _pageController.nextPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      } else {
                                        _pageController.nextPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    } else {
                                      _completeOnboarding();
                                      if (mounted) {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const HomePage(),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              disabledBackgroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _pages[index].buttonText,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _isLoading ? null : _signInWithGoogle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 24,
                  width: 24,
                  child: const Icon(
                    Icons.g_mobiledata,
                    size: 24,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sign in with Google',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String? description;
  final String buttonText;
  final bool hasTextField;
  final bool showNotificationRequest;
  final bool showLocationRequest;
  final bool showAuthOptions;

  OnboardingPage({
    required this.title,
    this.description,
    required this.buttonText,
    this.hasTextField = false,
    this.showNotificationRequest = false,
    this.showLocationRequest = false,
    this.showAuthOptions = false,
  });
}
