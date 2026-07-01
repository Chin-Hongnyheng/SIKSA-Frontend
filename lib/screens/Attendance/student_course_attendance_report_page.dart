import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/attendance_record_model.dart';
import '../../widgets/floating_line_background.dart';

class StudentCourseAttendanceReportPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String courseCode;
  final String courseName;

  const StudentCourseAttendanceReportPage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.courseCode,
    required this.courseName,
  });

  @override
  State<StudentCourseAttendanceReportPage> createState() =>
      _StudentCourseAttendanceReportPageState();
}

class _StudentCourseAttendanceReportPageState
    extends State<StudentCourseAttendanceReportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().loadStudentRecords(widget.studentId);
    });
  }

  // ── Status styling helpers ──────────────────────────────────────────────

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'present':
        return const Color(0xFF1E6B2D);
      case 'late':
        return const Color(0xFFE65100);
      case 'absent':
        return const Color(0xFFC62828);
      case 'permission':
        return const Color(0xFF1565C0);
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'present':
        return Icons.check_circle_rounded;
      case 'late':
        return Icons.watch_later_rounded;
      case 'absent':
        return Icons.cancel_rounded;
      case 'permission':
        return Icons.assignment_ind_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _statusLabel(String? status) {
    if (status == null || status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  // ── Summary tile ────────────────────────────────────────────────────────

  Widget _summaryTile(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.85),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Green gradient background ────────────────────────────────
          const Positioned.fill(
            child: FloatingLinesBackground(
              colors: [Color(0xFF00FF88), Color(0xFF00DD66), Color(0xFF1E6B2D)],
              lineCount: 6,
              animationSpeed: 0.5,
            ),
          ),

          // ── White body panel ─────────────────────────────────────────
          Positioned(
            top: topPadding + 70,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(color: Color(0xFFF5F6FA)),
              child: Consumer<AttendanceProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E6B2D),
                      ),
                    );
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Could not load records',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => context
                                .read<AttendanceProvider>()
                                .loadStudentRecords(widget.studentId),
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFF1E6B2D),
                            ),
                            label: const Text(
                              'Try again',
                              style: TextStyle(color: Color(0xFF1E6B2D)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter records to this course only
                  final records =
                      provider.studentRecords
                          .where((r) => r.courseCode == widget.courseCode)
                          .toList()
                        ..sort(
                          (a, b) => (b.date ?? '').compareTo(a.date ?? ''),
                        );

                  // Compute summary counts
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
                  final total = records.length;
                  final attendedPct = total == 0
                      ? 0.0
                      : (present + late) / total;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    children: [
                      // ── Attendance rate bar ──────────────────────────
                      if (total > 0) ...[
                        _AttendanceRateCard(
                          attendedPct: attendedPct,
                          total: total,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── Summary row ──────────────────────────────────
                      Row(
                        children: [
                          _summaryTile(
                            'Present',
                            present,
                            const Color(0xFF1E6B2D),
                          ),
                          const SizedBox(width: 8),
                          _summaryTile('Late', late, const Color(0xFFE65100)),
                          const SizedBox(width: 8),
                          _summaryTile(
                            'Absent',
                            absent,
                            const Color(0xFFC62828),
                          ),
                          const SizedBox(width: 8),
                          _summaryTile(
                            'Leave',
                            permission,
                            const Color(0xFF1565C0),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ── Section label ────────────────────────────────
                      Text(
                        total == 0
                            ? 'No records yet'
                            : 'Session History  ·  $total sessions',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Empty state ──────────────────────────────────
                      if (records.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy_rounded,
                                size: 56,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No attendance recorded\nfor this course yet',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Record list ──────────────────────────────────
                      ...records.map(
                        (record) => _RecordCard(
                          record: record,
                          statusColor: _statusColor(record.status),
                          statusIcon: _statusIcon(record.status),
                          statusLabel: _statusLabel(record.status),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // ── Top header ───────────────────────────────────────────────
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
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.courseName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.courseCode,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Attendance rate card
// ─────────────────────────────────────────────────────────────────────────────

class _AttendanceRateCard extends StatelessWidget {
  const _AttendanceRateCard({required this.attendedPct, required this.total});

  final double attendedPct;
  final int total;

  Color get _rateColor {
    if (attendedPct >= 0.8) return const Color(0xFF1E6B2D);
    if (attendedPct >= 0.6) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  @override
  Widget build(BuildContext context) {
    final pct = (attendedPct * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance Rate',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: _rateColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: attendedPct,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_rateColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Based on $total recorded sessions',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single record card
// ─────────────────────────────────────────────────────────────────────────────

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
  });

  final AttendanceRecordModel record;
  final Color statusColor;
  final IconData statusIcon;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.09)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status icon badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Date + check-in info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.date ?? 'No date',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (record.checkIn != null && record.checkIn!.isNotEmpty)
                    Text(
                      'Checked in at ${record.checkIn}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    )
                  else
                    Text(
                      'No check-in recorded',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
