import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/week_section.dart';

class StudentAttendance extends StatefulWidget {
  const StudentAttendance({super.key});

  @override
  State<StudentAttendance> createState() => _StudentAttendanceState();
}

class _StudentAttendanceState extends State<StudentAttendance> {
  DateTime selectedDate = DateTime.now();

  bool week1Expanded = true;
  bool week2Expanded = false;

  String _getCurrentMonth() => DateFormat('d MMMM yyyy').format(selectedDate);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Month + date picker ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _getCurrentMonth(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Summary cards ──
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

            // ── Week sections (no records passed → shows static placeholder rows) ──
            WeekSection(
              title: "Week 1",
              dateRange: "16-21 March",
              isExpanded: week1Expanded,
              onToggle: () => setState(() => week1Expanded = !week1Expanded),
            ),

            const SizedBox(height: 12),

            WeekSection(
              title: "Week 2",
              dateRange: "23-28 March",
              isExpanded: week2Expanded,
              onToggle: () => setState(() => week2Expanded = !week2Expanded),
            ),
          ],
        ),
      ),
    );
  }
}