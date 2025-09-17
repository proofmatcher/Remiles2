import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:majh/presentation/common/widgets/booked_now.dart';

class LoadCardInfo extends StatelessWidget {
  const LoadCardInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade200, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      "\$1500",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "215 (mi)",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Available",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Route Info
            Row(
              children: [
                SvgPicture.asset("assets/icons/location.svg",
                    width: 18, height: 18, color: Colors.green),
                const SizedBox(width: 8),
                const Text("From : Toronto, ON"),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                SvgPicture.asset("assets/icons/location.svg",
                    width: 18, height: 18, color: Colors.green),
                const SizedBox(width: 8),
                const Text("To : Montreal, QC"),
                const Spacer(),
                const Text(
                  "Load ID #1234",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Pickup & Delivery Dates
            Row(
              children: [
                SvgPicture.asset("assets/icons/calendar.svg",
                    width: 18, height: 18, color: Colors.green),
                const SizedBox(width: 8),
                const Text("Pickup : Sep 1st, 2025"),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                SvgPicture.asset("assets/icons/calendar.svg",
                    width: 18, height: 18, color: Colors.green),
                const SizedBox(width: 8),
                const Text("Delivery : Sep 3rd, 2025"),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) {
                        final screenHeight = MediaQuery.of(ctx).size.height;
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          insetPadding: const EdgeInsets.all(16), // margin from screen edges
                          child:
                          // SizedBox(
                          //   height: screenHeight * 0.7, // 90% of screen height
                          //   child:
                            const SingleChildScrollView(
                              child: BookedNow(),
                          //   ),
                           ),
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Book Now", style: TextStyle(color: Colors.white),),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),

            // Bottom Row
            Row(
              children: [
                SvgPicture.asset("assets/icons/truck.svg",
                    width: 20, height: 20, color: Colors.green),
                const SizedBox(width: 8),
                const Text("15,000 lb"),
                const Spacer(),
                const Text("Equipment Needed: Flatbed"),
                const Spacer(),
                const Text(
                  "2 Docs",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
