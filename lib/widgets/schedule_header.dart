import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScheduleHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onBack;
  final Color? backgroundColor;

  const ScheduleHeader({
    super.key,
    required this.onRefresh,
    required this.onBack,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final colorScheme = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: backgroundColor ?? colorScheme.primary,
      ),
      child: Container(
        width: double.infinity,
        color: backgroundColor ?? colorScheme.primary,
        padding: EdgeInsets.only(
          top: topPadding + 8,
          bottom: 12,
          left: 4,
          right: 4,
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: onBack,
            ),
            const Expanded(
              child: Center(
                // Add Center here
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
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 30),
              onPressed: onRefresh,
              tooltip: 'Refresh',
            ),
          ],
        ),
      ),
    );
  }
}
