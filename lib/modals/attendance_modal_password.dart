import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/attendance_session_model.dart';
import '../providers/attendance_provider.dart';
import '../providers/course_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/center_toast.dart';

class AttendancePasswordModal extends StatefulWidget {
  final AttendanceSessionModel session;

  const AttendancePasswordModal({super.key, required this.session});

  /// Convenience helper — call this instead of showDialog directly.
  static Future<void> show(
    BuildContext context,
    AttendanceSessionModel session,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AttendancePasswordModal(session: session),
    );
  }

  @override
  State<AttendancePasswordModal> createState() =>
      _AttendancePasswordModalState();
}

class _AttendancePasswordModalState extends State<AttendancePasswordModal> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _errorText = 'Please enter the attendance code.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final attendanceProvider = context.read<AttendanceProvider>();
    final courseProvider = context.read<CourseProvider>();
    final user = context.read<UserProvider>().user;

    if (user == null) {
      setState(() {
        _isSubmitting = false;
        _errorText = 'You must be logged in.';
      });
      return;
    }

    final course = courseProvider.allCourses
        .where((c) => c.courseCode == widget.session.courseCode)
        .firstOrNull;
    final isSubscribed = course?.isSubscribed ?? false;

    final outcome = await attendanceProvider.checkInWithQr(
      sessionId: widget.session.id,
      password: code,
      studentId: user.id,
      isSubscribed: isSubscribed,
    );

    if (!mounted) return;

    // Map result → color + message
    final bool isSuccess =
        outcome.result == CheckInResult.successPresent ||
        outcome.result == CheckInResult.successLate;

    if (isSuccess) {
      Navigator.of(context).pop();
      await CenterToast.show(
        context,
        message: outcome.message ?? 'Attendance marked!',
        icon: outcome.result == CheckInResult.successLate
            ? Icons.access_time_filled_rounded
            : Icons.check_circle_rounded,
        color: outcome.result == CheckInResult.successLate
            ? Colors.orange
            : Colors.green,
      );
    } else {
      setState(() {
        _isSubmitting = false;
        _errorText = outcome.message ?? 'Something went wrong.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E6B2D).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_open_rounded,
                    color: Color(0xFF1E6B2D),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter Attendance Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.session.title,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.grey.shade400,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),

            // ── Session info pill ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.session.date}  •  '
                    '${widget.session.startTime} – ${widget.session.endTime}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Code input ────────────────────────────────────────────
            TextField(
              controller: _controller,
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              enabled: !_isSubmitting,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: 10,
              ),
              decoration: InputDecoration(
                hintText: '······',
                hintStyle: TextStyle(
                  fontSize: 30,
                  letterSpacing: 10,
                  color: Colors.grey.shade300,
                  fontWeight: FontWeight.w800,
                ),
                errorText: _errorText,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF1E6B2D),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Submit button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E6B2D),
                  disabledBackgroundColor: const Color(
                    0xFF1E6B2D,
                  ).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
