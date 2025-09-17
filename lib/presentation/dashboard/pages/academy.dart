
import 'package:flutter/material.dart';


class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize the TabController with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF003D2B), // Dark green color
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Re-Miles Academy",style: TextStyle(color: Colors.white),),
            Text("Learn about the app and its features",style: TextStyle(color: Colors.white,fontSize: 12),),
          ],
        ), //
        leading: Text(''),// No title needed
        // The TabBar is placed in the 'bottom' property of the AppBar
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicator: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white,
                width: 4.0,
              ),
            ),
          ),
          tabs: const [
            Tab(text: 'VIDEOS'),
            Tab(text: 'PLAYLISTS'),
          ],
        ),
      ),
      // TabBarView holds the content for each tab
      body: TabBarView(
        controller: _tabController,
        children: [
          // Content for the first tab
          _buildTabContent(),
          // Content for the second tab (can be different)
          // For this example, we'll show the same layout
          _buildTabContent(),
        ],
      ),
    );
  }

  /// Builds the content layout for a single tab page.
  Widget _buildTabContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          const SizedBox(height: 20),
          // Video Grid
          Expanded(
            child: _buildVideoGrid(),
          ),
        ],
      ),
    );
  }

  /// Builds the styled search bar widget.
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: const TextField(
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(vertical: 15.0),
        ),
      ),
    );
  }

  /// Builds the grid of video placeholders.
  Widget _buildVideoGrid() {
    // Using a list of 8 for better scrolling demonstration
    return GridView.builder(
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,        // 2 columns
        crossAxisSpacing: 16.0,   // Horizontal space
        mainAxisSpacing: 16.0,    // Vertical space
        childAspectRatio: 16 / 10,
      ),
      itemBuilder: (context, index) {
        return _buildVideoThumbnail();
      },
    );
  }

  /// Builds a single video thumbnail placeholder.
  Widget _buildVideoThumbnail() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: const Center(
        child: Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 50,
        ),
      ),
    );
  }
}