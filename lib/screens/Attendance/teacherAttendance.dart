import 'package:flutter/material.dart';

import '../../widgets/student_mini_dashboard.dart';

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

  final List<int> days = [16, 17, 18, 19, 20, 21];

  final List<Map<String, dynamic>> students = [
    {
      "_id": "student1",
      "userName": "student1",
    },
    {
      "_id": "student2",
      "userName": "student2",
    },
    {
      "_id": "student3",
      "userName": "student3",
    },
  ];

  final Map<String, List<bool>> attendance = {
    "student1": [false, true, true, true, false, true],
    "student2": [false, false, true, false, true, false],
    "student3": [true, true, false, true, false, false],
  };

  List<Map<String, dynamic>> get filteredStudents {
    final visibleStudents =
        showMoreStudents ? students : students.take(1).toList();

    if (searchQuery.trim().isEmpty) {
      return visibleStudents;
    }

    return visibleStudents.where((student) {
      final name = student["userName"]?.toString().toLowerCase() ?? "";
      return name.contains(searchQuery.toLowerCase());
    }).toList();
  }

  void toggleAttendance(String studentId, int index) {
    setState(() {
      attendance[studentId] ??= List.generate(days.length, (_) => false);
      attendance[studentId]![index] = !attendance[studentId]![index];
    });
  }

  void showStudentDashboardPopup(Map<String, dynamic> student) {
    final studentId = student["_id"]?.toString() ?? "student1";
    final studentName = student["userName"]?.toString() ?? "student1";

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.86,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$studentName Attendance",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: SingleChildScrollView(
                    child: StudentMiniDashboard(
                      studentId: studentId,
                      studentName: studentName,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildSearchBox() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            size: 28,
            color: Colors.black,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: "Search",
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        icon: const Icon(Icons.keyboard_arrow_down),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: Text(
              "Student Name",
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          ...days.map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  "$day",
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildStudentRow(Map<String, dynamic> student) {
    final studentId = student["_id"]?.toString() ?? "";
    final studentName = student["userName"]?.toString() ?? "No Name";

    attendance[studentId] ??= List.generate(days.length, (_) => false);

    return GestureDetector(
      onTap: () {
        showStudentDashboardPopup(student);
      },
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                studentName,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            ...List.generate(days.length, (index) {
              final checked = attendance[studentId]![index];

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    toggleAttendance(studentId, index);
                  },
                  child: Center(
                    child: Container(
                      width: 90,
                      height: 16,
                      decoration: BoxDecoration(
                        color: checked ? Colors.green : Colors.transparent,
                        border: Border.all(
                          color: Colors.black,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget buildShowMoreButton() {
    return Column(
      children: [
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () {
            setState(() {
              showMoreStudents = !showMoreStudents;
            });
          },
          child: Icon(
            showMoreStudents
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            size: 28,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 1.3,
          width: double.infinity,
          color: Colors.black,
        ),
      ],
    );
  }

  Widget buildTeacherAttendanceBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 40),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: buildSearchBox(),
              ),
              const SizedBox(width: 18),
              buildDropdown(
                value: selectedYear,
                items: const ["Year", "2024", "2025", "2026"],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedYear = value;
                  });
                },
              ),
              const SizedBox(width: 18),
              buildDropdown(
                value: selectedCourse,
                items: const ["Course", "Mobile", "Web"],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedCourse = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          buildHeaderRow(),
          ...filteredStudents.map((student) {
            return buildStudentRow(student);
          }),
          buildShowMoreButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Colors.green,
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Attendance Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
      ),
      body: buildTeacherAttendanceBody(),
    );
  }
}