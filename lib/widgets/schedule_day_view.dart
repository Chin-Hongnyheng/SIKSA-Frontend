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
      (index) => visibleStartDate.add(Duration(days: index)),
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

class ScheduleTimelineGraph extends StatelessWidget {
  final List<ScheduleModel> tasks;

  const ScheduleTimelineGraph({super.key, required this.tasks});

  double _timeToOffset(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return ((hour + minute / 60) - _startHour) * _hourHeight;
  }

  String _formatHour(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(
      _endHour - _startHour + 1,
      (index) => _startHour + index,
    );
    final totalHeight = hours.length * _hourHeight;

    return SizedBox(
      height: totalHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Column(
              children: hours
                  .map(
                    (hour) => SizedBox(
                      height: _hourHeight,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Text(
                          _formatHour(hour),
                          style: const TextStyle(
                            color: Color(0xFF6B6B6B),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              children: [
                for (var i = 0; i < hours.length; i++)
                  Positioned(
                    top: i * _hourHeight,
                    left: 0,
                    right: 0,
                    child: Container(height: 1, color: _lineColor),
                  ),
                for (final task in tasks)
                  Positioned(
                    top: max(0, _timeToOffset(task.startTime)),
                    left: 0,
                    right: 0,
                    child: _TaskCard(
                      task: task,
                      height: max(
                        72,
                        _timeToOffset(task.endTime) -
                            _timeToOffset(task.startTime),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final ScheduleModel task;
  final double height;

  const _TaskCard({required this.task, required this.height});

  Color _getTaskColor() {
    try {
      if (task.color == null || task.color!.isEmpty) {
        return _accentColor;
      }
      final hex = task.color!.replaceAll('#', '');
      final rrggbb = hex.length > 6 ? hex.substring(hex.length - 6) : hex;
      return Color(int.parse('FF$rrggbb', radix: 16));
    } catch (_) {
      return _accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = max(height, 72).toDouble();

    return Padding(
      padding: const EdgeInsets.only(right: 10, left: 4),
      child: Container(
        height: cardHeight,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: _getTaskColor(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${task.courseCode} • ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _getTaskColor(),
                              ),
                            ),
                            TextSpan(
                              text: context
                                  .watch<CourseProvider>()
                                  .courses
                                  .firstWhere(
                                    (c) => c.courseCode == task.courseCode,
                                    orElse: () => CourseModel(
                                      courseCode: '',
                                      courseName: 'Unknown',
                                    ),
                                  )
                                  .courseName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF212121),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: _accentColor,
                          ),
                          const SizedBox(width: 8),
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
                          const SizedBox(width: 8),
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
            ),
          ],
        ),
      ),
    );
  }
}

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              child: ScheduleTimelineGraph(tasks: visibleSchedules),
            ),
          ),
        ),
      ],
    );
  }
}
