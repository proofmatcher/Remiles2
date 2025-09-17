import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:majh/presentation/dashboard/pages/academy.dart';
import 'package:majh/presentation/dashboard/pages/messages_page.dart' show MessagesPage;
import 'package:majh/presentation/dashboard/pages/notification.dart';
import 'package:majh/presentation/dashboard/pages/support.dart';

Widget TopNavigationBar(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: const BoxDecoration(
      color: Color(0xFF0A6837), // dark green background
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
    ),
    child: SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SvgPicture.asset('assets/app_icon.svg'),
          Row(
            children: [
              _navItem(
                context,
                icon: Icons.school,
                label: "Academy",
                page: const AcademyScreen(), // placeholder
              ),
              const SizedBox(width: 10),
              _navItem(
                context,
                icon: Icons.support_agent,
                label: "Support",
                page: SupportScreen(),
              ),
              const SizedBox(width: 10),
              _navItem(
                context,
                icon: Icons.message,
                label: "Messages",
                page: const MessagesPage(),
              ),
              const SizedBox(width: 10),
              _navItem(
                context,
                icon: Icons.notifications,
                label: "Notifications",
                page: const NoNotificationPage(),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _navItem(BuildContext context,
    {required IconData icon, required String label, required Widget page}) {
  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    },
    borderRadius: BorderRadius.circular(8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
