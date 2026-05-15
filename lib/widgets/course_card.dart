// lib/widgets/course_card_widget.dart
import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final String title;
  final String lecturer;
  final double progressPercent;
  final IconData rightIcon;

  const CourseCard({super.key, 
    required this.title,
    required this.lecturer,
    required this.progressPercent,
    required this.rightIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Defines standard colors based on the image
    final Color primaryGreen = Color(0xFF388E3C);
    final Color progressGreen = Color(0xFF4CAF50);
    final Color textGray = Color(0xFF757575);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Header (Title & Icon)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Lecturer: $lecturer',
                      style: TextStyle(color: textGray, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(
                rightIcon,
                color: primaryGreen,
                size: 32,
              ),
            ],
          ),
          SizedBox(height: 16),

          // Course Progress
          Text(
            'Courses Progress',
            style: TextStyle(color: textGray, fontSize: 14),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progressPercent,
                  color: progressGreen,
                  backgroundColor: Colors.grey[200],
                  minHeight: 12, // Match the visual thickness
                  borderRadius: BorderRadius.circular(10), // Optional smooth edges
                ),
              ),
              SizedBox(width: 12),
              Text(
                '${(progressPercent * 100).toInt()}%',
                style: TextStyle(
                  color: textGray,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Course Buttons (Quiz, Assignment, Exam)
          Row(
            children: [
              Expanded(
                child: _buildCourseButton(
                  Icons.assignment_outlined,
                  'Quiz',
                  progressGreen,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildCourseButton(
                  Icons.assignment,
                  'Assignment',
                  progressGreen,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildCourseButton(
                  Icons.school_outlined,
                  'Exam',
                  progressGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Reusable helper for course buttons
  Widget _buildCourseButton(IconData icon, String label, Color buttonColor) {
    return ElevatedButton(
      onPressed: () {}, // Handled by backend, placeholder for now
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white, // Text and icon color
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }
}