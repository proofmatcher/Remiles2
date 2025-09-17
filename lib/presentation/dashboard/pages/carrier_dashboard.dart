import 'package:flutter/material.dart';

import '../../common/widgets/bottom_navigation_bar.dart';
import '../../common/widgets/recommended_load.dart';
import '../../common/widgets/top_navigation_bar.dart';


class CarrierDashboardScreen extends StatelessWidget {
  const CarrierDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:

      SingleChildScrollView(
        child: Column(
          children: [
            /// Top Navigation Bar
            TopNavigationBar(context),

            const SizedBox(height: 20),

            /// Welcome Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      "Welcome\nChriss ann",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Column(
                    children: const [
                      Icon(Icons.eco, color: Colors.green, size: 32),
                      SizedBox(height: 8),
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.transparent,
                        child: Icon(Icons.person_outline,
                            color: Colors.black, size: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCA4D),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      "Find Loads",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C6B4A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      "\$ Payment",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// Carrier Preferences
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Carrier Preferences",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.filter_list, color: Colors.black),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// Recommended Load Caimport 'package:flutter/material.dart';
            // import 'package:flutter_svg/flutter_svg.dart';
            //
            // class LoadCard extends StatelessWidget {
            //   const LoadCard({super.key});
            //
            //   @override
            //   Widget build(BuildContext context) {
            //     return Card(
            //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            //       elevation: 3,
            //       margin: const EdgeInsets.all(12),
            //       child: Container(
            //         padding: const EdgeInsets.all(16),
            //         decoration: BoxDecoration(
            //           borderRadius: BorderRadius.circular(16),
            //           border: Border.all(color: Colors.green.shade200, width: 2),
            //         ),
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             // Top Row
            //             Row(
            //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //               children: [
            //                 Row(
            //                   children: [
            //                     const Text(
            //                       "\$1500",
            //                       style: TextStyle(
            //                         fontSize: 20,
            //                         fontWeight: FontWeight.bold,
            //                         color: Colors.green,
            //                       ),
            //                     ),
            //                     const SizedBox(width: 12),
            //                     const Text(
            //                       "215 (mi)",
            //                       style: TextStyle(fontSize: 16),
            //                     ),
            //                   ],
            //                 ),
            //                 Container(
            //                   padding:
            //                       const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            //                   decoration: BoxDecoration(
            //                     color: Colors.green,
            //                     borderRadius: BorderRadius.circular(12),
            //                   ),
            //                   child: const Text(
            //                     "Available",
            //                     style: TextStyle(color: Colors.white),
            //                   ),
            //                 ),
            //               ],
            //             ),
            //
            //             const SizedBox(height: 12),
            //
            //             // Route Info
            //             Row(
            //               children: [
            //                 SvgPicture.asset("assets/icons/location.svg",
            //                     width: 18, height: 18, color: Colors.green),
            //                 const SizedBox(width: 8),
            //                 const Text("From : Toronto, ON"),
            //               ],
            //             ),
            //             const SizedBox(height: 6),
            //             Row(
            //               children: [
            //                 SvgPicture.asset("assets/icons/location.svg",
            //                     width: 18, height: 18, color: Colors.green),
            //                 const SizedBox(width: 8),
            //                 const Text("To : Montreal, QC"),
            //                 const Spacer(),
            //                 const Text(
            //                   "Load ID #1234",
            //                   style: TextStyle(fontWeight: FontWeight.bold),
            //                 ),
            //               ],
            //             ),
            //
            //             const SizedBox(height: 12),
            //
            //             // Pickup & Delivery Dates
            //             Row(
            //               children: [
            //                 SvgPicture.asset("assets/icons/calendar.svg",
            //                     width: 18, height: 18, color: Colors.green),
            //                 const SizedBox(width: 8),
            //                 const Text("Pickup : Sep 1st, 2025"),
            //               ],
            //             ),
            //             const SizedBox(height: 6),
            //             Row(
            //               children: [
            //                 SvgPicture.asset("assets/icons/calendar.svg",
            //                     width: 18, height: 18, color: Colors.green),
            //                 const SizedBox(width: 8),
            //                 const Text("Delivery : Sep 3rd, 2025"),
            //                 const Spacer(),
            //                 ElevatedButton(
            //                   onPressed: () {},
            //                   style: ElevatedButton.styleFrom(
            //                     backgroundColor: Colors.green,
            //                     shape: RoundedRectangleBorder(
            //                         borderRadius: BorderRadius.circular(12)),
            //                   ),
            //                   child: const Text("Book Now"),
            //                 ),
            //               ],
            //             ),
            //
            //             const SizedBox(height: 12),
            //             const Divider(),
            //
            //             // Bottom Row
            //             Row(
            //               children: [
            //                 SvgPicture.asset("assets/icons/truck.svg",
            //                     width: 20, height: 20, color: Colors.green),
            //                 const SizedBox(width: 8),
            //                 const Text("15,000 lb"),
            //                 const Spacer(),
            //                 const Text("Equipment Needed: Flatbed"),
            //                 const Spacer(),
            //                 const Text(
            //                   "2 Docs",
            //                   style: TextStyle(
            //                       fontWeight: FontWeight.bold, color: Colors.green),
            //                 ),
            //               ],
            //             ),
            //           ],
            //         ),
            //       ),
            //     );
            //   }
            // }rd
            RecommendedLoad(),

            const SizedBox(height: 20),

            /// View All Button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1CAFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text("View All"),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Stats Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _statCard(Icons.attach_money, "\$2000", "Total Revenue"),
                  _statCard(Icons.check, "50", "Loads Delivered"),
                  _statCard(Icons.card_giftcard, "", "Special Offers"),
                  _statCard(Icons.star, "3.8/5", "Carrier Ratings"),
                ],
              ),
            ),

            const SizedBox(height: 80), // space for bottom nav
          ],
        ),
      ),


    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(

              child: Icon(icon, color: Colors.green, size: 28)),
          const SizedBox(height: 2),
          if (value.isNotEmpty)
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
