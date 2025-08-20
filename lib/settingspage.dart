import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'services/medication_service.dart';
import '../healthpage.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool alarmEnabled = true;
  bool notificationsEnabled = true;
  bool locationEnabled = true;
  final TextEditingController _nameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MedicationService _medicationService = MedicationService();
  final AuthService _authService = AuthService();
  String _userName = '';
  String _userEmail = '';
  bool _isGoogleLinked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkGoogleProvider();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      if (userData != null) {
        setState(() {
          _userName = userData['name'] ?? '';
          _userEmail = userData['email'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _checkGoogleProvider() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _isGoogleLinked = user.providerData
            .any((provider) => provider.providerId == 'google.com');
      });
    }
  }

  Future<void> _updateUserName(String newName) async {
    try {
      await _authService.updateUserData({'name': newName});
      await _loadUserData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name updated successfully')),
      );
    } catch (e) {
      print('Error updating user name: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Changes saved locally. Will sync when online.')),
      );
    }
  }

  Future<void> _linkWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_auth.currentUser == null) {
        // Sign in with Google if no user is signed in
        await _authService.signInWithGoogle();
      } else {
        // Link existing account with Google
        await _authService.linkAccountWithGoogle();
      }

      // Refresh user data
      await _loadUserData();
      await _checkGoogleProvider();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully linked with Google')),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      print('Firebase Auth Error: ${e.code} - ${e.message}');

      if (e.code == 'credential-already-in-use') {
        message = 'This Google account is already linked to another account';
      } else if (e.code == 'email-already-in-use') {
        message = 'This email is already in use by another account';
      } else if (e.code == 'provider-already-linked') {
        message = 'This account is already linked with Google';
      } else {
        message = 'Error: ${e.message ?? e.code}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      print('Error linking with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to link with Google: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null) {
        await _loadUserData();
        await _checkGoogleProvider();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully signed in with Google')),
        );
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in with Google')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _nameController..text = _userName,
                        decoration: InputDecoration(
                          hintText: 'Your name',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) => _updateUserName(value),
                      ),
                    ),
                    if (_userEmail.isNotEmpty) ...[
                      Divider(height: 1, color: Colors.grey[200]),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Text(
                              'Email: ',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _userEmail,
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Divider(height: 1, color: Colors.grey[200]),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : Column(
                              children: [
                                _buildGoogleSignInButton(),
                              ],
                            ),
                    ),
                  ],
                ),
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
                    Divider(height: 1, color: Colors.grey[200]),
                    _buildSwitchTile(
                      'Location',
                      locationEnabled,
                      (value) => setState(() => locationEnabled = value),
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    _buildTestNotificationTile(),
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

  Widget _buildGoogleSignInButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _isGoogleLinked ? Colors.grey.shade100 : Colors.white,
        boxShadow: _isGoogleLinked
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isGoogleLinked ? null : _linkWithGoogle,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Row(
              children: [
                Container(
                  height: 24,
                  width: 24,
                  child: Icon(
                    Icons.g_mobiledata,
                    size: 24,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _isGoogleLinked
                        ? 'Connected with Google'
                        : 'Connect with Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _isGoogleLinked
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                  ),
                ),
                if (_isGoogleLinked)
                  Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.shade100,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.green.shade700,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
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

  Widget _buildTestNotificationTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Medication Notification',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Send a test notification to verify it works',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _testMedicationNotification,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Test',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testMedicationNotification() async {
    try {
      // Show immediate test notification
      await NotificationService().showTestMedicationNotification();

      // Get pending notification count for debugging
      final pendingCount =
          await NotificationService().getPendingNotificationCount();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Test notification sent! Pending notifications: $pendingCount'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error sending test notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send test notification: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
