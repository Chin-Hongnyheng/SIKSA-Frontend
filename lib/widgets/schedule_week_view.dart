import 'dart:math';
import 'package:flutter/material.dart';
import '../models/schedule_model.dart';

const Color _accentColor = Color(0xFF1E6B2D);
const Color _lineColor = Color(0xFFE9ECEF);
const int _startHour = 7;
const int _endHour = 22;
const double _hourHeight = 60.0;
const double _timeGutterWidth = 40.0; // narrower gutter, shifted left

class ScheduleWeekView extends StatelessWidget {
  final DateTime visibleStartDate;
  final DateTime selectedDate;
  final List<ScheduleModel> allSchedules;
  final void Function(ScheduleModel) onEdit;
  final void Function(ScheduleModel) onDelete;
  final ValueChanged<DateTime> onDateSelected;

  const ScheduleWeekView({
    super.key,
    required this.visibleStartDate,
    required this.selectedDate,
    required this.allSchedules,
    required this.onEdit,
    required this.onDelete,
    required this.onDateSelected,
  });

  static const List<String> _weekdayLabels = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  // ── Recurrence ──────────────────────────────────────────────────────────
  bool _isOnDate(ScheduleModel s, DateTime date) {
    final r = s.recurrenceType.toLowerCase().trim();
    if (r == 'none') {
      if (s.date == null) return false;
      try {
        final d = DateTime.parse(s.date!).toUtc();
        return d.year == date.year &&
            d.month == date.month &&
            d.day == date.day;
      } catch (_) {
        return false;
      }
    }

    final start = s.startDate != null ? _parseDate(s.startDate!) : null;
    final end = s.endDate != null ? _parseDate(s.endDate!) : null;
    if (start == null || end == null) return false;

    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly.isBefore(start) || dateOnly.isAfter(end)) return false;

    if (r == 'daily') return true;

    if (r == 'weekly') {
      if (s.selectedDays == null || s.selectedDays!.isEmpty) return false;
      const names = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ];
      return s.selectedDays!
          .map((d) => d.toLowerCase().trim())
          .contains(names[date.weekday - 1]);
    }

    if (r == 'monthly') {
      if (s.selectedDays == null || s.selectedDays!.isEmpty) return false;
      return s.selectedDays!
          .map((d) => int.tryParse(d.trim().split(' ').first))
          .whereType<int>()
          .contains(date.day);
    }

    return false;
  }

  DateTime? _parseDate(String s) {
    try {
      final dt = DateTime.parse(s).toUtc();
      return DateTime(dt.year, dt.month, dt.day);
    } catch (_) {
      return null;
    }
  }

  double _timeToOffset(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return ((hour + minute / 60) - _startHour) * _hourHeight;
  }

  Color _taskColor(ScheduleModel s) {
    try {
      if (s.color == null || s.color!.isEmpty) return _accentColor;
      final hex = s.color!.replaceAll('#', '');
      final rrggbb = hex.length > 6 ? hex.substring(hex.length - 6) : hex;
      return Color(int.parse('FF$rrggbb', radix: 16));
    } catch (_) {
      return _accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      7,
      (i) => visibleStartDate.add(Duration(days: i)),
    );
    final hours = List.generate(
      _endHour - _startHour + 1,
      (i) => _startHour + i,
    );
    final totalHeight = hours.length * _hourHeight;
    final today = DateTime.now();

    return Column(
      children: [
        // ── Day header strip ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 16),
          child: Row(
            children: [
              // Spacer to align with the time gutter
              SizedBox(width: _timeGutterWidth + 8),
              ...days.asMap().entries.map((entry) {
                final i = entry.key;
                final date = entry.value;
                final isWeekend = date.weekday == 6 || date.weekday == 7;
                final isSelected =
                    date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;

                final labelColor = isSelected
                    ? _accentColor
                    : isWeekend
                    ? Colors.red
                    : const Color(0xFF6B6B6B);

                final numberColor = isSelected
                    ? Colors.white
                    : isWeekend
                    ? Colors.red
                    : const Color(0xFF212121);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDateSelected(date),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _weekdayLabels[date.weekday - 1],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _accentColor
                                : isToday
                                ? _accentColor.withOpacity(0.15)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: numberColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // ── Timeline ─────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 8, right: 16),
            child: SizedBox(
              height: totalHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Narrow time gutter
                  SizedBox(
                    width: _timeGutterWidth,
                    child: Column(
                      children: hours.map((hour) {
                        return SizedBox(
                          height: _hourHeight,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                '${hour.toString().padLeft(2, '0')}:00',
                                style: const TextStyle(
                                  color: Color(0xFF6B6B6B),
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 7 day columns
                  Expanded(
                    child: Stack(
                      children: [
                        // Hour lines
                        for (var i = 0; i < hours.length; i++)
                          Positioned(
                            top: i * _hourHeight,
                            left: 0,
                            right: 0,
                            child: Container(height: 1, color: _lineColor),
                          ),

                        // Columns + task chips
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final colWidth = constraints.maxWidth / 7;
                            return Stack(
                              children: [
                                // Vertical dividers
                                for (var col = 1; col < 7; col++)
                                  Positioned(
                                    top: 0,
                                    bottom: 0,
                                    left: colWidth * col,
                                    child: Container(
                                      width: 1,
                                      color: _lineColor,
                                    ),
                                  ),

                                // Tasks
                                for (var di = 0; di < days.length; di++)
                                  ..._buildDayTasks(days[di], di, colWidth),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDayTasks(DateTime date, int col, double colWidth) {
    final tasks = allSchedules.where((s) => _isOnDate(s, date)).toList();
    return tasks.map((task) {
      final top = max(0.0, _timeToOffset(task.startTime));
      final bottom = _timeToOffset(task.endTime);
      final height = max(22.0, bottom - top);
      final color = _taskColor(task);

      return Positioned(
        top: top,
        left: colWidth * col + 2,
        width: colWidth - 4,
        height: height,
        child: GestureDetector(
          onTap: () => onEdit(task),
          onLongPress: () => onDelete(task),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(5),
              border: Border(left: BorderSide(color: color, width: 3)),
            ),
            padding: const EdgeInsets.all(2),
            child: Center(
              child: Text(
                task.courseCode,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
