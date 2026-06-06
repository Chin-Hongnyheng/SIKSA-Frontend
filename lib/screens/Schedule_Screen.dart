import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import '../providers/course_provider.dart';
import '../providers/user_provider.dart';
import '../modals/schedule_modal.dart';
import '../widgets/schedule_header.dart';
import '../widgets/schedule_day_view.dart';
import '../widgets/schedule_week_view.dart';
import '../widgets/schedule_month_view.dart';
import '../widgets/floating_line_background.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const Color accentColor = Color(0xFF1E6B2D);

  late DateTime selectedDate;
  late DateTime weekStart;
  late DateTime monthStart;

  ScheduleViewMode _viewMode = ScheduleViewMode.day;

  static DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
    weekStart = _mondayOf(selectedDate);
    monthStart = _firstOfMonth(selectedDate);
    Future.microtask(() => context.read<ScheduleProvider>().loadSchedules());
  }

  bool _shouldShowOnDate(ScheduleModel s, DateTime date) {
    final r = s.recurrenceType.toLowerCase().trim();
    if (r == 'none') {
      if (s.date == null) return false;
      final t = _parseDate(s.date!);
      return t != null && _isSameDay(t, date);
    }
    final start = s.startDate != null ? _parseDate(s.startDate!) : null;
    final end = s.endDate != null ? _parseDate(s.endDate!) : null;
    if (start == null || end == null) return false;
    final d = DateTime(date.year, date.month, date.day);
    if (d.isBefore(start) || d.isAfter(end)) return false;
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
          .map((x) => x.toLowerCase().trim())
          .contains(names[date.weekday - 1]);
    }
    if (r == 'monthly') {
      if (s.selectedDays == null || s.selectedDays!.isEmpty) return false;
      return s.selectedDays!
          .map((x) => int.tryParse(x.trim().split(' ').first))
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

  int _weekTaskCount(List<ScheduleModel> schedules) {
    final seen = <String>{};
    var count = 0;
    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      for (final s in schedules) {
        if (_shouldShowOnDate(s, day) && seen.add('${s.scheduleId}-$day'))
          count++;
      }
    }
    return count;
  }

  int _monthTaskCount(List<ScheduleModel> schedules) {
    final days = DateUtils.getDaysInMonth(monthStart.year, monthStart.month);
    final seen = <String>{};
    var count = 0;
    for (var d = 1; d <= days; d++) {
      final day = DateTime(monthStart.year, monthStart.month, d);
      for (final s in schedules) {
        if (_shouldShowOnDate(s, day) && seen.add('${s.scheduleId}-$day'))
          count++;
      }
    }
    return count;
  }

  void _move(int dir) {
    setState(() {
      switch (_viewMode) {
        case ScheduleViewMode.day:
          selectedDate = selectedDate.add(Duration(days: dir));
          weekStart = _mondayOf(selectedDate);
          monthStart = _firstOfMonth(selectedDate);
          break;
        case ScheduleViewMode.week:
          weekStart = weekStart.add(Duration(days: 7 * dir));
          final weekEnd = weekStart.add(const Duration(days: 6));
          if (selectedDate.isBefore(weekStart))
            selectedDate = weekStart;
          else if (selectedDate.isAfter(weekEnd))
            selectedDate = weekEnd;
          monthStart = _firstOfMonth(selectedDate);
          break;
        case ScheduleViewMode.month:
          final m = monthStart.month + dir;
          monthStart = DateTime(
            monthStart.year + (m - 1) ~/ 12,
            ((m - 1) % 12) + 1,
            1,
          );
          final daysInMonth = DateUtils.getDaysInMonth(
            monthStart.year,
            monthStart.month,
          );
          selectedDate = DateTime(
            monthStart.year,
            monthStart.month,
            selectedDate.day.clamp(1, daysInMonth),
          );
          weekStart = _mondayOf(selectedDate);
          break;
      }
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      selectedDate = DateTime(now.year, now.month, now.day);
      weekStart = _mondayOf(selectedDate);
      monthStart = _firstOfMonth(selectedDate);
    });
  }

  void _switchMode(ScheduleViewMode mode) {
    setState(() {
      _viewMode = mode;
      weekStart = _mondayOf(selectedDate);
      monthStart = _firstOfMonth(selectedDate);
    });
  }

  String _dateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_isSameDay(selectedDate, today)) return 'Today';
    return selectedDate.isBefore(today) ? 'Previous' : 'Next';
  }

  Future<void> _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateTime(picked.year, picked.month, picked.day);
        weekStart = _mondayOf(selectedDate);
        monthStart = _firstOfMonth(selectedDate);
      });
    }
  }

  Future<void> _handleEdit(ScheduleModel s) async {
    await showCreateScheduleModal(
      context,
      title: 'Edit Schedule',
      scheduleId: s.scheduleId,
      initialData: {
        'courseCode': s.courseCode,
        'assessmentName': s.assessmentName,
        'location': s.location,
        'startTime': s.startTime,
        'endTime': s.endTime,
        'recurrenceType': s.recurrenceType,
        'date': s.date,
        'startDate': s.startDate,
        'endDate': s.endDate,
        'color': s.color,
        'reminder': s.reminder,
        'selectedDays': s.selectedDays,
      },
      onSubmit: (_) async {
        await context.read<ScheduleProvider>().loadSchedules();
        final role = context.read<UserProvider>().user?.role;
        await context.read<CourseProvider>().loadCourses(role: role);
      },
    );
  }

  Future<void> _handleDelete(ScheduleModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
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
    if (ok != true) return;
    await context.read<ScheduleProvider>().removeSchedule(s.scheduleId);
    final err = context.read<ScheduleProvider>().error;
    if (err != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
    }
  }

  static const _months = [
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
  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String _formatFullDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]} ${d.year}';

  String _formatMonthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final topPadding = MediaQuery.of(context).padding.top;

    final bool isWeekOrMonth =
        _viewMode == ScheduleViewMode.week ||
        _viewMode == ScheduleViewMode.month;

    final String titleText;
    final String subtitleText;
    switch (_viewMode) {
      case ScheduleViewMode.day:
        titleText = _formatFullDate(selectedDate);
        subtitleText =
            'You have ${provider.schedules.where((s) => _shouldShowOnDate(s, selectedDate)).length} tasks scheduled.';
        break;
      case ScheduleViewMode.week:
        titleText = _formatMonthYear(weekStart);
        subtitleText =
            'You have ${_weekTaskCount(provider.schedules)} tasks this week.';
        break;
      case ScheduleViewMode.month:
        titleText = _formatMonthYear(monthStart);
        subtitleText =
            'You have ${_monthTaskCount(provider.schedules)} tasks this month.';
        break;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: isWeekOrMonth
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _NavCircleButton(
                                    icon: Icons.chevron_left,
                                    onPressed: () => _move(-1),
                                    accentColor: accentColor,
                                  ),
                                  Text(
                                    titleText,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  _NavCircleButton(
                                    icon: Icons.chevron_right,
                                    onPressed: () => _move(1),
                                    accentColor: accentColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  subtitleText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 169, 167, 167),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      titleText,
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      subtitleText,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color.fromARGB(
                                          255,
                                          169,
                                          167,
                                          167,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _NavCircleButton(
                                    icon: Icons.chevron_left,
                                    onPressed: () => _move(-1),
                                    accentColor: accentColor,
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: _jumpToToday,
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
                                      _dateLabel(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _NavCircleButton(
                                    icon: Icons.chevron_right,
                                    onPressed: () => _move(1),
                                    accentColor: accentColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),
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
                        : _buildContent(provider),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ScheduleHeader(
              onRefresh: () => provider.loadSchedules(),
              onBack: () => context.pop(),
              backgroundColor: Colors.transparent,
              viewMode: _viewMode,
              onViewModeChanged: _switchMode,
              onCalendarTap: _openDatePicker,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ScheduleProvider provider) {
    switch (_viewMode) {
      case ScheduleViewMode.day:
        return ScheduleDayView(
          visibleStartDate: weekStart,
          selectedDate: selectedDate,
          visibleSchedules: provider.schedules
              .where((s) => _shouldShowOnDate(s, selectedDate))
              .toList(),
          onDateSelected: (date) => setState(() {
            selectedDate = date;
            weekStart = _mondayOf(date);
            monthStart = _firstOfMonth(date);
          }),
        );
      case ScheduleViewMode.week:
        return ScheduleWeekView(
          visibleStartDate: weekStart,
          selectedDate: selectedDate,
          allSchedules: provider.schedules,
          onEdit: _handleEdit,
          onDelete: _handleDelete,
          onDateSelected: (date) => setState(() {
            selectedDate = date;
            monthStart = _firstOfMonth(date);
          }),
        );
      case ScheduleViewMode.month:
        return ScheduleMonthView(
          focusedMonth: monthStart,
          selectedDate: selectedDate,
          allSchedules: provider.schedules,
          onEdit: _handleEdit,
          onDelete: _handleDelete,
          onDateSelected: (date) => setState(() {
            selectedDate = date;
            weekStart = _mondayOf(date);
            monthStart = _firstOfMonth(date);
            _viewMode = ScheduleViewMode.day;
          }),
        );
    }
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
