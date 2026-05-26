import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentAttendance extends StatefulWidget {
  const StudentAttendance({super.key});

  @override
  State<StudentAttendance> createState() => _StudentAttendanceState();
}

class _StudentAttendanceState extends State<StudentAttendance> {
  DateTime selectedDate = DateTime.now();

  bool week1Expanded = true;
  bool week2Expanded = false;

  String getCurrentMonth() {
    return DateFormat('d MMMM yyyy').format(selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),

      // ✅ Taller AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Colors.green,
          centerTitle: true,
          title: const Text(
            "My Attendance",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
      ),

      // ✅ FIXED SCROLL
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📅 Month + Date Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      getCurrentMonth(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                // 🔽 Date Picker Arrow
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );

                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 📊 Summary Cards Row 1
            Row(
              children: const [
                Expanded(
                  child: SummaryCard(
                    title: "Early Leave",
                    value: "3",
                    color: Color(0xFFFFE5E5),
                    borderColor: Colors.red,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: "Absents",
                    value: "4",
                    color: Color(0xFFFFE5E5),
                    borderColor: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 📊 Summary Cards Row 2
            Row(
              children: const [
                Expanded(
                  child: SummaryCard(
                    title: "Late in",
                    value: "0",
                    color: Color(0xFFF2F2F2),
                    borderColor: Colors.orange,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: "Permission",
                    value: "2",
                    color: Color(0xFFFFF0E5),
                    borderColor: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 📅 Week Sections
            WeekSection(
              title: "Week 1",
              dateRange: "16-21 March",
              isExpanded: week1Expanded,
              onToggle: () {
                setState(() {
                  week1Expanded = !week1Expanded;
                });
              },
            ),

            const SizedBox(height: 12),

            WeekSection(
              title: "Week 2",
              dateRange: "23-28 March",
              isExpanded: week2Expanded,
              onToggle: () {
                setState(() {
                  week2Expanded = !week2Expanded;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Color borderColor;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: borderColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }
}

class WeekSection extends StatelessWidget {
  final String title;
  final String dateRange;
  final bool isExpanded;
  final VoidCallback onToggle;

  const WeekSection({
    super.key,
    required this.title,
    required this.dateRange,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
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
                  Text(dateRange, style: const TextStyle(fontSize: 12)),
                ],
              ),
              IconButton(
                icon: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
                onPressed: onToggle,
              ),
            ],
          ),
        ),

        if (isExpanded) ...[
          const SizedBox(height: 8),
          const AttendanceRow(day: "16", weekDay: "Mon"),
          const AttendanceRow(day: "17", weekDay: "Tue"),
          const AttendanceRow(day: "18", weekDay: "Wed"),
        ],
      ],
    );
  }
}

class AttendanceRow extends StatelessWidget {
  final String day;
  final String weekDay;

  const AttendanceRow({super.key, required this.day, required this.weekDay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(weekDay),
            ],
          ),
          Column(
            children: const [
              Text("7:00 AM"),
              Text("Check in", style: TextStyle(fontSize: 10)),
            ],
          ),
          Column(
            children: const [
              Text("5:00 PM"),
              Text("Check out", style: TextStyle(fontSize: 10)),
            ],
          ),
          Column(
            children: const [
              Text("8h 00m"),
              Text("Total Hours", style: TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
