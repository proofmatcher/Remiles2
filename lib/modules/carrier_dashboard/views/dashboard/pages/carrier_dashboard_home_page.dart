import 'package:flutter/foundation.dart';
import 'package:remiles/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../../../providers/auth_provider.dart';
import '../../common/widgets/top_navigation_bar.dart';
import '../../common/widgets/recommended_load.dart';
import 'manage_load.dart';
import 'carrier_payment_page.dart';
import 'package:remiles/core/firebase_service.dart';
import 'package:remiles/core/stripe_service.dart';
import 'package:remiles/models/load_model.dart';
import 'package:remiles/models/carrier_model.dart';
import 'dart:io';

class CarrierDashboardHomeScreen extends StatefulWidget {
  const CarrierDashboardHomeScreen({super.key});

  @override
  State<CarrierDashboardHomeScreen> createState() =>
      _CarrierDashboardHomeScreenState();
}

class _CarrierDashboardHomeScreenState
    extends State<CarrierDashboardHomeScreen> {
  final primaryColor = Color(0xFF1C6B4A);

  // State management for recommended loads
  List<LoadModel> _recommendedLoads = [];
  bool _isLoading = false;
  String? _error;

  // Stripe status
  bool _hasStripeAccount = false;
  bool _needsOnboarding = false;
  bool _isCheckingStripe = true;

  // Stats data
  double _totalRevenue = 0.0;
  int _deliveriesCompleted = 0;
  int _specialOffersCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendedLoads();
    _checkStripeStatus();
    _loadStats();
  }

  Future<void> _checkStripeStatus() async {
    try {
      final status = await StripeService.getConnectAccountStatus();
      if (mounted) {
        setState(() {
          _hasStripeAccount = status['hasAccount'] as bool? ?? false;
          _needsOnboarding = status['needsOnboarding'] as bool? ?? false;
          _isCheckingStripe = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking stripe status: $e');
      if (mounted) {
        setState(() {
          _isCheckingStripe = false;
        });
      }
    }
  }

  Future<void> _loadRecommendedLoads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseService.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final result = await FirebaseService.getAvailableLoadsForCarrier(
        carrierUid: user.uid,
        searchQuery: '',
        limit: 1, // Show only top match
      );

      setState(() {
        _recommendedLoads = List<LoadModel>.from(result['loads']);
        _isLoading = false;
      });
    } catch (e) {
      String errorMessage;
      if (e is SocketException ||
          e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your connection.';
      } else {
        errorMessage = 'Failed to load recommended loads.';
      }

      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final user = FirebaseService.currentUser;
      if (user == null) {
        setState(() {
          _isLoadingStats = false;
        });
        return;
      }

      // Load revenue from transfers collection
      double totalRevenue = 0.0;
      try {
        final transfersSnapshot = await FirebaseService.firestore
            .collection('transfers')
            .where('carrierId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed')
            .get();

        for (final doc in transfersSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amountInCents = data['amountInCents'] as int?;
          final amountDollars = data['amount'] as num?;
          
          if (amountInCents != null) {
            totalRevenue += amountInCents / 100.0;
          } else if (amountDollars != null) {
            // If amount is already in dollars and > 1000, assume it's in cents
            if (amountDollars > 1000) {
              totalRevenue += amountDollars.toDouble() / 100.0;
            } else {
              totalRevenue += amountDollars.toDouble();
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading revenue from transfers: $e');
        // Try fallback: get revenue from delivery confirmations
        try {
          final confirmationsSnapshot = await FirebaseService.firestore
              .collection('delivery_confirmations')
              .where('carrierId', isEqualTo: user.uid)
              .where('paymentReleased', isEqualTo: true)
              .get();

          for (final doc in confirmationsSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final paymentAmount = data['paymentAmount'];
            if (paymentAmount != null) {
              if (paymentAmount is num) {
                totalRevenue += paymentAmount.toDouble();
              } else {
                final parsed = double.tryParse(paymentAmount.toString());
                if (parsed != null) {
                  totalRevenue += parsed;
                }
              }
            }
          }
        } catch (e2) {
          debugPrint('Error loading revenue from delivery confirmations: $e2');
        }
      }

      // Load completed deliveries count
      int deliveriesCompleted = 0;
      try {
        final bookedLoads = await FirebaseService.getCarrierBookedLoads(
          carrierUid: user.uid,
          status: 'completed',
          limit: 1000, // Get all completed loads
        );
        deliveriesCompleted = bookedLoads['totalCount'] as int? ?? 
                             (bookedLoads['loads'] as List<LoadModel>?)?.length ?? 0;
      } catch (e) {
        debugPrint('Error loading completed deliveries: $e');
      }

      // Load special offers (recommended loads with good match percentage > 70%)
      int specialOffersCount = 0;
      try {
        final result = await FirebaseService.getAvailableLoadsForCarrier(
          carrierUid: user.uid,
          searchQuery: '',
          limit: 1000, // Get all available loads to count special offers
        );
        
        final allLoads = List<LoadModel>.from(result['loads']);
        specialOffersCount = allLoads
            .where((load) => (load.matchPercentage ?? 0) >= 70.0)
            .length;
      } catch (e) {
        debugPrint('Error loading special offers: $e');
      }

      if (mounted) {
        setState(() {
          _totalRevenue = totalRevenue;
          _deliveriesCompleted = deliveriesCompleted;
          _specialOffersCount = specialOffersCount;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final carrier = authProvider.carrierUser;

        // Use company name if available, otherwise use display name, otherwise fallback to 'User'
        final displayName = carrier?.companyName ?? user?.displayName ?? 'User';

        return _buildDashboard(context, displayName, carrier);
      },
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    String displayName,
    CarrierModel? carrier,
  ) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final bool isWide = screenW >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Fixed Header Section (Top Nav, Welcome, Action Buttons)
            TopNavigationBar(context),

            const SizedBox(height: 20),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 100.0 : 20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Welcome Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            "Welcome\n$displayName",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/eco.svg',
                              width: 50,
                              height: 50,
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 75,
                              height: 65,
                              child:
                                  carrier?.profileImageUrl != null &&
                                      carrier!.profileImageUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        carrier.profileImageUrl!,
                                        width: 75,
                                        height: 65,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return SvgPicture.asset(
                                                'assets/person.svg',
                                                width: 75,
                                                height: 65,
                                              );
                                            },
                                      ),
                                    )
                                  : SvgPicture.asset(
                                      'assets/person.svg',
                                      width: 75,
                                      height: 65,
                                    ),
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ManageLoadScreen(),
                                ),
                              );
                            },
                            child: Container(
                              height: 49,
                              decoration: BoxDecoration(
                                color: yellowColor,
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.66),
                                    spreadRadius: -1,
                                    blurRadius: 3.5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "Find Loads",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CarrierPaymentPage(),
                                ),
                              );
                            },
                            child: Container(
                              height: 51,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.66),
                                    spreadRadius: -1,
                                    blurRadius: 3.5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "\$ Payment",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    // Stripe Onboarding Alert Strip
                    if (!_isCheckingStripe &&
                        (!_hasStripeAccount || _needsOnboarding))
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFBBF7D0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Color(0xFF166534),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: const Text(
                                          'Payment Setup Required',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Color(0xFF166534),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Tooltip(
                                        waitDuration: const Duration(
                                          seconds: 0,
                                        ),
                                        triggerMode: TooltipTriggerMode.tap,
                                        message:
                                            'Setting up your Stripe account is essential to receive payments directly for the loads you deliver. It ensures a secure and automated payout process.',
                                        child: const Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: Color(0xFF166534),
                                        ),
                                      ),
                                    ],
                                  ),

                                  Text(
                                    _hasStripeAccount
                                        ? 'Please complete your payment account activation.'
                                        : 'Please setup your payment account to receive payouts.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CarrierPaymentPage(),
                                  ),
                                ).then((_) => _checkStripeStatus());
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                backgroundColor: const Color(0xFF166534),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _hasStripeAccount ? 'Complete' : 'Setup Now',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    /// Carrier Preferences
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Carrier Preferences",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ManageLoadScreen(),
                              ),
                            );
                          },
                          child: SvgPicture.asset(
                            'assets/filter.svg',
                            width: 24,
                            height: 24,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// Recommended Loads Section (only top match)
                    _buildRecommendedLoadsSection(),
                    const SizedBox(height: 10),

                    /// View All Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManageLoadScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1CAFFF),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Text(
                            "View All",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Stats Grid - Responsive for Web
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: isWide ? 4 : 2,
                      childAspectRatio: isWide ? 1.3 : 1.1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildSummaryCard(
                          icon: Icons.attach_money_outlined,
                          iconBgColor: const Color(0xFFBFF497),
                          iconColor: Colors.black87,
                          value: _isLoadingStats
                              ? '...'
                              : '\$${_totalRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          label: 'Total Revenue',
                          isLoading: _isLoadingStats,
                        ),
                        _buildSummaryCard(
                          icon: Icons.check_circle_outline,
                          iconBgColor: const Color(0xFFFFE0B3),
                          iconColor: Colors.black87,
                          value: _isLoadingStats
                              ? '...'
                              : '$_deliveriesCompleted',
                          label: 'Loads Delivered',
                          isLoading: _isLoadingStats,
                        ),
                        _buildSummaryCard(
                          icon: Icons.card_giftcard,
                          iconBgColor: const Color(0xFFD1E9FF),
                          iconColor: Colors.black87,
                          value: _isLoadingStats
                              ? '...'
                              : '$_specialOffersCount',
                          label: 'Special Offers',
                          isLoading: _isLoadingStats,
                        ),
                        _buildSummaryCard(
                          icon: Icons.star,
                          iconBgColor: const Color(0xFFFEF3C7),
                          iconColor: Colors.amber.shade700,
                          value: _deliveriesCompleted > 0 ? '0/5' : '0/5',
                          label: 'Carrier Ratings',
                        ),
                      ],
                    ),
                    const SizedBox(height: 120), // space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String value,
    required String label,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6CA78A).withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedLoadsSection() {
    if (_isLoading) {
      return const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadRecommendedLoads,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_recommendedLoads.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'No recommended loads available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check back later for new opportunities',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show only the top recommended load (highest match percentage)
    if (_recommendedLoads.isNotEmpty) {
      if (kIsWeb) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: RecommendedLoad(load: _recommendedLoads.first),
        );
      } else {
        return RecommendedLoad(load: _recommendedLoads.first);
      }
    }

    return const SizedBox.shrink();
  }
}
