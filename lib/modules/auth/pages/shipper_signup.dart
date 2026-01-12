import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_state_provider.dart';
import '../../../core/auth_wrapper.dart';
import '../../../core/firebase_service.dart';
import '../../../models/user_model.dart';
import '../../carrier_dashboard/views/dashboard/pages/carrier_dashboard_main_page.dart';
import '../../shipper_dashboard/pages/shipper_dashboard_4_main_page.dart';
import '../../shipper_dashboard/pages/shipper_dashboard_1.dart';
import '../../shipper_onboarding/shipper_onboarding_wrapper.dart';
import 'choose_role.dart';

class ShipperSignUpScreen extends StatefulWidget {
  final VoidCallback? onOnboardingComplete;
  const ShipperSignUpScreen({Key? key, this.onOnboardingComplete})
    : super(key: key);

  @override
  State<ShipperSignUpScreen> createState() => _ShipperSignUpScreenState();
}

class _ShipperSignUpScreenState extends State<ShipperSignUpScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  // Country selection state
  String _selectedCountryKey = 'canada'; // Use unique key instead of code
  String _selectedCountryCode = '+1';
  String _selectedCountryFlag = 'assets/canada_flag.png';

  // Form controllers
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Country data with unique keys
  final List<Map<String, String>> _countries = [
    {
      'key': 'canada',
      'code': '+1',
      'flag': 'assets/canada_flag.png',
      'name': 'Canada',
    },
    // {'key': 'usa', 'code': '+1', 'flag': 'assets/flag.png', 'name': 'United States'},
    // {'key': 'uk', 'code': '+44', 'flag': 'assets/flag.png', 'name': 'United Kingdom'},
    // {'key': 'france', 'code': '+33', 'flag': 'assets/flag.png', 'name': 'France'},
    // {'key': 'germany', 'code': '+49', 'flag': 'assets/flag.png', 'name': 'Germany'},
    // {'key': 'japan', 'code': '+81', 'flag': 'assets/flag.png', 'name': 'Japan'},
    // {'key': 'china', 'code': '+86', 'flag': 'assets/flag.png', 'name': 'China'},
    // {'key': 'india', 'code': '+91', 'flag': 'assets/flag.png', 'name': 'India'},
    {
      'key': 'pakistan',
      'code': '+92',
      'flag': 'assets/flag.png',
      'name': 'Pakistan',
    },
    // {'key': 'australia', 'code': '+61', 'flag': 'assets/flag.png', 'name': 'Australia'},
    // {'key': 'brazil', 'code': '+55', 'flag': 'assets/flag.png', 'name': 'Brazil'},
  ];

  @override
  void initState() {
    super.initState();
    // Clear any previous error messages when navigating to signup page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final appStateProvider = context.read<AppStateProvider>();
      authProvider.clearError();
      appStateProvider.clearError();
    });
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Handle shipper signup
  Future<void> _handleSignup() async {
    print('_handleSignup called');

    // Validate form first
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      print('Terms not agreed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    print('Starting signup process...');
    final authProvider = context.read<AuthProvider>();
    final appStateProvider = context.read<AppStateProvider>();

    appStateProvider.showLoadingWithMessage('Creating your account...');

    try {
      final success = await authProvider.signUpShipper(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        companyName: _companyNameController.text.trim(),
        displayName: _companyNameController.text.trim(),
        phoneNumber: '$_selectedCountryCode${_phoneController.text.trim()}',
      );

      if (success) {
        print('Shipper signup successful, navigating based on user role');
        appStateProvider.showSuccess();
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Redirecting...'),
            backgroundColor: Color(0xFF4B744F),
            duration: Duration(seconds: 2),
          ),
        );

        // Add a small delay to ensure user data is fully loaded
        await Future.delayed(const Duration(milliseconds: 500));

        // Call onboarding completion callback if provided
        widget.onOnboardingComplete?.call();

        // Direct navigation as fallback if AuthWrapper doesn't trigger
        if (context.mounted) {
          await _navigateBasedOnRole(context, authProvider);
        }
      } else {
        print('Shipper signup failed: ${authProvider.errorMessage}');
        appStateProvider.showError(
          authProvider.errorMessage ?? 'Signup failed',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Signup failed. Please try again.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Exception during signup: $e');
      appStateProvider.showError('An error occurred: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Navigate based on user role
  Future<void> _navigateBasedOnRole(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final userRole = authProvider.currentUser?.role;
    print('Shipper Signup: Navigating based on role: $userRole');

    if (userRole == UserRole.shipper) {
      final shipper = authProvider.shipperUser;
      if (shipper != null && shipper.isOnboardingComplete == false) {
        print('Shipper Signup: Navigating to Shipper Onboarding');
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ShipperOnboardingWrapper()),
            (route) => false,
          );
        }
      } else if (shipper != null) {
        // Check if dashboard steps are completed
        print('Shipper Signup: Checking if dashboard steps are completed...');
        final isDashboardComplete =
            await FirebaseService.isShipperDashboardComplete(shipper.uid);
        print('Shipper Signup: Dashboard complete: $isDashboardComplete');

        if (!isDashboardComplete) {
          print('Shipper Signup: Navigating to Shipper Dashboard 1');
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ShipperDashboard1()),
              (route) => false,
            );
          }
        } else {
          print('Shipper Signup: Navigating to Shipper Dashboard Main Page');
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const ShipperDashboardMainPage(),
              ),
              (route) => false,
            );
          }
        }
      } else {
        print('Shipper Signup: No shipper data, navigating to AuthWrapper');
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        }
      }
    } else if (userRole == UserRole.carrier) {
      print('Shipper Signup: Navigating to Carrier Dashboard');
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CarrierDashboardMainPage()),
          (route) => false,
        );
      }
    } else {
      print('Shipper Signup: Role not determined, navigating to AuthWrapper');
      // If role is not determined, navigate to AuthWrapper
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    }
  }

  PageRouteBuilder _createFadePageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Consistent background
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Use a threshold to switch between mobile and web layouts
          if (constraints.maxWidth > 900) {
            return _buildWebView(context);
          } else {
            return _buildMobileView(context);
          }
        },
      ),
    );
  }

  // Builds the split-screen UI for web/large screens
  Widget _buildWebView(BuildContext context) {
    return Row(
      children: [
        // Left side: Branding and inspirational content
        Expanded(flex: 1, child: _buildBrandingPanel()),
        // Right side: The sign-up form
        Expanded(
          flex: 1,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: _buildSignUpForm(1.0, isWeb: true),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Builds the UI for mobile/small screens
  Widget _buildMobileView(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double designW = 456.0;
    const double designH = 952.0;
    final double scale = (screenWidth / designW < screenHeight / designH)
        ? screenWidth / designW
        : screenHeight / designH;

    return SingleChildScrollView(
      child: SizedBox(
        height: screenHeight,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color(0xFFFEFEF6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 40 * scale),
                      SizedBox(
                        width: 150 * scale,
                        height: 150 * scale,
                        child: Image.asset(
                          'assets/remiles.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 10 * scale),
                      Text(
                        'Shipper Sign up',
                        style: TextStyle(
                          fontSize: 24 * scale,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF000000),
                        ),
                      ),
                      SizedBox(height: 31 * scale),
                      Container(
                        width: 330 * scale,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFEF6),
                          borderRadius: BorderRadius.circular(37 * scale),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildMobileInputField(
                                scale: scale,
                                hintText: "Company name or Full name",
                                iconAsset: 'assets/user.png',
                                controller: _companyNameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter company name';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 25 * scale),
                              _buildMobileInputField(
                                scale: scale,
                                hintText: "Email Address",
                                iconAsset: 'assets/email.png',
                                keyboardType: TextInputType.emailAddress,
                                controller: _emailController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter email address';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 25 * scale),
                              _buildMobilePhoneInputField(
                                scale: scale,
                                hintText: "Contact Number",
                                controller: _phoneController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter contact number';
                                  }
                                  if (value.length < 10) {
                                    return 'Please enter a valid phone number';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 25 * scale),
                              _buildMobileInputField(
                                scale: scale,
                                hintText: "Password",
                                iconAsset: 'assets/password.png',
                                obscureText: _obscurePassword,
                                controller: _passwordController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                                onSuffixIconPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              SizedBox(height: 25 * scale),
                              _buildMobileInputField(
                                scale: scale,
                                hintText: "Confirm Password",
                                iconAsset: 'assets/password.png',
                                obscureText: _obscureConfirmPassword,
                                controller: _confirmPasswordController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                                onSuffixIconPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20 * scale),
                      Container(
                        width: 294 * scale,
                        height: 45 * scale,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _agreeToTerms = !_agreeToTerms;
                                });
                              },
                              child: Container(
                                width: 20 * scale,
                                height: 20 * scale,
                                margin: EdgeInsets.only(
                                  right: 8 * scale,
                                  top: 2 * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: _agreeToTerms
                                      ? const Color(0xFF4B744F)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    4 * scale,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF1C6B4A,
                                      ).withOpacity(0.95),
                                      blurRadius: 4,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _agreeToTerms
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14 * scale,
                                      )
                                    : null,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'I have read and agree to the Re-Miles Terms of Service, User Agreement, and Privacy Policy.',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12 * scale,
                                  height: 14 / 12,
                                  color: const Color(0xFF7D8AB0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Error message display
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.errorMessage != null) {
                      return Positioned(
                        bottom: 250 * scale,
                        left: 20 * scale,
                        right: 20 * scale,
                        child: Container(
                          padding: EdgeInsets.all(12 * scale),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8 * scale),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            authProvider.errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14 * scale,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // Back button
                Positioned(
                  top: 50 * scale,
                  left: 10 * scale,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.black,
                      size: 40 * scale,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/leather_up.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Button positioned AFTER the image so it's on top and can receive taps
                Positioned(
                  bottom: 190 * scale,
                  right: 30 * scale,
                  child: Consumer2<AuthProvider, AppStateProvider>(
                    builder: (context, authProvider, appStateProvider, child) {
                      final isEnabled =
                          _agreeToTerms && !authProvider.isLoading;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          print(
                            'Button tapped! isEnabled: $isEnabled, _agreeToTerms: $_agreeToTerms, isLoading: ${authProvider.isLoading}',
                          );
                          if (isEnabled) {
                            _handleSignup();
                          } else {
                            if (!_agreeToTerms) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please agree to the terms and conditions',
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        child: Opacity(
                          opacity: isEnabled ? 1.0 : 0.5,
                          child: Container(
                            width: 110 * scale,
                            height: 55 * scale,
                            decoration: BoxDecoration(
                              image: const DecorationImage(
                                image: AssetImage('assets/signup_button.png'),
                                fit: BoxFit.fill,
                              ),
                              borderRadius: BorderRadius.circular(24.5 * scale),
                            ),
                            child: Align(
                              alignment: Alignment(0, -0.2),
                              child: authProvider.isLoading
                                  ? SizedBox(
                                      width: 20 * scale,
                                      height: 20 * scale,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      "Next",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: const Color(
                                              0xFF1C6B4A,
                                            ).withOpacity(0.95),
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
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

  // Left branding panel for the web view
  Widget _buildBrandingPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF047857), Color(0xFF059669)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative background circles
          Positioned(
            top: 100,
            right: 50,
            child: _buildCircle(60, Colors.white.withOpacity(0.05)),
          ),
          Positioned(
            bottom: 150,
            left: 40,
            child: _buildCircle(40, Colors.white.withOpacity(0.05)),
          ),
          Positioned(
            top: 300,
            left: 100,
            child: _buildCircle(25, Colors.white.withOpacity(0.05)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 60.0,
              vertical: 40.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    const Text(
                      'Re-Miles',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 60),
                    // Hero Text
                    const Text(
                      'Join Thousands of',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const Text(
                      'Successful Shippers',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w300,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFA7F3D0),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Connect with reliable carriers, streamline your logistics, and grow your shipping business with our platform.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Feature points
                    _buildFeaturePoint(
                      Icons.shield_outlined,
                      'Secure & Reliable',
                      'End-to-end encrypted transactions',
                    ),
                    const SizedBox(height: 20),
                    _buildFeaturePoint(
                      Icons.auto_awesome,
                      'Smart Matching',
                      'AI-powered carrier recommendations',
                    ),
                  ],
                ),
                const Spacer(), // Pushes the icon to the bottom
                // Carrier Icon
                Image.asset('assets/shipper_icon.png', height: 320, width: 320),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for decorative circles in branding panel
  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // Helper for feature points in branding panel
  Widget _buildFeaturePoint(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF6EE7B7), size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // The main sign-up form, adapted for both web and mobile
  Widget _buildSignUpForm(double scale, {required bool isWeb}) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isWeb) SizedBox(height: 40 * scale),

          // Back Button for Web
          if (isWeb)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  _createFadePageRoute(const RoleSelectionScreen()),
                ),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                ),
              ),
            ),
          if (isWeb) const SizedBox(height: 24),

          // Header
          Align(
            alignment: isWeb ? Alignment.centerLeft : Alignment.center,
            child: Column(
              crossAxisAlignment: isWeb
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                if (!isWeb)
                  Image.asset(
                    'assets/remiles.png',
                    width: 120 * scale,
                    height: 120 * scale,
                    fit: BoxFit.contain,
                  ),
                Text(
                  'Shipper Signup',
                  style: TextStyle(
                    fontSize: isWeb ? 32 : 24 * scale,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start your shipping journey with us today',
                  style: TextStyle(
                    fontSize: isWeb ? 16 : 14 * scale,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 40 * scale),

          // Form Fields
          _buildInputField(
            scale: scale,
            hintText: "Company name or Full name",
            icon: Icons.person_outline,
            controller: _companyNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter company name';
              }
              return null;
            },
          ),
          SizedBox(height: 25 * scale),
          _buildInputField(
            scale: scale,
            hintText: "Email Address",
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter email address';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 25 * scale),
          _buildPhoneInputField(
            scale: scale,
            controller: _phoneController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter contact number';
              }
              if (value.length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          SizedBox(height: 25 * scale),
          _buildInputField(
            scale: scale,
            hintText: "Password",
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            isPassword: true,
            controller: _passwordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            onSuffixIconPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          SizedBox(height: 25 * scale),
          _buildInputField(
            scale: scale,
            hintText: "Confirm Password",
            icon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            isPassword: true,
            controller: _confirmPasswordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            onSuffixIconPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
          SizedBox(height: 25 * scale),

          // Terms and Conditions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _agreeToTerms = !_agreeToTerms;
                  });
                },
                child: Container(
                  width: isWeb ? 20 : 20 * scale,
                  height: isWeb ? 20 : 20 * scale,
                  margin: EdgeInsets.only(
                    right: isWeb ? 12 : 8 * scale,
                    top: isWeb ? 2 : 2 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: _agreeToTerms
                        ? (isWeb
                              ? const Color(0xFF4B744F)
                              : const Color(0xFF4B744F))
                        : Colors.white,
                    borderRadius: BorderRadius.circular(isWeb ? 4 : 4 * scale),
                    border: Border.all(
                      color: _agreeToTerms
                          ? (isWeb
                                ? const Color(0xFF4B744F)
                                : const Color(0xFF4B744F))
                          : (isWeb
                                ? const Color(0xFFD1D5DB)
                                : const Color(0xFFD1D5DB)),
                      width: isWeb ? 2 : 2,
                    ),
                    boxShadow: !isWeb
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1C6B4A).withOpacity(0.95),
                              blurRadius: 4,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: _agreeToTerms
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: isWeb ? 14 : 14 * scale,
                        )
                      : null,
                ),
              ),
              Expanded(
                child: Text(
                  'I have read and agree to the Re-Miles Terms of Service, User Agreement, and Privacy Policy.',
                  style: TextStyle(
                    fontSize: isWeb ? 14 : 12 * scale,
                    color: isWeb
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF7D8AB0),
                    height: isWeb ? 1.4 : 14 / 12,
                    fontWeight: isWeb ? FontWeight.normal : FontWeight.w700,
                    fontFamily: !isWeb ? 'Roboto' : null,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 40 * scale),

          // Submit Button
          Consumer2<AuthProvider, AppStateProvider>(
            builder: (context, authProvider, appStateProvider, child) {
              return ElevatedButton(
                onPressed: _agreeToTerms && !authProvider.isLoading
                    ? _handleSignup
                    : null,
                style:
                    ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      elevation: 2,
                    ).copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled))
                            return Colors.grey;
                          return const Color(0xFF059669);
                        },
                      ),
                    ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Create Account"),
              );
            },
          ),
          const SizedBox(height: 24),

          // Error message display
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.errorMessage != null) {
                return Container(
                  padding: EdgeInsets.all(12 * scale),
                  margin: EdgeInsets.symmetric(vertical: 8 * scale),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8 * scale),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    authProvider.errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14 * scale,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Already have an account link
          // Center(
          //   child: Text.rich(
          //     TextSpan(
          //       text: 'Already have an account? ',
          //       style: TextStyle(color: Colors.grey[600]),
          //       children: [
          //         TextSpan(
          //           text: 'Contact support to sign in',
          //           style: const TextStyle(
          //             color: Color(0xFF059669),
          //             fontWeight: FontWeight.bold,
          //           ),
          //           recognizer: TapGestureRecognizer()..onTap = () {
          //             // Handle tap
          //           },
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          if (!isWeb)
            SizedBox(height: 220 * scale), // Padding for bottom image on mobile
        ],
      ),
    );
  }

  // Updated input field with modern styling
  Widget _buildInputField({
    required double scale,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onSuffixIconPressed,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: onSuffixIconPressed,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[500]!, width: 2),
        ),
        errorStyle: TextStyle(fontSize: 12 * scale, color: Colors.red[700]),
        hintStyle: TextStyle(fontSize: 14 * scale, color: Colors.grey[400]),
      ),
      style: TextStyle(fontSize: 14 * scale, color: Colors.black),
    );
  }

  // Updated phone input field with country code dropdown
  Widget _buildPhoneInputField({
    required double scale,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Country dropdown
          _buildCountryDropdown(scale),
          const SizedBox(width: 12),
          // Phone number input
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.phone,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: validator,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: "Contact Number",
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                errorStyle: const TextStyle(fontSize: 12),
                hintStyle: TextStyle(
                  fontSize: 14 * scale,
                  color: Colors.grey[400],
                ),
              ),
              style: TextStyle(fontSize: 14 * scale, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile input field matching carrier signup style
  Widget _buildMobileInputField({
    required double scale,
    required String hintText,
    required String iconAsset,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onSuffixIconPressed,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return Container(
      width: 314 * scale,
      height: 60 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10 * scale),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C6B4A).withOpacity(0.95),
            blurRadius: 3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10 * scale),
        child: Row(
          children: [
            Image.asset(
              iconAsset,
              width: 15.71 * scale,
              height: 18 * scale,
              color: const Color(0x40000000),
            ),
            SizedBox(width: 10 * scale),
            Expanded(
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                inputFormatters: keyboardType == TextInputType.phone
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: validator,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 16 * scale,
                    color: const Color(0x40000000),
                  ),
                ),
                style: TextStyle(
                  fontSize: 16 * scale,
                  color: const Color(0xFF000000),
                ),
              ),
            ),
            if (onSuffixIconPressed != null)
              IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                  size: 24 * scale,
                ),
                onPressed: onSuffixIconPressed,
              ),
          ],
        ),
      ),
    );
  }

  // Mobile phone input field matching carrier signup style
  Widget _buildMobilePhoneInputField({
    required double scale,
    required String hintText,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return Container(
      width: 314 * scale,
      height: 60 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10 * scale),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C6B4A).withOpacity(0.95),
            blurRadius: 3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10 * scale),
        child: Row(
          children: [
            // Country dropdown for mobile
            _buildMobileCountryDropdown(scale),
            SizedBox(width: 10 * scale),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: validator,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 16 * scale,
                    color: const Color(0x40000000),
                  ),
                ),
                style: TextStyle(
                  fontSize: 16 * scale,
                  color: const Color(0xFF000000),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile country dropdown
  Widget _buildMobileCountryDropdown(double scale) {
    return Container(
      height: 40 * scale,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountryKey,
          isExpanded: false,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: const Color(0xFF6B7280),
            size: 20 * scale,
          ),
          style: TextStyle(
            fontSize: 14 * scale,
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w500,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCountryKey = newValue;
                final selectedCountry = _countries.firstWhere(
                  (country) => country['key'] == newValue,
                );
                _selectedCountryCode = selectedCountry['code']!;
                _selectedCountryFlag = selectedCountry['flag']!;
              });
            }
          },
          items: _countries.map<DropdownMenuItem<String>>((
            Map<String, String> country,
          ) {
            return DropdownMenuItem<String>(
              value: country['key'],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    country['flag']!,
                    width: 20 * scale,
                    height: 14 * scale,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 20 * scale,
                        height: 14 * scale,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2 * scale),
                        ),
                        child: Icon(
                          Icons.flag,
                          size: 12 * scale,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 6 * scale),
                  Text(
                    country['code']!,
                    style: TextStyle(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          selectedItemBuilder: (BuildContext context) {
            return _countries.map<Widget>((Map<String, String> country) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    _selectedCountryFlag,
                    width: 20 * scale,
                    height: 14 * scale,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 20 * scale,
                        height: 14 * scale,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2 * scale),
                        ),
                        child: Icon(
                          Icons.flag,
                          size: 12 * scale,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 6 * scale),
                  Text(
                    _selectedCountryCode,
                    style: TextStyle(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }

  // Country dropdown for shipper signup
  Widget _buildCountryDropdown(double scale) {
    return Container(
      height: 40 * scale,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountryKey,
          isExpanded: false,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: const Color(0xFF6B7280),
            size: 20 * scale,
          ),
          style: TextStyle(
            fontSize: 14 * scale,
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w500,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCountryKey = newValue;
                final selectedCountry = _countries.firstWhere(
                  (country) => country['key'] == newValue,
                );
                _selectedCountryCode = selectedCountry['code']!;
                _selectedCountryFlag = selectedCountry['flag']!;
              });
            }
          },
          items: _countries.map<DropdownMenuItem<String>>((
            Map<String, String> country,
          ) {
            return DropdownMenuItem<String>(
              value: country['key'],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    country['flag']!,
                    width: 20 * scale,
                    height: 14 * scale,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 20 * scale,
                        height: 14 * scale,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2 * scale),
                        ),
                        child: Icon(
                          Icons.flag,
                          size: 12 * scale,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 6 * scale),
                  Text(
                    country['code']!,
                    style: TextStyle(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          selectedItemBuilder: (BuildContext context) {
            return _countries.map<Widget>((Map<String, String> country) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    _selectedCountryFlag,
                    width: 20 * scale,
                    height: 14 * scale,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 20 * scale,
                        height: 14 * scale,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2 * scale),
                        ),
                        child: Icon(
                          Icons.flag,
                          size: 12 * scale,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 6 * scale),
                  Text(
                    _selectedCountryCode,
                    style: TextStyle(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
