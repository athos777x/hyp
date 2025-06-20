import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  static const String _offlineUserKey = 'offline_user_data';
  static const String _offlineCreatedKey = 'offline_created';

  AuthService() {
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        // When connection is restored, try to sync
        syncOfflineData();
      }
    });
  }

  // Mark user as created offline
  Future<void> markOfflineCreated(bool created) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineCreatedKey, created);
  }

  // Check if user was created offline
  Future<bool> _wasCreatedOffline() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offlineCreatedKey) ?? false;
  }

  // Sync offline data when connection is restored
  Future<void> syncOfflineData() async {
    try {
      final wasOffline = await _wasCreatedOffline();
      if (!wasOffline) return;

      final userData = await _getLocalUserData();
      if (userData == null) return;

      // Try to sign in anonymously if not already signed in
      if (_auth.currentUser == null) {
        final userCredential = await _auth.signInAnonymously();
        if (userCredential.user != null) {
          // Update Firestore with the local data
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(userData);

          // Update local storage with the new Firebase UID
          final updatedData = {
            ...userData,
            'uid': userCredential.user!.uid,
          };
          await _saveUserDataLocally(updatedData);

          // Clear the offline created flag
          await markOfflineCreated(false);

          print('Successfully synced offline user data to Firebase');
        }
      }
    } catch (e) {
      print('Error syncing offline data: $e');
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Begin interactive sign-in process
      print('Google Sign-In: Starting sign-in flow');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-In: User canceled the sign-in flow');
        return null; // User canceled the sign-in flow
      }

      print('Google Sign-In: Got user account ${googleUser.email}');

      // Obtain auth details from request
      try {
        print('Google Sign-In: Getting authentication tokens');
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        print(
            'Google Sign-In: Got authentication tokens - Access token length: ${googleAuth.accessToken?.length ?? 0}, ID token length: ${googleAuth.idToken?.length ?? 0}');

        if (googleAuth.accessToken == null || googleAuth.idToken == null) {
          print('Google Sign-In: Failed to get valid tokens');
          throw PlatformException(
            code: 'missing_tokens',
            message: 'Missing required authentication tokens',
          );
        }

        // Create new credential for Firebase
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken!,
          idToken: googleAuth.idToken!,
        );

        // Sign in to Firebase with the Google credential
        print('Google Sign-In: Signing in to Firebase');
        final userCredential = await _auth.signInWithCredential(credential);
        print(
            'Google Sign-In: Successfully signed in to Firebase with user ${userCredential.user?.uid}');

        // Check if this is a new user
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          // Create a new user document in Firestore
          await createUserInFirestore(
            userCredential.user!.uid,
            userCredential.user!.displayName ?? '',
            userCredential.user!.email ?? '',
          );
        } else {
          // Ensure user data exists in Firestore
          final userDoc = await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (!userDoc.exists) {
            // Create user document if it doesn't exist
            await createUserInFirestore(
              userCredential.user!.uid,
              userCredential.user!.displayName ?? '',
              userCredential.user!.email ?? '',
            );
          }
        }

        return userCredential;
      } catch (e) {
        print('Google Sign-In: Error during authentication: $e');
        if (e is PlatformException) {
          print(
              'Google Sign-In: Platform Exception - Code: ${e.code}, Message: ${e.message}');
          if (e.code == 'sign_in_failed' || e.code.contains('ApiException')) {
            print(
                'Google Sign-In: API Exception detected. This typically means the SHA-1 fingerprint is not configured in Firebase.');
          }
        }
        rethrow;
      }
    } catch (e) {
      print('Google Sign-In: Error signing in with Google: $e');
      rethrow;
    }
  }

  // Link existing account with Google
  Future<UserCredential> linkAccountWithGoogle() async {
    try {
      if (_auth.currentUser == null) {
        print('Google Link: No user is currently signed in');
        throw Exception('No user is currently signed in');
      }

      // Begin interactive sign-in process
      print('Google Link: Starting sign-in flow');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Link: User canceled the sign-in flow');
        throw Exception('Google sign-in was canceled');
      }

      print('Google Link: Got user account ${googleUser.email}');

      // Obtain auth details from request
      try {
        print('Google Link: Getting authentication tokens');
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        print(
            'Google Link: Got authentication tokens - Access token length: ${googleAuth.accessToken?.length ?? 0}, ID token length: ${googleAuth.idToken?.length ?? 0}');

        if (googleAuth.accessToken == null || googleAuth.idToken == null) {
          print('Google Link: Failed to get valid tokens');
          throw PlatformException(
            code: 'missing_tokens',
            message: 'Missing required authentication tokens',
          );
        }

        // Create new credential for Firebase
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken!,
          idToken: googleAuth.idToken!,
        );

        // Link the Google credential to the current user
        print(
            'Google Link: Linking credential to Firebase user ${_auth.currentUser?.uid}');
        final result = await _auth.currentUser!.linkWithCredential(credential);
        print('Google Link: Successfully linked Google account');
        return result;
      } catch (e) {
        print('Google Link: Error during authentication or linking: $e');
        if (e is PlatformException) {
          print(
              'Google Link: Platform Exception - Code: ${e.code}, Message: ${e.message}');
          if (e.code == 'sign_in_failed' || e.code.contains('ApiException')) {
            print(
                'Google Link: API Exception detected. This typically means the SHA-1 fingerprint is not configured in Firebase.');
          }
        } else if (e is FirebaseAuthException) {
          print(
              'Google Link: Firebase Auth Exception - Code: ${e.code}, Message: ${e.message}');
        }
        rethrow;
      }
    } catch (e) {
      print('Google Link: Error linking account with Google: $e');
      rethrow;
    }
  }

  // Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Save user data locally
  Future<void> _saveUserDataLocally(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_offlineUserKey, jsonEncode(userData));
  }

  // Get locally saved user data
  Future<Map<String, dynamic>?> _getLocalUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_offlineUserKey);
    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  // Create user in Firestore and handle offline case
  Future<void> createUserInFirestore(
      String uid, String name, String email) async {
    final userData = {
      'name': name,
      'email': email,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Always save locally first
    await _saveUserDataLocally(userData);

    // Try to save to Firestore if online
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      try {
        await _firestore.collection('users').doc(uid).set(userData);
        await markOfflineCreated(false);
      } catch (e) {
        print('Error saving user to Firestore: $e');
        await markOfflineCreated(true);
      }
    } else {
      // Mark as created offline
      await markOfflineCreated(true);
    }
  }

  // Sync user data with Firestore
  Future<void> syncUserData() async {
    if (currentUser == null) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      try {
        // Check if we have local data to sync
        final localData = await _getLocalUserData();
        if (localData != null) {
          await _firestore
              .collection('users')
              .doc(currentUser!.uid)
              .set(localData, SetOptions(merge: true));
        }
      } catch (e) {
        print('Error syncing user data: $e');
      }
    }
  }

  // Get user data with offline support
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser == null) return null;

    // Try to get local data first
    Map<String, dynamic>? userData = await _getLocalUserData();

    // If online, try to get from Firestore and update local
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      try {
        final doc =
            await _firestore.collection('users').doc(currentUser!.uid).get();
        if (doc.exists) {
          userData = doc.data();
          // Update local cache
          if (userData != null) {
            await _saveUserDataLocally(userData);
          }
        } else if (userData != null) {
          // If we have local data but no Firestore data, sync to Firestore
          await syncUserData();
        }
      } catch (e) {
        print('Error getting user data: $e');
      }
    }

    return userData;
  }

  // Update user data with offline support
  Future<void> updateUserData(Map<String, dynamic> data) async {
    // Update local data first
    final existingData = await _getLocalUserData() ?? {};
    final updatedData = {...existingData, ...data};
    await _saveUserDataLocally(updatedData);

    // Try to update Firestore if online and user exists
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      try {
        if (_auth.currentUser != null) {
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .update(data);
        } else {
          // If we're online but no auth user exists, try to sync
          await syncOfflineData();
        }
      } catch (e) {
        print('Error updating user data: $e');
      }
    }
  }
}
