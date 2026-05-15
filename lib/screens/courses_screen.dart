// lib/screens/courses_screen.dart
import 'package:flutter/material.dart';
import '../widgets/search_bar.dart';
import '../widgets/course_card.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Defines standard colors based on the image
    final Color headerGreen = Color(0xFF2E7D32); // Darker green for header
    final Color backgroundGray = Color(0xFFF5F5F5);

    // Mock data based on image
    final List<Map<String, dynamic>> coursesData = [
      {
        'title': 'Mobile App Development',
        'lecturer': 'Mr. Hok Tin',
        'progress': 0.50,
        'icon': Icons.phone_android,
      },
      {
        'title': 'Software Testing',
        'lecturer': 'Tal Tongsreng',
        'progress': 0.60,
        'icon': Icons.lock_outlined, // Closer look required to find the exact lock icon
      },
      {
        'title': 'Entrepreneurship',
        'lecturer': 'Mrs. Cheoun Chakrya',
        'progress': 0.80,
        'icon': Icons.business_center_outlined,
      },
    ];

    return Scaffold(
      backgroundColor: backgroundGray,
      // Custom green header (instead of AppBar)
      body: SafeArea(
        top: false, // Allows header to go all the way up
        child: Column(
          children: [
            // Custom Header Container
            Container(
              color: headerGreen,
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  bottom: 15,
                  left: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () {
                      // Handle back press
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Courses',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    SearchBarWidget(),

                    // Section Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Active Curriculum',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),

                    // List of Course Cards
                    ...coursesData.map((course) {
                      return CourseCard(
                        title: course['title'],
                        lecturer: course['lecturer'],
                        progressPercent: course['progress'],
                        rightIcon: course['icon'],
                      );
                    // ignore: unnecessary_to_list_in_spreads
                    }).toList(),

                    SizedBox(height: 24), // Extra padding at bottom
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}