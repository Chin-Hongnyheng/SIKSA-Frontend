import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color _accentColor = Color(0xFF1E6B2D);

enum ScheduleViewMode { day, week, month }

class ScheduleHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onBack;
  final Color? backgroundColor;
  final ScheduleViewMode viewMode;
  final ValueChanged<ScheduleViewMode> onViewModeChanged;
  final VoidCallback? onCalendarTap;

  const ScheduleHeader({
    super.key,
    required this.onRefresh,
    required this.onBack,
    required this.viewMode,
    required this.onViewModeChanged,
    this.backgroundColor,
    this.onCalendarTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Container(
        width: double.infinity,
        color: Colors.transparent, // ← transparent, background shows through
        padding: EdgeInsets.only(
          top: topPadding + 8,
          bottom: 12,
          left: 4,
          right: 4,
        ),
        child: Row(
          children: [
            // Back
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: onBack,
            ),

            // Title
            const Expanded(
              child: Center(
                child: Text(
                  'Schedule',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 28,
                  ),
                ),
              ),
            ),

            // Refresh
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 30),
              onPressed: onRefresh,
              tooltip: 'Refresh',
            ),

            // View-mode picker
            _ViewModeDropdown(
              viewMode: viewMode,
              onViewModeChanged: onViewModeChanged,
              onCalendarTap: onCalendarTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewModeDropdown extends StatelessWidget {
  final ScheduleViewMode viewMode;
  final ValueChanged<ScheduleViewMode> onViewModeChanged;
  final VoidCallback? onCalendarTap;

  const _ViewModeDropdown({
    required this.viewMode,
    required this.onViewModeChanged,
    this.onCalendarTap,
  });

  String _label(ScheduleViewMode m) {
    switch (m) {
      case ScheduleViewMode.day:
        return 'Day';
      case ScheduleViewMode.week:
        return 'Week';
      case ScheduleViewMode.month:
        return 'Month';
    }
  }

  IconData _activeIcon(ScheduleViewMode m) {
    switch (m) {
      case ScheduleViewMode.day:
        return Icons.today;
      case ScheduleViewMode.week:
        return Icons.date_range;
      case ScheduleViewMode.month:
        return Icons.calendar_month;
    }
  }

  IconData _outlineIcon(ScheduleViewMode m) {
    switch (m) {
      case ScheduleViewMode.day:
        return Icons.today_outlined;
      case ScheduleViewMode.week:
        return Icons.date_range_outlined;
      case ScheduleViewMode.month:
        return Icons.calendar_month_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ScheduleViewMode>(
      tooltip: 'Change view',
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 48),
      onSelected: onViewModeChanged,
      itemBuilder: (context) => ScheduleViewMode.values.map((mode) {
        final isActive = mode == viewMode;
        return PopupMenuItem<ScheduleViewMode>(
          value: mode,
          child: Row(
            children: [
              Icon(
                isActive ? _activeIcon(mode) : _outlineIcon(mode),
                size: 20,
                color: isActive ? _accentColor : const Color(0xFF6B6B6B),
              ),
              const SizedBox(width: 12),
              Text(
                _label(mode),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? _accentColor : const Color(0xFF212121),
                ),
              ),
              if (isActive) ...[
                const Spacer(),
                const Icon(Icons.check, size: 18, color: _accentColor),
              ],
            ],
          ),
        );
      }).toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_activeIcon(viewMode), color: Colors.white, size: 26),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
