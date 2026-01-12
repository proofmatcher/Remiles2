import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../core/auth_wrapper.dart';
import '../../models/user_model.dart';
import '../shipper_dashboard/pages/shipper_dashboard_4_main_page.dart';
import 'carrier_onboarding_wrapper.dart';

class CarrierSignUpScreen extends StatefulWidget {
  final VoidCallback? onOnboardingComplete;
  const CarrierSignUpScreen({Key? key, this.onOnboardingComplete})
    : super(key: key);

  @override
  State<CarrierSignUpScreen> createState() => _CarrierSignUpScreenState();
}

class _CarrierSignUpScreenState extends State<CarrierSignUpScreen> {
  // State for password visibility
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

  // Handle carrier signup
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final appStateProvider = context.read<AppStateProvider>();

    try {
      appStateProvider.showLoadingWithMessage('Creating your account...');

      final success = await authProvider.signUpCarrier(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        companyName: _companyNameController.text.trim(),
        displayName: _companyNameController.text.trim(),
        phoneNumber: '$_selectedCountryCode${_phoneController.text.trim()}',
      );

      if (success) {
        appStateProvider.showSuccess();
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Redirecting...'),
            backgroundColor: Color(0xFF4B744F),
            duration: Duration(seconds: 2),
          ),
        );

        print('Carrier signup successful, navigating based on user role');

        // Add a small delay to ensure user data is fully loaded
        await Future.delayed(const Duration(milliseconds: 500));

        // Call onboarding completion callback if provided
        widget.onOnboardingComplete?.call();

