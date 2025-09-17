import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:majh/presentation/dashboard/pages/carrier_dashboard.dart';
import 'package:majh/presentation/dashboard/pages/main_page.dart';

class CarrierOnboarding7Screen extends StatelessWidget {
  const CarrierOnboarding7Screen({super.key});
  PageRouteBuilder _createFadePageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions to apply proportional scaling
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double designW = 456.0;
    const double designH = 952.0;
    final double scale = (screenWidth / designW < screenHeight / designH)
        ? screenWidth / designW
        : screenHeight / designH;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              // Main background and content
              Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFFFEFEF6),
              ),

              // Re-miles logo at the top
              Positioned(
                top: 50 * scale,
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset(
                    'assets/remiles.png',
                    width: 206 * scale,
                    height: 206 * scale,
                  ),
                ),
              ),

              // Title text with underline
              Positioned(
                top: 251 * scale,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Thanks for sharing!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          letterSpacing: -1,
                          fontSize: 30 * scale,
                          fontWeight: FontWeight.w800, // Replaced FontWeight.bold with w800
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF000000),
                        ),
                      ),

                      // Green divider line under the title
                      SizedBox(height: 18 * scale),
                      Container(
                        width: 324 * scale,
                        height: 4 * scale,
                        decoration: BoxDecoration(
                          color: const Color(0xFF113F29).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8 * scale),
                        ),
                      ),

                      SizedBox(height: 22 * scale),

                    ],
                  ),
                ),
              ),

              // Body text
              Positioned(
                top: 331 * scale,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 388 * scale,
                    child: Text(
                      'Based on your responses, Re-Miles can help streamline your operations, reduce hassles, and connect you with better opportunities, all in one easy-to-use app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16 * scale,
                        color: const Color(0xFF0B0B0B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Here's how section, aligned left with the check icons
              Positioned(
                top: 448 * scale,
                left: 45 * scale, // Aligned with the _buildFeaturePoint left padding
                child: Text(
                  'Here’s how:',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B0B0B),
                  ),
                ),
              ),

              // Bullet points
              _buildFeaturePoint(scale, [
                TextSpan(
                  text: 'Find loads that match your truck type',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' to save time searching for suitable jobs',
                ),
              ], 479 * scale),
              _buildFeaturePoint(scale, [
                TextSpan(
                  text: 'Reduce empty miles and increase revenue',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' by optimizing your routes.',
                ),
              ], 532 * scale),
              _buildFeaturePoint(scale, [
                TextSpan(
                  text: 'Secure timely payments from verified shippers',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' for peace of mind and financial stability.',
                ),
              ], 583 * scale),

              // Next button
              Positioned(
                top: 677 * scale,
                left: 287 * scale,
                child: GestureDetector(
                  onTap: () {
                    // TODO: Add navigation to the next screen (e.g., home screen)
                    Navigator.push(
                      context,
                      _createFadePageRoute( MainPage()),
                    );
                  },
                  child: Container(
                    width: 110 * scale,
                    height: 55 * scale,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/signup_button.png'),
                        fit: BoxFit.fill,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(24.5)),
                    ),
                    child: Align(
                      alignment: const Alignment(0, -0.2),
                      child: Text(
                        "Next",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(
                              color: Color.fromRGBO(0, 0, 0, 0.3),
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom image positioned to touch the bottom and side edges
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/leather_up.png',
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePoint(double scale, List<TextSpan> spans, double top) {
    return Positioned(
      top: top,
      left: 45 * scale,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, color: Colors.black, size: 24 * scale),
          SizedBox(width: 10 * scale),
          Container(
            width: 311 * scale,
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16 * scale,
                  color: const Color(0xFF000000),
                ),
                children: spans,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
