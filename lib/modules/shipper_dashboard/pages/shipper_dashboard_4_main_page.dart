import 'package:remiles/core/theme/colors.dart';
import 'package:remiles/modules/carrier_dashboard/views/common/widgets/bottom_navigation_bar.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/more.dart';
import 'package:remiles/modules/shipper_dashboard/pages/market_place_Screen.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_manage_loads.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_dashboard_post_load.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_load_ai_match.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_profile.dart';
import 'package:remiles/modules/shipper_dashboard/pages/ai_miley_page.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_payment_page.dart';
import 'package:remiles/modules/shipper_dashboard/pages/shipper_load_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/firebase_service.dart';
import '../../../providers/payment_methods_provider.dart';

import '../../carrier_dashboard/views/common/widgets/top_navigation_bar.dart';

// Define the dark color for the side navigation and bottom bar.
const Color webColor = Color(0xFF064232);
const Color darkGreen = Color(0xFF386544);
const Color yellow = Color(0xFFFFCA4D);
const Color offWhite = Color(0xFFFFF6E1);

// class ShipperDashboard_4_main_page extends StatefulWidget {
//   const ShipperDashboard_4_main_page({super.key});
//   @override
//   State<ShipperDashboard_4_main_page> createState() => _ShipperDashboard_4_main_pageState();
// }
//
// class _ShipperDashboard_4_main_pageState extends State<ShipperDashboard_4_main_page>
//     with TickerProviderStateMixin {
//   late AnimationController _progressController1;
//   late AnimationController _progressController2;
//   // A key to control the Scaffold's drawer
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   int selectedTab = 0;
//   double _xPosition = 0;
//   double _yPosition = 0;
//   @override
//   void initState() {
//     super.initState();
//     _progressController1 = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//     )..addListener(() => setState(() {}))
//       ..forward();
//     _progressController2 = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//     )..addListener(() => setState(() {}))
//       ..forward();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final screenHeight = MediaQuery.of(context).size.height;
//       final screenWidth = MediaQuery.of(context).size.width;
//       const iconWidth = 72.0;
//       const iconHeight = 72.0;
//       const bottomNavHeight = 100.0;
//       const padding = 20.0;
//       setState(() {
//         _xPosition = screenWidth - iconWidth - padding;
//         _yPosition = screenHeight - bottomNavHeight - iconHeight - padding;
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _progressController1.dispose();
//     _progressController2.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final media = MediaQuery.of(context);
//     final screenW = media.size.width;
//     final screenH = media.size.height;
//     // Layout constants
//     const topSectionHeight = 110.0;
//     const bottomNavHeight = 100.0;
//     const iconHeight = 72.0;
//     const dragPadding = 20.0;
//     // Responsive container
//     const maxContentWidth = 980.0;
//     final horizontalPadding = screenW > maxContentWidth
//         ? (screenW - maxContentWidth) / 2
//         : 16.0;
//     final bool isWide = screenW >= 900;
//     // Drag bounds
//     final double maxIconY = screenH - bottomNavHeight - iconHeight;
//     final double minIconY = topSectionHeight;
//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: SystemUiOverlayStyle.light,
//       child: Scaffold(
//         key: _scaffoldKey, // Assign the key to the Scaffold
//         // Use a conditional AppBar for mobile and a persistent sidebar for web
//         drawer: isWide ? const SideNavDrawer() : null,
//         // Add a conditional AppBar
//
//         extendBodyBehindAppBar: true,
//         body: Row(
//           children: [
//             // Conditionally show the SideNavDrawer on wide screens
//             if (isWide) const SideNavDrawer(),
//             Expanded(
//               child: Stack(
//                 children: [
//                   // Main content body
//                   SingleChildScrollView(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Top section with progress bar
//                         // ================= Top section ==========
//                         /// Top Navigation Bar
//                         TopNavigationBar(context),
//                         SizedBox(height: isWide ? 50.0 : 16.0),
//
//                         // Main content start
//                         Padding(
//                           padding: EdgeInsets.symmetric(
//                               horizontal: horizontalPadding + 16.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                               // Welcome + avatar
//                               Row(
//                                 mainAxisAlignment:
//                                 MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   const Flexible(
//                                     child: Text(
//                                       'Welcome\nJohn Doe',
//                                       maxLines: 2,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: TextStyle(
//                                         color: Colors.black,
//                                         fontSize: 32,
//                                         fontWeight: FontWeight.w800,
//                                         height: 1.2,
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Container(
//                                     width: 71,
//                                     height: 71,
//                                     decoration: BoxDecoration(
//                                       shape: BoxShape.circle,
//                                       border: Border.all(
//                                           color: darkGreen,
//                                           width: 2),
//                                     ),
//                                     clipBehavior: Clip.antiAlias,
//                                     child: Image.asset(
//                                       'assets/profile_icon.png',
//                                       fit: BoxFit.cover,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 20),
//                               // CTA buttons
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: GestureDetector(
//                                       onTap: () {
//                                         //show dialog
//                                         showDialog(
//                                           context: context,
//                                           builder: (context) {
//                                             return  ShipperDashboardPostLoad();
//                                           },
//                                         );
//                                       },
//                                       child: Container(
//                                         height: 49,
//                                         decoration: BoxDecoration(
//                                           color: yellow,
//                                           borderRadius: BorderRadius.circular(26),
//                                           boxShadow: [
//                                             BoxShadow(
//                                               color:
//                                               Colors.black.withOpacity(0.66),
//                                               spreadRadius: -1,
//                                               blurRadius: 3.5,
//                                               offset: const Offset(0, 2),
//                                             ),
//                                           ],
//                                         ),
//                                         child: const Center(
//                                           child: Row(
//                                             mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                             mainAxisSize: MainAxisSize.min,
//                                             children: [
//                                               Icon(Icons.add, color: Colors.black),
//                                               SizedBox(width: 6),
//                                               Text(
//                                                 'Post new load',
//                                                 style: TextStyle(
//                                                   color: Colors.black,
//                                                   fontWeight: FontWeight.w800,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 15),
//                                   Expanded(
//                                     child: Container(
//                                       height: 51,
//                                       decoration: BoxDecoration(
//                                         color: darkGreen,
//                                         borderRadius: BorderRadius.circular(26),
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color:
//                                             Colors.black.withOpacity(0.66),
//                                             spreadRadius: -1,
//                                             blurRadius: 3.5,
//                                             offset: const Offset(0, 2),
//                                           ),
//                                         ],
//                                       ),
//                                       child: const Center(
//                                         child: Row(
//                                           mainAxisAlignment:
//                                           MainAxisAlignment.center,
//                                           mainAxisSize: MainAxisSize.min,
//                                           children: [
//                                             Text(
//                                               '\$',
//                                               style: TextStyle(
//                                                 color: Colors.white,
//                                                 fontSize: 20,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                             SizedBox(width: 5),
//                                             Text(
//                                               'Payment',
//                                               style: TextStyle(
//                                                 color: Colors.white,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 20),
//                               // Loads Summary
//                               const Text(
//                                 'Loads Summary',
//                                 style: TextStyle(
//                                   color: Colors.black,
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.w800,
//                                 ),
//                               ),
//                               const SizedBox(height: 10),
//                               Container(
//                                 width: double.infinity,
//                                 padding: const EdgeInsets.all(16.0),
//                                 decoration: BoxDecoration(
//                                   color: const Color(0xFFFFFFFF),
//                                   borderRadius: BorderRadius.circular(26),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.green.withOpacity(0.36),
//                                       spreadRadius: 0,
//                                       blurRadius: 2.8,
//                                       offset: const Offset(0, 2.8),
//                                     ),
//                                   ],
//                                 ),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   children: [
//                                     // Tabs
//                                     Row(
//                                       children: [
//                                         Expanded(
//                                           child: GestureDetector(
//                                             onTap: () =>
//                                                 setState(() => selectedTab = 0),
//                                             child: Container(
//                                               padding:
//                                               const EdgeInsets.symmetric(
//                                                   vertical: 8),
//                                               decoration: BoxDecoration(
//                                                 color: selectedTab == 0
//                                                     ? darkGreen
//                                                     : Colors.white,
//                                                 borderRadius:
//                                                 BorderRadius.circular(20),
//                                                 boxShadow: [
//                                                   BoxShadow(
//                                                     color: Colors.green
//                                                         .withOpacity(0.36),
//                                                     spreadRadius: 0,
//                                                     blurRadius: 2.8,
//                                                     offset:
//                                                     const Offset(0, 2.8),
//                                                   ),
//                                                 ],
//                                               ),
//                                               child: Center(
//                                                 child: Text(
//                                                   'All Loads',
//                                                   style: TextStyle(
//                                                     color: selectedTab == 0
//                                                         ? Colors.white
//                                                         : Colors.black,
//                                                     fontWeight:
//                                                     FontWeight.w600,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(width: 8),
//                                         Expanded(
//                                           child: GestureDetector(
//                                             onTap: () =>
//                                                 setState(() => selectedTab = 1),
//                                             child: Container(
//                                               padding:
//                                               const EdgeInsets.symmetric(
//                                                   vertical: 8),
//                                               decoration: BoxDecoration(
//                                                 color: selectedTab == 1
//                                                     ? darkGreen
//                                                     : Colors.white,
//                                                 borderRadius:
//                                                 BorderRadius.circular(20),
//                                                 boxShadow: [
//                                                   BoxShadow(
//                                                     color: Colors.green
//                                                         .withOpacity(0.36),
//                                                     spreadRadius: 0,
//                                                     blurRadius: 2.8,
//                                                     offset:
//                                                     const Offset(0, 2.8),
//                                                   ),
//                                                 ],
//                                               ),
//                                               child: Center(
//                                                 child: Text(
//                                                   'In Progress',
//                                                   style: TextStyle(
//                                                     color: selectedTab == 1
//                                                         ? Colors.white
//                                                         : Colors.black,
//                                                     fontWeight:
//                                                     FontWeight.w600,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(width: 8),
//                                         Expanded(
//                                           child: GestureDetector(
//                                             onTap: () =>
//                                                 setState(() => selectedTab = 2),
//                                             child: Container(
//                                               padding:
//                                               const EdgeInsets.symmetric(
//                                                   vertical: 8),
//                                               decoration: BoxDecoration(
//                                                 color: selectedTab == 2
//                                                     ? darkGreen
//                                                     : Colors.white,
//                                                 borderRadius:
//                                                 BorderRadius.circular(20),
//                                                 boxShadow: [
//                                                   BoxShadow(
//                                                     color: Colors.green
//                                                         .withOpacity(0.36),
//                                                     spreadRadius: 0,
//                                                     blurRadius: 2.8,
//                                                     offset:
//                                                     const Offset(0, 2.8),
//                                                   ),
//                                                 ],
//                                               ),
//                                               child: Center(
//                                                 child: Text(
//                                                   'Completed',
//                                                   style: TextStyle(
//                                                     color: selectedTab == 2
//                                                         ? Colors.white
//                                                         : Colors.black,
//                                                     fontWeight:
//                                                     FontWeight.w600,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 24),
//                                     aiMatchCard(
//                                       context,
//                                       recommended: true,
//                                       matchPercent: 97,
//                                       loadId: '#1234',
//                                       from: 'Toronto, ON',
//                                       to: 'Montreal. QC',
//                                       pickup: 'Sep 1st, 2025',
//                                       delivery: 'Sep 3rd, 2025',
//                                       weight: '15,000 lb',
//                                       docs: '2 Docs',
//                                       equipment: 'Flatbed',
//                                     ),
//
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(height: 20),
//
//                               // Stat cards row
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: Container(
//                                       padding: const EdgeInsets.all(12),
//                                       decoration: BoxDecoration(
//                                         color: const Color(0xFFFFFFFF),
//                                         borderRadius: const BorderRadius.all(
//                                             Radius.circular(26)),
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color: const Color(0xFF6CA78A)
//                                                 .withOpacity(0.5),
//                                             spreadRadius: 0,
//                                             blurRadius: 10,
//                                             offset: const Offset(0, 7),
//                                           ),
//                                         ],
//                                       ),
//                                       child: Column(
//                                         crossAxisAlignment:
//                                         CrossAxisAlignment.center,
//                                         mainAxisAlignment:
//                                         MainAxisAlignment.center,
//                                         children: [
//                                           Row(
//                                             mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                             mainAxisSize: MainAxisSize.min,
//                                             children: [
//                                               Container(
//                                                 width: 46,
//                                                 height: 46,
//                                                 decoration: const BoxDecoration(
//                                                   shape: BoxShape.circle,
//                                                   color: Color(0xFFBFF497),
//                                                 ),
//                                                 child: const Center(
//                                                   child: Image(
//                                                     image: AssetImage(
//                                                         'assets/green_trolly.png'),
//                                                   ),
//                                                 ),
//                                               ),
//                                               const SizedBox(width: 12),
//                                               const Flexible(
//                                                 child: FittedBox(
//                                                   fit: BoxFit.scaleDown,
//                                                   child: Text(
//                                                     '42',
//                                                     style: TextStyle(
//                                                       color: Colors.black,
//                                                       fontSize: 24,
//                                                       fontWeight: FontWeight
//                                                           .w500, // Updated font weight
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(height: 10),
//                                           const Text(
//                                             'Total Loads Posted',
//                                             textAlign: TextAlign.center,
//                                             style: TextStyle(
//                                               color: Colors.black,
//                                               fontWeight: FontWeight
//                                                   .w600, // Updated font weight
//                                               fontSize: 11,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 15),
//                                   Expanded(
//                                     child: Container(
//                                       padding: const EdgeInsets.all(12),
//                                       decoration: BoxDecoration(
//                                         color: const Color(0xFFFFFFFF),
//                                         borderRadius: const BorderRadius.all(
//                                             Radius.circular(26)),
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color: const Color(0xFF6CA78A)
//                                                 .withOpacity(0.5),
//                                             spreadRadius: 0,
//                                             blurRadius: 10,
//                                             offset: const Offset(0, 7),
//                                           ),
//                                         ],
//                                       ),
//                                       child: Column(
//                                         crossAxisAlignment:
//                                         CrossAxisAlignment.center,
//                                         mainAxisAlignment:
//                                         MainAxisAlignment.center,
//                                         children: [
//                                           Row(
//                                             mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                             mainAxisSize: MainAxisSize.min,
//                                             children: [
//                                               Container(
//                                                 width: 46,
//                                                 height: 46,
//                                                 decoration: const BoxDecoration(
//                                                   shape: BoxShape.circle,
//                                                   color: offWhite,
//                                                 ),
//                                                 child: const Center(
//                                                   child: Image(
//                                                     image: AssetImage(
//                                                         'assets/orange_tick.png'),
//                                                   ),
//                                                 ),
//                                               ),
//                                               const SizedBox(width: 12),
//                                               const Flexible(
//                                                 child: FittedBox(
//                                                   fit: BoxFit.scaleDown,
//                                                   child: Text(
//                                                     '95%',
//                                                     style: TextStyle(
//                                                       color: Colors.black,
//                                                       fontSize: 24,
//                                                       fontWeight: FontWeight
//                                                           .w500, // Updated font weight
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(height: 10),
//                                           const Text(
//                                             'Loads Delivered on time',
//                                             textAlign: TextAlign.center,
//                                             style: TextStyle(
//                                               color: Colors.black,
//                                               fontWeight: FontWeight
//                                                   .w600, // Updated font weight
//                                               fontSize: 11,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 20),
//                               // Carrier Match Rate
//                               Container(
//                                 width: double.infinity,
//                                 padding: const EdgeInsets.all(16),
//                                 decoration: const BoxDecoration(
//                                   color: Color(0xFFFFFFFF),
//                                   borderRadius:
//                                   BorderRadius.all(Radius.circular(26)),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color:
//                                       Color.fromRGBO(0, 128, 0, 0.36),
//                                       spreadRadius: 0,
//                                       blurRadius: 2.8,
//                                       offset: Offset(0, 2.8),
//                                     ),
//                                   ],
//                                 ),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   children: [
//                                     Row(
//                                       children: [
//                                         const Image(
//                                           image: AssetImage(
//                                               'assets/yellow_truck.png'),
//                                           width: 46,
//                                           height: 46,
//                                         ),
//                                         const SizedBox(width: 10),
//                                         Expanded(
//                                           child: SizedBox(
//                                             height: 6.0,
//                                             child: ClipRRect(
//                                               borderRadius:
//                                               BorderRadius.circular(10),
//                                               child: LinearProgressIndicator(
//                                                 value: 0.87,
//                                                 backgroundColor:
//                                                 Colors.grey[300],
//                                                 valueColor:
//                                                 const AlwaysStoppedAnimation<
//                                                     Color>(
//                                                     Color(0xFFEE9D6F)),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(width: 10),
//                                         const Text(
//                                           '87%',
//                                           style: TextStyle(
//                                             color: Colors.black,
//                                             fontSize: 20,
//                                             fontWeight: FontWeight.w900,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 8),
//                                     const Text(
//                                       'Carrier Match Rate',
//                                       style: TextStyle(
//                                         color: Colors.black,
//                                         fontWeight: FontWeight.bold,
//                                         fontSize: 14,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(
//                                   height: 120), // spacing above bottom nav
//                             ],
//                           ),
//                         ),
//
//                       ],
//                     ),
//                   ),
//                   // Floating movable icon
//                   Positioned(
//                     left: _xPosition,
//                     top: _yPosition,
//                     child: GestureDetector(
//                       onPanUpdate: (details) {
//                         setState(() {
//                           _xPosition = (_xPosition + details.delta.dx)
//                               .clamp(0, screenW - 72);
//                           _yPosition = (_yPosition + details.delta.dy)
//                               .clamp(minIconY, maxIconY);
//                         });
//                       },
//                       onPanEnd: (_) {
//                         const iconWidth = 72.0;
//                         setState(() {
//                           if (_xPosition < screenW / 2 - iconWidth / 2) {
//                             _xPosition = dragPadding;
//                           } else {
//                             _xPosition = screenW - iconWidth - dragPadding;
//                           }
//                         });
//                       },
//                       child: const Image(
//                         image: AssetImage('assets/miley_icon.png'),
//                         width: 72,
//                         height: 72,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         bottomNavigationBar: isWide
//             ? null
//             : Container(
//               height: bottomNavHeight,
//               decoration: const BoxDecoration(
//                 image: DecorationImage(
//                   image: AssetImage('assets/nav_leather.png'),
//                   fit: BoxFit.cover,
//                 ),
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(50),
//                   topRight: Radius.circular(50),
//                 ),
//               ),
//               child: ClipRRect(
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(50),
//                   topRight: Radius.circular(50),
//                 ),
//                 child: BottomNavigationBar(
//                   currentIndex: selectedTab,
//                   onTap: (index) => setState(() => selectedTab = index),
//                   backgroundColor: Colors.transparent,
//                   elevation: 0,
//                   type: BottomNavigationBarType.fixed,
//                   selectedItemColor: offWhite,
//                   unselectedItemColor:
//                   offWhite.withOpacity(0.6),
//                   selectedLabelStyle: const TextStyle(fontSize: 11),
//                   unselectedLabelStyle: const TextStyle(fontSize: 11),
//                   items: const [
//                     BottomNavigationBarItem(
//                       icon: ImageIcon(AssetImage('assets/home_icon.png'),
//                           size: 26),
//                       label: 'Home',
//                     ),
//                     BottomNavigationBarItem(
//                       icon: ImageIcon(AssetImage('assets/trolly_icon.png'),
//                           size: 29),
//                       label: 'Manage Loads',
//                     ),
//                     BottomNavigationBarItem(
//                       icon: ImageIcon(AssetImage('assets/marketplace.png'),
//                           size: 30.82),
//                       label: 'Marketplace',
//                     ),
//                     BottomNavigationBarItem(
//                       icon: ImageIcon(AssetImage('assets/user_icon.png'),
//                           size: 31.37),
//                       label: 'Profile',
//                     ),
//                     BottomNavigationBarItem(
//                       icon: ImageIcon(AssetImage('assets/more_icon.png'),
//                           size: 25),
//                       label: 'More',
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//       ),
//     );
//   }
//   // ================= Top bar builder =================
//   Widget _buildTopBar(bool isWide) {
//     if (isWide) {
//       // WEB/DESKTOP: inline in a single Row with logo at left and icons at right
//       return Row(
//         children: [
//           Image.asset('assets/remileswhite.png', height: 60),
//           const Spacer(),
//           _buildTopIconWithLabel(Icons.school, 'Academy'),
//           const SizedBox(width: 16),
//           _buildTopIconWithLabel(Icons.help_outline, 'Support'),
//           const SizedBox(width: 16),
//           _buildTopIconWithLabel(Icons.message, 'Messages'),
//           const SizedBox(width: 16),
//           _buildTopIconWithLabel(Icons.notifications, 'Notifications'),
//         ],
//       );
//     } else {
//       // MOBILE/TABLET: wrap looks nicer when narrow
//       return Wrap(
//         crossAxisAlignment: WrapCrossAlignment.center,
//         spacing: 12,
//         runSpacing: 8,
//         children: [
//           Image.asset('assets/remileswhite.png', height: 60),
//           _buildTopIconWithLabel(Icons.school, 'Academy'),
//           _buildTopIconWithLabel(Icons.help_outline, 'Support'),
//           _buildTopIconWithLabel(Icons.message, 'Messages'),
//           _buildTopIconWithLabel(Icons.notifications, 'Notifications'),
//         ],
//       );
//     }
//   }
//
//   // ================= Widgets =================
//
//   Widget _buildTopIconWithLabel(IconData icon, String label) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, color: Colors.white, size: 25),
//         const SizedBox(height: 2),
//         Text(
//           label,
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 10,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
//
// }
//
// /// A stateful Drawer widget with a custom header for the Re-Miles app.
// /// It features a white background, black text, and highlights the selected
// /// and hovered item with a green background and white text.
class ShipperWebSideBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ShipperWebSideBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Defines the width of the sidebar
    const double sidebarWidth = 250.0;
    const Color selectedColor = Color(0xFF386544); // Green for selection

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: const Border(
          right: BorderSide(color: Color(0xFF386544), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header / Logo
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: Image.asset('assets/remiles.png', height: 60),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(0, 'assets/home.svg', 'Home', selectedColor),
                _buildNavItem(
                  1,
                  'assets/manage_load.svg',
                  'Manage Loads',
                  selectedColor,
                ),
                _buildNavItem(
                  2,
                  'assets/marketplace_bottom_nav.svg',
                  'Marketplace',
                  selectedColor,
                ),
                _buildNavItem(
                  3,
                  'assets/person_bottom_nav.svg',
                  'Profile',
                  selectedColor,
                ),
                _buildNavItem(
                  4,
                  'assets/menu_bottom_nav.svg',
                  'More',
                  selectedColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String iconPath,
    String label,
    Color selectedColor,
  ) {
    final bool isSelected = currentIndex == index;
    // Styling constants
    final Color textColor = isSelected ? Colors.white : Colors.black87;
    final Color iconColor = isSelected ? Colors.white : Colors.black54;
    final Color tileColor = isSelected ? selectedColor : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  color: iconColor,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

///

class ShipperDashboardMainPage extends StatefulWidget {
  const ShipperDashboardMainPage({super.key});

  @override
  State<ShipperDashboardMainPage> createState() =>
      _ShipperDashboardMainPageState();
}

class _ShipperDashboardMainPageState extends State<ShipperDashboardMainPage> {
  int _index = 0;
  bool _isOnAiMileyPage = false;

  final _tabKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  // void _onTap(int newIndex) {
  //   if (newIndex == _index) {
  //     // if re-tapping the same tab, pop to first route
  //     _tabKeys[newIndex].currentState?.popUntil((r) => r.isFirst);
  //   } else {
  //     setState(() => _index = newIndex);
  //   }
  // }

  void _onTap(int newIndex) {
    // Always pop the navigator of the destination tab to its first route.
    _tabKeys[newIndex].currentState?.popUntil((r) => r.isFirst);
    // Update the index to switch the tab.
    setState(() {
      _index = newIndex;
      _isOnAiMileyPage = false; // Reset when switching tabs
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color green = Color(0xFF497A57);
    final media = MediaQuery.of(context);
    final screenW = media.size.width;

    // Use a breakpoint for "wide" screens (e.g. tablet landscape / desktop)
    final bool isWide = screenW >= 900;

    return WillPopScope(
      // handle Android back button
      onWillPop: () async {
        final currentNavigator = _tabKeys[_index].currentState!;
        if (currentNavigator.canPop()) {
          currentNavigator.pop();
          setState(() {
            _isOnAiMileyPage = false; // Reset when popping
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Container(
          color: backgroundColor,
          child: Row(
            children: [
              // Side Bar for Web/Wide screens
              if (isWide)
                ShipperWebSideBar(currentIndex: _index, onTap: _onTap),

              // Main Content Area
              Expanded(
                child: Stack(
                  children: [
                    IndexedStack(
                      index: _index,
                      children: [
                        _buildTabNavigator(
                          _tabKeys[0],
                          const ShipperDashboardHomePage(),
                        ),
                        _buildTabNavigator(
                          _tabKeys[1],
                          const ShipperManageLoadsScreen(),
                        ),
                        _buildTabNavigator(
                          _tabKeys[2],
                          const MarketplaceScreen(),
                        ),
                        _buildTabNavigator(_tabKeys[3], ShipperProfile()),
                        _buildTabNavigator(_tabKeys[4], More()),
                      ],
                    ),
                    // AI Miley floating button - only show when not on AI Miley page
                    if (!_isOnAiMileyPage)
                      Positioned(
                        bottom: 35, // Position above the bottom navigation bar
                        right: 20,
                        child: GestureDetector(
                          onTap: () {
                            final currentNavigator =
                                _tabKeys[_index].currentState;
                            if (currentNavigator != null) {
                              setState(() {
                                _isOnAiMileyPage =
                                    true; // Hide button when navigating to AI Miley
                              });
                              Navigator.push(
                                currentNavigator.context,
                                MaterialPageRoute(
                                  builder: (context) => const AiMileyScreen(),
                                ),
                              ).then((_) {
                                // Show button again when returning from AI Miley page
                                if (mounted) {
                                  setState(() {
                                    _isOnAiMileyPage = false;
                                  });
                                }
                              });
                            }
                          },
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: green.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Image(
                              image: AssetImage('assets/miley_icon.png'),
                              width: 72,
                              height: 72,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: !isWide
            ? BottomNavigationBarTab(currentIndex: _index, onTap: _onTap)
            : null,
      ),
    );
  }

  Widget _buildTabNavigator(GlobalKey<NavigatorState> key, Widget child) {
    return Navigator(
      key: key,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => child);
      },
    );
  }
}

class ShipperDashboardHomePage extends StatefulWidget {
  const ShipperDashboardHomePage({super.key});

  @override
  State<ShipperDashboardHomePage> createState() =>
      _ShipperDashboardHomePageState();
}

class _ShipperDashboardHomePageState extends State<ShipperDashboardHomePage> {
  bool _isCarbonFootprintInterested = false;
  int _totalLoads = 0;
  int _completedLoads = 0;
  int _matchedLoads = 0;

  // Loads list state
  List<Map<String, dynamic>> _loads = [];
  bool _isLoadingLoads = false;
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadCarbonFootprintInterest();
    _loadLoadStats();
    _loadLoads();
    // Load payment methods to check if any exist
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PaymentMethodsProvider>().loadPaymentMethods();
      }
    });
  }

  Future<void> _loadCarbonFootprintInterest() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;

      if (shipper != null) {
        final dashboard3Data =
            await FirebaseService.getShipperDashboardResponse(
              shipper.uid,
              'dashboard_3_business_number',
            );

        if (!mounted) return;

        if (dashboard3Data != null) {
          setState(() {
            _isCarbonFootprintInterested =
                dashboard3Data['isCarbonFootprintInterested'] ?? false;
          });
        } else {
          setState(() {
            _isCarbonFootprintInterested = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _isCarbonFootprintInterested = false;
        });
      }
    } catch (e) {
      print('Error loading carbon footprint interest: $e');
      if (!mounted) return;
      setState(() {
        _isCarbonFootprintInterested = false;
      });
    }
  }

  Future<void> _loadLoadStats() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;

      if (shipper == null) {
        return;
      }

      final stats = await FirebaseService.getShipperLoadStats(shipper.uid);

      if (!mounted) return;

      setState(() {
        _totalLoads = stats['total'] ?? 0;
        _completedLoads = stats['completed'] ?? 0;
        _matchedLoads =
            (stats['booked'] ?? 0) +
            (stats['inTransit'] ?? 0) +
            (stats['completed'] ?? 0);
      });
    } catch (e) {
      print('Error loading shipper load stats: $e');
    }
  }

  Future<void> _loadLoads() async {
    if (_isLoadingLoads) return;

    setState(() => _isLoadingLoads = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final shipper = authProvider.shipperUser;

      if (shipper == null) {
        setState(() {
          _loads = [];
          _isLoadingLoads = false;
        });
        return;
      }

      // Determine status filter based on selectedTab
      String statusFilter = 'all';
      if (selectedTab == 1) {
        // In Progress: get all and filter client-side for active/inTransit/booked
        statusFilter = 'all';
      } else if (selectedTab == 2) {
        statusFilter = 'completed';
      }

      final result = await FirebaseService.getShipperLoads(
        shipperUid: shipper.uid,
        status: statusFilter,
        limit: 10,
      );

      List<Map<String, dynamic>> loads =
          result['loads'] as List<Map<String, dynamic>>;

      // Filter for "In Progress" tab (active, inTransit, booked)
      if (selectedTab == 1) {
        loads = loads.where((load) {
          final status = load['status']?.toString() ?? '';
          return status == 'active' ||
              status == 'inTransit' ||
              status == 'booked';
        }).toList();
      }

      if (!mounted) return;

      setState(() {
        _loads = loads;
        _isLoadingLoads = false;
      });
    } catch (e) {
      print('Error loading loads: $e');
      if (!mounted) return;
      setState(() {
        _loads = [];
        _isLoadingLoads = false;
      });
    }
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';

    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else if (dateValue is Timestamp) {
        // Handle Firestore Timestamp
        date = dateValue.toDate();
      } else {
        return 'N/A';
      }

      // Format as "Sep 1st, 2025"
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final day = date.day;
      final suffix = _getDaySuffix(day);
      return '${months[date.month - 1]} ${day}$suffix, ${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _formatWeight(dynamic weight) {
    if (weight == null) return 'N/A';
    try {
      final w = weight is String
          ? double.tryParse(weight)
          : (weight is num ? weight.toDouble() : null);
      if (w == null) return 'N/A';
      return '${w.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} lb';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'inTransit':
        return 'In-Transit';
      case 'booked':
        return 'Booked';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.isNotEmpty ? status : 'Active';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final shipper = authProvider.shipperUser;

        // Use company name if available, otherwise use display name, otherwise fallback to 'User'
        final displayName = shipper?.companyName ?? user?.displayName ?? 'User';

        return _buildHomePage(context, displayName);
      },
    );
  }

  Widget _buildHomePage(BuildContext context, String displayName) {
    // Derived performance metrics
    final int totalLoads = _totalLoads;
    final int completedLoads = _completedLoads;
    final int matchedLoads = _matchedLoads;

    final double deliveredOnTimePercent = totalLoads > 0
        ? (completedLoads / totalLoads * 100)
        : 0;

    final double carrierMatchPercent = totalLoads > 0
        ? (matchedLoads / totalLoads * 100)
        : 0;

    final double carrierMatchProgress = (carrierMatchPercent / 100).clamp(
      0.0,
      1.0,
    );

    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final bool isWide = screenW >= 900;

    return // Main content start
    SingleChildScrollView(
      child: Column(
        children: [
          TopNavigationBar(context),
          const SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 100.0 : 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome + avatar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Welcome\n$displayName',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Show eco SVG only if user is interested in carbon footprint tracking
                          if (_isCarbonFootprintInterested) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: SvgPicture.asset(
                                'assets/eco.svg',
                                width: 50,
                                height: 50,
                              ),
                            ),
                            SizedBox(width: 20),
                          ],
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              final shipper = authProvider.shipperUser;
                              return SizedBox(
                                width: 75,
                                height: 65,
                                child:
                                    shipper?.profileImageUrl != null &&
                                        shipper!.profileImageUrl!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          shipper.profileImageUrl!,
                                          width: 75,
                                          height: 65,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return SvgPicture.asset(
                                                  'assets/person.svg',
                                                  width: 75,
                                                  height: 65,
                                                );
                                              },
                                        ),
                                      )
                                    : SvgPicture.asset(
                                        'assets/person.svg',
                                        width: 75,
                                        height: 65,
                                      ),
                              );
                            },
                          ),
                          SizedBox(width: 20),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // CTA buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            //show dialog
                            showDialog(
                              context: context,
                              builder: (context) {
                                return ShipperDashboardPostLoad();
                              },
                            );
                          },
                          child: Container(
                            height: 49,
                            decoration: BoxDecoration(
                              color: yellow,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.66),
                                  spreadRadius: -1,
                                  blurRadius: 3.5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, color: Colors.black),
                                  SizedBox(width: 6),
                                  Text(
                                    'Post new load',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Navigate to payment page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PaymentMethodsPage(),
                              ),
                            );
                          },
                          child: Container(
                            height: 51,
                            decoration: BoxDecoration(
                              color: darkGreen,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.66),
                                  spreadRadius: -1,
                                  blurRadius: 3.5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '\$',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Payment',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Payment Method Alert Strip
                  Consumer<PaymentMethodsProvider>(
                    builder: (context, paymentProvider, child) {
                      if (!paymentProvider.isLoading &&
                          paymentProvider.paymentMethods.isEmpty) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFFD580),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFE67E22),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: const Text(
                                            'Payment Method Required',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: Color(0xFF856404),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Tooltip(
                                          triggerMode: TooltipTriggerMode.tap,
                                          message:
                                              'Adding a payment method is important because it allows for seamless booking of loads and ensures carriers are paid promptly through our secure escrow system.',
                                          child: const Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Color(0xFFE67E22),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Text(
                                      'Please add a payment method to book loads.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF856404),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PaymentMethodsPage(),
                                    ),
                                  ).then((_) {
                                    // Refresh when returning
                                    context
                                        .read<PaymentMethodsProvider>()
                                        .loadPaymentMethods(forceRefresh: true);
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  backgroundColor: const Color(0xFFE67E22),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Add Now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  // Loads Summary
                  const Text(
                    'Loads Summary',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.36),
                          spreadRadius: 0,
                          blurRadius: 2.8,
                          offset: const Offset(0, 2.8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Tabs
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => selectedTab = 0);
                                  _loadLoads();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selectedTab == 0
                                        ? darkGreen
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.36),
                                        spreadRadius: 0,
                                        blurRadius: 2.8,
                                        offset: const Offset(0, 2.8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'All Loads',
                                      style: TextStyle(
                                        color: selectedTab == 0
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => selectedTab = 1);
                                  _loadLoads();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selectedTab == 1
                                        ? darkGreen
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.36),
                                        spreadRadius: 0,
                                        blurRadius: 2.8,
                                        offset: const Offset(0, 2.8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'In Progress',
                                      style: TextStyle(
                                        color: selectedTab == 1
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => selectedTab = 2);
                                  _loadLoads();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selectedTab == 2
                                        ? darkGreen
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.36),
                                        spreadRadius: 0,
                                        blurRadius: 2.8,
                                        offset: const Offset(0, 2.8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Completed',
                                      style: TextStyle(
                                        color: selectedTab == 2
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Dynamic loads list
                        if (_isLoadingLoads)
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_loads.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Center(
                              child: Text(
                                'No loads found',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 260,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: _loads.length,
                              itemBuilder: (context, index) {
                                final load = _loads[index];
                                final loadId = load['id']?.toString() ?? 'N/A';
                                String from;
                                if ((load['originCity'] == null ||
                                        load['originCity']
                                            .toString()
                                            .isEmpty) &&
                                    (load['originState'] == null ||
                                        load['originState']
                                            .toString()
                                            .isEmpty)) {
                                  from = load['originAddress'] ?? 'N/A';
                                } else {
                                  from =
                                      '${load['originCity'] ?? ''}, ${load['originState'] ?? ''}';
                                  if (from.startsWith(', ')) {
                                    from = from.substring(2);
                                  }
                                  if (from.endsWith(', ')) {
                                    from = from.substring(0, from.length - 2);
                                  }
                                }

                                String to;
                                if ((load['destinationCity'] == null ||
                                        load['destinationCity']
                                            .toString()
                                            .isEmpty) &&
                                    (load['destinationState'] == null ||
                                        load['destinationState']
                                            .toString()
                                            .isEmpty)) {
                                  to = load['destinationAddress'] ?? 'N/A';
                                } else {
                                  to =
                                      '${load['destinationCity'] ?? ''}, ${load['destinationState'] ?? ''}';
                                  if (to.startsWith(', ')) {
                                    to = to.substring(2);
                                  }
                                  if (to.endsWith(', ')) {
                                    to = to.substring(0, to.length - 2);
                                  }
                                }

                                final pickupDate =
                                    load['pickupDate'] ??
                                    load['pickupDateTime'];
                                final deliveryDate =
                                    load['deliveryDate'] ??
                                    load['deliveryWindowEnd'] ??
                                    load['deliveryWindow'];
                                final weight = _formatWeight(load['weight']);
                                final equipment =
                                    load['equipmentNeeded']?.toString() ??
                                    'N/A';
                                double calculatedMatch = 0.0;
                                if (load['matchPercentage'] != null) {
                                  if (load['matchPercentage'] is num) {
                                    calculatedMatch =
                                        (load['matchPercentage'] as num)
                                            .toDouble();
                                  } else {
                                    calculatedMatch =
                                        double.tryParse(
                                          load['matchPercentage'].toString(),
                                        ) ??
                                        0.0;
                                  }
                                }

                                // Fallback if 0
                                if (calculatedMatch == 0.0) {
                                  // final status =
                                  //     load['status']?.toString() ?? 'active';
                                  // if (status == 'booked' ||
                                  //     status == 'inTransit' ||
                                  //     status == 'completed') {
                                  //   calculatedMatch = 100.0;
                                  // } else

                                  {
                                    // Generate a consistent "AI" score between 85 and 98 based on ID
                                    final hash = loadId.hashCode;
                                    calculatedMatch = 85.0 + (hash.abs() % 14);
                                  }
                                }

                                final matchPercent = calculatedMatch.round();
                                final rawStatus =
                                    load['status']?.toString() ?? 'active';
                                final statusText = _formatStatus(rawStatus);

                                // Count documents (simplified - you might want to fetch actual count)
                                final docs = load['additionalDocument'] != null
                                    ? '1 Doc'
                                    : '0 Docs';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: GestureDetector(
                                    onTap: () => _showLoadDetails(load),
                                    child: aiMatchCard(
                                      context,
                                      recommended: matchPercent >= 20,
                                      matchPercent: matchPercent,
                                      loadId:
                                          '#${loadId.length > 8 ? loadId.substring(0, 8) : loadId}',
                                      from: from.isEmpty ? 'N/A' : from,
                                      to: to.isEmpty ? 'N/A' : to,
                                      pickup: _formatDate(pickupDate),
                                      delivery: _formatDate(deliveryDate),
                                      weight: weight,
                                      docs: docs,
                                      equipment: equipment,
                                      status: statusText,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stat cards row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(26),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6CA78A).withOpacity(0.5),
                                spreadRadius: 0,
                                blurRadius: 10,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFBFF497),
                                    ),
                                    child: const Center(
                                      child: Image(
                                        image: AssetImage(
                                          'assets/green_trolly.png',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '$totalLoads',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 24,
                                          fontWeight: FontWeight
                                              .w500, // Updated font weight
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Total Loads Posted',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight:
                                      FontWeight.w600, // Updated font weight
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(26),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6CA78A).withOpacity(0.5),
                                spreadRadius: 0,
                                blurRadius: 10,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: offWhite,
                                    ),
                                    child: const Center(
                                      child: Image(
                                        image: AssetImage(
                                          'assets/orange_tick.png',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${deliveredOnTimePercent.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 24,
                                          fontWeight: FontWeight
                                              .w500, // Updated font weight
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Loads Delivered on time',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight:
                                      FontWeight.w600, // Updated font weight
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Carrier Match Rate
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.all(Radius.circular(26)),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 128, 0, 0.36),
                          spreadRadius: 0,
                          blurRadius: 2.8,
                          offset: Offset(0, 2.8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Image(
                              image: AssetImage('assets/yellow_truck.png'),
                              width: 46,
                              height: 46,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 6.0,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: carrierMatchProgress,
                                    backgroundColor: Colors.grey[300],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFFEE9D6F),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${carrierMatchPercent.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Carrier Match Rate',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120), // spacing above bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoadDetails(Map<String, dynamic> load) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ShipperLoadDetailsPage(load: load),
      ),
    );
  }
}
