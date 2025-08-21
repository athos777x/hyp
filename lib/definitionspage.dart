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
                  _buildFoodsForHypertensionPage(),
                  _buildExercisesForHypertensionPage(),
                ],
              ),
            ),
            // Page Indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
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

  Widget _buildFoodsForHypertensionPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Food for Hypertension',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Tap on any food to learn more about its effects on blood pressure.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 24),

            // Food to Eat Section
            Text(
              'Food to Eat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 12),
            _buildFoodGrid([
              FoodItem(
                name: 'Leafy Greens',
                icon: Icons.eco,
                color: Colors.green[100]!,
                iconColor: Colors.green,
                isHealthy: true,
                description:
                    'Rich in potassium, which helps your kidneys flush out sodium that raises blood pressure. Examples include spinach, kale, and collard greens.',
              ),
              FoodItem(
                name: 'Berries',
                icon: Icons.bubble_chart,
                color: Colors.purple[100]!,
                iconColor: Colors.purple,
                isHealthy: true,
                description:
                    'High in antioxidants called flavonoids, which can help lower blood pressure and improve blood vessel function.',
              ),
              FoodItem(
                name: 'Bananas',
                icon: Icons.star,
                color: Colors.yellow[100]!,
                iconColor: Colors.amber,
                isHealthy: true,
                description:
                    'Excellent source of potassium, which helps counteract the effects of sodium and relaxes blood vessel walls.',
              ),
              FoodItem(
                name: 'Oatmeal',
                icon: Icons.breakfast_dining,
                color: Colors.brown[100]!,
                iconColor: Colors.brown,
                isHealthy: true,
                description:
                    'High in fiber and low in sodium. Regular consumption has been linked to reduced cholesterol levels and blood pressure.',
              ),
              FoodItem(
                name: 'Fatty Fish',
                icon: Icons.set_meal,
                color: Colors.blue[100]!,
                iconColor: Colors.blue,
                isHealthy: true,
                description:
                    'Rich in omega-3 fatty acids which can reduce inflammation and lower blood pressure. Examples include salmon, mackerel, and sardines.',
              ),
              FoodItem(
                name: 'Garlic',
                icon: Icons.spa,
                color: Colors.grey[100]!,
                iconColor: Colors.grey[700]!,
                isHealthy: true,
                description:
                    'Contains allicin, which may help reduce blood pressure by promoting the production of nitric oxide that helps relax blood vessels.',
              ),
            ]),

            SizedBox(height: 32),

            // Food to Avoid Section
            Text(
              'Food to Avoid',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 12),
            _buildFoodGrid([
              FoodItem(
                name: 'Salt',
                icon: Icons.grain,
                color: Colors.red[100]!,
                iconColor: Colors.red,
                isHealthy: false,
                description:
                    'High sodium intake causes your body to retain fluid, increasing blood pressure. Limit salt to less than 1,500mg per day if you have hypertension.',
              ),
              FoodItem(
                name: 'Processed Foods',
                icon: Icons.fastfood,
                color: Colors.orange[100]!,
                iconColor: Colors.orange,
                isHealthy: false,
                description:
                    'Often high in salt, sugar, and unhealthy fats. These include frozen meals, canned soups, and packaged snacks.',
              ),
              FoodItem(
                name: 'Alcohol',
                icon: Icons.local_bar,
                color: Colors.amber[100]!,
                iconColor: Colors.amber[700]!,
                isHealthy: false,
                description:
                    'Excessive drinking can raise blood pressure. Limit to one drink per day for women and two for men, if at all.',
              ),
              FoodItem(
                name: 'Caffeine',
                icon: Icons.coffee,
                color: Colors.brown[100]!,
                iconColor: Colors.brown[700]!,
                isHealthy: false,
                description:
                    'Can cause a temporary spike in blood pressure. Moderate consumption is generally okay, but some people are more sensitive to its effects.',
              ),
              FoodItem(
                name: 'Red Meat',
                icon: Icons.restaurant_menu,
                color: Colors.red[100]!,
                iconColor: Colors.red[700]!,
                isHealthy: false,
                description:
                    'High in saturated fat which can raise blood cholesterol levels and contribute to heart disease. Limit consumption and choose lean cuts.',
              ),
              FoodItem(
                name: 'Sugar',
                icon: Icons.cake,
                color: Colors.pink[100]!,
                iconColor: Colors.pink,
                isHealthy: false,
                description:
                    'Excessive sugar intake is linked to obesity and increased blood pressure. Avoid sugary drinks and desserts.',
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesForHypertensionPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exercises for Hypertension',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Regular physical activity can lower your blood pressure by 5-8 mmHg. Tap on any exercise to learn more.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 24),
            _buildExerciseCard(
              title: 'Walking',
              icon: Icons.directions_walk,
              color: Colors.blue[100]!,
              iconColor: Colors.blue[700]!,
              description:
                  'A simple but effective exercise that most people can do. Aim for 30 minutes of brisk walking most days of the week. This aerobic activity helps your heart become stronger and more efficient at pumping blood, which lowers the pressure in your arteries.',
              duration: '30-60 minutes',
              frequency: '5-7 days per week',
              intensity: 'Moderate',
            ),
            _buildExerciseCard(
              title: 'Swimming',
              icon: Icons.pool,
              color: Colors.cyan[100]!,
              iconColor: Colors.cyan[700]!,
              description:
                  'Swimming is an excellent full-body workout that\'s gentle on your joints. The water supports your body weight, making it ideal for people with joint problems or obesity. It improves cardiovascular health and lowers blood pressure.',
              duration: '30-45 minutes',
              frequency: '3-5 days per week',
              intensity: 'Moderate to vigorous',
            ),
            _buildExerciseCard(
              title: 'Cycling',
              icon: Icons.directions_bike,
              color: Colors.green[100]!,
              iconColor: Colors.green[700]!,
              description:
                  'Whether outdoors or on a stationary bike, cycling is a low-impact exercise that gets your heart pumping. It improves cardiovascular fitness and helps lower blood pressure while being gentle on your joints.',
              duration: '30-60 minutes',
              frequency: '3-5 days per week',
              intensity: 'Moderate to vigorous',
            ),
            _buildExerciseCard(
              title: 'Strength Training',
              icon: Icons.fitness_center,
              color: Colors.amber[100]!,
              iconColor: Colors.amber[700]!,
              description:
                  'Light to moderate weight training can help lower blood pressure by improving overall cardiovascular health. Focus on lighter weights with more repetitions rather than heavy lifting, which can temporarily raise blood pressure during exercise.',
              duration: '20-30 minutes',
              frequency: '2-3 days per week',
              intensity: 'Light to moderate',
            ),
            _buildExerciseCard(
              title: 'Yoga',
              icon: Icons.self_improvement,
              color: Colors.purple[100]!,
              iconColor: Colors.purple[700]!,
              description:
                  'Yoga combines physical postures, breathing exercises, and meditation. It can help reduce stress, a common contributor to high blood pressure. Certain yoga practices focus on relaxation and can have a significant impact on blood pressure levels.',
              duration: '30-60 minutes',
              frequency: '3-7 days per week',
              intensity: 'Low to moderate',
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Important Safety Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Always consult your doctor before starting a new exercise program.\n'
                    '• Start slowly and gradually increase intensity.\n'
                    '• Stop exercising and seek medical attention if you experience chest pain, severe shortness of breath, or dizziness.\n'
                    '• Avoid exercises that involve heavy lifting or straining.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.red[900],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodGrid(List<FoodItem> foods) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        return _buildFoodCard(foods[index]);
      },
    );
  }

  Widget _buildFoodCard(FoodItem food) {
    return GestureDetector(
      onTap: () => _showFoodDetails(food),
      child: Container(
        decoration: BoxDecoration(
          color: food.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              food.icon,
              color: food.iconColor,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              food.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFoodDetails(FoodItem food) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: food.color,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        food.icon,
                        color: food.iconColor,
                        size: 36,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          food.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: food.isHealthy ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          food.isHealthy ? 'Beneficial' : 'Avoid',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    food.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildExerciseCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String description,
    required String duration,
    required String frequency,
    required String intensity,
  }) {
    return GestureDetector(
      onTap: () => _showExerciseDetails(
        title: title,
        icon: icon,
        color: color,
        iconColor: iconColor,
        description: description,
        duration: duration,
        frequency: frequency,
        intensity: intensity,
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap to learn more',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseDetails({
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String description,
    required String duration,
    required String frequency,
    required String intensity,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildDetailRow('Duration', duration, Icons.timer),
                        SizedBox(height: 8),
                        _buildDetailRow(
                            'Frequency', frequency, Icons.calendar_today),
                        SizedBox(height: 8),
                        _buildDetailRow('Intensity', intensity, Icons.speed),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}

class FoodItem {
  final String name;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final bool isHealthy;
  final String description;

  FoodItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.isHealthy,
    required this.description,
  });
}
