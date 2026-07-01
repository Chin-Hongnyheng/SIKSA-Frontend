import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/selected_card.dart';

import '../../widgets/floating_line_background.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Animated green background ──────────────────────────────────
          const Positioned.fill(
            child: FloatingLinesBackground(
              colors: [Color(0xFF00FF88), Color(0xFF00DD66), Color(0xFF1E6B2D)],
              lineCount: 6,
              animationSpeed: 0.5,
            ),
          ),

          // ── White body panel ───────────────────────────────────────────
          Positioned(
            top: topPadding + 70,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What would you like to do?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFA9A7A7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Manage Attendance ──────────────────────────────────
                    SelectedCard(
                      icon: Icons.fact_check_outlined,
                      iconColor: Colors.green,
                      title: 'Manage Attendance',
                      subtitle:
                          'Mark your student attendance for an active session',
                      onTap: () => context.push('/attendance/home'),
                    ),

                    const SizedBox(height: 14),

                    // ── Mark Attendance ──────────────────────────────────
                    SelectedCard(
                      icon: Icons.how_to_reg_rounded,
                      iconColor: Colors.orange,
                      title: 'Mark Attendance',
                      subtitle:
                          'Mark your own attendance for an active session',
                      onTap: () => context.push('/attendance/mark'),
                    ),

                    const SizedBox(height: 14),

                    // ── My Attendance ────────────────────────────────────
                    SelectedCard(
                      icon: Icons.history_edu_outlined,
                      iconColor: Colors.blue,
                      title: 'My Attendance',
                      subtitle: 'View your attendance history and records',
                      onTap: () => context.push('/attendance/student'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Top header (floats over the green background) ──────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.white,
                    ),
                    const Expanded(
                      child: Text(
                        'Attendance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
