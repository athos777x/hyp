import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'dailypage.dart';
import 'healthpage.dart'; // Import the HealthPage
import 'medicationspage.dart'; // Import the MedicationsPage
import 'definitionspage.dart'; // Import the DefinitionsPage
import 'signsandsymptomspage.dart'; // Import the SignsAndSymptomsPage
import 'hospitalspage.dart'; // Import the HospitalsPage
import 'settingspage.dart'; // Import the SettingsPage

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Track the selected index

  // List of pages to display
  final List<Widget> _pages = [
    // Add your pages here
    DailyPage(),
    HealthPage(),
    MedicationsPage(),
    DefinitionsPage(),
    SignsAndSymptomsPage(),
    HospitalsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex, // Show the selected page
        children: _pages, // List of pages
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GNav(
                    gap: 4,
                    activeColor: Color(0xFF4CAF50),
                    iconSize: 17,
                    backgroundColor: Color.fromARGB(255, 255, 255, 255),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    tabMargin: EdgeInsets.symmetric(horizontal: 4),
                    tabBackgroundColor: Color(0xFF4CAF50).withOpacity(0.1),
                    color: Colors.grey,
                    tabs: [
                      GButton(
                        icon: Icons.calendar_today,
                        text: 'Daily',
                      ),
                      GButton(
                        icon: Icons.health_and_safety,
                        text: 'Health',
                      ),
                      GButton(
                        icon: Icons.medication,
                        text: 'Medications',
                      ),
                      GButton(
                        icon: Icons.book,
                        text: 'Definitions',
                      ),
                      GButton(
                        icon: Icons.warning,
                        text: 'S/Sx',
                      ),
                      GButton(
                        icon: Icons.local_hospital,
                        text: 'Hospitals',
                      ),
                      GButton(
                        icon: Icons.settings,
                        text: 'Settings',
                      ),
                    ],
                    selectedIndex: _selectedIndex,
                    onTabChange: (index) {
                      setState(() {
                        _selectedIndex = index; // Update the selected index
                      });
                    },
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
