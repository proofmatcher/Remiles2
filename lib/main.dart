// import 'package:Remiles/shipper_dashboard/MarketPlace_Screen.dart';
// import 'package:Remiles/shipper_dashboard/carvon_screen.dart';
// import 'package:Remiles/shipper_dashboard/manage_loads.dart';
// import 'package:Remiles/shipper_dashboard/manage_loads_2.dart';
// import 'package:Remiles/shipper_dashboard/manage_loads_3.dart';
// import 'package:Remiles/shipper_dashboard/shipper_booked_loads.dart';
// import 'package:Remiles/shipper_dashboard/shipper_cancelled_orders.dart';
// import 'package:Remiles/shipper_dashboard/shipper_completed_loads.dart';
// import 'package:Remiles/shipper_dashboard/shipper_dashboard_1.dart';
// import 'package:Remiles/shipper_dashboard/shipper_dashboard_post_load.dart';
// import 'package:Remiles/shipper_dashboard/shipper_intransit_orders.dart';
// import 'package:Remiles/shipper_dashboard/shipper_load_ai_match.dart';
// import 'package:Remiles/shipper_dashboard/shipper_more_options.dart';
// import 'package:Remiles/shipper_dashboard/shipper_notifications.dart';
// import 'package:Remiles/shipper_dashboard/shipper_profile.dart';
// import 'package:Remiles/shipper_signup.dart';

import 'login_screen.dart';
import 'shipper_dashboard/shipper_dashboard_3.dart';

import 'shipper_dashboard/shipper_dashboard_2.dart';
import 'package:flutter/material.dart';
// import 'shipper_dashboard/shipper_dashboard_1.dart';
// import '/shipper_signup.dart';
// import 'carrier_onboarding/carrier_onboarding_1.dart'; // Make sure this path is correct
// import 'carrier_onboarding/carrier_signup.dart';


void main() {
  // The main function is the entry point for all Flutter apps.
  // It calls the runApp() function, which takes the root widget of the app.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hides the debug banner
      title: 'Remiles App',
      theme: ThemeData(
        primarySwatch: Colors.green, // You can customize your app's theme here
      ),
      home: const ShipperDashboard3(), // Sets the CarrierSignUpScreen as the initial screen
    );
  }
}
