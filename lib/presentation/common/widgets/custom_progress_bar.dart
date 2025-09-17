import 'package:flutter/material.dart';

class CustomProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0

  const CustomProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          // Green filled portion
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value, // 0.0 → 1.0
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          // Percentage text
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                "${(value * 100).toInt()}%",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
