import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/attendance_session_model.dart';
import '../../models/attendance_record_model.dart';
import '../../providers/attendance_provider.dart';
import '../../service/course_service.dart';
import '../../widgets/floating_line_background.dart';
import '../../widgets/student_mini_dashboard.dart';

class AttendanceSessionReportPage extends StatefulWidget {
  final AttendanceSessionModel session;

  const AttendanceSessionReportPage({super.key, required this.session});

  @override
  State<AttendanceSessionReportPage> createState() =>
      _AttendanceSessionReportPageState();
}

class _AttendanceSessionReportPageState
    extends State<AttendanceSessionReportPage> {
  final CourseService _courseService = CourseService();

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> students = [];
  List<AttendanceRecordModel> records = [];

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  Future<void> loadReport() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final provider = context.read<AttendanceProvider>();
      final rawStudents = await _courseService.getCourseSubscribers(
        widget.session.courseCode,
      );
      await provider.loadSessionAttendance(widget.session.id);

      if (!mounted) return;

      setState(() {
        students = (rawStudents as List)
            .map<Map<String, dynamic>>(
              (s) => Map<String, dynamic>.from(s as Map),
            )
            .toList();
        records = List.from(provider.sessionRecords);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _openEditPage() async {
    final provider = context.read<AttendanceProvider>();

    // Use Navigator.push — properly awaits until page is popped
    await context.push('/attendance/home/list/create/${widget.session.id}');

    if (!mounted) return;
    await provider.loadSessionAttendance(widget.session.id);
    if (!mounted) return;
    // Read directly from provider — no re-fetch, trust what edit page saved
    setState(() {
      records = List.from(provider.sessionRecords);
    });
  }

  AttendanceRecordModel? _findRecord(String studentId) {
    try {
      return records.firstWhere((r) => r.studentId == studentId);
    } catch (_) {
      return null;
    }
  }

  String _totalTime(String? checkIn, String? checkOut) {
    if (checkIn == null || checkOut == null) return '-';
    if (checkIn.isEmpty || checkOut.isEmpty) return '-';
    try {
      final sp = checkIn.split(':');
      final ep = checkOut.split(':');
      final start = Duration(
        hours: int.parse(sp[0]),
        minutes: int.parse(sp[1]),
      );
      final end = Duration(hours: int.parse(ep[0]), minutes: int.parse(ep[1]));
      final diff = end - start;
      if (diff.isNegative) return '-';
      final h = diff.inHours;
      final m = diff.inMinutes.remainder(60);
      if (h == 0) return '${m}m';
      if (m == 0) return '${h}h';
      return '${h}h ${m}m';
    } catch (_) {
      return '-';
    }
  }

  Color _statusColor(String status) {
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
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    if (status.isEmpty) return 'Not marked';
    return status[0].toUpperCase() + status.substring(1);
  }

  String _getSessionStatus() {
    if (!widget.session.isActive) return 'Closed';
    try {
      final now = DateTime.now();
      final sp = widget.session.startTime.split(':');
      final ep = widget.session.endTime.split(':');
      final start = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(sp[0]),
        int.parse(sp[1]),
      );
      final end = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(ep[0]),
        int.parse(ep[1]),
      );
      if (now.isBefore(start)) return 'Upcoming';
      if (now.isAfter(end)) return 'Finished';
      return 'Active';
    } catch (_) {
      return 'Unknown';
    }
  }

  void _openMiniDashboard(Map<String, dynamic> student) {
    final studentId = student['id']?.toString() ?? '';
    final studentName = student['userName']?.toString() ?? studentId;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                children: [
                  Expanded(
                    child: Text(
                      '$studentName Attendance',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Flexible(
                child: SingleChildScrollView(
                  child: StudentMiniDashboard(
                    studentId: studentId,
                    studentName: studentName,
                    courseCode: widget.session.courseCode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryHeader() {
    int present = 0, late = 0, absent = 0, permission = 0;
    for (final r in records) {
      switch (r.status?.toLowerCase()) {
        case 'present':
          present++;
          break;
        case 'late':
          late++;
          break;
        case 'absent':
          absent++;
          break;
        case 'permission':
          permission++;
          break;
      }
    }

    final sessionStatus = _getSessionStatus();
    final statusColors = {
      'Active': Colors.green,
      'Upcoming': Colors.orange,
      'Finished': Colors.red,
      'Closed': Colors.grey,
      'Unknown': Colors.grey,
    };
    final badgeColor = statusColors[sessionStatus] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.session.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  sessionStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.session.courseCode}  •  ${widget.session.date}  •  '
            '${widget.session.startTime} – ${widget.session.endTime}',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _miniCount('Present', present, Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _miniCount('Late', late, Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _miniCount('Absent', absent, Colors.red)),
              const SizedBox(width: 8),
              Expanded(
                child: _miniCount('Permission', permission, Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniCount(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Student',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Check In',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Check Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _studentRow(Map<String, dynamic> student, int index) {
    final studentId = student['id']?.toString() ?? '';
    final studentName = student['userName']?.toString() ?? studentId;
    final record = _findRecord(studentId);

    final status = record?.status ?? '';
    final checkIn = record?.checkIn ?? '-';
    final checkOut = record?.checkOut ?? '-';
    final total = _totalTime(record?.checkIn, record?.checkOut);

    return InkWell(
      onTap: () => _openMiniDashboard(student),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: index.isEven ? Colors.white : Colors.grey.shade50,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.green.withOpacity(0.12),
                    child: Text(
                      studentName.isNotEmpty
                          ? studentName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      studentName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor(status)),
                  ),
                  child: Text(
                    _statusText(status),
                    style: TextStyle(
                      fontSize: 11,
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(flex: 2, child: Text(checkIn)),
            Expanded(flex: 2, child: Text(checkOut)),
            Expanded(flex: 2, child: Text(total)),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _tableHeader(),
          if (students.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No students found'),
            )
          else
            ...students.asMap().entries.map((e) => _studentRow(e.value, e.key)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditPage,
        backgroundColor: AppColors.primary,
        tooltip: 'Edit Attendance',
        child: const Icon(Icons.edit, size: 28),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: FloatingLinesBackground(
              colors: [Color(0xFF00FF88), Color(0xFF00DD66), Color(0xFF1E6B2D)],
              lineCount: 6,
              animationSpeed: 0.5,
            ),
          ),
          Positioned(
            top: topPadding + 70,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: RefreshIndicator(
                onRefresh: loadReport,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _summaryHeader(),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(width: 900, child: _buildTable()),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
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
                        'Attendance Report',
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
