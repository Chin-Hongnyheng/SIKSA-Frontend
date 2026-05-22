import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../modals/schedule_modal.dart';
import '../widgets/schedule_date_selector.dart';
import '../widgets/schedule_header.dart';
import '../widgets/schedule_timeline_graph.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const Color accentColor = Color(0xFF1E6B2D);
  static const Color pageBackground = Color(0xFFF8F9FA);

  DateTime visibleStartDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  DateTime selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  void initState() {
    super.initState();
    // Load schedules when screen starts
    Future.microtask(() {
      context.read<ScheduleProvider>().loadSchedules();
    });
  }

  bool _shouldShowOnDate(ScheduleModel schedule, DateTime date) {
    final recurrence = schedule.recurrenceType.toLowerCase().trim();

    if (recurrence == 'none') {
      // Only show on the exact picked date
      if (schedule.date == null) return false;
      final target = _parseDate(schedule.date!);
      return target != null && _isSameDay(target, date);
    }

    // For daily/weekly/monthly, we need startDate and endDate
    final start = schedule.startDate != null
        ? _parseDate(schedule.startDate!)
        : null;
    final end = schedule.endDate != null ? _parseDate(schedule.endDate!) : null;

    if (start == null || end == null) return false;

    // Date must be within the range [startDate, endDate]
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly.isBefore(start) || dateOnly.isAfter(end)) return false;

    if (recurrence == 'daily') {
      return true;
    }

    if (recurrence == 'weekly') {
      // selectedDays holds weekday names e.g. ["Monday", "Wednesday"]
      if (schedule.selectedDays == null || schedule.selectedDays!.isEmpty)
        return false;
      final weekdayName = _weekdayName(
        date.weekday,
      ); // date.weekday: 1=Mon ... 7=Sun
      return schedule.selectedDays!
          .map((d) => d.toLowerCase().trim())
          .contains(weekdayName.toLowerCase());
    }

    if (recurrence == 'monthly') {
      return date.day == start.day;
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

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

  void _openCreateScheduleModal() {
    showCreateScheduleModal(
      context,
      onSubmit: (scheduleMap) {
        final provider = context.read<ScheduleProvider>();
        final newSchedule = ScheduleModel.fromMap(scheduleMap);
        provider.addSchedule(newSchedule);
      },
    );
  }

  Future<void> _handleEditTask(ScheduleModel schedule) async {
    await showCreateScheduleModal(
      context,
      title: 'Edit Schedule',
      scheduleId: schedule.scheduleId,
      initialData: {
        'courseCode': schedule.courseCode,
        'assessmentName': schedule.assessmentName,
        'location': schedule.location,
        'startTime': schedule.startTime,
        'endTime': schedule.endTime,
        'recurrenceType': schedule.recurrenceType,
        'date': schedule.date,
        'startDate': schedule.startDate,
        'endDate': schedule.endDate,
        'color': schedule.color,
        'reminder': schedule.reminder,
        'selectedDays': schedule.selectedDays,
      },
      onSubmit: (scheduleMap) {
        final updated = ScheduleModel.fromMap({
          ...scheduleMap,
          'scheduleId': schedule.scheduleId,
        });
        context.read<ScheduleProvider>().editSchedule(
          schedule.scheduleId,
          updated,
        );
      },
    );
  }

  Future<void> _confirmDeleteTask(ScheduleModel schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete schedule'),
        content: const Text('Are you sure you want to delete this schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await context.read<ScheduleProvider>().removeSchedule(schedule.scheduleId);
    final error = context.read<ScheduleProvider>().error;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  void _moveWindow(int offsetDays) {
    setState(() {
      visibleStartDate = visibleStartDate.add(Duration(days: offsetDays));
      final visibleEndDate = visibleStartDate.add(const Duration(days: 6));
      if (selectedDate.isBefore(visibleStartDate)) {
        selectedDate = visibleStartDate;
      } else if (selectedDate.isAfter(visibleEndDate)) {
        selectedDate = visibleEndDate;
      }
    });
  }

  String _getDateLabel() {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    if (visibleStartDate.isAtSameMomentAs(today)) return 'Today';
    if (visibleStartDate.isBefore(today)) return 'Previous';
    return 'Next';
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${weekdays[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    final visibleSchedules = provider.schedules
        .where((s) => _shouldShowOnDate(s, selectedDate))
        .toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateScheduleModal,
        backgroundColor: accentColor,
        icon: const Icon(Icons.add, size: 26),
        label: const Text(
          'Create Schedule',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScheduleHeader(
              onRefresh: () => provider.loadSchedules(),
              onBack: () {},
              backgroundColor: accentColor,
            ),
            Expanded(
              child: Container(
                color: pageBackground,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatMonthYear(DateTime.now()),
                                  style: const TextStyle(
                                    fontSize: 33,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  // Show count for selected date, not total
                                  'You have ${visibleSchedules.length} tasks scheduled.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 169, 167, 167),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _NavCircleButton(
                                    icon: Icons.chevron_left,
                                    onPressed: () => _moveWindow(-1),
                                    accentColor: accentColor,
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        visibleStartDate = DateTime(
                                          DateTime.now().year,
                                          DateTime.now().month,
                                          DateTime.now().day,
                                        );
                                        selectedDate = visibleStartDate;
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: accentColor.withOpacity(
                                        0.12,
                                      ),
                                      foregroundColor: accentColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                    ),
                                    child: Text(
                                      _getDateLabel(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _NavCircleButton(
                                    icon: Icons.chevron_right,
                                    onPressed: () => _moveWindow(1),
                                    accentColor: accentColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        selectedDate = DateTime(
                                          picked.year,
                                          picked.month,
                                          picked.day,
                                        );
                                        visibleStartDate = selectedDate;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.calendar_today),
                                  color: accentColor,
                                  tooltip: 'Select date',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ScheduleDateSelector(
                      visibleStartDate: visibleStartDate,
                      selectedDate: selectedDate,
                      onDateSelected: (date) {
                        setState(() {
                          selectedDate = date;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Loading / error / timeline
                    Expanded(
                      child: provider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : provider.error != null && provider.schedules.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Failed to load schedules',
                                    style: TextStyle(color: Colors.red[400]),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => provider.loadSchedules(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: SingleChildScrollView(
                                child: ScheduleTimelineGraph(
                                  tasks: visibleSchedules,
                                  onEdit: _handleEditTask,
                                  onDelete: _confirmDeleteTask,
                                ),
                              ),
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

class _NavCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color accentColor;

  const _NavCircleButton({
    required this.icon,
    required this.onPressed,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: IconButton(
        padding: const EdgeInsets.all(8),
        icon: Icon(icon),
        color: accentColor,
        onPressed: onPressed,
      ),
    );
  }
}
