import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'app_config.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import '../models/shipper_model.dart';
import '../models/carrier_model.dart';
import '../models/carrier_onboarding_data.dart';
import '../models/shipper_onboarding_data.dart';
import '../models/product_listing.dart';
import '../models/chat_model.dart';
import '../models/load_model.dart';
import '../models/offer_model.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../models/academy_content.dart';
// import 'utils/distance_service.dart'; // Temporarily disabled until Distance Matrix API is activated

/// Firebase service class to handle all Firebase operations
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Authentication methods
  static FirebaseAuth get auth => _auth;
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firestore methods
  static FirebaseFirestore get firestore => _firestore;
  static CollectionReference get users => _firestore.collection('users');
  static CollectionReference get shippers => _firestore.collection('shippers');
  static CollectionReference get carriers => _firestore.collection('carriers');
  static CollectionReference get loads => _firestore.collection('loads');
  static CollectionReference get listings => _firestore.collection('listings');
  static CollectionReference get conversations =>
      _firestore.collection('conversations');
  static CollectionReference get messages => _firestore.collection('messages');
  static CollectionReference get bookings => _firestore.collection('bookings');
  static CollectionReference get offers => _firestore.collection('offers');
  static CollectionReference get reports => _firestore.collection('reports');

  // Storage methods
  static FirebaseStorage get storage => _storage;
  static Reference get storageRef => _storage.ref();

  // Analytics methods according to official docs
  static FirebaseAnalytics get analytics => _analytics;

  // Log custom event with proper parameter validation
  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    try {
      // Validate event name (max 40 characters as per official docs)
      if (name.length > 40) {
        throw ArgumentError('Event name must be 40 characters or fewer');
      }

      // Validate parameters (max 25 parameters as per official docs)
      if (parameters != null && parameters.length > 25) {
        throw ArgumentError('Event can have at most 25 parameters');
      }

      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Failed to log analytics event: $e');
      }
    }
  }

  // Helper method to convert dynamic parameters to Object parameters
  static Map<String, Object> _convertParameters(Map<String, dynamic>? params) {
    if (params == null) return {};
    return params.map((key, value) => MapEntry(key, value as Object));
  }

  // Public version for external use
  static Map<String, Object> convertParameters(Map<String, dynamic>? params) {
    if (params == null) return {};
    return params.map((key, value) => MapEntry(key, value as Object));
  }

  // User properties for analytics
  static Future<void> setUserProperty(String name, String? value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  static Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  // Test method to verify analytics is working (debug only)
  static Future<void> testAnalytics() async {
    if (!AppConfig.enableTestEvents) {
      if (AppConfig.enableDebugLogging) {
        print('Analytics test skipped in ${AppConfig.buildMode} mode');
      }
      return;
    }

    try {
      // Add timeout to prevent hanging
      await logEvent(
        'analytics_test',
        parameters: _convertParameters({
          'test_timestamp': DateTime.now().millisecondsSinceEpoch,
          'test_success': 'true',
          'build_mode': AppConfig.buildMode,
          'app_version': AppConfig.versionInfo,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (AppConfig.enableDebugLogging) {
            print('Analytics test timed out');
          }
        },
      );
      if (AppConfig.enableDebugLogging) {
        print('Analytics test event logged successfully');
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Analytics test failed: $e');
      }
    }
  }

  // Crashlytics methods according to official docs
  static FirebaseCrashlytics get crashlytics => _crashlytics;

  // Record non-fatal error with proper error handling
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    try {
      await _crashlytics.recordError(exception, stackTrace, reason: reason);
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Failed to record error in Crashlytics: $e');
      }
    }
  }

  // Record custom log message
  static Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Failed to log message in Crashlytics: $e');
      }
    }
  }

  // Set custom key-value pair
  static Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Failed to set custom key in Crashlytics: $e');
      }
    }
  }

  // Set user identifier
  static Future<void> setUserIdentifier(String identifier) async {
    try {
      await _crashlytics.setUserIdentifier(identifier);
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Failed to set user identifier in Crashlytics: $e');
      }
    }
  }

  // Test method to verify Crashlytics is working (debug only)
  static Future<void> testCrashlytics() async {
    if (!AppConfig.enableTestEvents) {
      if (AppConfig.enableDebugLogging) {
        print('Crashlytics test skipped in ${AppConfig.buildMode} mode');
      }
      return;
    }

    try {
      if (AppConfig.enableDebugLogging) {
        print('Starting Crashlytics test...');
      }

      // Test 1: Set user identifier (this usually works even if other methods fail)
      await setUserIdentifier(
        'test_user_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (AppConfig.enableDebugLogging) {
        print('✓ User identifier set successfully');
      }

      // Test 2: Set custom key (this usually works)
      await setCustomKey(
        'test_key',
        'test_value_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (AppConfig.enableDebugLogging) {
        print('✓ Custom key set successfully');
      }

      // Test 3: Log message (this might fail with 404)
      await log('Crashlytics test log - ${DateTime.now().toIso8601String()}');
      if (AppConfig.enableDebugLogging) {
        print('✓ Log message sent successfully');
      }

      // Test 4: Record non-fatal error (this might fail with 404)
      await recordError(
        'Test non-fatal error from ${AppConfig.buildMode} mode',
        StackTrace.current,
        reason: 'Testing Crashlytics integration',
      );
      if (AppConfig.enableDebugLogging) {
        print('✓ Non-fatal error recorded successfully');
      }

      if (AppConfig.enableDebugLogging) {
        print(
          'Crashlytics test completed. Some methods may fail with 404 if Crashlytics is not fully enabled in Firebase Console.',
        );
        print('Check Firebase Console > Crashlytics in a few minutes');
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Crashlytics test failed: $e');
      }
    }
  }

  // Method to force a test crash (use with caution - only for testing)
  static void testCrash() {
    if (AppConfig.enableTestEvents) {
      if (AppConfig.enableDebugLogging) {
        print('Triggering test crash for Crashlytics verification');
      }
      // This will cause a crash for testing purposes
      throw Exception('Test crash for Crashlytics verification');
    }
  }

  // Method to check if Crashlytics is working
  static Future<bool> isCrashlyticsWorking() async {
    try {
      // Try to set a custom key to test if Crashlytics is responsive
      await _crashlytics.setCustomKey(
        'health_check',
        DateTime.now().millisecondsSinceEpoch,
      );
      return true;
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('Crashlytics health check failed: $e');
      }
      return false;
    }
  }

  // Method to manually test Crashlytics from UI
  static Future<void> manualCrashlyticsTest() async {
    try {
      print('Starting manual Crashlytics test...');

      // Test 1: Set user identifier (usually works)
      await setUserIdentifier(
        'manual_test_user_${DateTime.now().millisecondsSinceEpoch}',
      );
      print('✓ User identifier set successfully');

      // Test 2: Set custom keys (usually works)
      await setCustomKey('manual_test_key', 'manual_test_value');
      await setCustomKey(
        'test_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
      print('✓ Custom keys set successfully');

      // Test 3: Log a custom message (might fail with 404)
      await log('Manual test log - ${DateTime.now().toIso8601String()}');
      print('✓ Log message sent successfully');

      // Test 4: Record a non-fatal error (might fail with 404)
      await recordError(
        'Manual test error - ${DateTime.now().toIso8601String()}',
        StackTrace.current,
        reason: 'Manual UI test',
      );
      print('✓ Non-fatal error recorded successfully');

      print('Manual Crashlytics test completed!');
      print(
        'Note: 404 errors are common if Crashlytics is not fully enabled in Firebase Console',
      );
      print('Check Firebase Console > Crashlytics in 5-10 minutes');
    } catch (e) {
      print('Manual Crashlytics test failed: $e');
    }
  }

  // User management methods
  static Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Log successful sign in
      await logEvent(
        'login',
        parameters: _convertParameters({
          'method': 'email_password',
          'success': 'true',
        }),
      );
      return result;
    } catch (e) {
      // Log failed sign in
      await logEvent(
        'login',
        parameters: _convertParameters({
          'method': 'email_password',
          'success': 'false',
          'error': e.toString(),
        }),
      );
      await recordError(e, StackTrace.current, reason: 'Sign in failed');
      rethrow;
    }
  }

  static Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Log successful user creation
      await logEvent(
        'sign_up',
        parameters: _convertParameters({
          'method': 'email_password',
          'success': 'true',
        }),
      );
      return result;
    } catch (e) {
      // Log failed user creation
      await logEvent(
        'sign_up',
        parameters: _convertParameters({
          'method': 'email_password',
          'success': 'false',
          'error': e.toString(),
        }),
      );
      await recordError(e, StackTrace.current, reason: 'User creation failed');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Log successful sign out
      await logEvent(
        'logout',
        parameters: _convertParameters({'success': 'true'}),
      );
    } catch (e) {
      // Log failed sign out
      await logEvent(
        'logout',
        parameters: _convertParameters({
          'success': 'false',
          'error': e.toString(),
        }),
      );
      await recordError(e, StackTrace.current, reason: 'Sign out failed');
      rethrow;
    }
  }

  // Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // For web, use Firebase Auth's native Google Sign-In provider
        // This uses signInWithPopup internally and is the recommended approach
        // It doesn't require the google_sign_in package and handles idToken automatically
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        // Sign in with popup (native Firebase Auth method for web)
        final userCredential = await _auth.signInWithPopup(googleProvider);

        // Log successful sign in
        await logEvent(
          'login',
          parameters: _convertParameters({'method': 'google', 'success': 'true'}),
        );

        return userCredential;
      } else {
        // For mobile (iOS/Android), use google_sign_in package
        const String clientId =
            '60865903848-qufrm62v42k4kuh30jr022dr2mjcim5i.apps.googleusercontent.com';

        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile', 'openid'],
          serverClientId: clientId,
        );

        // Trigger the authentication flow
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          // User canceled the sign-in
          return null;
        }

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Check if idToken is available (required for Firebase Auth)
        if (googleAuth.idToken == null) {
          throw Exception('Failed to obtain Google ID token. Please try again.');
        }

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        final userCredential = await _auth.signInWithCredential(credential);

        // Log successful sign in
        await logEvent(
          'login',
          parameters: _convertParameters({'method': 'google', 'success': 'true'}),
        );

        return userCredential;
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors
      await logEvent(
        'login',
        parameters: _convertParameters({
          'method': 'google',
          'success': 'false',
          'error': e.code,
        }),
      );
      await recordError(e, StackTrace.current, reason: 'Google sign in failed: ${e.code}');
      rethrow;
    } catch (e) {
      // Log failed sign in
      await logEvent(
        'login',
        parameters: _convertParameters({
          'method': 'google',
          'success': 'false',
          'error': e.toString(),
        }),
      );
      await recordError(e, StackTrace.current, reason: 'Google sign in failed');
      rethrow;
    }
  }

  // Firestore data methods
  static Future<void> createUserDocument(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      await users.doc(userId).set(userData);
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Create user document failed',
      );
      rethrow;
    }
  }

  static Future<DocumentSnapshot> getUserDocument(String userId) async {
    try {
      return await users.doc(userId).get();
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Get user document failed',
      );
      rethrow;
    }
  }

  static Future<void> updateUserDocument(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await users.doc(userId).update(updates);
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Update user document failed',
      );
      rethrow;
    }
  }

  // Storage methods
  // static Future<String> uploadFile(String path, List<int> data) async {
  //   try {
  //     final ref = _storage.ref().child(path);
  //     final uploadTask = await ref.putData(data);
  //     return await uploadTask.ref.getDownloadURL();
  //   } catch (e) {
  //     await recordError(e, StackTrace.current, reason: 'File upload failed');
  //     rethrow;
  //   }
  // }

  static Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'File deletion failed');
      rethrow;
    }
  }

  // Delete file from Storage using URL
  static Future<void> deleteFileFromURL(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // If the file doesn't exist, that's fine – nothing to delete.
      if (e is FirebaseException && e.code == 'object-not-found') {
        if (AppConfig.enableDebugLogging) {
          print(
            'deleteFileFromURL: object not found, skipping delete for $url',
          );
        }
        return;
      }
      await recordError(
        e,
        StackTrace.current,
        reason: 'File deletion from URL failed',
      );
      rethrow;
    }
  }

  // Role-based user management methods
  static Future<ShipperModel?> createShipper(ShipperModel shipper) async {
    try {
      final docRef = shippers.doc(shipper.uid);
      await docRef.set(shipper.toFirestore());
      return shipper;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Create shipper failed');
      rethrow;
    }
  }

  static Future<CarrierModel?> createCarrier(CarrierModel carrier) async {
    try {
      final docRef = carriers.doc(carrier.uid);
      await docRef.set(carrier.toFirestore());
      return carrier;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Create carrier failed');
      rethrow;
    }
  }

  static Future<ShipperModel?> getShipper(String uid) async {
    try {
      final doc = await shippers.doc(uid).get();
      if (doc.exists) {
        return ShipperModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Get shipper failed');
      rethrow;
    }
  }

  static Future<CarrierModel?> getCarrier(String uid) async {
    try {
      final doc = await carriers.doc(uid).get();
      if (doc.exists) {
        return CarrierModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Get carrier failed');
      rethrow;
    }
  }

  static Future<void> updateShipper(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    try {
      await shippers.doc(uid).update(updates);
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Update shipper failed');
      rethrow;
    }
  }

  static Future<void> updateCarrier(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    try {
      await carriers.doc(uid).update(updates);
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Update carrier failed');
      rethrow;
    }
  }

  static Future<UserRole?> getUserRole(String uid) async {
    try {
      // Check shippers collection first
      final shipperDoc = await shippers.doc(uid).get();
      if (shipperDoc.exists) {
        return UserRole.shipper;
      }

      // Check carriers collection
      final carrierDoc = await carriers.doc(uid).get();
      if (carrierDoc.exists) {
        return UserRole.carrier;
      }

      return null;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Get user role failed');
      rethrow;
    }
  }

  static Future<UserModel?> getUserByRole(String uid, UserRole role) async {
    try {
      switch (role) {
        case UserRole.shipper:
          return await getShipper(uid);
        case UserRole.carrier:
          return await getCarrier(uid);
      }
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Get user by role failed',
      );
      rethrow;
    }
  }

  /// Check if a phone number is available (not already used by another user)
  /// Returns true if phone number is available, false if already in use
  /// Excludes the current user's phone number from the check
  static Future<bool> isPhoneNumberAvailable({
    required String phoneNumber,
    String? excludeUid,
  }) async {
    try {
      // Normalize phone number (ensure it starts with +)
      String normalizedPhone = phoneNumber.trim();
      if (!normalizedPhone.startsWith('+')) {
        normalizedPhone = '+$normalizedPhone';
      }

      // Check in shippers collection
      final shippersQuery = await shippers
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .get();

      for (var doc in shippersQuery.docs) {
        // Skip if this is the current user's document
        if (excludeUid != null && doc.id == excludeUid) {
          continue;
        }
        // Phone number is already in use
        return false;
      }

      // Check in carriers collection
      final carriersQuery = await carriers
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .get();

      for (var doc in carriersQuery.docs) {
        // Skip if this is the current user's document
        if (excludeUid != null && doc.id == excludeUid) {
          continue;
        }
        // Phone number is already in use
        return false;
      }

      // Phone number is available
      return true;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Check phone number availability failed',
      );
      // On error, return true to allow the user to proceed (fail open)
      return true;
    }
  }

  // Enhanced authentication methods with role handling
  static Future<UserCredential?> signUpShipper({
    required String email,
    required String password,
    required ShipperModel shipperData,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create shipper document in Firestore
        final shipper = shipperData.copyWithShipper(
          uid: userCredential.user!.uid,
        );
        print(
          'FirebaseService: Creating shipper with isOnboardingComplete: ${shipper.isOnboardingComplete}',
        );
        await createShipper(shipper);
        print('FirebaseService: Shipper created successfully');

        // Set user properties for analytics
        await setUserId(userCredential.user!.uid);
        await setUserProperty('user_type', 'shipper');
        await setUserProperty(
          'onboarding_complete',
          shipper.isOnboardingComplete.toString(),
        );

        // Log shipper signup event
        await logEvent(
          'shipper_signup',
          parameters: _convertParameters({
            'success': 'true',
            'onboarding_complete': shipper.isOnboardingComplete,
          }),
        );
      }

      return userCredential;
    } catch (e) {
      // Log failed shipper signup
      await logEvent(
        'shipper_signup',
        parameters: _convertParameters({
          'success': 'false',
          'error': e.toString(),
        }),
      );
      await recordError(e, StackTrace.current, reason: 'Shipper signup failed');
      rethrow;
    }
  }

  static Future<UserCredential?> signUpCarrier({
    required String email,
    required String password,
    required CarrierModel carrierData,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create carrier document in Firestore
        final carrier = carrierData.copyWithCarrier(
          uid: userCredential.user!.uid,
        );
        await createCarrier(carrier);

        // Set user properties for analytics
        await setUserId(userCredential.user!.uid);
        await setUserProperty('user_type', 'carrier');
        await setUserProperty(
          'onboarding_complete',
          carrier.isOnboardingComplete.toString(),
        );

        // Log carrier signup event
        await logEvent(
          'carrier_signup',
          parameters: _convertParameters({
            'success': 'true',
            'onboarding_complete': carrier.isOnboardingComplete,
          }),
        );
      }

      return userCredential;
    } catch (e) {
      // Log failed carrier signup
      await logEvent(
        'carrier_signup',
        parameters: _convertParameters({
          'success': 'false',
          'error': e.toString(),
        }),
      );
      await recordError(e, StackTrace.current, reason: 'Carrier signup failed');
      rethrow;
    }
  }

  static Future<UserModel?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final role = await getUserRole(user.uid);
      if (role == null) return null;

      // Set user properties for analytics when getting current user data
      await setUserId(user.uid);
      await setUserProperty('user_type', role.name);

      final userData = await getUserByRole(user.uid, role);

      // Set additional user properties based on user type
      if (userData != null) {
        if (role == UserRole.shipper) {
          final shipper = userData as ShipperModel;
          await setUserProperty(
            'onboarding_complete',
            shipper.isOnboardingComplete.toString(),
          );
        } else if (role == UserRole.carrier) {
          final carrier = userData as CarrierModel;
          await setUserProperty(
            'onboarding_complete',
            carrier.isOnboardingComplete.toString(),
          );
        }
      }

      return userData;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Get current user data failed',
      );
      rethrow;
    }
  }

  // Carrier Onboarding Data Methods
  static Future<void> saveCarrierOnboardingResponse(
    String carrierId,
    String screenName,
    Map<String, dynamic> response,
  ) async {
    try {
      final carrierRef = carriers.doc(carrierId);
      final carrierDoc = await carrierRef.get();

      if (!carrierDoc.exists) {
        throw Exception('Carrier document not found');
      }

      final carrierData = carrierDoc.data() as Map<String, dynamic>;
      final currentOnboardingData = carrierData['onboardingData'] != null
          ? CarrierOnboardingData.fromFirestore(carrierData['onboardingData'])
          : CarrierOnboardingData();

      final updatedOnboardingData = currentOnboardingData.addResponse(
        screenName,
        response,
      );

      await carrierRef.update({
        'onboardingData': updatedOnboardingData.toFirestore(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('Onboarding response saved for screen: $screenName');
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Save carrier onboarding response failed',
      );
      rethrow;
    }
  }

  static Future<void> markCarrierOnboardingComplete(String carrierId) async {
    try {
      final carrierRef = carriers.doc(carrierId);
      final carrierDoc = await carrierRef.get();

      if (!carrierDoc.exists) {
        throw Exception('Carrier document not found');
      }

      final carrierData = carrierDoc.data() as Map<String, dynamic>;
      final currentOnboardingData = carrierData['onboardingData'] != null
          ? CarrierOnboardingData.fromFirestore(carrierData['onboardingData'])
          : CarrierOnboardingData();

      final completedOnboardingData = currentOnboardingData.markComplete();

      await carrierRef.update({
        'onboardingData': completedOnboardingData.toFirestore(),
        'isOnboardingComplete': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update user property for analytics
      await setUserProperty('onboarding_complete', 'true');

      // Log onboarding completion event
      await logEvent(
        'onboarding_complete',
        parameters: _convertParameters({
          'user_type': 'carrier',
          'success': 'true',
        }),
      );

      print('Carrier onboarding marked as complete');
    } catch (e) {
      // Log failed onboarding completion
      await logEvent(
        'onboarding_complete',
        parameters: _convertParameters({
          'user_type': 'carrier',
          'success': 'false',
          'error': e.toString(),
        }),
      );
      await recordError(
        e,
        StackTrace.current,
        reason: 'Mark carrier onboarding complete failed',
      );
      rethrow;
    }
  }

  static Future<CarrierOnboardingData?> getCarrierOnboardingData(
    String carrierId,
  ) async {
    try {
      final carrierDoc = await carriers.doc(carrierId).get();

      if (!carrierDoc.exists) {
        return null;
      }

      final carrierData = carrierDoc.data() as Map<String, dynamic>;
      return carrierData['onboardingData'] != null
          ? CarrierOnboardingData.fromFirestore(carrierData['onboardingData'])
          : null;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Get carrier onboarding data failed',
      );
      rethrow;
    }
  }

  static Future<bool> isCarrierOnboardingComplete(String carrierId) async {
    try {
      final onboardingData = await getCarrierOnboardingData(carrierId);
      return onboardingData?.isCompleted ?? false;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Check carrier onboarding complete failed',
      );
      return false;
    }
  }

  static Future<List<String>> getCompletedOnboardingScreens(
    String carrierId,
  ) async {
    try {
      final onboardingData = await getCarrierOnboardingData(carrierId);
      return onboardingData?.completedScreens ?? [];
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Get completed onboarding screens failed',
      );
      return [];
    }
  }

  // Shipper Onboarding Data Methods
  static Future<void> saveShipperOnboardingResponse(
    String shipperId,
    String screenName,
    Map<String, dynamic> response,
  ) async {
    try {
      final shipperRef = shippers.doc(shipperId);
      final shipperDoc = await shipperRef.get();

      if (!shipperDoc.exists) {
        throw Exception('Shipper document not found');
      }

      final shipperData = shipperDoc.data() as Map<String, dynamic>;
      final currentOnboardingData = shipperData['onboardingData'] != null
          ? ShipperOnboardingData.fromFirestore(shipperData['onboardingData'])
          : const ShipperOnboardingData();

      final updatedOnboardingData = currentOnboardingData.addResponse(
        screenName,
        response,
      );

      await shipperRef.update({
        'onboardingData': updatedOnboardingData.toFirestore(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('Shipper onboarding response saved for screen: $screenName');
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Save shipper onboarding response failed',
      );
      rethrow;
    }
  }

  static Future<void> markShipperOnboardingComplete(String shipperId) async {
    try {
      final shipperRef = shippers.doc(shipperId);
      final shipperDoc = await shipperRef.get();

      if (!shipperDoc.exists) {
        throw Exception('Shipper document not found');
      }

      final shipperData = shipperDoc.data() as Map<String, dynamic>;
      final currentOnboardingData = shipperData['onboardingData'] != null
          ? ShipperOnboardingData.fromFirestore(shipperData['onboardingData'])
          : const ShipperOnboardingData();

      final completedOnboardingData = currentOnboardingData.markComplete();

      await shipperRef.update({
        'onboardingData': completedOnboardingData.toFirestore(),
        'isOnboardingComplete': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update user property for analytics
      await setUserProperty('onboarding_complete', 'true');

      // Log onboarding completion event
      await logEvent(
        'onboarding_complete',
        parameters: _convertParameters({
          'user_type': 'shipper',
          'success': 'true',
        }),
      );

      print('Shipper onboarding marked as complete');
    } catch (e) {
      // Log failed onboarding completion
      await logEvent(
        'onboarding_complete',
        parameters: _convertParameters({
          'user_type': 'shipper',
          'success': 'false',
          'error': e.toString(),
        }),
      );
      await recordError(
        e,
        StackTrace.current,
        reason: 'Mark shipper onboarding complete failed',
      );
      rethrow;
    }
  }

  static Future<ShipperOnboardingData?> getShipperOnboardingData(
    String shipperId,
  ) async {
    try {
      final shipperDoc = await shippers.doc(shipperId).get();

      if (!shipperDoc.exists) {
        return null;
      }

      final shipperData = shipperDoc.data() as Map<String, dynamic>;
      return shipperData['onboardingData'] != null
          ? ShipperOnboardingData.fromFirestore(shipperData['onboardingData'])
          : null;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Get shipper onboarding data failed',
      );
      rethrow;
    }
  }

  static Future<bool> isShipperOnboardingComplete(String shipperId) async {
    try {
      final onboardingData = await getShipperOnboardingData(shipperId);
      return onboardingData?.isCompleted ?? false;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Check shipper onboarding complete failed',
      );
      return false;
    }
  }

  // Save shipper dashboard response
  static Future<void> saveShipperDashboardResponse(
    String shipperUid,
    String screenKey,
    Map<String, dynamic> response,
  ) async {
    try {
      await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('dashboard_responses')
          .doc(screenKey)
          .set(response, SetOptions(merge: true));
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to save shipper dashboard response',
      );
      rethrow;
    }
  }

  // Get shipper dashboard response
  static Future<Map<String, dynamic>?> getShipperDashboardResponse(
    String shipperUid,
    String screenKey,
  ) async {
    try {
      final doc = await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('dashboard_responses')
          .doc(screenKey)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get shipper dashboard response',
      );
      return null;
    }
  }

  // Check if shipper has completed all dashboard steps
  static Future<bool> isShipperDashboardComplete(String shipperUid) async {
    try {
      // Check if all three dashboard steps are completed
      final dashboard2 = await getShipperDashboardResponse(
        shipperUid,
        'dashboard_2_business_info',
      );
      final dashboard3 = await getShipperDashboardResponse(
        shipperUid,
        'dashboard_3_business_number',
      );

      return dashboard2 != null && dashboard3 != null;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Check shipper dashboard complete failed',
      );
      return false;
    }
  }

  // Upload image to Firebase Storage
  static Future<String?> uploadImage(
    String shipperUid,
    String imageType,
    dynamic imageFile,
  ) async {
    try {
      final ref = _storage.ref().child(
        'shippers/$shipperUid/documents/$imageType.jpg',
      );

      UploadTask uploadTask;
      if (kIsWeb) {
        final xfile = imageFile as XFile;
        final bytes = await xfile.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        final file = imageFile is XFile
            ? File(imageFile.path)
            : imageFile as File;
        uploadTask = ref.putFile(file);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to upload image',
      );
      return null;
    }
  }

  // Web-friendly: upload from bytes (Uint8List)
  static Future<String?> uploadImageBytes(
    String shipperUid,
    String imageType,
    Uint8List bytes, {
    String mimeType = 'image/jpeg',
  }) async {
    print('log this $bytes');
    // Guard against empty byte arrays to avoid cloud storage errors on web
    if (bytes.isEmpty) {
      // You can log here if you want
      return null;
    }
    try {
      final ref = _storage.ref().child(
        'shippers/$shipperUid/documents/$imageType.jpg',
      );
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: mimeType),
      );
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to upload image bytes',
      );
      return null;
    }
  }

  // Upload carrier profile image to Firebase Storage
  static Future<String?> uploadCarrierProfileImage(
    String carrierUid,
    dynamic imageFile, // Can be File or XFile
  ) async {
    try {
      final ref = _storage.ref().child(
        'carriers/$carrierUid/profile/profile_image.jpg',
      );

      UploadTask uploadTask;
      if (kIsWeb) {
        final xfile = imageFile as XFile;
        final bytes = await xfile.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        final file = imageFile is XFile
            ? File(imageFile.path)
            : imageFile as File;
        uploadTask = ref.putFile(file);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to upload carrier profile image',
      );
      return null;
    }
  }

  // Upload shipper profile image to Firebase Storage
  static Future<String?> uploadShipperProfileImage(
    String shipperUid,
    dynamic imageFile, // Can be File or XFile
  ) async {
    try {
      final ref = _storage.ref().child(
        'shippers/$shipperUid/profile/profile_image.jpg',
      );

      UploadTask uploadTask;
      if (kIsWeb) {
        final xfile = imageFile as XFile;
        final bytes = await xfile.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        final file = imageFile is XFile
            ? File(imageFile.path)
            : imageFile as File;
        uploadTask = ref.putFile(file);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to upload shipper profile image',
      );
      return null;
    }
  }

  // Save carrier dashboard response
  static Future<void> saveCarrierDashboardResponse(
    String carrierUid,
    String screenKey,
    Map<String, dynamic> response,
  ) async {
    try {
      await _firestore
          .collection('carriers')
          .doc(carrierUid)
          .collection('dashboard_responses')
          .doc(screenKey)
          .set(response, SetOptions(merge: true));
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to save carrier dashboard response',
      );
      rethrow;
    }
  }

  // Get carrier dashboard response
  static Future<Map<String, dynamic>?> getCarrierDashboardResponse(
    String carrierUid,
    String screenKey,
  ) async {
    try {
      final doc = await _firestore
          .collection('carriers')
          .doc(carrierUid)
          .collection('dashboard_responses')
          .doc(screenKey)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get carrier dashboard response',
      );
      return null;
    }
  }

  // Check if carrier has completed all dashboard steps
  static Future<bool> isCarrierDashboardComplete(String carrierUid) async {
    try {
      // Check if both dashboard steps are completed
      final dashboard2 = await getCarrierDashboardResponse(
        carrierUid,
        'dashboard_2_business_info',
      );
      final dashboard3 = await getCarrierDashboardResponse(
        carrierUid,
        'dashboard_3_business_number',
      );

      return dashboard2 != null && dashboard3 != null;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Check carrier dashboard complete failed',
      );
      return false;
    }
  }

  // Upload carrier document to Firebase Storage
  static Future<String?> uploadCarrierDocument(
    String carrierUid,
    String documentType,
    dynamic imageFile,
  ) async {
    try {
      final ref = _storage.ref().child(
        'carriers/$carrierUid/documents/$documentType.jpg',
      );

      // Use putData on all platforms to avoid file path length issues
      // that can cause "Message too long" errors
      Uint8List bytes;
      if (imageFile is XFile) {
        // XFile works on both web and mobile, use it directly
        bytes = await imageFile.readAsBytes();
      } else {
        // It's a File object (mobile only)
        bytes = await (imageFile as File).readAsBytes();
      }

      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to upload carrier document',
      );
      return null;
    }
  }

  // Update user password
  static Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        await logEvent(
          'password_update',
          parameters: _convertParameters({'success': 'true'}),
        );
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to update password',
      );
      await logEvent(
        'password_update',
        parameters: _convertParameters({
          'success': 'false',
          'error': e.toString(),
        }),
      );
      rethrow;
    }
  }

  // Reauthenticate user (required before password change)
  static Future<void> reauthenticateUser(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to reauthenticate user',
      );
      rethrow;
    }
  }

  // Phone verification methods
  /// Send OTP to phone number for verification
  /// Returns a Future that completes with the verificationId when code is sent
  static Future<String> sendPhoneOTP(
    String phoneNumber, {
    Function(PhoneAuthCredential)? onVerificationCompleted,
    Function(String)? onCodeSent,
  }) async {
    final completer = Completer<String>();

    try {
      // Log analytics event for sending OTP
      await logEvent(
        'phone_otp_send_attempt',
        parameters: _convertParameters({
          'phone_number_length': phoneNumber.length.toString(),
          'has_country_code': phoneNumber.startsWith('+').toString(),
          'platform': kIsWeb ? 'web' : 'mobile',
        }),
      );

      // For web, Firebase automatically shows reCAPTCHA when verifyPhoneNumber is called
      // The reCAPTCHA container in index.html allows for inline display if needed
      // We use the same verifyPhoneNumber call for all platforms - Firebase handles reCAPTCHA automatically on web
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          if (onVerificationCompleted != null) {
            onVerificationCompleted(credential);
          } else {
            final user = _auth.currentUser;
            if (user != null) {
              await user.updatePhoneNumber(credential);
              // Update Firestore
              final role = await getUserRole(user.uid);
              if (role == UserRole.shipper) {
                await updateShipper(user.uid, {
                  'isPhoneVerified': true,
                  'phoneNumber': phoneNumber,
                });
              } else if (role == UserRole.carrier) {
                await updateCarrier(user.uid, {
                  'isPhoneVerified': true,
                  'phoneNumber': phoneNumber,
                });
              }

              // Log successful auto-verification
              await logEvent(
                'phone_verification_auto_completed',
                parameters: _convertParameters({
                  'user_role': role.toString().split('.').last,
                }),
              );
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) async {
          // Log analytics for failed verification
          await logEvent(
            'phone_otp_send_failed',
            parameters: _convertParameters({
              'error_code': e.code,
              'error_message': e.message ?? 'Unknown error',
            }),
          );

          // Record error in Crashlytics
          await recordError(
            e,
            StackTrace.current,
            reason: 'Phone OTP send failed: ${e.code}',
          );

          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          // Log successful OTP send
          await logEvent(
            'phone_otp_sent',
            parameters: _convertParameters({
              'has_resend_token': (resendToken != null).toString(),
            }),
          );

          if (onCodeSent != null) {
            onCodeSent(verificationId);
          }
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout - code not received automatically
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        timeout: const Duration(seconds: 60),
      );

      return completer.future;
    } catch (e) {
      // Log analytics for exception
      await logEvent(
        'phone_otp_send_error',
        parameters: _convertParameters({'error': e.toString()}),
      );

      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to send phone OTP',
      );
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    }
  }

  /// Verify OTP code and update phone verification status
  static Future<void> verifyPhoneOTP({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
    required String userUid,
    required UserRole userRole,
  }) async {
    try {
      // Log analytics event for verification attempt
      await logEvent(
        'phone_otp_verify_attempt',
        parameters: _convertParameters({
          'user_role': userRole.toString().split('.').last,
          'otp_length': smsCode.length.toString(),
        }),
      );

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final user = _auth.currentUser;
      if (user != null) {
        // Link phone number to user account
        await user.updatePhoneNumber(credential);

        // Update Firestore with verified phone number
        final updateData = {
          'isPhoneVerified': true,
          'phoneNumber': phoneNumber,
        };

        if (userRole == UserRole.shipper) {
          await updateShipper(userUid, updateData);
        } else if (userRole == UserRole.carrier) {
          await updateCarrier(userUid, updateData);
        }

        // Log successful verification
        await logEvent(
          'phone_verification_success',
          parameters: _convertParameters({
            'user_role': userRole.toString().split('.').last,
            'phone_number_length': phoneNumber.length.toString(),
          }),
        );
      } else {
        throw Exception('User not authenticated');
      }
    } on FirebaseAuthException catch (e) {
      // Log analytics for Firebase auth errors
      await logEvent(
        'phone_otp_verify_failed',
        parameters: _convertParameters({
          'error_code': e.code,
          'error_message': e.message ?? 'Unknown error',
          'user_role': userRole.toString().split('.').last,
        }),
      );

      // Record error in Crashlytics
      await recordError(
        e,
        StackTrace.current,
        reason: 'Phone OTP verification failed: ${e.code}',
      );
      rethrow;
    } catch (e) {
      // Log analytics for general errors
      await logEvent(
        'phone_otp_verify_error',
        parameters: _convertParameters({
          'error': e.toString(),
          'user_role': userRole.toString().split('.').last,
        }),
      );

      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to verify phone OTP',
      );
      rethrow;
    }
  }

  // Upload load document to separate folder
  static Future<String?> uploadLoadDocument(
    String shipperUid,
    String loadId,
    dynamic document, // XFile or File
  ) async {
    try {
      // Get file name
      String fileName;
      if (document is XFile) {
        fileName = document.name;
      } else {
        fileName = (document as File).path.split('/').last;
      }

      final ref = _storage.ref().child(
        'shippers/$shipperUid/loads/$loadId/documents/$fileName',
      );

      if (kIsWeb) {
        final xfile = document as XFile;
        final bytes = await xfile.readAsBytes();
        final uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'application/octet-stream'), // Default
        );
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      } else {
        final file = document is XFile ? File(document.path) : document as File;
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to upload load document',
      );
      return null;
    }
  }

  // Save shipper load data
  static Future<void> saveShipperLoad(
    String shipperUid,
    Map<String, dynamic> loadData,
  ) async {
    try {
      final loadId = DateTime.now().millisecondsSinceEpoch.toString();
      loadData['id'] = loadId;
      await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .doc(loadId)
          .set(loadData);

      // Log load creation event
      await logEvent(
        'load_created',
        parameters: _convertParameters({
          'load_id': loadId,
          'load_type': loadData['loadType'] ?? 'unknown',
          'equipment_needed': loadData['equipmentNeeded'] ?? 'unknown',
          'success': 'true',
        }),
      );
    } catch (e) {
      // Log failed load creation
      await logEvent(
        'load_created',
        parameters: _convertParameters({
          'success': 'false',
          'error': e.toString(),
        }),
      );
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to save shipper load',
      );
      rethrow;
    }
  }

  // Update existing shipper load data
  static Future<void> updateShipperLoad(
    String shipperUid,
    String loadId,
    Map<String, dynamic> loadData,
  ) async {
    try {
      loadData['id'] = loadId;
      loadData['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .doc(loadId)
          .update(loadData);
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to update shipper load',
      );
      rethrow;
    }
  }

  // Save support ticket
  static Future<void> saveSupportTicket(
    String userId,
    Map<String, dynamic> supportData,
  ) async {
    try {
      final ticketId = DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore
          .collection('support_tickets')
          .doc(ticketId)
          .set(supportData);
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to save support ticket',
      );
      rethrow;
    }
  }

  // Save user preferences
  static Future<void> saveUserPreferences(
    String userId,
    Map<String, dynamic> preferencesData,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('user_preferences')
          .set(preferencesData, SetOptions(merge: true));
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to save user preferences',
      );
      rethrow;
    }
  }

  // Get user preferences
  static Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('user_preferences')
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get user preferences',
      );
      return null;
    }
  }

  // Save shipper preferences (stored in shipper document)
  static Future<void> saveShipperPreferences(
    String shipperUid,
    Map<String, dynamic> preferencesData,
  ) async {
    try {
      await _firestore.collection('shippers').doc(shipperUid).update({
        'preferences': preferencesData,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to save shipper preferences',
      );
      rethrow;
    }
  }

  // Get shipper preferences (from shipper document)
  static Future<Map<String, dynamic>?> getShipperPreferences(
    String shipperUid,
  ) async {
    try {
      final doc = await _firestore.collection('shippers').doc(shipperUid).get();

      if (doc.exists) {
        final data = doc.data();
        return data?['preferences'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get shipper preferences',
      );
      return null;
    }
  }

  // Get shipper loads with search, filter, and pagination
  static Future<Map<String, dynamic>> getShipperLoads({
    required String shipperUid,
    String searchQuery = '',
    String status = 'all',
    String loadType = 'all',
    String equipmentType = 'all',
    String originCity = 'all',
    String destinationCity = 'all',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads');

      // Apply status filter
      if (status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      // Apply load type filter
      if (loadType != 'all') {
        query = query.where('loadType', isEqualTo: loadType);
      }

      // Apply equipment type filter
      if (equipmentType != 'all') {
        query = query.where('equipmentNeeded', isEqualTo: equipmentType);
      }

      // Note: City filtering will be done client-side due to Firestore limitations
      // with compound queries and text search

      // Apply sorting
      query = query.orderBy(sortBy, descending: sortOrder == 'desc');

      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Apply limit
      query = query.limit(limit);

      final snapshot = await query.get();
      final loads = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Apply search and city filters client-side
      final filteredLoads = loads.where((load) {
        // Apply search filter
        bool matchesSearch = true;
        if (searchQuery.isNotEmpty) {
          final searchLower = searchQuery.toLowerCase();
          matchesSearch =
              (load['originAddress']?.toString().toLowerCase().contains(
                    searchLower,
                  ) ??
                  false) ||
              (load['destinationAddress']?.toString().toLowerCase().contains(
                    searchLower,
                  ) ??
                  false) ||
              (load['loadType']?.toString().toLowerCase().contains(
                    searchLower,
                  ) ??
                  false) ||
              (load['loadDescription']?.toString().toLowerCase().contains(
                    searchLower,
                  ) ??
                  false) ||
              (load['equipmentNeeded']?.toString().toLowerCase().contains(
                    searchLower,
                  ) ??
                  false);
        }

        // Apply origin city filter
        bool matchesOriginCity = true;
        if (originCity != 'all') {
          matchesOriginCity =
              load['originAddress']?.toString().contains(originCity) ?? false;
        }

        // Apply destination city filter
        bool matchesDestinationCity = true;
        if (destinationCity != 'all') {
          matchesDestinationCity =
              load['destinationAddress']?.toString().contains(
                destinationCity,
              ) ??
              false;
        }

        return matchesSearch && matchesOriginCity && matchesDestinationCity;
      }).toList();

      return {
        'loads': filteredLoads,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length == limit,
        'totalCount': filteredLoads.length,
      };
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get shipper loads',
      );
      return {
        'loads': <Map<String, dynamic>>[],
        'lastDocument': null,
        'hasMore': false,
        'totalCount': 0,
      };
    }
  }

  // Get load statistics for shipper
  static Future<Map<String, int>> getShipperLoadStats(String shipperUid) async {
    try {
      final snapshot = await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .get();

      final stats = <String, int>{
        'active': 0,
        'inTransit': 0,
        'booked': 0,
        'cancelled': 0,
        'completed': 0,
        'total': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString() ?? 'active';

        stats['total'] = (stats['total'] ?? 0) + 1;

        if (stats.containsKey(status)) {
          stats[status] = (stats[status] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get shipper load stats',
      );
      return {
        'active': 0,
        'inTransit': 0,
        'booked': 0,
        'cancelled': 0,
        'completed': 0,
        'total': 0,
      };
    }
  }

  // Update load status
  static Future<void> updateLoadStatus(
    String shipperUid,
    String loadId,
    String newStatus,
  ) async {
    try {
      await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .doc(loadId)
          .update({
            'status': newStatus,
            'updatedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to update load status',
      );
      rethrow;
    }
  }

  // Delete load and all associated documents
  static Future<void> deleteLoad(String shipperUid, String loadId) async {
    try {
      // First, get the load data to find document URLs
      final loadDoc = await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .doc(loadId)
          .get();

      if (loadDoc.exists) {
        final loadData = loadDoc.data();

        // Delete associated documents from Storage
        if (loadData != null) {
          // Delete additional document if it exists
          if (loadData['additionalDocument'] != null) {
            try {
              final documentUrl = loadData['additionalDocument'].toString();
              final ref = _storage.refFromURL(documentUrl);
              await ref.delete();
            } catch (e) {
              // Log error but don't fail the entire operation
              await recordError(
                e,
                StackTrace.current,
                reason: 'Failed to delete load document from storage',
              );
            }
          }
        }

        // Also try to delete the entire load documents folder
        try {
          final loadDocumentsRef = _storage.ref().child(
            'shippers/$shipperUid/loads/$loadId',
          );
          final listResult = await loadDocumentsRef.listAll();

          // Delete all files in the load documents folder
          for (final item in listResult.items) {
            try {
              await item.delete();
            } catch (e) {
              // Log individual file deletion errors but continue
              await recordError(
                e,
                StackTrace.current,
                reason: 'Failed to delete individual load document file',
              );
            }
          }
        } catch (e) {
          // Log folder deletion error but don't fail the entire operation
          await recordError(
            e,
            StackTrace.current,
            reason: 'Failed to delete load documents folder',
          );
        }
      }

      // Delete the Firestore document
      await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .doc(loadId)
          .delete();
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to delete load');
      rethrow;
    }
  }

  // Mark load as booked
  static Future<void> markLoadAsBooked(String shipperUid, String loadId) async {
    try {
      await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .doc(loadId)
          .update({
            'isBooked': true,
            'status': 'booked', // Update status to booked
            'bookedAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });

      // Log load booking event
      await logEvent(
        'load_booked',
        parameters: _convertParameters({'load_id': loadId, 'success': 'true'}),
      );
    } catch (e) {
      // Log failed load booking
      await logEvent(
        'load_booked',
        parameters: _convertParameters({
          'load_id': loadId,
          'success': 'false',
          'error': e.toString(),
        }),
      );
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to mark load as booked',
      );
      rethrow;
    }
  }

  // Unmark load as booked
  static Future<void> unmarkLoadAsBooked(
    String shipperUid,
    String loadId,
  ) async {
    try {
      await _firestore
          .collection('shippers')
          .doc(shipperUid)
          .collection('loads')
          .doc(loadId)
          .update({
            'isBooked': false,
            'status': 'active', // Restore status to active
            'bookedAt': null,
            'updatedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to unmark load as booked',
      );
      rethrow;
    }
  }

  // Product listing methods
  static Future<String> createProductListing(ProductListing listing) async {
    try {
      final docRef = await listings.add(listing.toFirestore());

      // Log listing creation event
      await logEvent(
        'listing_created',
        parameters: _convertParameters({
          'listing_id': docRef.id,
          'shipper_uid': listing.shipperUid,
          'condition': listing.condition,
          'price': listing.price,
          'success': 'true',
        }),
      );

      return docRef.id;
    } catch (e) {
      // Log failed listing creation
      await logEvent(
        'listing_created',
        parameters: _convertParameters({
          'success': 'false',
          'error': e.toString(),
        }),
      );
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to create product listing',
      );
      rethrow;
    }
  }

  static Future<void> updateProductListing(
    String listingId,
    ProductListing listing,
  ) async {
    try {
      await listings.doc(listingId).update(listing.toFirestore());

      // Log listing update event
      await logEvent(
        'listing_updated',
        parameters: _convertParameters({
          'listing_id': listingId,
          'shipper_uid': listing.shipperUid,
          'success': 'true',
        }),
      );
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to update product listing',
      );
      rethrow;
    }
  }

  static Future<void> deleteProductListing(String listingId) async {
    try {
      // First, get the listing to find image and video URLs
      final listingDoc = await listings.doc(listingId).get();

      if (listingDoc.exists) {
        final listingData = listingDoc.data() as Map<String, dynamic>?;

        if (listingData != null) {
          // Delete images from Storage
          if (listingData['imageUrls'] != null) {
            final imageUrls = List<String>.from(listingData['imageUrls'] ?? []);
            for (final imageUrl in imageUrls) {
              try {
                final ref = _storage.refFromURL(imageUrl);
                await ref.delete();
              } catch (e) {
                // Log error but don't fail the entire operation
                await recordError(
                  e,
                  StackTrace.current,
                  reason: 'Failed to delete listing image from storage',
                );
              }
            }
          }

          // Delete video from Storage
          if (listingData['videoUrl'] != null &&
              listingData['videoUrl'].toString().isNotEmpty) {
            try {
              final videoUrl = listingData['videoUrl'].toString();
              final ref = _storage.refFromURL(videoUrl);
              await ref.delete();
            } catch (e) {
              // Log error but don't fail the entire operation
              await recordError(
                e,
                StackTrace.current,
                reason: 'Failed to delete listing video from storage',
              );
            }
          }

          // Try to delete the entire listing folder from Storage
          final listingSnapshot = await listings.doc(listingId).get();
          if (listingSnapshot.exists) {
            final listing = ProductListing.fromFirestore(listingSnapshot);
            try {
              final listingImagesRef = _storage.ref().child(
                'shippers/${listing.shipperUid}/listings/$listingId/images',
              );
              final listResult = await listingImagesRef.listAll();

              // Delete all images in the folder
              for (final item in listResult.items) {
                try {
                  await item.delete();
                } catch (e) {
                  await recordError(
                    e,
                    StackTrace.current,
                    reason: 'Failed to delete individual listing image',
                  );
                }
              }

              // Delete video folder
              try {
                final listingVideoRef = _storage.ref().child(
                  'shippers/${listing.shipperUid}/listings/$listingId/video',
                );
                final videoListResult = await listingVideoRef.listAll();

                for (final item in videoListResult.items) {
                  try {
                    await item.delete();
                  } catch (e) {
                    await recordError(
                      e,
                      StackTrace.current,
                      reason: 'Failed to delete listing video',
                    );
                  }
                }
              } catch (e) {
                // Video folder might not exist, that's okay
              }
            } catch (e) {
              // Folder might not exist, that's okay
              await recordError(
                e,
                StackTrace.current,
                reason: 'Failed to delete listing folder from storage',
              );
            }
          }
        }
      }

      // Delete the Firestore document
      await listings.doc(listingId).delete();

      // Log listing deletion event
      await logEvent(
        'listing_deleted',
        parameters: _convertParameters({
          'listing_id': listingId,
          'success': 'true',
        }),
      );
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to delete product listing',
      );
      rethrow;
    }
  }

  static Future<ProductListing?> getProductListing(String listingId) async {
    try {
      final doc = await listings.doc(listingId).get();
      if (doc.exists) {
        return ProductListing.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get product listing',
      );
      rethrow;
    }
  }

  static Future<List<ProductListing>> getProductListings({
    String? shipperUid,
    String? condition,
    String? location,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      Query query = listings.where('isActive', isEqualTo: true);

      if (shipperUid != null) {
        query = query.where('shipperUid', isEqualTo: shipperUid);
      }

      if (condition != null) {
        query = query.where('condition', isEqualTo: condition);
      }

      if (location != null) {
        query = query.where('location', isEqualTo: location);
      }

      query = query.orderBy('createdAt', descending: true);

      // For pagination, we need to use startAfter with the last document
      // For now, we'll use a simple approach with limit and offset
      if (offset > 0) {
        // Get documents to skip
        final skipQuery = query.limit(offset);
        final skipSnapshot = await skipQuery.get();

        if (skipSnapshot.docs.isNotEmpty) {
          query = query.startAfterDocument(skipSnapshot.docs.last);
        }
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ProductListing.fromFirestore(doc))
          .toList();
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get product listings',
      );
      rethrow;
    }
  }

  // Upload product images
  static Future<List<String>> uploadProductImages(
    String shipperUid,
    String listingId,
    List<dynamic> images, // Can be List<File> or List<XFile>
  ) async {
    try {
      final List<String> imageUrls = [];

      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        final fileName =
            'image_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = _storage.ref().child(
          'shippers/$shipperUid/listings/$listingId/images/$fileName',
        );

        if (kIsWeb) {
          final xfile = image as XFile;
          final bytes = await xfile.readAsBytes();
          final uploadTask = ref.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          final snapshot = await uploadTask;
          imageUrls.add(await snapshot.ref.getDownloadURL());
        } else {
          final file = image is XFile ? File(image.path) : image as File;
          final uploadTask = ref.putFile(file);
          final snapshot = await uploadTask;
          imageUrls.add(await snapshot.ref.getDownloadURL());
        }
      }

      return imageUrls;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to upload product images',
      );
      rethrow;
    }
  }

  // Upload product video
  static Future<String?> uploadProductVideo(
    String shipperUid,
    String listingId,
    dynamic video, // Can be File or XFile
  ) async {
    try {
      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final ref = _storage.ref().child(
        'shippers/$shipperUid/listings/$listingId/video/$fileName',
      );

      if (kIsWeb) {
        final xfile = video as XFile;
        final bytes = await xfile.readAsBytes();
        final uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'video/mp4'),
        );
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      } else {
        final file = video is XFile ? File(video.path) : video as File;
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to upload product video',
      );
      return null;
    }
  }

  // Save a listing for a user
  static Future<void> saveListing(String userId, ProductListing listing) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedListings')
          .doc(listing.id)
          .set(listing.toFirestore());
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to save listing',
      );
      rethrow;
    }
  }

  // Remove a saved listing for a user
  static Future<void> removeSavedListing(
    String userId,
    String listingId,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedListings')
          .doc(listingId)
          .delete();
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to remove saved listing',
      );
      rethrow;
    }
  }

  // Check if a listing is saved by a user
  static Future<bool> isListingSaved(String userId, String listingId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedListings')
          .doc(listingId)
          .get();
      return doc.exists;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to check saved status',
      );
      rethrow;
    }
  }

  // Get all saved listings for a user
  static Future<List<ProductListing>> getSavedListings(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedListings')
          .get();
      return snapshot.docs
          .map((doc) => ProductListing.fromFirestore(doc))
          .toList();
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get saved listings',
      );
      rethrow;
    }
  }

  // Chat functionality
  static Future<String> createOrGetConversation({
    required String senderId,
    required String receiverId,
    String? listingId,
    String? listingTitle,
    String? listingImageUrl,
  }) async {
    try {
      print('Creating/getting conversation between $senderId and $receiverId');

      // Check if conversation already exists
      final existingConversation = await conversations
          .where('participants', arrayContains: senderId)
          .get();

      print(
        'Found ${existingConversation.docs.length} existing conversations for sender',
      );

      for (final doc in existingConversation.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        print(
          'Checking conversation ${doc.id} with participants: $participants',
        );
        if (participants.contains(receiverId)) {
          print('Found existing conversation: ${doc.id}');
          return doc.id;
        }
      }

      // Create new conversation
      final conversationId = conversations.doc().id;
      print('Creating new conversation: $conversationId');

      final conversation = ChatConversation(
        id: conversationId,
        participants: [senderId, receiverId],
        listingId: listingId,
        listingTitle: listingTitle,
        listingImageUrl: listingImageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('Conversation data: ${conversation.toFirestore()}');
      await conversations.doc(conversationId).set(conversation.toFirestore());
      print('Conversation created successfully');
      return conversationId;
    } catch (e) {
      print('Error creating conversation: $e');
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to create conversation',
      );
      rethrow;
    }
  }

  static Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    String? listingId,
  }) async {
    try {
      print('Sending message to conversation: $conversationId');
      print('Sender: $senderId, Receiver: $receiverId');
      print('Content: $content');

      final messageId = messages.doc().id;
      final message = ChatMessage(
        id: messageId,
        conversationId: conversationId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        listingId: listingId,
      );

      print('Message data: ${message.toFirestore()}');

      // Add message to messages collection
      await messages.doc(messageId).set(message.toFirestore());
      print('Message saved to messages collection');

      // Update conversation with last message
      final updateData = <String, dynamic>{
        'lastMessage': message.toFirestore(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      // Only update unreadCount if receiverId is valid (not empty)
      if (receiverId.isNotEmpty) {
        updateData['unreadCount.$receiverId'] = true;
      }

      await conversations.doc(conversationId).update(updateData);
      print('Conversation updated with last message');

      // Send notification for support messages
      final convDoc = await conversations.doc(conversationId).get();
      if (convDoc.exists) {
        final convData = convDoc.data() as Map<String, dynamic>;
        final isSupportConversation = convData['isSupport'] == true;
        if (isSupportConversation) {
          // Send notification for support messages
          await NotificationService.createNotification(
            userId: receiverId,
            type: NotificationType.message,
            title: "New Support Message",
            body: content.length > 50
                ? '${content.substring(0, 50)}...'
                : content,
            data: {'conversationId': conversationId, 'senderId': senderId},
            relatedId: conversationId,
          );
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to send message',
      );
      rethrow;
    }
  }

  static Future<void> deleteMessageForUser(
    String messageId,
    String userId,
  ) async {
    try {
      await messages.doc(messageId).update({
        'deletedBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to delete message for user',
      );
      rethrow;
    }
  }

  static Future<void> clearConversationForUser(
    String conversationId,
    String userId,
  ) async {
    try {
      await conversations.doc(conversationId).update({
        'clearedAt.$userId': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to clear conversation for user',
      );
      rethrow;
    }
  }

  // Support Chat functionality
  static const String supportUserId =
      'support_system'; // System support user ID

  /// Create or get support conversation for a user
  static Future<String> createOrGetSupportConversation(String userId) async {
    try {
      print('Creating/getting support conversation for user: $userId');

      // Check if support conversation already exists
      final existingConversation = await conversations
          .where('participants', arrayContains: userId)
          .where('isSupport', isEqualTo: true)
          .get();

      if (existingConversation.docs.isNotEmpty) {
        print(
          'Found existing support conversation: ${existingConversation.docs.first.id}',
        );
        return existingConversation.docs.first.id;
      }

      // Create new support conversation
      final conversationId = conversations.doc().id;
      print('Creating new support conversation: $conversationId');

      final conversation = ChatConversation(
        id: conversationId,
        participants: [userId, supportUserId],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSupport: true, // Mark as support conversation
      );

      final conversationData = conversation.toFirestore();
      conversationData['supportTitle'] = 'Support Chat';

      await conversations.doc(conversationId).set(conversationData);
      print('Support conversation created successfully');
      return conversationId;
    } catch (e) {
      print('Error creating support conversation: $e');
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to create support conversation',
      );
      rethrow;
    }
  }

  /// Send support message
  static Future<void> sendSupportMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    try {
      // Determine receiver (if sender is user, receiver is support, and vice versa)
      final convDoc = await conversations.doc(conversationId).get();
      if (!convDoc.exists) {
        throw Exception('Support conversation not found');
      }

      final convData = convDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(convData['participants'] ?? []);
      final receiverId = participants.firstWhere(
        (id) => id != senderId,
        orElse: () => supportUserId,
      );

      await sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
      );
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to send support message',
      );
      rethrow;
    }
  }

  /// Get support conversation for a user
  static Future<ChatConversation?> getSupportConversation(String userId) async {
    try {
      final snapshot = await conversations
          .where('participants', arrayContains: userId)
          .where('isSupport', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return ChatConversation.fromFirestore(snapshot.docs.first);
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get support conversation',
      );
      return null;
    }
  }

  static Future<List<ChatConversation>> getUserConversations(
    String userId,
  ) async {
    try {
      print('Getting conversations for user: $userId');
      final snapshot = await conversations
          .where('participants', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      print('Found ${snapshot.docs.length} conversation documents');

      final conversationList = snapshot.docs.map((doc) {
        print('Processing conversation doc: ${doc.id}');
        print('Doc data: ${doc.data()}');
        return ChatConversation.fromFirestore(doc);
      }).toList();

      print('Created ${conversationList.length} conversation objects');
      return conversationList;
    } catch (e) {
      print('Error getting conversations: $e');
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get conversations',
      );
      rethrow;
    }
  }

  static Stream<List<ChatConversation>> getUserConversationsStream(
    String userId,
  ) {
    print('Getting conversations stream for user: $userId');
    return conversations
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print(
            'Conversation snapshot received: ${snapshot.docs.length} conversations',
          );
          final conversationList = snapshot.docs.map((doc) {
            print('Processing conversation doc: ${doc.id}');
            return ChatConversation.fromFirestore(doc);
          }).toList();

          print('Created ${conversationList.length} conversation objects');
          return conversationList;
        });
  }

  static Stream<List<ChatMessage>> getConversationMessages(
    String conversationId,
  ) {
    print('Getting messages for conversation: $conversationId');
    return messages
        .where('conversationId', isEqualTo: conversationId)
        .snapshots()
        .map((snapshot) {
          print('Message snapshot received: ${snapshot.docs.length} messages');
          final messageList = snapshot.docs.map((doc) {
            print('Processing message doc: ${doc.id}');
            return ChatMessage.fromFirestore(doc);
          }).toList();

          // Sort messages by timestamp in ascending order (oldest first)
          messageList.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          print('Created ${messageList.length} message objects');
          return messageList;
        });
  }

  static Future<List<ChatMessage>> getConversationMessagesOnce(
    String conversationId,
  ) async {
    try {
      print('Getting messages once for conversation: $conversationId');
      final snapshot = await messages
          .where('conversationId', isEqualTo: conversationId)
          .get();

      print('Found ${snapshot.docs.length} messages in one-time query');
      final messageList = snapshot.docs.map((doc) {
        print('Processing message doc: ${doc.id}');
        return ChatMessage.fromFirestore(doc);
      }).toList();

      // Sort messages by timestamp in ascending order (oldest first)
      messageList.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      print('Created ${messageList.length} message objects');
      return messageList;
    } catch (e) {
      print('Error getting messages once: $e');
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get messages once',
      );
      rethrow;
    }
  }

  static Future<void> markMessagesAsRead(
    String conversationId,
    String userId,
  ) async {
    try {
      // Mark all unread messages as read
      final unreadMessages = await messages
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Update conversation unread count
      await conversations.doc(conversationId).update({
        'unreadCount.$userId': false,
      });
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to mark messages as read',
      );
      rethrow;
    }
  }

  // ==================== Offer and Negotiation Functions ====================

  /// Create or get conversation for load negotiation
  static Future<String> createLoadConversation({
    required String loadId,
    required String carrierUid,
    required String shipperUid,
  }) async {
    try {
      // Validate inputs
      if (carrierUid.isEmpty) {
        throw Exception('carrierUid cannot be empty');
      }
      if (shipperUid.isEmpty) {
        throw Exception('shipperUid cannot be empty');
      }
      if (loadId.isEmpty) {
        throw Exception('loadId cannot be empty');
      }

      print(
        'createLoadConversation: loadId=$loadId, carrierUid=$carrierUid, shipperUid=$shipperUid',
      );

      // Check if conversation already exists for this load-carrier pair
      final existingConversations = await conversations
          .where('loadId', isEqualTo: loadId)
          .where('participants', arrayContains: carrierUid)
          .get();

      for (final doc in existingConversations.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        print(
          'Checking existing conversation ${doc.id}: participants=$participants',
        );
        if (participants.contains(shipperUid)) {
          print('Found existing load conversation: ${doc.id}');
          return doc.id;
        }
      }

      // Create new conversation for load negotiation
      final conversationId = conversations.doc().id;
      final participantsList = [carrierUid, shipperUid];
      print('Creating new conversation with participants: $participantsList');

      final conversation = ChatConversation(
        id: conversationId,
        participants: participantsList,
        loadId: loadId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final firestoreData = conversation.toFirestore();
      print('Conversation firestore data: $firestoreData');
      print('Participants in firestore data: ${firestoreData['participants']}');

      await conversations.doc(conversationId).set(firestoreData);

      // Verify the conversation was saved correctly
      final savedDoc = await conversations.doc(conversationId).get();
      if (savedDoc.exists) {
        final savedData = savedDoc.data() as Map<String, dynamic>;
        final savedParticipants = List<String>.from(
          savedData['participants'] ?? [],
        );
        print('Verified saved conversation participants: $savedParticipants');
        if (savedParticipants.length != 2) {
          print(
            'WARNING: Conversation saved with ${savedParticipants.length} participants instead of 2!',
          );
        }
      }

      print('Created new load conversation: $conversationId');
      return conversationId;
    } catch (e) {
      print('Error in createLoadConversation: $e');
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to create load conversation',
      );
      rethrow;
    }
  }

  /// Get conversation by loadId and carrierId
  static Future<String?> getConversationByLoadId({
    required String loadId,
    required String carrierId,
  }) async {
    try {
      final snapshot = await conversations
          .where('loadId', isEqualTo: loadId)
          .where('participants', arrayContains: carrierId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.id;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get conversation by loadId',
      );
      return null;
    }
  }

  /// Send initial offer (starts 30-minute timer)
  static Future<String> sendOffer({
    required String conversationId,
    required String carrierId,
    required String carrierName,
    required String shipperId,
    required String loadId,
    required double offerAmount,
  }) async {
    try {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 12));

      // Create offer document
      final offerId = offers.doc().id;
      final offer = OfferModel(
        id: offerId,
        loadId: loadId,
        conversationId: conversationId,
        carrierId: carrierId,
        carrierName: carrierName,
        shipperId: shipperId,
        offerAmount: offerAmount,
        status: OfferStatus.pending,
        negotiationStartTime: now,
        expiresAt: expiresAt,
        createdAt: now,
        updatedAt: now,
      );

      await offers.doc(offerId).set(offer.toFirestore());

      // Update conversation with negotiation info
      await conversations.doc(conversationId).update({
        'negotiationStartTime': Timestamp.fromDate(now),
        'negotiationExpiresAt': Timestamp.fromDate(expiresAt),
        'isNegotiationActive': true,
        'activeOfferId': offerId,
        'updatedAt': Timestamp.fromDate(now),
      });

      // Send offer message
      final messageId = messages.doc().id;
      final message = ChatMessage(
        id: messageId,
        conversationId: conversationId,
        senderId: carrierId,
        receiverId: shipperId,
        content: 'Offered \$${offerAmount.toStringAsFixed(2)}',
        timestamp: now,
        type: MessageType.offer,
        offerId: offerId,
      );

      await messages.doc(messageId).set(message.toFirestore());

      // Update conversation last message
      await conversations.doc(conversationId).update({
        'lastMessage': message.toFirestore(),
        'updatedAt': Timestamp.fromDate(now),
      });

      print('Offer sent successfully: $offerId');
      return offerId;
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to send offer');
      rethrow;
    }
  }

  /// Shipper sends counter-offer
  static Future<void> sendCounterOffer({
    required String offerId,
    required double counterAmount,
  }) async {
    try {
      final offerDoc = await offers.doc(offerId).get();
      if (!offerDoc.exists) {
        throw Exception('Offer not found');
      }

      final offerData = offerDoc.data() as Map<String, dynamic>;
      final originalAmount = (offerData['offerAmount'] as num).toDouble();
      final conversationId = offerData['conversationId'] as String;
      final carrierId = offerData['carrierId'] as String;
      final shipperId = offerData['shipperId'] as String;

      // Update offer with counter-offer
      await offers.doc(offerId).update({
        'status': OfferStatus.counterOffered.toString().split('.').last,
        'counterOfferAmount': counterAmount,
        'originalOfferAmount': originalAmount,
        'updatedAt': Timestamp.now(),
      });

      // Send counter-offer message
      final now = DateTime.now();
      final messageId = messages.doc().id;
      final message = ChatMessage(
        id: messageId,
        conversationId: conversationId,
        senderId: shipperId,
        receiverId: carrierId,
        content: 'Counter-offered \$${counterAmount.toStringAsFixed(2)}',
        timestamp: now,
        type: MessageType.offer,
        offerId: offerId,
      );

      await messages.doc(messageId).set(message.toFirestore());

      // Update conversation
      await conversations.doc(conversationId).update({
        'lastMessage': message.toFirestore(),
        'updatedAt': Timestamp.fromDate(now),
      });

      print('Counter-offer sent successfully for offer: $offerId');
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to send counter-offer',
      );
      rethrow;
    }
  }

  /// Accept offer (updates load status, closes other negotiations)
  static Future<bool> acceptOffer({
    required String offerId,
    required String loadId,
  }) async {
    try {
      // Get offer data first to extract carrierId and shipperId
      final offerDoc = await offers.doc(offerId).get();
      if (!offerDoc.exists) {
        throw Exception('Offer not found');
      }
      final offerData = offerDoc.data() as Map<String, dynamic>;
      final carrierId = offerData['carrierId'] as String;
      final shipperId = offerData['shipperId'] as String;

      return await _firestore
          .runTransaction<bool>((transaction) async {
            // Get offer
            final offerRef = offers.doc(offerId);
            final offerDoc = await transaction.get(offerRef);

            if (!offerDoc.exists) {
              throw Exception('Offer not found');
            }

            final offerData = offerDoc.data() as Map<String, dynamic>;
            final status = offerData['status'] as String;

            if (status.contains('accepted') || status.contains('rejected')) {
              throw Exception('Offer already processed');
            }

            final carrierName = offerData['carrierName'] as String;
            final conversationId = offerData['conversationId'] as String;
            final acceptedAmount =
                offerData['counterOfferAmount'] as double? ??
                (offerData['offerAmount'] as num).toDouble();

            // Find the load in shipper subcollection (using shipperId from offer)
            final loadRef = _firestore
                .collection('shippers')
                .doc(shipperId)
                .collection('loads')
                .doc(loadId);

            // Check if load exists and is still available
            final loadDoc = await transaction.get(loadRef);
            if (!loadDoc.exists) {
              throw Exception('Load not found');
            }

            final loadData = loadDoc.data() as Map<String, dynamic>;
            if (loadData['status'] != 'active' &&
                loadData['status'] != 'available') {
              throw Exception('Load is no longer available');
            }

            final now = DateTime.now();

            // Update offer status
            transaction.update(offerRef, {
              'status': OfferStatus.accepted.toString().split('.').last,
              'acceptedAt': Timestamp.fromDate(now),
              'updatedAt': Timestamp.fromDate(now),
            });

            // Update load - book it
            transaction.update(loadRef, {
              'status': 'booked',
              'bookedByCarrierId': carrierId,
              'bookedAt': Timestamp.fromDate(now),
              'updatedAt': Timestamp.fromDate(now),
              'price': acceptedAmount, // Update price to accepted offer amount
            });

            // Note: Closing other negotiations is handled outside transaction for efficiency
            // We'll update them after transaction completes

            // Update accepted conversation
            final convRef = conversations.doc(conversationId);
            transaction.update(convRef, {
              'isNegotiationActive': false,
              'updatedAt': Timestamp.fromDate(now),
            });

            // Send acceptance message
            final messageId = messages.doc().id;
            final message = ChatMessage(
              id: messageId,
              conversationId: conversationId,
              senderId: shipperId,
              receiverId: carrierId,
              content: 'Offer accepted: \$${acceptedAmount.toStringAsFixed(2)}',
              timestamp: now,
              type: MessageType.offer,
              offerId: offerId,
            );

            transaction.set(messages.doc(messageId), message.toFirestore());
            transaction.update(convRef, {'lastMessage': message.toFirestore()});

            // Create booking record
            final bookingRef = bookings.doc();
            transaction.set(bookingRef, {
              'loadId': loadId,
              'carrierId': carrierId,
              'carrierName': carrierName,
              'shipperId': shipperId,
              'status': 'booked',
              'bookedAt': Timestamp.fromDate(now),
              'createdAt': Timestamp.fromDate(now),
              'updatedAt': Timestamp.fromDate(now),
            });

            // Add to carrier's myBookings
            final carrierBookingRef = carriers
                .doc(carrierId)
                .collection('myBookings')
                .doc(loadId);
            transaction.set(carrierBookingRef, {
              'loadId': loadId,
              'status': 'booked',
              'bookedAt': Timestamp.fromDate(now),
              'createdAt': Timestamp.fromDate(now),
            });

            return true;
          })
          .then((success) async {
            if (success) {
              // Close all other active negotiations for this load after transaction
              await closeNegotiationsForLoad(loadId, carrierId);

              // Send notifications to both shipper and carrier
              try {
                await NotificationService.createNotification(
                  userId: shipperId,
                  type: NotificationType.orderStatus,
                  title: "Order Booked",
                  body:
                      "A carrier has accepted your order! Please deposit payment to escrow to proceed.",
                  data: {
                    'loadId': loadId,
                    'oldStatus': 'available',
                    'newStatus': 'booked',
                    'requiresEscrowPayment': true,
                  },
                  relatedId: loadId,
                );

                await NotificationService.createNotification(
                  userId: carrierId,
                  type: NotificationType.orderStatus,
                  title: "Load Booked Successfully",
                  body: "You have successfully booked this load!",
                  data: {
                    'loadId': loadId,
                    'oldStatus': 'available',
                    'newStatus': 'booked',
                  },
                  relatedId: loadId,
                );
              } catch (e) {
                debugPrint('Error sending booking notifications: $e');
                // Don't fail the booking if notification fails
              }
            }
            return success;
          });
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to accept offer',
      );
      return false;
    }
  }

  /// Reject offer
  static Future<void> rejectOffer(String offerId) async {
    try {
      final offerDoc = await offers.doc(offerId).get();
      if (!offerDoc.exists) {
        throw Exception('Offer not found');
      }

      await offers.doc(offerId).update({
        'status': OfferStatus.rejected.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });

      print('Offer rejected: $offerId');
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to reject offer',
      );
      rethrow;
    }
  }

  /// Get all active offers for a load
  static Future<List<OfferModel>> getActiveOffersForLoad(String loadId) async {
    try {
      final snapshot = await offers
          .where('loadId', isEqualTo: loadId)
          .where(
            'status',
            whereIn: [
              OfferStatus.pending.toString().split('.').last,
              OfferStatus.counterOffered.toString().split('.').last,
            ],
          )
          .get();

      return snapshot.docs.map((doc) => OfferModel.fromFirestore(doc)).toList();
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get active offers',
      );
      return [];
    }
  }

  /// Get offer by ID
  static Future<OfferModel?> getOfferById(String offerId) async {
    try {
      final doc = await offers.doc(offerId).get();
      if (!doc.exists) return null;
      return OfferModel.fromFirestore(doc);
    } catch (e) {
      await recordError(e, StackTrace.current, reason: 'Failed to get offer');
      return null;
    }
  }

  /// Check if negotiation timer has expired
  static Future<bool> checkNegotiationTimer(String conversationId) async {
    try {
      final convDoc = await conversations.doc(conversationId).get();
      if (!convDoc.exists) return true;

      final data = convDoc.data() as Map<String, dynamic>;
      final expiresAt = data['negotiationExpiresAt'] as Timestamp?;

      if (expiresAt == null) return false;
      return DateTime.now().isAfter(expiresAt.toDate());
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to check negotiation timer',
      );
      return true;
    }
  }

  /// Close all other negotiations when an offer is accepted (called internally)
  static Future<void> closeNegotiationsForLoad(
    String loadId,
    String acceptedCarrierId,
  ) async {
    try {
      // This is handled in acceptOffer transaction, but kept for explicit calls if needed
      final activeOffers = await getActiveOffersForLoad(loadId);

      for (final offer in activeOffers) {
        if (offer.carrierId != acceptedCarrierId) {
          await offers.doc(offer.id).update({
            'status': OfferStatus.rejected.toString().split('.').last,
            'updatedAt': Timestamp.now(),
          });

          await conversations.doc(offer.conversationId).update({
            'isNegotiationActive': false,
            'updatedAt': Timestamp.now(),
          });
        }
      }
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to close negotiations',
      );
    }
  }

  // Get a single product listing by ID
  static Future<ProductListing?> getProductListingById(String listingId) async {
    try {
      print('Getting product listing by ID: $listingId');
      final doc = await listings.doc(listingId).get();

      if (doc.exists && doc.data() != null) {
        final listing = ProductListing.fromFirestore(doc);
        print('Found listing: ${listing.title}');
        return listing;
      } else {
        print('Listing not found with ID: $listingId');
        return null;
      }
    } catch (e) {
      print('Error getting product listing by ID: $e');
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get product listing by ID',
      );
      return null;
    }
  }

  // Get shipper details by UID
  static Future<Map<String, dynamic>?> getShipperDetails(
    String shipperUid,
  ) async {
    try {
      print('Getting shipper details for UID: $shipperUid');
      final doc = await _firestore.collection('shippers').doc(shipperUid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        print('Found shipper: ${data['name'] ?? 'Unknown'}');
        return data;
      } else {
        print('Shipper not found with UID: $shipperUid');
        return null;
      }
    } catch (e) {
      print('Error getting shipper details: $e');
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get shipper details',
      );
      return null;
    }
  }

  // ========== LOAD MANAGEMENT METHODS ==========

  /// Calculate match percentage between load and carrier preferences
  ///
  /// MATCHING SCORING SYSTEM (Total: 100 points):
  /// - Equipment/Vehicle Type Match: 35 points (35%)
  /// - Location/Service Area Match: 30 points (30%)
  /// - Weight Capacity Match: 20 points (20%)
  /// - Distance Preference Match: 10 points (10%)
  /// - Preferred Load Type Match: 5 points (5%)
  ///
  /// To adjust weights, modify the point values below and ensure they sum to 100.
  ///
  /// [carrierLocation] - Optional carrier's current location address for distance calculation
  /// [apiKey] - Google API key for distance calculations
  static Future<double> calculateLoadMatchPercentage(
    LoadModel load,
    CarrierModel carrier, {
    String? carrierLocation,
    String? apiKey,
  }) async {
    double totalScore = 0.0;
    const double maxScore = 100.0;

    // ============================================================================
    // 1. EQUIPMENT/VEHICLE TYPE MATCH (35 points) - MADE MORE LENIENT
    // ============================================================================
    // Matches carrier's vehicle types against load's equipment needed
    // Example: "Dry Van" matches "Dry Van", "Refrigerated" matches "Reefer"
    // Made more lenient - partial matches also get points
    //
    // TO ADJUST: Change the 35.0 value below (currently 35% of total score)
    if (carrier.vehicleTypes != null &&
        carrier.vehicleTypes!.isNotEmpty &&
        load.equipmentNeeded.isNotEmpty) {
      final equipmentLower = load.equipmentNeeded.toLowerCase();
      bool exactMatch = false;
      bool partialMatch = false;

      for (final vehicleType in carrier.vehicleTypes!) {
        final vehicleTypeLower = vehicleType.toLowerCase();

        // Check for exact or partial match
        if (equipmentLower == vehicleTypeLower ||
            equipmentLower.contains(vehicleTypeLower) ||
            vehicleTypeLower.contains(equipmentLower)) {
          exactMatch = true;
          break;
        }

        // Check for partial word matches (e.g., "Dry Van" matches "Van")
        final equipmentWords = equipmentLower.split(RegExp(r'[\s\-_]+'));
        final vehicleWords = vehicleTypeLower.split(RegExp(r'[\s\-_]+'));

        for (final equipmentWord in equipmentWords) {
          for (final vehicleWord in vehicleWords) {
            if (equipmentWord.length >= 3 &&
                vehicleWord.length >= 3 &&
                (equipmentWord.contains(vehicleWord) ||
                    vehicleWord.contains(equipmentWord))) {
              partialMatch = true;
              break;
            }
          }
          if (partialMatch) break;
        }
      }

      if (exactMatch) {
        totalScore += 35.0; // Full points for exact match
      } else if (partialMatch) {
        totalScore += 20.0; // Partial points for partial match
      }
    } else if (load.equipmentNeeded.isEmpty) {
      // If equipment is not specified, don't penalize - give some points
      totalScore += 10.0;
    }

    // ============================================================================
    // 2. LOCATION/SERVICE AREA MATCH (30 points) - SIMPLIFIED
    // ============================================================================
    // Matches carrier's service areas against load's origin and destination
    // Uses simple string contains matching - no complex parsing
    //
    // Scoring:
    // - Origin OR destination matches any service area: 30 points (full score)
    // - Partial match (service area appears in address): 15 points (half score)
    //
    // TO ADJUST: Change the 30.0 and 15.0 values below
    if (carrier.serviceAreas != null && carrier.serviceAreas!.isNotEmpty) {
      final originLower = load.originAddress.toLowerCase();
      final destinationLower = load.destinationAddress.toLowerCase();

      // Check if any service area matches origin or destination
      bool originMatch = false;
      bool destinationMatch = false;
      bool partialOriginMatch = false;
      bool partialDestinationMatch = false;

      for (final area in carrier.serviceAreas!) {
        final areaLower = area.toLowerCase();

        // Check for exact or partial match in origin
        if (originLower.contains(areaLower) ||
            areaLower.contains(originLower)) {
          // Check if it's a full match (service area format: "City, Province")
          if (areaLower.contains(',') &&
              originLower.contains(areaLower.split(',')[0].trim())) {
            originMatch = true;
          } else {
            partialOriginMatch = true;
          }
        }

        // Check for exact or partial match in destination
        if (destinationLower.contains(areaLower) ||
            areaLower.contains(destinationLower)) {
          // Check if it's a full match
          if (areaLower.contains(',') &&
              destinationLower.contains(areaLower.split(',')[0].trim())) {
            destinationMatch = true;
          } else {
            partialDestinationMatch = true;
          }
        }
      }

      // Award points - make it easier to get matches
      // Give points for ANY match, even partial
      if (originMatch || destinationMatch) {
        totalScore +=
            30.0; // Full points if either origin or destination matches
      } else if (partialOriginMatch || partialDestinationMatch) {
        totalScore +=
            20.0; // More points for partial matches (increased from 15)
      } else {
        // Even if no direct match, check if any service area city appears in addresses
        bool cityMatch = false;
        for (final area in carrier.serviceAreas!) {
          final areaLower = area.toLowerCase();
          final cityName = areaLower.split(',')[0].trim();
          if (cityName.isNotEmpty &&
              (originLower.contains(cityName) ||
                  destinationLower.contains(cityName))) {
            cityMatch = true;
            break;
          }
        }
        if (cityMatch) {
          totalScore += 10.0; // Small points for city name match
        }
      }
    }

    // ============================================================================
    // 3. WEIGHT CAPACITY MATCH (20 points)
    // ============================================================================
    // Checks if load weight is within carrier's max weight capacity
    // Special value 999999 means "No Limit" - accepts all weights
    //
    // Scoring: Full points if within capacity, bonus for lighter loads
    //
    // TO ADJUST: Change the 20.0 value below and the 0.3 bonus multiplier
    if (carrier.carrierPreferences != null &&
        carrier.carrierPreferences!['maxWeight'] != null) {
      try {
        final maxWeightValue = carrier.carrierPreferences!['maxWeight'];
        double? maxWeight;

        // Handle different data types from Firestore
        if (maxWeightValue is num) {
          maxWeight = maxWeightValue.toDouble();
        } else if (maxWeightValue is String) {
          maxWeight = double.tryParse(
            maxWeightValue.replaceAll(RegExp(r'[^\d.]'), ''),
          );
        }

        if (maxWeight != null && maxWeight > 0) {
          // 999999 = "No Limit" - accept all loads
          if (maxWeight >= 999999) {
            totalScore += 20.0; // Full points for unlimited capacity
          } else if (load.weight <= maxWeight) {
            // Calculate score with bonus for lighter loads
            final weightRatio = load.weight / maxWeight;
            // Bonus multiplier: 0.3 means lighter loads get up to 30% bonus
            totalScore += 20.0 * (1.0 - weightRatio * 0.3);
          }
          // If load.weight > maxWeight, no points (outside capacity)
        }
      } catch (e) {
        print('Error parsing maxWeight in matching: $e');
      }
    }

    // ============================================================================
    // 4. DISTANCE PREFERENCE MATCH (10 points) - TEMPORARILY DISABLED Distance Matrix API
    // ============================================================================
    // Checks if load's origin-to-destination distance is within carrier's max distance preference
    // NOTE: Distance Matrix API calls are commented out until API is activated
    // Special value 999999 means "Nationwide" - accepts all distances
    //
    // Scoring: Full points if within range, bonus for shorter distances
    //
    // TO ADJUST: Change the 10.0 value below and the 0.2 bonus multiplier
    if (carrier.carrierPreferences != null &&
        carrier.carrierPreferences!['maxDistance'] != null) {
      try {
        final maxDistanceValue = carrier.carrierPreferences!['maxDistance'];
        double? maxDistance;

        // Handle different data types from Firestore
        if (maxDistanceValue is num) {
          maxDistance = maxDistanceValue.toDouble();
        } else if (maxDistanceValue is String) {
          // Parse distance string like "50 miles" or "1,000 miles"
          final match = RegExp(
            r'(\d{1,3}(?:,\d{3})*)',
          ).firstMatch(maxDistanceValue);
          if (match != null) {
            maxDistance = double.tryParse(match.group(1)!.replaceAll(',', ''));
          }
        }

        if (maxDistance != null && maxDistance > 0) {
          // 999999 = "Nationwide" - accept all distances
          if (maxDistance >= 999999) {
            totalScore += 10.0; // Full points for nationwide service
          } else {
            // TEMPORARILY DISABLED: Distance Matrix API calls
            // TODO: Re-enable when Distance Matrix API is activated in Google Cloud Console
            /*
            bool withinDistance = false;
            double? distanceToUse;
            
            // Check carrier-to-origin distance if carrier location is provided
            if (carrierLocation != null && carrierLocation.isNotEmpty && apiKey != null) {
              try {
                final carrierToOriginDistance = await DistanceService.calculateDistance(
                  carrierLocation,
                  load.originAddress,
                  apiKey,
                );
                
                if (carrierToOriginDistance != null && carrierToOriginDistance <= maxDistance) {
                  withinDistance = true;
                  distanceToUse = carrierToOriginDistance;
                }
              } catch (e) {
                print('Error calculating carrier-to-origin distance: $e');
                // Fall through to check load distance
              }
            }
            */

            // Check load's origin-to-destination distance (using stored distance field)
            // If load.distance is 0 or not set, skip distance matching (don't penalize)
            if (load.distance > 0 && load.distance <= maxDistance) {
              // Calculate score with bonus for shorter distances
              final distanceRatio = load.distance / maxDistance;
              // Bonus multiplier: 0.2 means shorter distances get up to 20% bonus
              totalScore += 10.0 * (1.0 - distanceRatio * 0.2);
            } else if (load.distance == 0) {
              // If distance is not calculated yet, give partial points to not exclude the load
              totalScore += 5.0; // Half points if distance not available
            }
          }
        }
      } catch (e) {
        print('Error parsing maxDistance in matching: $e');
      }
    }

    // ============================================================================
    // 5. PREFERRED LOAD TYPE MATCH (5 points)
    // ============================================================================
    // Checks if load type matches carrier's preferred load types
    // Example: If carrier prefers "Electronics" and load is "Electronics", award points
    //
    // TO ADJUST: Change the 5.0 value below
    if (carrier.carrierPreferences != null) {
      final preferredLoadTypesRaw =
          carrier.carrierPreferences!['preferredLoadTypes'];
      if (preferredLoadTypesRaw != null) {
        // Handle both List<String> and List<dynamic> from Firestore
        List<String> preferredLoadTypes;
        if (preferredLoadTypesRaw is List<String>) {
          preferredLoadTypes = preferredLoadTypesRaw;
        } else if (preferredLoadTypesRaw is List) {
          preferredLoadTypes = preferredLoadTypesRaw.cast<String>();
        } else {
          preferredLoadTypes = [];
        }

        // Award points if load type is in preferred list
        if (preferredLoadTypes.isNotEmpty &&
            preferredLoadTypes.contains(load.loadType)) {
          totalScore += 5.0;
        }
      }
    }

    // ============================================================================
    // FINAL CALCULATION
    // ============================================================================
    // Convert score to percentage (0-100%)
    // Clamp ensures result is between 0 and 100
    // Show all loads with any match (even 5% match percentage)
    final finalScore = (totalScore / maxScore * 100).clamp(0.0, 100.0);

    // Debug: Print final score breakdown
    print(
      'Total Score: $totalScore / $maxScore = ${finalScore.toStringAsFixed(1)}%',
    );
    print('====================');

    return finalScore;
  }

  /// Get available loads for carrier with matching percentage calculation
  static Future<Map<String, dynamic>> getAvailableLoadsForCarrier({
    required String carrierUid,
    String searchQuery = '',
    String equipmentFilter = 'all',
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // Get carrier data for preference matching
      final carrierDoc = await carriers.doc(carrierUid).get();
      if (!carrierDoc.exists) {
        throw Exception('Carrier not found');
      }
      final carrier = CarrierModel.fromFirestore(carrierDoc);

      // Get all shippers first
      final shippersSnapshot = await _firestore.collection('shippers').get();
      final allLoads = <LoadModel>[];

      // Fetch loads from each shipper using the same pattern as getShipperLoads
      for (final shipperDoc in shippersSnapshot.docs) {
        final shipperUid = shipperDoc.id;

        // Use the same query pattern as getShipperLoads
        Query query = _firestore
            .collection('shippers')
            .doc(shipperUid)
            .collection('loads')
            .where('status', isEqualTo: 'active');

        // Apply equipment filter
        // if (equipmentFilter != 'all') {
        //   query = query.where('equipmentNeeded', isEqualTo: equipmentFilter);
        // }

        // Apply sorting (same as getShipperLoads)
        query = query.orderBy('createdAt', descending: true);

        final snapshot = await query.get();

        // Google API key for distance calculations (temporarily not used)
        // const String googleApiKey = AppConstants.googleApiKey;

        // Get carrier's current location (use address if currentLocation is not available)
        // Temporarily not used until Distance Matrix API is activated
        // final carrierLocation = carrier.currentLocation ??
        //                        (carrier.address != null && carrier.address!.isNotEmpty
        //                         ? carrier.address!
        //                         : null);

        // Get shipper name from shipper document
        final shipperData = shipperDoc.data() as Map<String, dynamic>?;
        final shipperName =
            shipperData?['displayName'] ??
            shipperData?['companyName'] ??
            shipperData?['shipperName'] ??
            shipperData?['name'] ??
            '';

        for (final doc in snapshot.docs) {
          try {
            // Pass shipperUid from parent document path
            var load = LoadModel.fromFirestore(
              doc,
              parentShipperUid: shipperUid,
            );

            // If shipperName is missing from load, use the one from shipper document
            if (load.shipperName.isEmpty && shipperName.isNotEmpty) {
              load = load.copyWith(shipperName: shipperName);
            }

            // Use async version without distance API calls (commented out)
            final matchPercentage = await calculateLoadMatchPercentage(
              load,
              carrier,
              carrierLocation: null, // Temporarily disabled
              apiKey: null, // Temporarily disabled
            );

            // Only log matches above 10% to reduce console spam
            if (matchPercentage >= 10.0) {
              print(
                'Load ${load.id}: ${matchPercentage.toStringAsFixed(1)}% match',
              );
            }

            final loadWithMatch = load.copyWith(
              matchPercentage: matchPercentage,
            );
            allLoads.add(loadWithMatch);
          } catch (e) {
            print('Error parsing load ${doc.id}: $e');
            continue;
          }
        }
      }

      // Filter out loads booked by other carriers (only show unbooked loads or loads booked by this carrier)
      final availableLoads = allLoads.where((load) {
        // Exclude loads that are booked by other carriers
        // Check for null, empty string, or different carrier ID
        final bookedById = load.bookedByCarrierId;
        if (bookedById != null &&
            bookedById.isNotEmpty &&
            bookedById != carrierUid) {
          return false; // Booked by another carrier - exclude
        }
        // Include if: null, empty string, or booked by this carrier
        return true;
      }).toList();

      // Sort by match percentage (highest first)
      availableLoads.sort(
        (a, b) => (b.matchPercentage ?? 0).compareTo(a.matchPercentage ?? 0),
      );

      // Apply search filter client-side (same pattern as getShipperLoads)
      final filteredLoads = availableLoads.where((load) {
        if (searchQuery.isEmpty) return true;
        final searchLower = searchQuery.toLowerCase();
        return load.originAddress.toLowerCase().contains(searchLower) ||
            load.destinationAddress.toLowerCase().contains(searchLower) ||
            load.originCity.toLowerCase().contains(searchLower) ||
            load.destinationCity.toLowerCase().contains(searchLower) ||
            load.equipmentNeeded.toLowerCase().contains(searchLower) ||
            load.loadType.toLowerCase().contains(searchLower) ||
            load.description.toLowerCase().contains(searchLower);
      }).toList();

      // Apply pagination client-side
      final startIndex =
          0; // Simplified for now since we're aggregating from multiple collections
      final endIndex = (startIndex + limit).clamp(0, filteredLoads.length);
      final paginatedLoads = filteredLoads.sublist(startIndex, endIndex);

      return {
        'loads': paginatedLoads,
        'lastDocument': null, // Simplified pagination
        'hasMore': endIndex < filteredLoads.length,
        'totalCount': filteredLoads.length,
      };
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get available loads for carrier',
      );

      // Re-throw network errors to be handled by the UI
      if (e.toString().contains('network') ||
          e.toString().contains('connection') ||
          e.toString().contains('timeout')) {
        rethrow;
      }

      return {
        'loads': <LoadModel>[],
        'lastDocument': null,
        'hasMore': false,
        'totalCount': 0,
      };
    }
  }

  /// Get all loads for carrier (both available and booked)
  static Future<Map<String, dynamic>> getAllLoadsForCarrier({
    required String carrierUid,
    String searchQuery = '',
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // Get carrier data for preference matching
      final carrierDoc = await carriers.doc(carrierUid).get();
      if (!carrierDoc.exists) {
        throw Exception('Carrier not found');
      }
      final carrier = CarrierModel.fromFirestore(carrierDoc);

      // Get all shippers first
      final shippersSnapshot = await _firestore.collection('shippers').get();
      final allLoads = <LoadModel>[];

      // Fetch loads from each shipper using the same pattern as getShipperLoads
      for (final shipperDoc in shippersSnapshot.docs) {
        final shipperUid = shipperDoc.id;

        // Get available loads (same pattern as getShipperLoads)
        Query availableQuery = _firestore
            .collection('shippers')
            .doc(shipperUid)
            .collection('loads')
            .where('status', isEqualTo: 'active');

        // Get booked loads by this carrier
        Query bookedQuery = _firestore
            .collection('shippers')
            .doc(shipperUid)
            .collection('loads')
            .where('bookedByCarrierId', isEqualTo: carrierUid);

        // Apply sorting (same as getShipperLoads)
        availableQuery = availableQuery.orderBy('createdAt', descending: true);
        bookedQuery = bookedQuery.orderBy('createdAt', descending: true);

        // Execute both queries
        final availableSnapshot = await availableQuery.get();
        final bookedSnapshot = await bookedQuery.get();

        // Google API key for distance calculations (temporarily not used)
        // const String googleApiKey = AppConstants.googleApiKey;

        // Get carrier's current location (temporarily not used)
        // final carrierLocation = carrier.currentLocation ??
        //                        (carrier.address != null && carrier.address!.isNotEmpty
        //                         ? carrier.address!
        //                         : null);

        // Get shipper name from shipper document
        final shipperData = shipperDoc.data() as Map<String, dynamic>?;
        final shipperName =
            shipperData?['displayName'] ??
            shipperData?['companyName'] ??
            shipperData?['shipperName'] ??
            shipperData?['name'] ??
            '';

        // Process available loads (exclude those booked by other carriers)
        for (final doc in availableSnapshot.docs) {
          try {
            // Pass shipperUid from parent document path
            var load = LoadModel.fromFirestore(
              doc,
              parentShipperUid: shipperUid,
            );

            // If shipperName is missing from load, use the one from shipper document
            if (load.shipperName.isEmpty && shipperName.isNotEmpty) {
              load = load.copyWith(shipperName: shipperName);
            }

            // Only include if not booked by another carrier
            // Check for null, empty string, or same carrier ID
            final bookedById = load.bookedByCarrierId;
            if (bookedById == null ||
                bookedById.isEmpty ||
                bookedById == carrierUid) {
              // Use async version without distance API calls (commented out)
              final matchPercentage = await calculateLoadMatchPercentage(
                load,
                carrier,
                carrierLocation: null, // Temporarily disabled
                apiKey: null, // Temporarily disabled
              );

              // Debug logging
              if (matchPercentage > 0) {
                print(
                  'Load ${load.id} match: $matchPercentage% - Equipment: ${load.equipmentNeeded}',
                );
              }

              final loadWithMatch = load.copyWith(
                matchPercentage: matchPercentage,
              );
              allLoads.add(loadWithMatch);
            }
          } catch (e) {
            print('Error parsing available load ${doc.id}: $e');
            continue;
          }
        }

        // Process booked loads
        for (final doc in bookedSnapshot.docs) {
          try {
            // Pass shipperUid from parent document path
            var load = LoadModel.fromFirestore(
              doc,
              parentShipperUid: shipperUid,
            );

            // If shipperName is missing from load, use the one from shipper document
            if (load.shipperName.isEmpty && shipperName.isNotEmpty) {
              load = load.copyWith(shipperName: shipperName);
            }

            allLoads.add(load);
          } catch (e) {
            print('Error parsing booked load ${doc.id}: $e');
            continue;
          }
        }
      }

      // Sort by creation date (newest first)
      allLoads.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply search filter client-side (same pattern as getShipperLoads)
      final filteredLoads = allLoads.where((load) {
        if (searchQuery.isEmpty) return true;
        final searchLower = searchQuery.toLowerCase();
        return load.originAddress.toLowerCase().contains(searchLower) ||
            load.destinationAddress.toLowerCase().contains(searchLower) ||
            load.originCity.toLowerCase().contains(searchLower) ||
            load.destinationCity.toLowerCase().contains(searchLower) ||
            load.equipmentNeeded.toLowerCase().contains(searchLower) ||
            load.loadType.toLowerCase().contains(searchLower) ||
            load.description.toLowerCase().contains(searchLower);
      }).toList();

      // Apply pagination client-side
      final startIndex =
          0; // Simplified for now since we're aggregating from multiple collections
      final endIndex = (startIndex + limit).clamp(0, filteredLoads.length);
      final paginatedLoads = filteredLoads.sublist(startIndex, endIndex);

      return {
        'loads': paginatedLoads,
        'lastDocument': null, // Simplified pagination
        'hasMore': endIndex < filteredLoads.length,
        'totalCount': filteredLoads.length,
      };
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get all loads for carrier',
      );

      // Re-throw network errors to be handled by the UI
      if (e.toString().contains('network') ||
          e.toString().contains('connection') ||
          e.toString().contains('timeout')) {
        rethrow;
      }

      return {
        'loads': <LoadModel>[],
        'lastDocument': null,
        'hasMore': false,
        'totalCount': 0,
      };
    }
  }

  /// Get carrier's booked loads with different statuses
  static Future<Map<String, dynamic>> getCarrierBookedLoads({
    required String carrierUid,
    String status = 'all',
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // Get all shippers first
      final shippersSnapshot = await _firestore.collection('shippers').get();
      final allLoads = <LoadModel>[];

      // Fetch booked loads from each shipper using the same pattern as getShipperLoads
      for (final shipperDoc in shippersSnapshot.docs) {
        final shipperUid = shipperDoc.id;

        // Use the same query pattern as getShipperLoads
        Query query = _firestore
            .collection('shippers')
            .doc(shipperUid)
            .collection('loads')
            .where('bookedByCarrierId', isEqualTo: carrierUid);

        // Apply status filter
        if (status != 'all') {
          query = query.where('status', isEqualTo: status);
        }

        // Apply sorting (same as getShipperLoads)
        query = query.orderBy('createdAt', descending: true);

        final snapshot = await query.get();

        // Get shipper name from shipper document
        final shipperData = shipperDoc.data() as Map<String, dynamic>?;
        final shipperName =
            shipperData?['displayName'] ??
            shipperData?['companyName'] ??
            shipperData?['shipperName'] ??
            shipperData?['name'] ??
            '';

        for (final doc in snapshot.docs) {
          try {
            // Pass shipperUid from parent document path
            var load = LoadModel.fromFirestore(
              doc,
              parentShipperUid: shipperUid,
            );

            // If shipperName is missing from load, use the one from shipper document
            if (load.shipperName.isEmpty && shipperName.isNotEmpty) {
              load = load.copyWith(shipperName: shipperName);
            }

            allLoads.add(load);
          } catch (e) {
            print('Error parsing booked load ${doc.id}: $e');
            continue;
          }
        }
      }

      // Sort by creation date (newest first)
      allLoads.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply pagination client-side
      final startIndex =
          0; // Simplified for now since we're aggregating from multiple collections
      final endIndex = (startIndex + limit).clamp(0, allLoads.length);
      final paginatedLoads = allLoads.sublist(startIndex, endIndex);

      return {
        'loads': paginatedLoads,
        'lastDocument': null, // Simplified pagination
        'hasMore': endIndex < allLoads.length,
        'totalCount': allLoads.length,
      };
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get carrier booked loads',
      );

      // Re-throw network errors to be handled by the UI
      if (e.toString().contains('network') ||
          e.toString().contains('connection') ||
          e.toString().contains('timeout')) {
        rethrow;
      }

      return {
        'loads': <LoadModel>[],
        'lastDocument': null,
        'hasMore': false,
        'totalCount': 0,
      };
    }
  }

  /// Debug method to check if there are any loads in the database
  static Future<void> debugCheckLoads() async {
    try {
      print('=== DEBUG: Checking for loads in database ===');

      // Check main loads collection
      final mainLoadsSnapshot = await _firestore.collection('loads').get();
      print(
        'DEBUG: Main loads collection has ${mainLoadsSnapshot.docs.length} documents',
      );

      // Check shippers collection
      final shippersSnapshot = await _firestore.collection('shippers').get();
      print('DEBUG: Found ${shippersSnapshot.docs.length} shippers');

      int totalLoads = 0;
      for (final shipperDoc in shippersSnapshot.docs) {
        final shipperUid = shipperDoc.id;
        print('DEBUG: Checking shipper $shipperUid...');

        // Check if shipper document exists and has basic info
        final shipperData = shipperDoc.data();
        print('DEBUG: Shipper $shipperUid data: ${shipperData.keys.toList()}');

        final loadsSnapshot = await _firestore
            .collection('shippers')
            .doc(shipperUid)
            .collection('loads')
            .get();

        print(
          'DEBUG: Shipper $shipperUid has ${loadsSnapshot.docs.length} loads',
        );
        totalLoads += loadsSnapshot.docs.length;

        // Print details of each load
        for (final loadDoc in loadsSnapshot.docs) {
          final data = loadDoc.data();
          print(
            '  - Load ${loadDoc.id}: status=${data['status']}, title=${data['title']}',
          );
        }

        // Also check if there are any documents in the loads subcollection at all
        if (loadsSnapshot.docs.isEmpty) {
          print(
            'DEBUG: No loads found for shipper $shipperUid - checking if subcollection exists...',
          );
          // Try to get a count query to see if there are any documents
          final countQuery = await _firestore
              .collection('shippers')
              .doc(shipperUid)
              .collection('loads')
              .limit(1)
              .get();
          print(
            'DEBUG: Count query returned ${countQuery.docs.length} documents',
          );
        }
      }

      print('DEBUG: Total loads across all shippers: $totalLoads');
      print('=== END DEBUG ===');
    } catch (e) {
      print('DEBUG ERROR: $e');
    }
  }

  /// Book a load for a carrier
  /// Submit a report
  static Future<bool> submitReport({
    required String reporterId,
    required String reportedUserId,
    required String reportedUserName,
    required String reason,
    String? loadId,
    String? conversationId,
    String? offerId,
    String? listingId,
  }) async {
    try {
      await reports.add({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reportedUserName': reportedUserName,
        'reason': reason,
        'loadId': loadId,
        'conversationId': conversationId,
        'offerId': offerId,
        'listingId': listingId,
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('Report submitted successfully');
      return true;
    } catch (e) {
      print('Error submitting report: $e');
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to submit report',
      );
      return false;
    }
  }

  static Future<bool> bookLoad({
    required String loadId,
    required String carrierUid,
  }) async {
    try {
      print(
        'DEBUG bookLoad: Starting to book load $loadId for carrier $carrierUid',
      );

      // First, find the load outside of transaction to avoid timeout
      final shippersSnapshot = await _firestore.collection('shippers').get();
      DocumentReference? loadRef;
      Map<String, dynamic>? loadData;
      String? shipperUid;

      print(
        'DEBUG bookLoad: Searching through ${shippersSnapshot.docs.length} shippers',
      );

      // Search for the load in all shipper subcollections
      for (final shipperDoc in shippersSnapshot.docs) {
        final shipperId = shipperDoc.id;
        final tempLoadRef = _firestore
            .collection('shippers')
            .doc(shipperId)
            .collection('loads')
            .doc(loadId);

        final loadDoc = await tempLoadRef.get();
        if (loadDoc.exists) {
          loadRef = tempLoadRef;
          loadData = loadDoc.data() as Map<String, dynamic>;
          shipperUid = shipperId;
          print('DEBUG bookLoad: Found load in shipper $shipperId');
          break;
        }
      }

      if (loadRef == null || loadData == null || shipperUid == null) {
        print('DEBUG bookLoad: Load not found');
        throw Exception('Load not found');
      }

      // Check if load is still available (active or available status)
      if (loadData['status'] != 'active' && loadData['status'] != 'available') {
        print(
          'DEBUG bookLoad: Load is no longer available, status: ${loadData['status']}',
        );
        throw Exception('Load is no longer available');
      }

      // Get carrier data outside of transaction
      final carrierDoc = await carriers.doc(carrierUid).get();
      if (!carrierDoc.exists) {
        print('DEBUG bookLoad: Carrier not found');
        throw Exception('Carrier not found');
      }

      final carrierData = carrierDoc.data() as Map<String, dynamic>;
      final carrierName =
          carrierData['displayName'] ??
          carrierData['companyName'] ??
          'Unknown Carrier';
      print('DEBUG bookLoad: Carrier found: $carrierName');

      // Now run the transaction with the found references
      return await _firestore
          .runTransaction<bool>((transaction) async {
            print('DEBUG bookLoad: Starting transaction');

            // Ensure loadRef is not null
            if (loadRef == null) {
              throw Exception('Load reference is null');
            }

            // Re-check load status within transaction
            final loadDoc = await transaction.get(loadRef);
            if (!loadDoc.exists) {
              throw Exception('Load no longer exists');
            }

            final currentLoadData = loadDoc.data() as Map<String, dynamic>;
            if (currentLoadData['status'] != 'active' &&
                currentLoadData['status'] != 'available') {
              throw Exception('Load is no longer available');
            }

            // Update load status in shipper subcollection
            transaction.update(loadRef, {
              'status': 'booked',
              'bookedByCarrierId': carrierUid,
              'bookedAt': Timestamp.now(),
              'updatedAt': Timestamp.now(),
            });

            // Create booking record
            final bookingRef = bookings.doc();
            transaction.set(bookingRef, {
              'loadId': loadId,
              'carrierId': carrierUid,
              'carrierName': carrierName,
              'shipperId': shipperUid,
              'shipperName': loadData?['shipperName'] ?? 'Unknown Shipper',
              'status': 'booked',
              'bookedAt': Timestamp.now(),
              'createdAt': Timestamp.now(),
              'updatedAt': Timestamp.now(),
            });

            // Add to carrier's myBookings subcollection
            final carrierBookingRef = carriers
                .doc(carrierUid)
                .collection('myBookings')
                .doc(loadId);
            transaction.set(carrierBookingRef, {
              'loadId': loadId,
              'status': 'booked',
              'bookedAt': Timestamp.now(),
              'createdAt': Timestamp.now(),
            });

            print('DEBUG bookLoad: Transaction completed successfully');
            return true;
          })
          .then((success) async {
            if (success && shipperUid != null) {
              // Send notifications to both shipper and carrier
              try {
                await NotificationService.createNotification(
                  userId: shipperUid,
                  type: NotificationType.orderStatus,
                  title: "Order Booked",
                  body:
                      "A carrier has accepted your order! Please deposit payment to escrow to proceed.",
                  data: {
                    'loadId': loadId,
                    'oldStatus': 'available',
                    'newStatus': 'booked',
                    'requiresEscrowPayment': true,
                  },
                  relatedId: loadId,
                );

                await NotificationService.createNotification(
                  userId: carrierUid,
                  type: NotificationType.orderStatus,
                  title: "Load Booked Successfully",
                  body: "You have successfully booked this load!",
                  data: {
                    'loadId': loadId,
                    'oldStatus': 'available',
                    'newStatus': 'booked',
                  },
                  relatedId: loadId,
                );
              } catch (e) {
                debugPrint('Error sending booking notifications: $e');
                // Don't fail the booking if notification fails
              }
            }
            return success;
          });
    } catch (e) {
      print('DEBUG bookLoad: Error occurred: $e');
      await recordError(e, StackTrace.current, reason: 'Failed to book load');
      return false;
    }
  }

  /// Update load status for carriers
  /// Loads are stored in shippers/{shipperUid}/loads/{loadId}
  static Future<bool> updateCarrierLoadStatus({
    required String loadId,
    required String status,
    String? carrierUid,
  }) async {
    try {
      // First, find the load in shipper subcollections (same pattern as bookLoad)
      final shippersSnapshot = await _firestore.collection('shippers').get();
      DocumentReference? loadRef;
      Map<String, dynamic>? loadData;
      String? shipperUid;

      // Search for the load in all shipper subcollections
      for (final shipperDoc in shippersSnapshot.docs) {
        final shipperId = shipperDoc.id;
        final tempLoadRef = _firestore
            .collection('shippers')
            .doc(shipperId)
            .collection('loads')
            .doc(loadId);

        final loadDoc = await tempLoadRef.get();
        if (loadDoc.exists) {
          loadRef = tempLoadRef;
          loadData = loadDoc.data() as Map<String, dynamic>;
          shipperUid = shipperId;
          break;
        }
      }

      if (loadRef == null || loadData == null || shipperUid == null) {
        throw Exception('Load not found');
      }

      final currentCarrierId = loadData['bookedByCarrierId'] as String?;

      // Verify carrier has permission to update this load
      if (carrierUid != null && currentCarrierId != carrierUid) {
        throw Exception('Unauthorized to update this load');
      }

      // Store old status before update
      final oldStatus = loadData['status'] as String? ?? 'booked';

      // Now run the transaction with the found reference
      return await _firestore
          .runTransaction<bool>((transaction) async {
            // Re-check load within transaction
            final loadDoc = await transaction.get(loadRef!);
            if (!loadDoc.exists) {
              throw Exception('Load no longer exists');
            }

            // Update load status
            final updateData = <String, dynamic>{
              'status': status,
              'updatedAt': Timestamp.now(),
            };

            if (status == 'completed') {
              updateData['completedAt'] = Timestamp.now();
            }

            transaction.update(loadRef, updateData);

            // Update booking record
            final bookingQuery = bookings.where('loadId', isEqualTo: loadId);
            final bookingSnapshot = await bookingQuery.get();

            for (final bookingDoc in bookingSnapshot.docs) {
              transaction.update(bookingDoc.reference, {
                'status': status,
                'updatedAt': Timestamp.now(),
              });
            }

            // Update carrier's myBookings subcollection
            if (currentCarrierId != null) {
              final carrierBookingRef = carriers
                  .doc(currentCarrierId)
                  .collection('myBookings')
                  .doc(loadId);
              transaction.update(carrierBookingRef, {
                'status': status,
                'updatedAt': Timestamp.now(),
              });
            }

            return true;
          })
          .then((success) async {
            if (success && shipperUid != null && oldStatus != status) {
              // Send notification to shipper about status change
              try {
                String title;
                String body;

                if (status == 'in-transit' && oldStatus == 'booked') {
                  // Pickup completed - load is now in transit
                  title = "Pickup Completed";
                  body = "Your order has been picked up and is now in transit!";
                } else if (status == 'completed' && oldStatus == 'in-transit') {
                  // Delivery completed
                  title = "Delivery Completed";
                  body = "Your order has been delivered successfully!";
                } else {
                  // Generic status update
                  title = "Order Status Updated";
                  body =
                      "Your order status has been updated to ${status.replaceAll('-', ' ')}.";
                }

                await NotificationService.createNotification(
                  userId: shipperUid,
                  type: NotificationType.orderStatus,
                  title: title,
                  body: body,
                  data: {
                    'loadId': loadId,
                    'oldStatus': oldStatus,
                    'newStatus': status,
                  },
                  relatedId: loadId,
                );
              } catch (e) {
                debugPrint('Error sending status update notification: $e');
                // Don't fail the status update if notification fails
              }
            }
            return success;
          });
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to update load status',
      );
      // Re-throw to allow proper error handling in UI
      // The exception will be caught by the calling code
      rethrow;
    }
  }

  /// Update carrier preferences
  static Future<bool> updateCarrierPreferences({
    required String carrierUid,
    List<String>? vehicleTypes,
    List<String>? serviceAreas,
    Map<String, dynamic>? carrierPreferences,
  }) async {
    try {
      final updateData = <String, dynamic>{'updatedAt': Timestamp.now()};

      if (vehicleTypes != null) {
        updateData['vehicleTypes'] = vehicleTypes;
      }

      if (serviceAreas != null) {
        updateData['serviceAreas'] = serviceAreas;
      }

      if (carrierPreferences != null) {
        updateData['carrierPreferences'] = carrierPreferences;
      }

      print('Firebase: Updating carrier preferences with data: $updateData');
      await carriers.doc(carrierUid).update(updateData);
      print('Firebase: Successfully updated carrier preferences');
      return true;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to update carrier preferences',
      );
      return false;
    }
  }

  /// Create escrow payment record in Firestore
  static Future<bool> createEscrowPayment({
    required String loadId,
    required String carrierId,
    required String shipperId,
    required String paymentIntentId,
    required int amountInCents,
    String currency = 'usd',
  }) async {
    try {
      await _firestore.collection('escrow_payments').add({
        'loadId': loadId,
        'carrierId': carrierId,
        'shipperId': shipperId,
        'paymentIntentId': paymentIntentId,
        'amount': amountInCents,
        'amountInDollars': amountInCents / 100,
        'currency': currency,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      // Update load document with escrow payment info
      final shippersSnapshot = await _firestore.collection('shippers').get();
      for (final shipperDoc in shippersSnapshot.docs) {
        final loadDoc = await _firestore
            .collection('shippers')
            .doc(shipperDoc.id)
            .collection('loads')
            .doc(loadId)
            .get();

        if (loadDoc.exists) {
          await _firestore
              .collection('shippers')
              .doc(shipperDoc.id)
              .collection('loads')
              .doc(loadId)
              .update({
                'escrowPaymentIntentId': paymentIntentId,
                'escrowPaymentStatus': 'pending',
                'escrowAmount': amountInCents / 100,
                'updatedAt': Timestamp.now(),
              });
          break;
        }
      }

      return true;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to create escrow payment',
      );
      return false;
    }
  }

  /// Get escrow payment for a load
  static Future<Map<String, dynamic>?> getEscrowPayment(String loadId) async {
    try {
      final querySnapshot = await _firestore
          .collection('escrow_payments')
          .where('loadId', isEqualTo: loadId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      return {...data, 'id': doc.id};
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get escrow payment',
      );
      return null;
    }
  }

  /// Update escrow payment status
  static Future<bool> updateEscrowPaymentStatus({
    required String paymentIntentId,
    required String status,
    String? loadId,
    String? transferId,
    DateTime? releasedAt,
  }) async {
    try {
      // Find escrow payment by paymentIntentId
      final querySnapshot = await _firestore
          .collection('escrow_payments')
          .where('paymentIntentId', isEqualTo: paymentIntentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Escrow payment not found');
      }

      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': Timestamp.now(),
      };

      if (transferId != null) {
        updateData['transferId'] = transferId;
      }

      if (releasedAt != null) {
        updateData['releasedAt'] = Timestamp.fromDate(releasedAt);
      }

      await querySnapshot.docs.first.reference.update(updateData);

      // Update load document if loadId provided
      if (loadId != null) {
        final shippersSnapshot = await _firestore.collection('shippers').get();
        for (final shipperDoc in shippersSnapshot.docs) {
          final loadDoc = await _firestore
              .collection('shippers')
              .doc(shipperDoc.id)
              .collection('loads')
              .doc(loadId)
              .get();

          if (loadDoc.exists) {
            await _firestore
                .collection('shippers')
                .doc(shipperDoc.id)
                .collection('loads')
                .doc(loadId)
                .update({
                  'escrowPaymentStatus': status,
                  'updatedAt': Timestamp.now(),
                  if (releasedAt != null)
                    'escrowReleasedAt': Timestamp.fromDate(releasedAt),
                });
            break;
          }
        }
      }

      return true;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to update escrow payment status',
      );
      return false;
    }
  }

  /// Mark escrow payment as deposited (after successful payment)
  static Future<bool> markEscrowPaymentDeposited({
    required String paymentIntentId,
    required String loadId,
  }) async {
    return await updateEscrowPaymentStatus(
      paymentIntentId: paymentIntentId,
      status: 'deposited',
      loadId: loadId,
    );
  }

  // ==================== Academy Content Methods ====================

  /// Upload academy thumbnail image
  static Future<String?> uploadAcademyThumbnail(dynamic imageFile) async {
    try {
      int fileSize;
      if (kIsWeb) {
        final xfile = imageFile as XFile;
        fileSize = (await xfile.readAsBytes()).length;
      } else {
        final file = imageFile is XFile
            ? File(imageFile.path)
            : imageFile as File;
        fileSize = await file.length();
      }

      // Validate file size (5MB limit)
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image file is too large. Maximum size is 5MB');
      }

      final fileName = 'thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('academy/thumbnails/$fileName');

      // Set metadata with content type
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      );

      UploadTask uploadTask;
      if (kIsWeb) {
        final xfile = imageFile as XFile;
        final bytes = await xfile.readAsBytes();
        uploadTask = ref.putData(bytes, metadata);
      } else {
        final file = imageFile is XFile
            ? File(imageFile.path)
            : imageFile as File;
        uploadTask = ref.putFile(file, metadata);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to upload academy thumbnail',
      );
      return null;
    }
  }

  /// Upload academy video
  static Future<String?> uploadAcademyVideo(dynamic videoFile) async {
    try {
      int fileSize;
      if (kIsWeb) {
        final xfile = videoFile as XFile;
        fileSize = (await xfile.readAsBytes()).length;
      } else {
        final file = videoFile is XFile
            ? File(videoFile.path)
            : videoFile as File;
        fileSize = await file.length();
      }

      // Validate file size (50MB limit)
      if (fileSize > 50 * 1024 * 1024) {
        throw Exception('Video file is too large. Maximum size is 50MB');
      }

      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final ref = _storage.ref().child('academy/videos/$fileName');

      // Set metadata with content type
      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        cacheControl: 'public, max-age=31536000',
      );

      UploadTask uploadTask;
      if (kIsWeb) {
        final xfile = videoFile as XFile;
        final bytes = await xfile.readAsBytes();
        uploadTask = ref.putData(bytes, metadata);
      } else {
        final file = videoFile is XFile
            ? File(videoFile.path)
            : videoFile as File;
        uploadTask = ref.putFile(file, metadata);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to upload academy video',
      );
      return null;
    }
  }

  /// Upload academy document
  static Future<String?> uploadAcademyDocument(dynamic documentFile) async {
    try {
      final String filePath = documentFile is XFile
          ? documentFile.path
          : (documentFile as File).path;
      final fileName = 'document_${DateTime.now().millisecondsSinceEpoch}';
      final extension = filePath.split('.').last;
      final ref = _storage.ref().child(
        'academy/documents/$fileName.$extension',
      );

      // Determine content type based on extension
      String contentType = 'application/octet-stream';
      switch (extension.toLowerCase()) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'doc':
          contentType = 'application/msword';
          break;
        case 'docx':
          contentType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'txt':
          contentType = 'text/plain';
          break;
      }

      // Set metadata with content type
      final metadata = SettableMetadata(
        contentType: contentType,
        cacheControl: 'public, max-age=31536000',
      );

      UploadTask uploadTask;
      if (kIsWeb) {
        final xfile = documentFile as XFile;
        final bytes = await xfile.readAsBytes();
        uploadTask = ref.putData(bytes, metadata);
      } else {
        final file = documentFile is XFile
            ? File(documentFile.path)
            : documentFile as File;
        uploadTask = ref.putFile(file, metadata);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to upload academy document',
      );
      return null;
    }
  }

  /// Get all academy content as a stream
  static Stream<List<AcademyContent>> getAcademyContentStream() {
    return _firestore
        .collection('academy_content')
        .orderBy('order')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AcademyContent.fromFirestore(doc))
              .toList();
        });
  }

  /// Get all academy content (one-time fetch)
  static Future<List<AcademyContent>> getAcademyContent() async {
    try {
      final snapshot = await _firestore
          .collection('academy_content')
          .orderBy('order')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => AcademyContent.fromFirestore(doc))
          .toList();
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get academy content',
      );
      return [];
    }
  }

  /// Get academy content by ID
  static Future<AcademyContent?> getAcademyContentById(String contentId) async {
    try {
      final doc = await _firestore
          .collection('academy_content')
          .doc(contentId)
          .get();
      if (doc.exists) {
        return AcademyContent.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get academy content by ID',
      );
      return null;
    }
  }

  /// Save or update academy content
  static Future<void> saveAcademyContent(AcademyContent content) async {
    try {
      final data = content.toFirestore();
      data['updatedAt'] = Timestamp.now();

      if (content.id.isEmpty || !await _academyContentExists(content.id)) {
        // Create new content
        data['createdAt'] = Timestamp.now();
        await _firestore.collection('academy_content').add(data);
      } else {
        // Update existing content
        await _firestore
            .collection('academy_content')
            .doc(content.id)
            .update(data);
      }
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to save academy content',
      );
      rethrow;
    }
  }

  /// Check if academy content exists
  static Future<bool> _academyContentExists(String contentId) async {
    try {
      final doc = await _firestore
          .collection('academy_content')
          .doc(contentId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Delete academy content and associated files
  static Future<void> deleteAcademyContent(String contentId) async {
    try {
      final content = await getAcademyContentById(contentId);
      if (content == null) return;

      // Delete files from storage
      if (content.thumbnailUrl != null) {
        try {
          final ref = _storage.refFromURL(content.thumbnailUrl!);
          await ref.delete();
        } catch (e) {
          print('Warning: Failed to delete thumbnail: $e');
        }
      }

      if (content.videoUrl != null) {
        try {
          final ref = _storage.refFromURL(content.videoUrl!);
          await ref.delete();
        } catch (e) {
          print('Warning: Failed to delete video: $e');
        }
      }

      if (content.documentUrl != null) {
        try {
          final ref = _storage.refFromURL(content.documentUrl!);
          await ref.delete();
        } catch (e) {
          print('Warning: Failed to delete document: $e');
        }
      }

      // Delete Firestore document
      await _firestore.collection('academy_content').doc(contentId).delete();
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to delete academy content',
      );
      rethrow;
    }
  }

  /// Get academy playlists
  static Future<List<Map<String, dynamic>>> getAcademyPlaylists() async {
    try {
      final snapshot = await _firestore
          .collection('academy_playlists')
          .orderBy('name')
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to get academy playlists',
      );
      return [];
    }
  }

  /// Create or update academy playlist
  static Future<void> saveAcademyPlaylist({
    required String? playlistId,
    required String name,
    String? description,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'description': description,
        'updatedAt': Timestamp.now(),
      };

      if (playlistId == null || playlistId.isEmpty) {
        data['createdAt'] = Timestamp.now();
        await _firestore.collection('academy_playlists').add(data);
      } else {
        await _firestore
            .collection('academy_playlists')
            .doc(playlistId)
            .update(data);
      }
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to save academy playlist',
      );
      rethrow;
    }
  }

  /// Delete user account and all associated data via Cloud Function
  /// This method:
  /// 1. Reauthenticates user with password (for email/password users)
  /// 2. Calls Cloud Function to delete all data, storage, Stripe account, and Auth user
  static Future<void> deleteAccount({
    required String userId,
    required UserRole userRole,
    String? password, // Required for email/password users
  }) async {
    try {
      await log('Starting account deletion for user: $userId');
      await logEvent(
        'account_deletion_started',
        parameters: _convertParameters({
          'user_role': userRole.toString().split('.').last,
        }),
      );

      // Step 1: Reauthenticate with password (required for email/password users)
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is email/password user
      bool isEmailPasswordUser = false;
      for (var provider in user.providerData) {
        if (provider.providerId == 'password') {
          isEmailPasswordUser = true;
          break;
        }
      }

      // Require password for email/password users
      if (isEmailPasswordUser) {
        if (password == null || password.trim().isEmpty) {
          throw Exception('Password is required for email/password accounts');
        }

        if (user.email == null) {
          throw Exception('User email not found');
        }

        try {
          await reauthenticateUser(user.email!, password);
          await log('Password reauthentication successful');
        } on FirebaseAuthException catch (e) {
          await logEvent(
            'account_deletion_failed',
            parameters: _convertParameters({
              'reason': 'reauthentication_failed',
              'error_code': e.code,
              'error': e.message ?? e.toString(),
            }),
          );
          
          // Re-throw with user-friendly message
          if (e.code == 'wrong-password') {
            throw Exception('Incorrect password. Please try again.');
          } else if (e.code == 'invalid-credential') {
            throw Exception('Invalid password. Please try again.');
          } else {
            rethrow;
          }
        } catch (e) {
          await logEvent(
            'account_deletion_failed',
            parameters: _convertParameters({
              'reason': 'reauthentication_failed',
              'error': e.toString(),
            }),
          );
          rethrow;
        }
      } else {
        // OAuth users don't need password, but log it
        await log('OAuth user - skipping password reauthentication');
      }

      // Step 2: Get fresh auth token after reauthentication
      final freshToken = await user.getIdToken(true);
      if (freshToken == null || freshToken.isEmpty) {
        throw Exception('Failed to get authentication token');
      }

      // Step 3: Call Cloud Function to delete account
      const projectId = 're-miles-dfm';
      const region = 'northamerica-northeast1';
      final functionUrl = 'https://$region-$projectId.cloudfunctions.net/deleteUserAccount';

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $freshToken',
        },
        body: jsonEncode({
          'data': {
            'userRole': userRole == UserRole.shipper ? 'shipper' : 'carrier',
          },
        }),
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception('Account deletion timed out. Please try again.');
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['result'] != null && responseData['result']['success'] == true) {
          await log('Account deletion completed successfully via Cloud Function');
          await logEvent(
            'account_deletion_completed',
            parameters: _convertParameters({
              'user_role': userRole.toString().split('.').last,
              'success': 'true',
            }),
          );
        } else {
          throw Exception(responseData['error']?['message'] ?? 'Account deletion failed');
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Failed to delete account';
        throw Exception(errorMessage);
      }
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to delete user account',
      );
      await logEvent(
        'account_deletion_failed',
        parameters: _convertParameters({
          'user_role': userRole.toString().split('.').last,
          'error': e.toString(),
        }),
      );
      rethrow;
    }
  }

  /// Delete all Firestore data associated with a user
  static Future<void> _deleteUserFirestoreData(
    String userId,
    UserRole userRole,
  ) async {
    try {
      // Delete user document from shippers or carriers collection
      if (userRole == UserRole.shipper) {
        // Delete shipper document
        await shippers.doc(userId).delete();

        // Delete all loads for this shipper
        final loadsSnapshot = await _firestore
            .collection('shippers')
            .doc(userId)
            .collection('loads')
            .get();
        for (var doc in loadsSnapshot.docs) {
          await doc.reference.delete();
        }

        // Delete all listings for this shipper
        final listingsSnapshot = await listings
            .where('shipperUid', isEqualTo: userId)
            .get();
        for (var doc in listingsSnapshot.docs) {
          await deleteProductListing(doc.id);
        }
      } else if (userRole == UserRole.carrier) {
        // Delete carrier document
        await carriers.doc(userId).delete();

        // Delete all bookings for this carrier
        final bookingsSnapshot = await bookings
            .where('carrierId', isEqualTo: userId)
            .get();
        for (var doc in bookingsSnapshot.docs) {
          await doc.reference.delete();
        }

        // Delete all offers for this carrier
        final offersSnapshot = await offers
            .where('carrierId', isEqualTo: userId)
            .get();
        for (var doc in offersSnapshot.docs) {
          await doc.reference.delete();
        }
      }

      // Delete conversations where user is a participant
      final conversationsSnapshot = await conversations
          .where('participants', arrayContains: userId)
          .get();
      for (var doc in conversationsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete messages sent by this user
      final messagesSnapshot = await messages
          .where('senderId', isEqualTo: userId)
          .get();
      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete reports filed by this user
      final reportsSnapshot = await reports
          .where('reporterId', isEqualTo: userId)
          .get();
      for (var doc in reportsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete from users collection if exists
      try {
        await users.doc(userId).delete();
      } catch (e) {
        // User might not exist in users collection, that's okay
      }
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to delete user Firestore data',
      );
      rethrow;
    }
  }

  /// Delete all storage files associated with a user
  static Future<void> _deleteUserStorageFiles(
    String userId,
    UserRole userRole,
  ) async {
    try {
      final prefix = userRole == UserRole.shipper ? 'shippers' : 'carriers';
      
      // Delete user's storage folder
      try {
        final userFolderRef = _storage.ref().child('$prefix/$userId');
        final listResult = await userFolderRef.listAll();
        
        // Delete all files in the folder
        for (var item in listResult.items) {
          try {
            await item.delete();
          } catch (e) {
            await recordError(
              e,
              StackTrace.current,
              reason: 'Failed to delete storage file: ${item.fullPath}',
            );
          }
        }

        // Delete subfolders (loads, listings, etc.)
        for (var prefix in listResult.prefixes) {
          try {
            final subfolderList = await prefix.listAll();
            for (var item in subfolderList.items) {
              try {
                await item.delete();
              } catch (e) {
                await recordError(
                  e,
                  StackTrace.current,
                  reason: 'Failed to delete storage file: ${item.fullPath}',
                );
              }
            }
          } catch (e) {
            // Subfolder might not exist, that's okay
          }
        }
      } catch (e) {
        // Folder might not exist, that's okay
        if (AppConfig.enableDebugLogging) {
          print('Storage folder not found or already deleted: $prefix/$userId');
        }
      }

      // Delete profile image if exists
      try {
        final profileImageRef = _storage.ref().child('$prefix/$userId/profile_image.jpg');
        await profileImageRef.delete();
      } catch (e) {
        // Profile image might not exist, that's okay
      }
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to delete user storage files',
      );
      // Don't rethrow - storage deletion failures shouldn't block account deletion
    }
  }

  /// Delete Stripe Connect account for carrier
  static Future<void> _deleteStripeConnectAccount(String accountId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in');
      }

      final freshToken = await currentUser.getIdToken(true);
      if (freshToken == null) {
        throw Exception('Failed to obtain authentication token');
      }

      await log('Deleting Stripe Connect account: $accountId');
      await logEvent(
        'stripe_account_deletion_started',
        parameters: _convertParameters({
          'account_id': accountId,
        }),
      );

      const projectId = 're-miles-dfm';
      const region = 'northamerica-northeast1';
      final functionUrl =
          'https://$region-$projectId.cloudfunctions.net/deleteConnectAccount';

      final response = await http
          .post(
            Uri.parse(functionUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $freshToken',
            },
            body: jsonEncode({'data': {}}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Delete Stripe account timed out');
            },
          );

      if (response.statusCode != 200) {
        final errorBody = response.body;
        try {
          final errorJson = jsonDecode(errorBody);
          final error = errorJson['error'] as Map<String, dynamic>?;
          final errorMessage = error?['message'] as String?;
          throw Exception(errorMessage ?? 'Failed to delete Stripe Connect account');
        } catch (parseError) {
          throw Exception(
            'Failed to delete Stripe Connect account: ${response.statusCode}',
          );
        }
      }

      final responseJson = jsonDecode(response.body);
      final result = responseJson['result'] as Map<String, dynamic>?;
      final deleted = result?['deleted'] as bool? ?? false;

      if (deleted) {
        await log('Stripe Connect account deleted successfully: $accountId');
        await logEvent(
          'stripe_account_deletion_success',
          parameters: _convertParameters({
            'account_id': accountId,
          }),
        );
      } else {
        await log('Stripe Connect account deletion completed (may not have existed): $accountId');
        await logEvent(
          'stripe_account_deletion_completed',
          parameters: _convertParameters({
            'account_id': accountId,
            'deleted': 'false',
          }),
        );
      }
    } catch (e) {
      await recordError(
        e,
        StackTrace.current,
        reason: 'Failed to delete Stripe Connect account',
      );
      await logEvent(
        'stripe_account_deletion_failed',
        parameters: _convertParameters({
          'account_id': accountId,
          'error': e.toString(),
        }),
      );
      rethrow;
    }
  }
}
