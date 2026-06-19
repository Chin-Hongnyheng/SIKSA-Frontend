// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AttendanceRow extends StatelessWidget {
  final String day;
  final String weekDay;
  final String checkIn;
  final String checkOut;
  final String totalHours;
  final String status;

  const AttendanceRow({
    super.key,
    required this.day,
    required this.weekDay,
    this.checkIn = '-',
    this.checkOut = '-',
    this.totalHours = '-',
    this.status = '',
  });

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      case 'permission':
        return Colors.blue;
      default:
        return Colors.black54;
    }
  }

  String get statusText {
    if (status.isEmpty) return '';
    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status.isEmpty
              ? Colors.transparent
              : statusColor.withOpacity(0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    day,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(weekDay),
                ],
              ),
              Column(
                children: [
                  Text(checkIn),
                  const Text("Check in", style: TextStyle(fontSize: 10)),
                ],
              ),
              Column(
                children: [
                  Text(checkOut),
                  const Text("Check out", style: TextStyle(fontSize: 10)),
                ],
              ),
              Column(
                children: [
                  Text(totalHours),
                  const Text("Total Hours", style: TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),

          if (status.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
