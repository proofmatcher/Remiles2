import 'package:flutter/material.dart';

Widget RecommendedLoad() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Recommended Load",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "97% Match",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          /// Price and Load ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "\$1500   215(mi)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "Load ID #1234",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          /// From/To
          Row(
            children: const [
              Icon(Icons.location_on, size: 18, color: Colors.green),
              SizedBox(width: 6),
              Text("From : Toronto, ON"),
            ],
          ),
          Row(
            children: const [
              Icon(Icons.location_on_outlined, size: 18, color: Colors.green),
              SizedBox(width: 6),
              Text("To : Montreal, QC"),
            ],
          ),
          Row(
            children: const [
              Icon(Icons.calendar_today, size: 16, color: Colors.green),
              SizedBox(width: 6),
              Text("Pickup : Sep 1st, 2025"),
            ],
          ),
          Row(
            children: const [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.green,
              ),
              SizedBox(width: 6),
              Text("Delivery : Sep 3rd, 2025"),
            ],
          ),
          const SizedBox(height: 12),

          /// Weight
          Row(
            children: const [
              Icon(Icons.local_shipping, size: 20, color: Colors.green),
              SizedBox(width: 6),
              Text("15,000 lb"),
              Spacer(),
              Text("Equipment Needed: Flatbed"),
            ],
          ),

          const SizedBox(height: 12),

          /// Instant Booking
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCA4D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () {},
              child: const Text(
                "Instant Booking",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
