import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule_model.dart';
import '../models/course_model.dart';
import '../providers/schedule_provider.dart';
import '../providers/course_provider.dart';

class TodaySchedule extends StatelessWidget {
  const TodaySchedule({super.key});

  bool _shouldShowToday(ScheduleModel schedule, DateTime date) {
    final recurrence = schedule.recurrenceType.toLowerCase().trim();

    if (recurrence == 'none') {
      if (schedule.date == null) return false;
      final target = _parseDate(schedule.date!);
      return target != null && _isSameDay(target, date);
    }

    final start = schedule.startDate != null
        ? _parseDate(schedule.startDate!)
        : null;
    final end = schedule.endDate != null ? _parseDate(schedule.endDate!) : null;
    if (start == null || end == null) return false;

    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly.isBefore(start) || dateOnly.isAfter(end)) return false;

    if (recurrence == 'daily') return true;

    if (recurrence == 'weekly') {
      if (schedule.selectedDays == null || schedule.selectedDays!.isEmpty)
        return false;
      final weekdayName = _weekdayName(date.weekday);
      return schedule.selectedDays!
          .map((d) => d.toLowerCase().trim())
          .contains(weekdayName.toLowerCase());
    }

    if (recurrence == 'monthly') {
      if (schedule.selectedDays == null || schedule.selectedDays!.isEmpty)
        return false;
      final selectedDayNumbers = schedule.selectedDays!
          .map((d) => int.tryParse(d.trim().split(' ').first))
          .whereType<int>()
          .toList();
      return selectedDayNumbers.contains(date.day);
    }

    return false;
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toUtc();
      return DateTime(dt.year, dt.month, dt.day);
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  Color _getTaskColor(ScheduleModel task) {
    try {
      if (task.color.isEmpty) return const Color(0xFF1E6B2D);
      final hex = task.color.replaceAll('#', '');
      final rrggbb = hex.length > 6 ? hex.substring(hex.length - 6) : hex;
      return Color(int.parse('FF$rrggbb', radix: 16));
    } catch (_) {
      return const Color(0xFF1E6B2D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final schedules = context.watch<ScheduleProvider>().schedules;
    // Use allCourses (teaching + enrolled + discoverable), not the
    // teaching-only `courses` list — otherwise any schedule belonging to
    // a course you're enrolled in (but didn't create) can't be matched
    // and falls back to "Unknown".
    final courses = context.watch<CourseProvider>().allCourses;

    final todaySchedules =
        schedules.where((s) => _shouldShowToday(s, today)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Divider + Header ──────────────────────────────────
        const Divider(color: Colors.white24, thickness: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.today_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "Today's Schedule",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${todaySchedules.length} task${todaySchedules.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Schedule List ─────────────────────────────────────
        if (todaySchedules.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  color: Colors.white54,
                  size: 36,
                ),
                SizedBox(height: 8),
                Text(
                  'No schedule today',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ...todaySchedules.map((schedule) {
            final taskColor = _getTaskColor(schedule);
            final courseName = courses
                .firstWhere(
                  (c) => c.courseCode == schedule.courseCode,
                  orElse: () =>
                      CourseModel(courseCode: '', courseName: 'Unknown'),
                )
                .courseName;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                // 👈 clips color bar to card radius
                borderRadius: BorderRadius.circular(14),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 8, color: taskColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      courseName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF212121),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (schedule.source != null) ...[
                                    const SizedBox(width: 6),
                                    _ScheduleSourceTag(
                                      source: schedule.source!,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                schedule.courseCode,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: taskColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Time + Location
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Color(0xFF9E9E9E),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${schedule.startTime} - ${schedule.endTime}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9E9E9E),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: Color(0xFF9E9E9E),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  schedule.location,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Teaching / Enrolled tag ───────────────────────────────────────────────────

class _ScheduleSourceTag extends StatelessWidget {
  final String source; // 'own' or 'enrolled'
  const _ScheduleSourceTag({required this.source});

  @override
  Widget build(BuildContext context) {
    final isOwn = source == 'own';
    final bg = isOwn ? const Color(0xFFE6F4EA) : const Color(0xFFE3F0FB);
    final fg = isOwn ? const Color(0xFF1E6B2D) : const Color(0xFF1565C0);
    final icon = isOwn ? Icons.edit_note : Icons.school_outlined;
    final label = isOwn ? 'Teaching' : 'Enrolled';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
