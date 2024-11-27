import 'package:flutter/material.dart';
import '/homepage.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnBoardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
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
      title: 'Great!',
      buttonText: 'Start',
    ),
  ];

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
                        const SizedBox(height: 20),
                        if (_pages[index].hasTextField)
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Your name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (_pages[index].showNotificationRequest)
                          const Text(
                            'Allow us to send notifications',
                            style: TextStyle(color: Colors.grey),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentPage < _pages.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                // Navigate to HomePage
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const HomePage(),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
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
}

class OnboardingPage {
  final String title;
  final String buttonText;
  final bool hasTextField;
  final bool showNotificationRequest;

  OnboardingPage({
    required this.title,
    required this.buttonText,
    this.hasTextField = false,
    this.showNotificationRequest = false,
  });
}
