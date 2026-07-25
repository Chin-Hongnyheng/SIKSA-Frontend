import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'attendance_row.dart';

class WeekSection extends StatelessWidget {
  final String title;
  final String dateRange;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<dynamic>? records;

  const WeekSection({
    super.key,
    required this.title,
    required this.dateRange,
    required this.isExpanded,
    required this.onToggle,
    this.records,
  });

  String _getDay(String? date) {
    if (date == null || date.isEmpty) return "-";
    return date.split("-").last;
  }

  String _getWeekDay(String? date) {
    if (date == null || date.isEmpty) return "-";

    try {
      return DateFormat('EEE').format(DateTime.parse(date));
    } catch (_) {
      return "-";
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return "-";

    try {
      final parts = time.split(":");
      final dt = DateTime(
        2026,
        1,
        1,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return time;
    }
  }

  String _getTotalHours(String? checkIn, String? checkOut) {
    if (checkIn == null ||
        checkOut == null ||
        checkIn.isEmpty ||
        checkOut.isEmpty) {
      return "-";
    }

    try {
      final inParts = checkIn.split(":");
      final outParts = checkOut.split(":");

      final inTime = DateTime(
        2026,
        1,
        1,
        int.parse(inParts[0]),
        int.parse(inParts[1]),
      );

      final outTime = DateTime(
        2026,
        1,
        1,
        int.parse(outParts[0]),
        int.parse(outParts[1]),
      );

      final diff = outTime.difference(inTime);

      return "${diff.inHours}h ${diff.inMinutes.remainder(60).toString().padLeft(2, '0')}m";
    } catch (_) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeRecords = records ?? [];

    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    Text(
                      dateRange,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          if (safeRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text("No attendance records"),
            )
          else
            ...safeRecords.map((record) {
              final date = record["date"]?.toString();
              final checkIn = record["checkIn"]?.toString();
              final checkOut = record["checkOut"]?.toString();
              final status = record["status"]?.toString() ?? "";

              return AttendanceRow(
                day: _getDay(date),
                weekDay: _getWeekDay(date),
                checkIn: _formatTime(checkIn),
                checkOut: _formatTime(checkOut),
                totalHours: _getTotalHours(checkIn, checkOut),
                status: status,
              );
            }),
        ],
      ],
    );
  }
}