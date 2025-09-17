import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadsFilterSection extends StatelessWidget {
  const LoadsFilterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green, width: 2),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            color: Colors.white,
          ),
          child: Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search My Loads",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              IconButton(
                icon: SvgPicture.asset(
                  "assets/icons/filter.svg", // your filter SVG
                  width: 20,
                  height: 20,
                  color: Colors.black,
                ),
                onPressed: () {},
              )
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Category Buttons
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _buildCategoryButton("Available Loads", isPrimary: true),
            _buildCategoryButton("My Bookings", isPrimary: true),
            _buildCategoryButton("In-Transit"),
            _buildCategoryButton("Cancelled Loads"),
            _buildCategoryButton("Completed Loads"),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryButton(String text, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(24),
        color: isPrimary ? Colors.white : Colors.white,
        boxShadow: [
          if (isPrimary)
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
          color: Colors.black,
        ),
      ),
    );
  }
}
