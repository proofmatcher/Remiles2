import 'package:flutter/material.dart';
import 'package:majh/presentation/common/widgets/top_navigation_bar.dart';

class NoNotificationPage extends StatelessWidget {
  const NoNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Column(
mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TopNavigationBar(context),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 200.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 120,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No Notifications",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
