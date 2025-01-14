import 'package:flutter/material.dart';

class DefinitionsPage extends StatefulWidget {
  @override
  _DefinitionsPageState createState() => _DefinitionsPageState();
}

class _DefinitionsPageState extends State<DefinitionsPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildHypertensionPage(),
                  _buildBloodPressureStagesPage(),
                ],
              ),
            ),
            // Page Indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  2,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Color(0xFF4CAF50)
                          : Colors.grey[300],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHypertensionPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.image,
                color: Color(0xFF4CAF50),
                size: 48,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'What is Hypertension or commonly known as high blood pressure?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Hypertension, or high blood pressure, happens when the force of blood pushing against the walls of your blood vessels is too high. Imagine water flowing through a hose—if the pressure is too strong, it can damage the hose over time. Similarly, high blood pressure can harm your blood vessels, heart, and other organs.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Blood pressure is measured with two numbers:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '1. Top number (systolic): Pressure when your heart beats.\n2. Bottom number (diastolic): Pressure when your heart is resting between beats.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodPressureStagesPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stages of high blood pressure',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            _buildStageCard(
              color: Color(0xFFE8F5E9),
              dotColor: Colors.green,
              title: 'Normal Blood Pressure',
              description:
                  'Your blood pressure is healthy if the top number (systolic) is less than 120 and the bottom number (diastolic) is less than 80.',
            ),
            _buildStageCard(
              color: Color(0xFFFFFDE7),
              dotColor: Colors.amber,
              title: 'Elevated Blood Pressure',
              description:
                  'This is like a warning stage. The top number is between 120 and 129, but the bottom number is still below 80. It\'s not dangerous yet, but it could get worse if not addressed.',
            ),
            _buildStageCard(
              color: Color(0xFFFFF3E0),
              dotColor: Colors.orange,
              title: 'Stage 1 High Blood Pressure',
              description:
                  'The top number is between 130 and 139, or the bottom number is between 80 and 89. This means your heart and arteries are under more strain.',
            ),
            _buildStageCard(
              color: Color(0xFFFFEBEE),
              dotColor: Colors.red[400]!,
              title: 'Stage 2 High Blood Pressure',
              description:
                  'The top number is 140 or higher, or the bottom number is 90 or higher. This is more serious and increases the risk of health problems like heart disease or stroke.',
            ),
            _buildStageCard(
              color: Color(0xFFFFCDD2),
              dotColor: Colors.red,
              title: 'Hypertensive Crisis',
              description:
                  'If the top number goes above 180 or the bottom number goes above 120, it is a medical emergency. This level of pressure can damage your organs and requires immediate attention.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageCard({
    required Color color,
    required Color dotColor,
    required String title,
    required String description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
