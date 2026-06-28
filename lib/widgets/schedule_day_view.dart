import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../models/schedule_model.dart';
import '../models/course_model.dart';
import '../providers/course_provider.dart';

const Color _accentColor = Color(0xFF1E6B2D);
const Color _inactiveText = Color(0xFF5C5C5C);
const Color _lineColor = Color(0xFFE9ECEF);
const int _startHour = 7;
const int _endHour = 22;
const double _hourHeight = 96.0;

int _timeToMinutes(String time) {
  final parts = time.split(':');
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  return hour * 60 + minute;
}

bool _overlaps(ScheduleModel a, ScheduleModel b) {
  final aStart = _timeToMinutes(a.startTime);
  final aEnd = _timeToMinutes(a.endTime);
  final bStart = _timeToMinutes(b.startTime);
  final bEnd = _timeToMinutes(b.endTime);
  return aStart < bEnd && bStart < aEnd;
}

class _SlottedTask {
  final ScheduleModel task;
  final int slot;
  final int totalCols;
  const _SlottedTask(this.task, this.slot, this.totalCols);
}

List<_SlottedTask> _assignSlots(List<ScheduleModel> tasks) {
  final slots = List<int>.filled(tasks.length, 0);

  for (var i = 0; i < tasks.length; i++) {
    final takenSlots = <int>{};
    for (var j = 0; j < i; j++) {
      if (_overlaps(tasks[j], tasks[i])) {
        takenSlots.add(slots[j]);
      }
    }
    var slot = 0;
    while (takenSlots.contains(slot)) slot++;
    slots[i] = slot;
  }

  final result = <_SlottedTask>[];
  for (var i = 0; i < tasks.length; i++) {
    var maxSlot = slots[i];
    for (var j = 0; j < tasks.length; j++) {
      if (i != j && _overlaps(tasks[i], tasks[j])) {
        maxSlot = max(maxSlot, slots[j]);
      }
    }
    result.add(_SlottedTask(tasks[i], slots[i], maxSlot + 1));
  }
  return result;
}

// ── Date selector ─────────────────────────────────────────────────────────────

class ScheduleDateSelector extends StatelessWidget {
  final DateTime visibleStartDate;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const ScheduleDateSelector({
    super.key,
    required this.visibleStartDate,
    this.selectedDate,
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

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      7,
      (i) => visibleStartDate.add(Duration(days: i)),
    );

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = days[index];
          final isActive =
              selectedDate != null &&
              date.year == selectedDate!.year &&
              date.month == selectedDate!.month &&
              date.day == selectedDate!.day;

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: isActive ? _accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _weekdayLabels[date.weekday - 1],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : _inactiveText,
                    ),
                  ),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : Colors.black,
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Swipeable timeline graph ──────────────────────────────────────────────────

const double _cardMinWidth = 220.0;
const double _timeGutterWidth = 76.0;
const int _maxCourseNameLength = 16;

class ScheduleTimelineGraph extends StatelessWidget {
  final List<ScheduleModel> tasks;

  const ScheduleTimelineGraph({super.key, required this.tasks});

  double _timeToOffset(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return ((hour + minute / 60) - _startHour) * _hourHeight;
  }

