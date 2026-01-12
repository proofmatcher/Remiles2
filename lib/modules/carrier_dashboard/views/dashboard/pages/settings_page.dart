import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../../../core/html_stub.dart' as html if (dart.library.html) 'dart:html';
import '../../../../../providers/auth_provider.dart';
import '../../../../../providers/app_state_provider.dart';
import '../../../../../core/firebase_service.dart';
import '../../../../../core/app_config.dart';
import '../../../../../core/auth_wrapper.dart';
import '../../../../../models/user_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  // Phone verification state
  String? _verificationId;
  bool _isPhoneVerificationLoading = false;
  bool _isOtpSent = false;
  bool _isVerifyingOtp = false;

  // Delete account state
  final _deletePasswordController = TextEditingController();
  final _deleteOtpController = TextEditingController();
  String? _deleteVerificationId;
  bool _isDeleteOtpSent = false;
  bool _isDeletingAccount = false;
  bool _showDeleteAccountSection = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill phone number from user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final carrier = context.read<AuthProvider>().carrierUser;
      if (carrier?.phoneNumber != null && mounted) {
        _phoneController.text = carrier!.phoneNumber!;
      }
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _deletePasswordController.dispose();
    _deleteOtpController.dispose();
    super.dispose();
  }

  // Check if user signed in with Google or Apple (OAuth providers that don't use passwords)
  bool _isOAuthUser() {
    final authProvider = context.read<AuthProvider>();
    final firebaseUser = authProvider.firebaseUser;
    
    if (firebaseUser == null) return false;
    
    // Check provider data to see if user signed in with Google or Apple
    final providerData = firebaseUser.providerData;
    for (var provider in providerData) {
      final providerId = provider.providerId;
      // Google provider: "google.com"
      // Apple provider: "apple.com"
      // Email/Password provider: "password"
      print('providerId: $providerId');
      if (providerId == 'google.com' || providerId == 'apple.com') {
        return true;
      }
    }
    
    return false;
  }

  // Get the provider name for display
  String _getProviderName() {
    final authProvider = context.read<AuthProvider>();
    final firebaseUser = authProvider.firebaseUser;
    
    if (firebaseUser == null) return '';
    
    final providerData = firebaseUser.providerData;
    for (var provider in providerData) {
      final providerId = provider.providerId;
      if (providerId == 'google.com') {
        return 'Google';
      } else if (providerId == 'apple.com') {
        return 'Apple';
      }
    }
    
    return '';
  }

  Future<void> _updatePassword() async {
    // Check if user is OAuth user (shouldn't reach here, but double-check for safety)
    if (_isOAuthUser()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changes are not available for OAuth accounts.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final appStateProvider = context.read<AppStateProvider>();
      final carrier = authProvider.carrierUser;

      if (carrier == null) {
        throw Exception('Carrier not found');
      }

      appStateProvider.showLoadingWithMessage('Updating password...');

      // Reauthenticate user with current password
      await FirebaseService.reauthenticateUser(
        carrier.email,
        _currentPasswordController.text.trim(),
      );

      // Update password
      await FirebaseService.updatePassword(_newPasswordController.text.trim());

      appStateProvider.showSuccess();

      if (mounted) {
        // Clear form
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully'),
            backgroundColor: Color(0xFF4B744F),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      final appStateProvider = context.read<AppStateProvider>();
      String errorMessage;
      
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Current password is incorrect';
          break;
        case 'weak-password':
          errorMessage = 'New password is too weak';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please log out and log in again before changing password';
          break;
        default:
          errorMessage = 'Failed to update password: ${e.message}';
      }
      
      appStateProvider.showError(errorMessage);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.showError('Failed to update password. Please try again.');
      print('Error updating password: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Phone verification methods
  Future<void> _sendPhoneOTP() async {
    if (_phoneController.text.trim().isEmpty) {
      // Log analytics for validation error
      await FirebaseService.logEvent(
        'phone_otp_send_validation_error',
        parameters: FirebaseService.convertParameters({
          'error_type': 'empty_phone_number',
        }),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a phone number'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isPhoneVerificationLoading = true;
    });

    try {
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.showLoadingWithMessage('Sending OTP...');

      // Format phone number (ensure it starts with +)
      String phoneNumber = _phoneController.text.trim();
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+$phoneNumber';
      }

      final verificationId = await FirebaseService.sendPhoneOTP(
        phoneNumber,
        onCodeSent: (String verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _isOtpSent = true;
            });
          }
        },
      );

      // Set verification ID if not already set by callback
      if (!_isOtpSent) {
        setState(() {
          _verificationId = verificationId;
          _isOtpSent = true;
        });
      }

      appStateProvider.showSuccess();

      if (mounted) {
        // Clean up reCAPTCHA container on web after OTP is sent
        if (kIsWeb) {
          try {
            Future.delayed(const Duration(seconds: 2), () {
              final container = html.window.document.getElementById('recaptcha-container');
              if (container != null) {
                container.style.display = 'none';
              }
            });
          } catch (e) {
            // Ignore errors in cleanup
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully. Please check your phone.'),
            backgroundColor: Color(0xFF4B744F),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      final appStateProvider = context.read<AppStateProvider>();
      String errorMessage;
      
      switch (e.code) {
        case 'invalid-phone-number':
          errorMessage = 'Invalid phone number format';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Phone authentication is not enabled. Please contact support or enable it in Firebase Console.';
          break;
        case 'quota-exceeded':
          errorMessage = 'SMS quota exceeded. Please try again later.';
          break;
        default:
          errorMessage = 'Failed to send OTP: ${e.message ?? e.code}';
      }
      
      // Record error in Crashlytics
      await FirebaseService.recordError(
        e,
        StackTrace.current,
        reason: 'Phone OTP send failed in UI: ${e.code}',
      );
      
      appStateProvider.showError(errorMessage);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Record error in Crashlytics
      await FirebaseService.recordError(
        e,
        StackTrace.current,
        reason: 'Unexpected error sending phone OTP in UI',
      );
      
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.showError('Failed to send OTP. Please try again.');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPhoneVerificationLoading = false;
        });
      }
    }
  }

  Future<void> _verifyPhoneOTP() async {
    if (_otpController.text.trim().isEmpty) {
      // Log analytics for validation error
      await FirebaseService.logEvent(
        'phone_otp_verify_validation_error',
        parameters: FirebaseService.convertParameters({
          'error_type': 'empty_otp_code',
        }),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the OTP code'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_verificationId == null) {
      // Log analytics for validation error
      await FirebaseService.logEvent(
        'phone_otp_verify_validation_error',
        parameters: FirebaseService.convertParameters({
          'error_type': 'missing_verification_id',
        }),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please send OTP first'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final appStateProvider = context.read<AppStateProvider>();
      final carrier = authProvider.carrierUser;

      if (carrier == null) {
        // Record error in Crashlytics
        final error = Exception('Carrier not found during phone verification');
        await FirebaseService.recordError(
          error,
          StackTrace.current,
          reason: 'Carrier user is null during phone OTP verification',
        );
        throw error;
      }

      appStateProvider.showLoadingWithMessage('Verifying phone number...');

      // Format phone number
      String phoneNumber = _phoneController.text.trim();
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+$phoneNumber';
      }

      await FirebaseService.verifyPhoneOTP(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
        phoneNumber: phoneNumber,
        userUid: carrier.uid,
        userRole: UserRole.carrier,
      );

      // Refresh user data
      await authProvider.refreshUser();

      appStateProvider.showSuccess();

      if (mounted) {
        // Clean up reCAPTCHA container on web after verification
        if (kIsWeb) {
          try {
            final container = html.window.document.getElementById('recaptcha-container');
            if (container != null) {
              container.style.display = 'none';
              container.innerHtml = '';
            }
          } catch (e) {
            // Ignore errors in cleanup
          }
        }

        // Clear form
        _phoneController.clear();
        _otpController.clear();
        setState(() {
          _verificationId = null;
          _isOtpSent = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number verified successfully'),
            backgroundColor: Color(0xFF4B744F),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      final appStateProvider = context.read<AppStateProvider>();
      String errorMessage;
      
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP code. Please try again.';
          break;
        case 'session-expired':
          errorMessage = 'OTP session expired. Please request a new code.';
          break;
        default:
          errorMessage = 'Failed to verify OTP: ${e.message}';
      }
      
      // Record error in Crashlytics
      await FirebaseService.recordError(
        e,
        StackTrace.current,
        reason: 'Phone OTP verification failed in UI: ${e.code}',
      );
      
      appStateProvider.showError(errorMessage);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Record error in Crashlytics
      await FirebaseService.recordError(
        e,
        StackTrace.current,
        reason: 'Unexpected error verifying phone OTP in UI',
      );
      
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.showError('Failed to verify OTP. Please try again.');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
        });
      }
    }
  }

  // Delete account methods
  Future<void> _sendDeleteAccountOTP() async {
    final carrier = context.read<AuthProvider>().carrierUser;
    if (carrier?.phoneNumber == null || carrier!.phoneNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number is required for account deletion'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate password FIRST for email/password users
    if (!_isOAuthUser()) {
      if (_deletePasswordController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your password first'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Verify password before sending OTP
      try {
        final authProvider = context.read<AuthProvider>();
        final firebaseUser = authProvider.firebaseUser;
        if (firebaseUser?.email == null) {
          throw Exception('User email not found');
        }

        await FirebaseService.reauthenticateUser(
          firebaseUser!.email!,
          _deletePasswordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'wrong-password':
            errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'invalid-credential':
            errorMessage = 'Invalid password. Please try again.';
            break;
          case 'user-mismatch':
            errorMessage = 'User mismatch. Please try again.';
            break;
          case 'user-not-found':
            errorMessage = 'User not found.';
            break;
          default:
            errorMessage = 'Password verification failed: ${e.message ?? e.code}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password verification failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    setState(() {
      _isPhoneVerificationLoading = true;
    });

    try {
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.showLoadingWithMessage('Sending OTP...');

      String phoneNumber = carrier.phoneNumber!.trim();
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+$phoneNumber';
      }

      final verificationId = await FirebaseService.sendPhoneOTP(
        phoneNumber,
        onCodeSent: (String verificationId) {
          if (mounted) {
            setState(() {
              _deleteVerificationId = verificationId;
              _isDeleteOtpSent = true;
            });
          }
        },
      );

      if (!_isDeleteOtpSent) {
        setState(() {
          _deleteVerificationId = verificationId;
          _isDeleteOtpSent = true;
        });
      }

      appStateProvider.showSuccess();

      if (mounted) {
        // Clean up reCAPTCHA container on web after OTP is sent
        if (kIsWeb) {
          try {
            Future.delayed(const Duration(seconds: 2), () {
              final container = html.window.document.getElementById('recaptcha-container');
              if (container != null) {
                container.style.display = 'none';
              }
            });
          } catch (e) {
            // Ignore errors in cleanup
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully. Please check your phone.'),
            backgroundColor: Color(0xFF4B744F),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.showError('Failed to send OTP. Please try again.');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPhoneVerificationLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (!_isDeleteOtpSent || _deleteVerificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your phone number first'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_deleteOtpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the OTP code'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Validate password for email/password users
    if (!_isOAuthUser()) {
      if (_deletePasswordController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password is required for account deletion'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your data, bookings, offers, messages, and Stripe account will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeletingAccount = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final appStateProvider = context.read<AppStateProvider>();
      final carrier = authProvider.carrierUser;

      if (carrier == null) {
        throw Exception('Carrier not found');
      }

      appStateProvider.showLoadingWithMessage('Deleting account...');

      // Verify OTP first
      String phoneNumber = carrier.phoneNumber!.trim();
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+$phoneNumber';
      }

      await FirebaseService.verifyPhoneOTP(
        verificationId: _deleteVerificationId!,
        smsCode: _deleteOtpController.text.trim(),
        phoneNumber: phoneNumber,
        userUid: carrier.uid,
        userRole: UserRole.carrier,
      );

      // Delete account with timeout to prevent hanging
      await FirebaseService.deleteAccount(
        userId: carrier.uid,
        userRole: UserRole.carrier,
        password: _isOAuthUser() ? null : _deletePasswordController.text.trim(),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Account deletion timed out. Please try again.');
        },
      );

      // Clear loading state immediately after successful deletion
      appStateProvider.clearLoading();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Color(0xFF4B744F),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Clear form and state
        _deletePasswordController.clear();
        _deleteOtpController.clear();
        setState(() {
          _deleteVerificationId = null;
          _isDeleteOtpSent = false;
          _isDeletingAccount = false;
        });

        // Clean up reCAPTCHA container on web
        if (kIsWeb) {
          try {
            // Hide reCAPTCHA container
            final container = html.window.document.getElementById('recaptcha-container');
            if (container != null) {
              container.style.display = 'none';
              container.innerHtml = '';
            }
          } catch (e) {
            // Ignore errors in cleanup
            print('Error cleaning up reCAPTCHA: $e');
          }
        }

        // Small delay to ensure UI updates
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Sign out and navigate to welcome screen
        // Wrap in try-catch to handle any errors during sign out
        try {
          await authProvider.signOut();
        } catch (e) {
          // User might already be deleted, ignore sign out errors
          if (AppConfig.enableDebugLogging) {
            print('Error during sign out after account deletion: $e');
          }
        }
        
        // Navigate directly to AuthWrapper which will show welcome screen
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      final appStateProvider = context.read<AppStateProvider>();
      String errorMessage;
      
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP code. Please try again.';
          break;
        case 'session-expired':
          errorMessage = 'OTP session expired. Please request a new code.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        default:
          errorMessage = 'Failed to delete account: ${e.message}';
      }
      
      appStateProvider.clearLoading();
      appStateProvider.showError(errorMessage);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      final appStateProvider = context.read<AppStateProvider>();
      appStateProvider.clearLoading();
      appStateProvider.showError('Failed to delete account. Please try again.');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Always clear loading state, even if there was an error
      if (mounted) {
        try {
          final appStateProvider = context.read<AppStateProvider>();
          appStateProvider.clearLoading();
        } catch (e) {
          // Ignore errors when clearing loading
          if (AppConfig.enableDebugLogging) {
            print('Error clearing loading state: $e');
          }
        }
        
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrier = context.watch<AuthProvider>().carrierUser;
    
    // Update phone controller when carrier data changes
    if (carrier?.phoneNumber != null && _phoneController.text != carrier!.phoneNumber) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _phoneController.text = carrier.phoneNumber!;
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF186230)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF186230),
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: carrier == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Update Password Section (only show for email/password users)
                    if (!_isOAuthUser()) ...[
                      const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF186230),
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      // OAuth User Info Section
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF186230),
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You signed in with ${_getProviderName()}. Password changes are not available for ${_getProviderName()} accounts. To change your password, please manage your account through ${_getProviderName()}.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade900,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],

                    // Password fields (only show for email/password users)
                    if (!_isOAuthUser()) ...[
                      // Current Password
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPassword,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your current password';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          labelStyle: const TextStyle(
                            color: Color(0xFF186230),
                            fontFamily: 'Roboto',
                          ),
                          prefixIcon: const Icon(Icons.lock, color: Color(0xFF186230)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCurrentPassword = !_obscureCurrentPassword;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // New Password
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          if (value == _currentPasswordController.text.trim()) {
                            return 'New password must be different from current password';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle: const TextStyle(
                            color: Color(0xFF186230),
                            fontFamily: 'Roboto',
                          ),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF186230)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (value != _newPasswordController.text.trim()) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          labelStyle: const TextStyle(
                            color: Color(0xFF186230),
                            fontFamily: 'Roboto',
                          ),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF186230)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Update Password Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updatePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43975A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Update Password',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Security Note
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'For security reasons, you must enter your current password to change it.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Phone Verification Section
                    const SizedBox(height: 40),
                    const Text(
                      'Phone Verification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF186230),
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Current phone status
                    if (carrier.phoneNumber != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: carrier.isPhoneVerified 
                              ? Colors.green.shade50 
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: carrier.isPhoneVerified 
                                ? Colors.green.shade200 
                                : Colors.orange.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              carrier.isPhoneVerified 
                                  ? Icons.verified 
                                  : Icons.warning_amber_rounded,
                              color: carrier.isPhoneVerified 
                                  ? Colors.green.shade700 
                                  : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Phone Number: ${carrier.phoneNumber}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: carrier.isPhoneVerified 
                                          ? Colors.green.shade900 
                                          : Colors.orange.shade900,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    carrier.isPhoneVerified 
                                        ? 'Phone number is verified' 
                                        : 'Phone number is not verified',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: carrier.isPhoneVerified 
                                          ? Colors.green.shade700 
                                          : Colors.orange.shade700,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Phone verification form (only show if phone is not verified)
                    if (!carrier.isPhoneVerified) ...[
                      // Phone number input (disabled and auto-filled)
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        enabled: false, // Always disabled - phone number should not be typed
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '+1234567890',
                          labelStyle: const TextStyle(
                            color: Color(0xFF186230),
                            fontFamily: 'Roboto',
                          ),
                          prefixIcon: const Icon(Icons.phone, color: Color(0xFF186230)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          helperText: 'Phone number is auto-filled from your account',
                          helperStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // OTP input (only show after OTP is sent)
                      if (_isOtpSent) ...[
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: 'Enter OTP',
                            hintText: '123456',
                            labelStyle: const TextStyle(
                              color: Color(0xFF186230),
                              fontFamily: 'Roboto',
                            ),
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF186230)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF43975A), width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the OTP';
                            }
                            if (value.length != 6) {
                              return 'OTP must be 6 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Send OTP / Verify OTP Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: (_isPhoneVerificationLoading || _isVerifyingOtp) 
                              ? null 
                              : (_isOtpSent ? _verifyPhoneOTP : _sendPhoneOTP),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43975A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 4,
                          ),
                          child: (_isPhoneVerificationLoading || _isVerifyingOtp)
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  _isOtpSent ? 'Verify OTP' : 'Send OTP',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      // Resend OTP option
                      if (_isOtpSent) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isPhoneVerificationLoading 
                              ? null 
                              : () {
                                  setState(() {
                                    _isOtpSent = false;
                                    _verificationId = null;
                                    _otpController.clear();
                                  });
                                },
                          child: const Text(
                            'Change Phone Number',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              color: Color(0xFF43975A),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Info note
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Enter your phone number with country code (e.g., +1234567890). You will receive an OTP to verify your number.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Delete Account Section
                    const SizedBox(height: 40),
                    const Divider(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _showDeleteAccountSection
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: Colors.red.shade700,
                          ),
                          onPressed: () {
                            setState(() {
                              _showDeleteAccountSection = !_showDeleteAccountSection;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_showDeleteAccountSection) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning, color: Colors.red.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Deleting your account will permanently remove all your data, including bookings, offers, messages, payment information, and your Stripe Connect account. This action cannot be undone.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade900,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password field (only for email/password users)
                      if (!_isOAuthUser()) ...[
                        TextFormField(
                          controller: _deletePasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Enter Password',
                            labelStyle: const TextStyle(
                              color: Color(0xFF186230),
                              fontFamily: 'Roboto',
                            ),
                            prefixIcon: const Icon(Icons.lock, color: Color(0xFF186230)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // OTP section
                      if (!_isDeleteOtpSent) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isPhoneVerificationLoading
                                ? null
                                : _sendDeleteAccountOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 4,
                            ),
                            child: _isPhoneVerificationLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Send OTP to Phone',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _deleteOtpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: 'Enter OTP',
                            hintText: '123456',
                            labelStyle: const TextStyle(
                              color: Color(0xFF186230),
                              fontFamily: 'Roboto',
                            ),
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF186230)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isDeletingAccount ? null : _deleteAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 4,
                            ),
                            child: _isDeletingAccount
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Delete Account',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

