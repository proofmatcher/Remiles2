import 'package:flutter/material.dart';
import 'package:majh/presentation/common/widgets/load_card_info.dart';

import '../../common/widgets/load_filter_section.dart';
import '../../common/widgets/recommended_load.dart';
import '../../common/widgets/top_navigation_bar.dart';

class ManageLoadScreen extends StatelessWidget {
  const ManageLoadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Navigation Bar
            TopNavigationBar(context),


          Padding(
            padding: const EdgeInsets.only(top:20,left: 20.0),
            child: Text(
                  "Manage Loads", textAlign: TextAlign.center,
                  style: TextStyle(

                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
          ),

            const SizedBox(height: 20),
            LoadsFilterSection(),
            const SizedBox(height: 16),
            RecommendedLoad(),

            const SizedBox(height: 20),

            LoadCardInfo()

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
          Icon(icon, color: Colors.green, size: 28),
          const SizedBox(height: 6),
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
