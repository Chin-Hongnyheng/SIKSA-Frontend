// ignore_for_file: deprecated_member_use, unnecessary_null_comparison, unnecessary_non_null_assertion

import 'package:flutter/material.dart';
import '../models/schedule_model.dart';

const Color _accentColor = Color(0xFF1E6B2D);

class ScheduleMonthView extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final List<ScheduleModel> allSchedules;
  final void Function(ScheduleModel) onEdit;
  final void Function(ScheduleModel) onDelete;
  final ValueChanged<DateTime> onDateSelected;

  const ScheduleMonthView({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.allSchedules,
    required this.onEdit,
    required this.onDelete,
    required this.onDateSelected,
  });

  // MON=0 … SUN=6 in the grid; SAT=5, SUN=6
  static const _weekdayLabels = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  List<_CalendarDay> _buildCalendarDays() {
    final firstOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final leadingBlanks = (firstOfMonth.weekday - 1) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(
      focusedMonth.year,
      focusedMonth.month,
    );

    final cells = <_CalendarDay>[];

    for (var i = leadingBlanks; i > 0; i--) {
      cells.add(
        _CalendarDay(
          date: firstOfMonth.subtract(Duration(days: i)),
          isCurrentMonth: false,
        ),
      );
    }

    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(
        _CalendarDay(
          date: DateTime(focusedMonth.year, focusedMonth.month, d),
          isCurrentMonth: true,
        ),
      );
    }

    var trailing = 1;
    while (cells.length % 7 != 0) {
      cells.add(
        _CalendarDay(
          date: DateTime(
            focusedMonth.year,
            focusedMonth.month,
            daysInMonth + trailing,
          ),
          isCurrentMonth: false,
        ),
      );
      trailing++;
    }

    return cells;
  }

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
    final today = DateTime.now();
    final cells = _buildCalendarDays();
    final rowCount = (cells.length / 7).ceil();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // ── Weekday header — no border, no background ──────────────────
          Row(
            children: List.generate(7, (col) {
              // col 5 = SAT, col 6 = SUN (0-indexed MON…SUN)
              final isWeekend = col == 5 || col == 6;
              return Expanded(
                child: SizedBox(
                  height: 32,
                  child: Center(
                    child: Text(
                      _weekdayLabels[col],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isWeekend ? Colors.red : const Color(0xFF6B6B6B),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          // ── Calendar rows ───────────────────────────────────────────────
          ...List.generate(rowCount, (row) {
            final week = cells.sublist(row * 7, row * 7 + 7);
            return _buildWeekRow(week, today);
          }),
        ],
      ),
    );
  }

  Widget _buildWeekRow(List<_CalendarDay> week, DateTime today) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: week.asMap().entries.map((entry) {
        final col = entry.key;
        final cell = entry.value;
        final date = cell.date;
        final isCurrent = cell.isCurrentMonth;
        // col 5 = SAT, col 6 = SUN
        final isWeekend = col == 5 || col == 6;

        final isSelected =
            isCurrent &&
            date.year == selectedDate.year &&
            date.month == selectedDate.month &&
            date.day == selectedDate.day;

        final isToday =
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;

        final tasks = isCurrent
            ? allSchedules.where((s) => _isOnDate(s, date)).toList()
            : <ScheduleModel>[];

        // Number color: selected → white; weekend → red; other month → faded; normal → dark
        Color numberColor;
        if (isSelected) {
          numberColor = Colors.white;
        } else if (!isCurrent) {
          numberColor = const Color(0xFFCCCCCC);
        } else if (isWeekend) {
          numberColor = Colors.red;
        } else {
          numberColor = const Color(0xFF212121);
        }

        return Expanded(
          child: GestureDetector(
            onTap: isCurrent ? () => onDateSelected(date) : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              color: isSelected
                  ? _accentColor.withOpacity(0.06)
                  : Colors.transparent,
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Day number centred under the weekday label
                  Container(
                    width: 26,
                    height: 26,
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: numberColor,
                        ),
                      ),
                    ),
                  ),

                  // Task pills
                  if (tasks.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    ...tasks.take(2).map((t) {
                      final c = _taskColor(t);
                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: 2,
                          left: 2,
                          right: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: c.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          t.courseCode,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: c,
                          ),
                          overflow: TextOverflow.clip,
                          maxLines: 1,
                        ),
                      );
                    }),
                    if (tasks.length > 2)
                      Text(
                        '+${tasks.length - 2}',
                        style: const TextStyle(
                          fontSize: 8,
                          color: Color(0xFF6B6B6B),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CalendarDay {
  final DateTime date;
  final bool isCurrentMonth;
  const _CalendarDay({required this.date, required this.isCurrentMonth});
}