        // Direct navigation as fallback if AuthWrapper doesn't trigger
        if (context.mounted) {
          _navigateBasedOnRole(context, authProvider);
        }
      } else {
        print('Carrier signup failed: ${authProvider.errorMessage}');
        appStateProvider.showError(
          authProvider.errorMessage ?? 'Signup failed',
        );
      }
    } catch (e) {
      // Stop loading and show error for any unexpected errors
      print('Carrier signup error: $e');
      appStateProvider.showError(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Navigate based on user role
  void _navigateBasedOnRole(BuildContext context, AuthProvider authProvider) {
    final userRole = authProvider.currentUser?.role;
    print('Carrier Signup: Navigating based on role: $userRole');

    if (userRole == UserRole.shipper) {
      print('Carrier Signup: Navigating to Shipper Dashboard');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ShipperDashboardMainPage()),
        (route) => false,
      );
    } else if (userRole == UserRole.carrier) {
      print('Carrier Signup: Navigating to Carrier Onboarding Wrapper');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CarrierOnboardingWrapper()),
        (route) => false,
      );
    } else {
      print('Carrier Signup: Role not determined, navigating to AuthWrapper');
      // If role is not determined, navigate to AuthWrapper
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isWeb = kIsWeb;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;

    if (isWeb && isDesktop) {
      return _buildWebDesktopLayout(context, screenWidth, screenHeight);
    } else if (isWeb && isTablet) {
      return _buildWebTabletLayout(context, screenWidth, screenHeight);
    } else {
      return _buildMobileLayout(context, screenWidth, screenHeight);
    }
  }

  Widget _buildWebDesktopLayout(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return Scaffold(
      body: Row(
        children: [
          // Left side - Welcome section with gradient background
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4B744F),
                    Color(0xFF6B8E6F),
                    Color(0xFF8BA88F),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Decorative elements
                  Positioned(
                    top: 100,
                    left: 50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 150,
                    right: 80,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // Main content
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(60.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1C6B4A,
                                  ).withOpacity(0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/remiles.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Welcome text
                          const Text(
                            'Welcome to\nRe-Miles',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Join our network of trusted carriers and start your journey with us today.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Feature highlights
                          _buildFeatureItem(
                            '✓',
                            'Secure and reliable platform',
                          ),
                          const SizedBox(height: 15),
                          _buildFeatureItem('✓', 'Easy onboarding process'),
                          const SizedBox(height: 15),
                          _buildFeatureItem('✓', '24/7 customer support'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right side - Sign up form
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFFFEFEF6),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(60.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Back button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.black,
                                size: 32,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Title
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF000000),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sign up to get started',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF7D8AB0),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          // Form fields
                          _buildWebInputField(
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
                          const SizedBox(height: 20),
                          _buildWebInputField(
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
                          const SizedBox(height: 20),
                          _buildWebPhoneInputField(
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
                          const SizedBox(height: 20),
                          _buildWebInputField(
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
                          const SizedBox(height: 20),
                          _buildWebInputField(
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
                          const SizedBox(height: 25),
                          _buildWebTermsCheckbox(),
                          const SizedBox(height: 25),
                          // Error message display
                          Consumer2<AuthProvider, AppStateProvider>(
                            builder:
                                (
                                  context,
                                  authProvider,
                                  appStateProvider,
                                  child,
                                ) {
                                  final error =
                                      authProvider.errorMessage ??
                                      appStateProvider.errorMessage;
                                  if (error != null) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 20,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.red.shade200,
                                          ),
                                        ),
                                        child: Text(
                                          error,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                          ),
                          const SizedBox(height: 10),
                          // Sign up button
                          _buildWebSignUpButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTabletLayout(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4B744F), Color(0xFFFEFEF6)],
            stops: [0.3, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              children: [
                // Header section
                Container(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1C6B4A).withOpacity(0.95),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/remiles.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome to Re-Miles',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Form section
                Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEFEF6),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1C6B4A).withOpacity(0.95),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000000),
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildWebInputField(
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
                        const SizedBox(height: 20),
                        _buildWebInputField(
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
                        const SizedBox(height: 20),
                        _buildWebPhoneInputField(
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
                        const SizedBox(height: 20),
                        _buildWebInputField(
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
                        const SizedBox(height: 20),
                        _buildWebInputField(
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
                        const SizedBox(height: 25),
                        _buildWebTermsCheckbox(),
                        const SizedBox(height: 25),
                        // Error message display
                        Consumer2<AuthProvider, AppStateProvider>(
                          builder:
                              (context, authProvider, appStateProvider, child) {
                                final error =
                                    authProvider.errorMessage ??
                                    appStateProvider.errorMessage;
                                if (error != null) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.red.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        error,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                        ),
                        const SizedBox(height: 10),
                        _buildWebSignUpButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    const double designW = 456.0;
    const double designH = 952.0;
    final double scale = (screenWidth / designW < screenHeight / designH)
        ? screenWidth / designW
        : screenHeight / designH;

    return Scaffold(
      body: SingleChildScrollView(
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
                          'Carrier Sign up',
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
                                _buildInputField(
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
                                _buildInputField(
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
                                _buildPhoneInputField(
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
                                _buildInputField(
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
                                _buildInputField(
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
                  !kIsWeb
                      ? Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Image.asset(
                            'assets/leather_up.png',
                            fit: BoxFit.cover,
                          ),
                        )
                      : const SizedBox.shrink(),
                  Positioned(
                    bottom: 190 * scale,
                    right: 30 * scale,
                    child: Consumer2<AuthProvider, AppStateProvider>(
                      builder:
                          (context, authProvider, appStateProvider, child) {
                            return GestureDetector(
                              onTap: _handleSignup,
                              child: Container(
                                width: 110 * scale,
                                height: 55 * scale,
                                decoration: BoxDecoration(
                                  image: const DecorationImage(
                                    image: AssetImage(
                                      'assets/signup_button.png',
                                    ),
                                    fit: BoxFit.fill,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    24.5 * scale,
                                  ),
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
                            );
                          },
                    ),
                  ),
                  // Error message display
                  Consumer2<AuthProvider, AppStateProvider>(
                    builder: (context, authProvider, appStateProvider, child) {
                      final error =
                          authProvider.errorMessage ??
                          appStateProvider.errorMessage;
                      if (error != null) {
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
                              error,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebInputField({
    required String hintText,
    required String iconAsset,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onSuffixIconPressed,
    List<TextInputFormatter>? inputFormatters,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C6B4A).withOpacity(0.95),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Image.asset(
              iconAsset,
              width: 20,
              height: 20,
              color: const Color(0xFF6B7280),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: validator,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF111827)),
              ),
            ),
            if (onSuffixIconPressed != null)
              IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF6B7280),
                  size: 20,
                ),
                onPressed: onSuffixIconPressed,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebPhoneInputField({
    required String hintText,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C6B4A).withOpacity(0.95),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Country dropdown
            _buildCountryDropdown(),
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
                  hintText: hintText,
                  border: InputBorder.none,
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                style: const TextStyle(fontSize: 16, color: Color(0xFF111827)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountryKey,
          isExpanded: false,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF6B7280),
            size: 20,
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF111827),
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
                    width: 20,
                    height: 14,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 20,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Icon(
                          Icons.flag,
                          size: 12,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    country['code']!,
                    style: const TextStyle(
                      fontSize: 14,
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
                    width: 20,
                    height: 14,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 20,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Icon(
                          Icons.flag,
                          size: 12,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedCountryCode,
                    style: const TextStyle(
                      fontSize: 14,
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

  Widget _buildWebTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _agreeToTerms = !_agreeToTerms;
            });
          },
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              color: _agreeToTerms ? const Color(0xFF4B744F) : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _agreeToTerms
                    ? const Color(0xFF4B744F)
                    : const Color(0xFFD1D5DB),
                width: 2,
              ),
            ),
            child: _agreeToTerms
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _agreeToTerms = !_agreeToTerms;
              });
            },
            child: const Text(
              'I have read and agree to the Re-Miles Terms of Service, User Agreement, and Privacy Policy.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebSignUpButton() {
    return Consumer2<AuthProvider, AppStateProvider>(
      builder: (context, authProvider, appStateProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4B744F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: authProvider.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(String icon, String text) {
    return Row(
      children: [
        Text(
          icon,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
      ],
    );
  }

  // Helper method to build a standardized input field
  Widget _buildInputField({
    required double scale,
    required String hintText,
    required String iconAsset,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onSuffixIconPressed,
    List<TextInputFormatter>? inputFormatters,
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
                inputFormatters: inputFormatters,
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

  // Helper method for the phone number field with flag and country code
  Widget _buildPhoneInputField({
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
}