  String _formatHour(int hour) => '${hour.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(
      _endHour - _startHour + 1,
      (i) => _startHour + i,
    );
    final totalHeight = hours.length * _hourHeight;
    final slotted = _assignSlots(tasks);

    final maxCols = slotted.isEmpty
        ? 1
        : slotted.map((s) => s.totalCols).reduce(max);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final taskAreaWidth = max(
          availableWidth - _timeGutterWidth,
          maxCols * _cardMinWidth,
        );
        final canvasWidth = _timeGutterWidth + taskAreaWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: maxCols > 1
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: SizedBox(
            width: canvasWidth,
            height: totalHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hour labels ──────────────────────────────────────────
                SizedBox(
                  width: _timeGutterWidth,
                  child: Column(
                    children: hours.map((hour) {
                      return SizedBox(
                        height: _hourHeight,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Text(
                              _formatHour(hour),
                              style: const TextStyle(
                                color: Color(0xFF6B6B6B),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // ── Task canvas ──────────────────────────────────────────
                SizedBox(
                  width: taskAreaWidth,
                  child: Stack(
                    children: [
                      for (var i = 0; i < hours.length; i++)
                        Positioned(
                          top: i * _hourHeight,
                          left: 0,
                          right: 0,
                          child: Container(height: 1, color: _lineColor),
                        ),
                      for (final st in slotted)
                        _buildCard(st, taskAreaWidth, context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(
    _SlottedTask st,
    double taskAreaWidth,
    BuildContext context,
  ) {
    final colWidth = taskAreaWidth / st.totalCols;
    final left = colWidth * st.slot;
    final top = max(0.0, _timeToOffset(st.task.startTime));
    final bottom = _timeToOffset(st.task.endTime);
    final height = max(72.0, bottom - top);

    return Positioned(
      top: top,
      left: left,
      width: colWidth,
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(right: 6, left: 4, bottom: 2),
        child: st.totalCols == 1
            ? _SingleTaskCard(task: st.task)
            : _CompactTaskCard(task: st.task),
      ),
    );
  }
}

// ── Source badge ─────────────────────────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  final String? source;
  const _SourceBadge({this.source});

  @override
  Widget build(BuildContext context) {
    if (source == null) return const SizedBox.shrink();
    final isOwn = source == 'own';
    final bg = isOwn ? const Color(0xFFE6F4EA) : const Color(0xFFE3F0FB);
    final fg = isOwn ? const Color(0xFF1E6B2D) : const Color(0xFF1565C0);
    final icon = isOwn ? Icons.edit_note : Icons.school_outlined;
    final label = isOwn ? 'Owner' : 'Enrolled';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

// ── Full-detail card (solo schedule) ─────────────────────────────────────────

class _SingleTaskCard extends StatelessWidget {
  final ScheduleModel task;
  const _SingleTaskCard({required this.task});

  Color _color() {
    try {
      if (task.color.isEmpty) return _accentColor;
      final hex = task.color.replaceAll('#', '');
      final rrggbb = hex.length > 6 ? hex.substring(hex.length - 6) : hex;
      return Color(int.parse('FF$rrggbb', radix: 16));
    } catch (_) {
      return _accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final courseName = context
        .watch<CourseProvider>()
        .allCourses
        .firstWhere(
          (c) => c.courseCode == task.courseCode,
          orElse: () => CourseModel(courseCode: '', courseName: 'Unknown'),
        )
        .courseName;
    final showFullName = courseName.length <= _maxCourseNameLength;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Accent bar
          Container(
            width: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course title row + badge (no more overlap with long names)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: RichText(
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          text: TextSpan(
                            children: showFullName
                                ? [
                                    TextSpan(
                                      text: '${task.courseCode} • ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                    TextSpan(
                                      text: courseName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF212121),
                                      ),
                                    ),
                                  ]
                                : [
                                    TextSpan(
                                      text: task.courseCode,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                  ],
                          ),
                        ),
                      ),
                      if (task.source != null) ...[
                        const SizedBox(width: 6),
                        _SourceBadge(source: task.source),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: _accentColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          task.location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B6B6B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: _accentColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${task.startTime} - ${task.endTime}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B6B6B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Compact card (overlapping schedule) ──────────────────────────────────────

class _CompactTaskCard extends StatelessWidget {
  final ScheduleModel task;
  const _CompactTaskCard({required this.task});

  Color _color() {
    try {
      if (task.color.isEmpty) return _accentColor;
      final hex = task.color.replaceAll('#', '');
      final rrggbb = hex.length > 6 ? hex.substring(hex.length - 6) : hex;
      return Color(int.parse('FF$rrggbb', radix: 16));
    } catch (_) {
      return _accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent bar
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    4,
                    8,
                    task.source != null
                        ? 44
                        : 4, // reserve space for corner badge
                    8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.courseCode,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: _accentColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              task.location,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B6B6B),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: _accentColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${task.startTime} - ${task.endTime}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B6B6B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (task.source != null)
          Positioned(
            top: 6,
            right: 6,
            child: _SourceBadge(source: task.source),
          ),
      ],
    );
  }
}

// ── Day view ──────────────────────────────────────────────────────────────────

class ScheduleDayView extends StatelessWidget {
  final DateTime visibleStartDate;
  final DateTime selectedDate;
  final List<ScheduleModel> visibleSchedules;
  final ValueChanged<DateTime> onDateSelected;

  const ScheduleDayView({
    super.key,
    required this.visibleStartDate,
    required this.selectedDate,
    required this.visibleSchedules,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScheduleDateSelector(
          visibleStartDate: visibleStartDate,
          selectedDate: selectedDate,
          onDateSelected: onDateSelected,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ScheduleTimelineGraph(tasks: visibleSchedules),
          ),
        ),
      ],
    );
  }
}
