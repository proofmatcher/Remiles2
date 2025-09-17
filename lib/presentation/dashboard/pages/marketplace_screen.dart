import 'package:flutter/material.dart';
import 'package:majh/presentation/common/widgets/custom_progress_bar.dart';
import 'package:majh/presentation/common/widgets/top_navigation_bar.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  // Colors chosen to visually match the screenshot.
  static const Color green = Color(0xFF2E9340);
  static const Color blue = Color(0xFF2265A6);
  static const Color trackGray = Color(0xFFE5E5E5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // screenshot background is dark/black
      body: SafeArea(
        child: Column(
          children: [
            // Top bar without padding
            TopNavigationBar(context),

            // Rest of the content with padding + scroll
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18.0,
                  vertical: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0, bottom: 20),
                        child: Text(
                          "Load ID #1234",
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.2,
                          ),
                        ),
                      ),

                      // --- Top status pills ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatusPill(label: "En Route", color: green),
                          _StatusPill(label: "Pickup", color: green),
                          _StatusPill(label: "In Transit", color: blue),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // --- Big map/image placeholder ---
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- Progress bar with percent on right ---
                      CustomProgressBar(value: 0.75), // 75%

                      const SizedBox(height: 24),

                      // --- Shipper row ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shipper / Pickup / Delivery column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Shipper card
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: green, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: green.withOpacity(0.18),
                                        blurRadius: 4,
                                        spreadRadius: 0.5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Shipper",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "John Smith\n(123) 456 - 7890",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Pickup card
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Pickup",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "123 Elm St, Moncton, NB",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Call & Chat buttons
                          Column(
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.phone_rounded),
                                color: Colors.grey.shade400,
                                iconSize: 30,
                              ),
                              const SizedBox(height: 6),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.chat_bubble_outline_rounded),
                                color: Colors.grey.shade400,
                                iconSize: 30,
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 40), // instead of Spacer()

                      // bottom row with confirm button
                      Row(
                        children: [
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: Colors.black45,
                            ),
                            child: const Text(
                              "Confirm Load\nDelivery",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status pill widget with border and slight shadow to match screenshot.
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      // pill width flexible but consistent
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.6), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}
