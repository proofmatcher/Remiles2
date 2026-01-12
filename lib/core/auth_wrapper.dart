import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/notification_provider.dart';
import '../modules/auth/pages/login_screen.dart';
import '../modules/auth/pages/welcome.dart';
import '../modules/auth/pages/joiningoption.dart';
import '../modules/shipper_dashboard/pages/shipper_dashboard_4_main_page.dart';
import '../modules/shipper_dashboard/pages/shipper_dashboard_1.dart';
import '../modules/carrier_onboarding/carrier_onboarding_wrapper.dart';
import '../modules/shipper_onboarding/shipper_onboarding_wrapper.dart';
import '../modules/carrier_dashboard/views/dashboard/pages/carrier_dashboard_1.dart';
import '../modules/carrier_dashboard/views/dashboard/pages/carrier_dashboard_main_page.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    // Listen for auth state changes and initialize user data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _authProvider = context.read<AuthProvider>();
      await _authProvider.initialize(); // Initialize the auth provider
      _authProvider.addListener(_onAuthStateChanged);
      _onAuthStateChanged(); // Initial check
    });
  }

  @override
  void dispose() {
    // Use the stored reference instead of context.read
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() async {
    if (!mounted) return; // Prevent navigation if widget is disposed

    print(
      'AuthWrapper: Auth state changed - isLoggedIn: ${_authProvider.isLoggedIn}, firebaseUser: ${_authProvider.firebaseUser?.uid}',
    );

    final userProvider = context.read<UserProvider>();

    // Check for Firebase user (even if Firestore data doesn't exist yet - e.g., new Google Sign-In users)
    if (_authProvider.firebaseUser != null) {
      // User is logged in via Firebase Auth, now fetch their app-specific data
      print('AuthWrapper: currentUser is ${_authProvider.currentUser?.role}');
      if (_authProvider.currentUser == null) {
        // If currentUser is not yet loaded, try to load it
        print('AuthWrapper: Loading user data...');
        try {
          await userProvider.loadCurrentUser();

          // Update AuthProvider with the loaded user data
          if (userProvider.currentUser != null) {
            print(
              'AuthWrapper: User data loaded successfully: ${userProvider.currentUser?.role}',
            );
            _authProvider.setUserData(
              _authProvider.firebaseUser,
              userProvider.currentUser,
            );
          } else {
            print(
              'AuthWrapper: No user data found in UserProvider - this might be a new user',
            );
            // Don't sign out - this could be a new Google Sign-In user who needs role selection
            // Keep the Firebase user authenticated
          }
        } catch (e) {
          print('AuthWrapper: Error fetching user data: $e');
          debugPrint('Error fetching user data in AuthWrapper: $e');
          // Don't sign out automatically - user might be in the role selection flow
          // Only sign out if it's a critical error
        }
      } else {
        // Firebase user exists but no Firestore data - could be new user
        print(
          'AuthWrapper: Firebase user exists but no Firestore data - likely new user',
        );
        // Don't navigate away - let the current flow (e.g., role selection) continue
      }

      // Initialize notification provider when user logs in
      if (_authProvider.firebaseUser != null) {
        try {
          final notificationProvider = context.read<NotificationProvider>();
          notificationProvider.initialize(_authProvider.firebaseUser!.uid);
        } catch (e) {
          debugPrint('Error initializing notification provider: $e');
        }
      }

      // Navigate based on role
      print(
        'AuthWrapper: Navigating based on role: ${_authProvider.currentUser?.role}',
      );
      if (_authProvider.currentUser?.role == UserRole.shipper) {
        // Check if shipper needs onboarding
        final shipper = _authProvider.shipperUser;
        print('AuthWrapper: Shipper data: ${shipper?.toString()}');
        if (shipper != null) {
          // Check both the flag and actual onboarding data
          final isOnboardingComplete = shipper.isOnboardingComplete;
          print(
            'AuthWrapper: Shipper isOnboardingComplete flag: $isOnboardingComplete',
          );
          print(
            'AuthWrapper: Shipper onboarding data: ${shipper.onboardingData?.toString()}',
          );

          if (!isOnboardingComplete) {
            print('AuthWrapper: Navigating to Shipper Onboarding Wrapper');
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const ShipperOnboardingWrapper(),
                ),
                (route) => false,
              );
            }
          } else {
            // Check if dashboard steps are completed
            print('AuthWrapper: Checking if dashboard steps are completed...');
            final isDashboardComplete =
                await FirebaseService.isShipperDashboardComplete(shipper.uid);
            print('AuthWrapper: Dashboard complete: $isDashboardComplete');

            if (!isDashboardComplete) {
              print('AuthWrapper: Navigating to Shipper Dashboard 1');
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const ShipperDashboard1()),
                  (route) => false,
                );
              }
            } else {
              print('AuthWrapper: Navigating to Shipper Dashboard Main Page');
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const ShipperDashboardMainPage(),
                  ),
                  (route) => false,
                );
              }
            }
          }
        } else {
          print('AuthWrapper: No shipper data found, navigating to login');
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      } else if (_authProvider.currentUser?.role == UserRole.carrier) {
        final carrier = _authProvider.carrierUser;
        if (carrier != null && carrier.isOnboardingComplete == false) {
          print('AuthWrapper: Navigating to Carrier Onboarding Wrapper');
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const CarrierOnboardingWrapper(),
              ),
              (route) => false,
            );
          }
        } else if (carrier != null) {
          // Check if dashboard steps are completed
          print(
            'AuthWrapper: Checking if carrier dashboard steps are completed...',
          );
          final isDashboardComplete =
              await FirebaseService.isCarrierDashboardComplete(carrier.uid);
          print(
            'AuthWrapper: Carrier dashboard complete: $isDashboardComplete',
          );

          if (!isDashboardComplete) {
            print('AuthWrapper: Navigating to Carrier Dashboard 1');
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CarrierDashboard1()),
                (route) => false,
              );
            }
          } else {
            print('AuthWrapper: Navigating to Carrier Main Page');
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const CarrierDashboardMainPage(),
                ),
                (route) => false,
              );
            }
          }
        } else {
          print('AuthWrapper: No carrier data found, navigating to login');
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      } else {
        // If role is not determined or invalid, go to login
        print('AuthWrapper: Role not determined, navigating to Login');
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } else {
      // User is not authenticated, show welcome screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const WelcomeScreen(
              nextScreen: SignScreen(nextScreen: LoginScreen()),
            ),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a simple loading screen while determining auth state
    return const LoadingScreen(message: 'Loading...');
  }
}

// Loading screen widget
class LoadingScreen extends StatelessWidget {
  final String? message;

  const LoadingScreen({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEF6),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/remiles.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4B744F)),
            ),

            if (message != null) ...[
              const SizedBox(height: 20),
              Text(
                message!,
                style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Error screen widget
class ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorScreen({Key? key, required this.error, this.onRetry})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEF6),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Color(0xFFE53E3E),
              ),
              const SizedBox(height: 20),

              // Error message
              Text(
                'Something went wrong',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              Text(
                error,
                style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Retry button
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B744F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
