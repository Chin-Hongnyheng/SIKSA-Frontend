import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TeacherAttendance extends StatefulWidget {
  const TeacherAttendance({super.key});

  @override
  State<TeacherAttendance> createState() => _TeacherAttendanceState();
}

class _TeacherAttendanceState extends State<TeacherAttendance> {
  String searchQuery = "";
  String selectedYear = "Year";
  String selectedCourse = "Course";

  bool showMoreStudents = false;
  String? selectedStudent;

  // ✅ MORE STUDENTS ADDED
  List<String> students = [
    "Chin Hongnyheng",
    "Sok Dara",
    "Kim Lina",
    "Chan Vuthy",
    "Ly Sopheak",
    "Student A",
    "Student B",
    "Student C",
    "Student D",
    "Student E",
  ];

  List<int> days = [16, 17, 18, 19, 20, 21];

  Map<String, List<bool>> attendance = {};

  @override
  void initState() {
    super.initState();
    for (var student in students) {
      attendance[student] = List.generate(days.length, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> visibleStudents =
        showMoreStudents ? students : students.take(5).toList();

    List<String> filteredStudents = visibleStudents
        .where((s) => s.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Colors.green,
          centerTitle: true,
          title: const Text("Attendance Dashboard"),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 SEARCH
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Search",
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),

                DropdownButton<String>(
                  value: selectedYear,
                  items: ["Year", "2024", "2025"]
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedYear = value!;
                    });
                  },
                ),

                const SizedBox(width: 8),

                DropdownButton<String>(
                  value: selectedCourse,
                  items: ["Course", "Mobile", "Web"]
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCourse = value!;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // HEADER
            Row(
              children: [
                const Expanded(flex: 2, child: Text("Student Name")),
                ...days.map((d) =>
                    Expanded(child: Center(child: Text("$d"))))
              ],
            ),

            const SizedBox(height: 8),

            // STUDENTS
            ...filteredStudents.map((student) {
              bool isSelected = selectedStudent == student;

              return GestureDetector(
                onTap: () {
                  setState(() {
  
                    if (selectedStudent == student) {
                      selectedStudent = null;
                    } else {
                      selectedStudent = student;
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(student)),

                      ...List.generate(days.length, (index) {
                        bool checked =
                            attendance[student]![index];

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                attendance[student]![index] =
                                    !checked;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.all(15),
                              width: 0,
                              height: 14,
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.circular(4),
                                color: checked
                                    ? Colors.green
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                        );
                      })
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),


            GestureDetector(
              onTap: () {
                setState(() {
                  showMoreStudents = !showMoreStudents;
                });
              },
              child: Column(
                children: [
                  Icon(showMoreStudents
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down),
                  const Divider(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ✅ SHOW STUDENT ATTENDANCE
            if (selectedStudent != null)
              StudentAttendanceView(student: selectedStudent!),
          ],
        ),
      ),
    );
  }
}


class StudentAttendanceView extends StatefulWidget {
  final String student;

  const StudentAttendanceView({super.key, required this.student});

  @override
  State<StudentAttendanceView> createState() =>
      _StudentAttendanceViewState();
}

class _StudentAttendanceViewState
    extends State<StudentAttendanceView> {
  DateTime selectedDate = DateTime.now();

  bool week1Expanded = true;
  bool week2Expanded = false;

  String getMonth() {
    return DateFormat('d MMMM yyyy').format(selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 📅 DATE (ARROW 3 FIXED)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(getMonth()),
              ],
            ),
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
            )
          ],
        ),

        const SizedBox(height: 12),

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
          Text(value,
              style: TextStyle(
                  color: borderColor,
                  fontWeight: FontWeight.bold)),
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
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.all(12),
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
                    Text(dateRange,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
                Icon(isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),

        if (isExpanded)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Attendance rows here..."),
          )
      ],
    );
  }
}