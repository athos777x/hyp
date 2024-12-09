import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'services/medication_service.dart';
import '../healthpage.dart';
import 'services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool alarmEnabled = true;
  bool notificationsEnabled = true;
  final TextEditingController _nameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MedicationService _medicationService = MedicationService();

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final userId = _auth.currentUser?.uid;
      print('Current user ID: $userId');

      if (userId != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        print('Firestore data: ${userData.data()}');

        if (userData.exists && userData.data()?['name'] != null) {
          setState(() {
            _nameController.text = userData.data()!['name'];
          });
          print('Name loaded: ${_nameController.text}');
        } else {
          print('No user data found or name is null');
        }
      }
    } catch (e) {
      print('Error loading user name: $e');
    }
  }

  Future<void> _updateUserName() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'name': _nameController.text.trim(),
        });
      }
    } catch (e) {
      print('Error updating user name: $e');
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Cancel all notifications before deleting account
        await NotificationService().cancelAllNotifications();

        // Delete user data from Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();

        // Clear all medications from SharedPreferences
        await _medicationService.clearMedications();

        // Clear blood pressure measurements
        await HealthPage.clearMeasurements();

        // Delete the Firebase Auth account
        await user.delete();

        // Reset onboarding flag
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('showOnboarding', true);

        // Navigate to onboarding screen
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const OnBoardingScreen(),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('Error deleting account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete account. Please try again.'),
        ),
      );
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
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MY PROFILE Section
              Text(
                'MY PROFILE',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_auth.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('Error: ${snapshot.error}');
                    return Text('Error loading name');
                  }

                  if (snapshot.hasData && snapshot.data != null) {
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>?;
                    final name = userData?['name'] as String? ?? '';
                    _nameController.text = name;

                    print('Loaded name from stream: $name'); // Debug print

                    return TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Your name',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                      onSubmitted: (_) => _updateUserName(),
                    );
                  }

                  return Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),

              SizedBox(height: 24),

              // CONFIGURE NOTIFICATIONS Section
              Text(
                'CONFIGURE NOTIFICATIONS',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      'Alarm',
                      alarmEnabled,
                      (value) => setState(() => alarmEnabled = value),
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    _buildSwitchTile(
                      'Notifications',
                      notificationsEnabled,
                      (value) => setState(() => notificationsEnabled = value),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Delete Account Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Account'),
                        content: const Text(
                          'Are you sure you want to delete your account? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteAccount();
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  title: const Text(
                    'Delete account',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }
}
