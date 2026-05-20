import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/stat_card.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final Color backgroundGray = const Color(0xFFF9F9F9);

    return Scaffold(
      backgroundColor: backgroundGray,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            DashboardHeader(
              name: 'Vong',
              subtitle: 'Your class start today.',
              // avatarUrl: 'https://example.com/avatar.png',
              onBellPressed: () {
                // Navigator.pushNamed(context, '/notifications');
                context.push('/notifications');
              },
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Row with stat cards
                    Row(
                      children: const [
                        Expanded(
                          child: StatCard(
                            value: '18',
                            label: 'Classes Attended',
                            progress: 1.0,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            value: '70%',
                            label: 'Performance Rate',
                            progress: 0.7,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Placeholder for other dashboard widgets
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(''),
                        ],
                      ),
                    ),
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
