import 'dart:math';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../models/course_model.dart';
import '../providers/course_provider.dart';

const Color _accentColor = Color(0xFF1E6B2D);
const Color _lineColor = Color(0xFFE9ECEF);
const int _startHour = 7;
const int _endHour = 22;
const double _hourHeight = 96.0;

class ScheduleTimelineGraph extends StatelessWidget {
  final List<ScheduleModel> tasks;
  final void Function(ScheduleModel task) onEdit;
  final void Function(ScheduleModel task) onDelete;

  const ScheduleTimelineGraph({
    super.key,
    required this.tasks,
    required this.onEdit,
    required this.onDelete,
  });

  double _timeToOffset(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return ((hour + minute / 60) - _startHour) * _hourHeight;
  }

  String _formatHour(int hour) {
    final value = hour.toString().padLeft(2, '0');
    return '$value:00';
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
                for (var index = 0; index < hours.length; index++)
                  Positioned(
                    top: index * _hourHeight,
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
                      onEdit: () => onEdit(task),
                      onDelete: () => onDelete(task),
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.height,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getTaskColor() {
    try {
      if (task.color == null || task.color!.isEmpty) {
        return const Color(0xFF1E6B2D);
      }

      final hex = task.color!.replaceAll('#', '');
      final rrggbb = hex.length > 6 ? hex.substring(hex.length - 6) : hex;

      return Color(int.parse('FF$rrggbb', radix: 16));
    } catch (e) {
      return const Color(0xFF1E6B2D);
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
                borderRadius: BorderRadius.only(
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
                    mainAxisAlignment: MainAxisAlignment.start,
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
                      SizedBox(height: 4),
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
                      SizedBox(height: 4),
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
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: PopupMenuButton<String>(
                  padding: const EdgeInsets.all(0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  icon: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF6B6B6B),
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: const [
                          Icon(Icons.edit, size: 18, color: _accentColor),
                          SizedBox(width: 10),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: const [
                          Icon(Icons.delete, size: 18, color: Colors.redAccent),
                          SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
