import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/attendance_provider.dart';
import '../providers/course_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/center_toast.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final ImagePicker _picker = ImagePicker();

  bool _isProcessing = false;
  bool _isDone = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isDone) return;

    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    await _processRawValue(raw);
  }

  Future<void> _processRawValue(String raw) async {
    if (_isProcessing || _isDone) return;

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      await CenterToast.show(
        context,
        message: 'Invalid QR code. Please scan a valid code.',
        icon: Icons.qr_code_2,
        color: Colors.red,
      );
      return;
    }

    final type = payload['type'];

    if (type == 'course') {
      await _handleCourseQr(payload);
    } else if (type == 'attendance') {
      await _handleAttendanceQr(payload);
    } else {
      await CenterToast.show(
        context,
        message: 'This QR code is not recognized.',
        icon: Icons.error_outline_rounded,
        color: Colors.orange,
      );
    }
  }

  // ── Course join QR ──────────────────────────────────────────────────────

  Future<void> _handleCourseQr(Map<String, dynamic> payload) async {
    if (payload['courseCode'] == null) {
      await CenterToast.show(
        context,
        message: 'This QR code is not a course code.',
        icon: Icons.error_outline_rounded,
        color: Colors.orange,
      );
      return;
    }

    final courseCode = payload['courseCode'] as String;

    setState(() => _isProcessing = true);
    await _controller.stop();

    final courseProvider = context.read<CourseProvider>();
    final user = context.read<UserProvider>().user;

    final allCourses = courseProvider.allCourses;
    final target = allCourses
        .where((c) => c.courseCode == courseCode)
        .firstOrNull;

    if (target == null) {
      await CenterToast.show(
        context,
        message: 'Course "$courseCode" not found.',
        icon: Icons.search_off_rounded,
        color: Colors.red,
      );
      setState(() => _isProcessing = false);
      await _controller.start();
      return;
    }

    if (target.createdBy == user?.userName) {
      await CenterToast.show(
        context,
        message: 'You cannot join your own course.',
        icon: Icons.block_rounded,
        color: Colors.orange,
      );
      setState(() => _isProcessing = false);
      await _controller.start();
      return;
    }

    if (target.isSubscribed) {
      // ── Resume camera first so background stays live ──────────────
      setState(() => _isProcessing = false);
      await _controller.start();
      await CenterToast.show(
        context,
        message: 'You are already enrolled in "${target.courseName}".',
        icon: Icons.info_outline_rounded,
        color: Colors.blue,
      );
      // Reset _isDone so they can scan another course after toast
      setState(() => _isDone = false);
      return;
    }

    try {
      await courseProvider.subscribeCourse(courseCode: courseCode);

      // ── Show success toast, stay on page, resume camera ──────────
      setState(() {
        _isProcessing = false;
        _isDone = false; // allow scanning again
      });
      await _controller.start();
      await CenterToast.show(
        context,
        message: 'Joined successfully!',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
      );
    } catch (e) {
      await CenterToast.show(
        context,
        message: 'Failed to join course: $e',
        icon: Icons.wifi_off_rounded,
        color: Colors.red,
      );
      setState(() => _isProcessing = false);
      await _controller.start();
    }
  }

  // ── Attendance check-in QR ──────────────────────────────────────────────

  Future<void> _handleAttendanceQr(Map<String, dynamic> payload) async {
    final sessionId = payload['sessionId'] as String?;
    final password = payload['password'] as String?;

    if (sessionId == null || password == null) {
      await CenterToast.show(
        context,
        message: 'This QR code is not a valid attendance code.',
        icon: Icons.error_outline_rounded,
        color: Colors.orange,
      );
      return;
    }

    setState(() => _isProcessing = true);
    await _controller.stop();

    final attendanceProvider = context.read<AttendanceProvider>();
    final courseProvider = context.read<CourseProvider>();
    final user = context.read<UserProvider>().user;

    if (user == null) {
      await CenterToast.show(
        context,
        message: 'You must be logged in to check in.',
        icon: Icons.lock_outline_rounded,
        color: Colors.red,
      );
      setState(() => _isProcessing = false);
      await _controller.start();
      return;
    }

    // First we need the session to know which course this is for, so we
    // can check this student's subscription the same way course-join does
    // (via courseProvider.allCourses + isSubscribed).
    final session = await attendanceProvider.getSessionById(sessionId);
    if (session == null) {
      await CenterToast.show(
        context,
        message: attendanceProvider.error ?? 'Attendance session not found.',
        icon: Icons.search_off_rounded,
        color: Colors.red,
      );
      setState(() => _isProcessing = false);
      await _controller.start();
      return;
    }

    final course = courseProvider.allCourses
        .where((c) => c.courseCode == session.courseCode)
        .firstOrNull;
    final isSubscribed = course?.isSubscribed ?? false;

    final outcome = await attendanceProvider.checkInWithQr(
      sessionId: sessionId,
      password: password,
      studentId: user.id,
      isSubscribed: isSubscribed,
    );

    setState(() => _isProcessing = false);
    await _controller.start();

    final IconData icon;
    final Color color;
    switch (outcome.result) {
      case CheckInResult.successPresent:
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        break;
      case CheckInResult.successLate:
        icon = Icons.access_time_filled_rounded;
        color = Colors.orange;
        break;
      case CheckInResult.alreadyMarked:
        icon = Icons.info_outline_rounded;
        color = Colors.blue;
        break;
      case CheckInResult.notSubscribed:
        icon = Icons.block_rounded;
        color = Colors.orange;
        break;
      case CheckInResult.wrongPassword:
        icon = Icons.qr_code_2;
        color = Colors.red;
        break;
      case CheckInResult.sessionClosed:
        icon = Icons.timer_off_rounded;
        color = Colors.red;
        break;
      case CheckInResult.sessionNotFound:
        icon = Icons.search_off_rounded;
        color = Colors.red;
        break;
      case CheckInResult.error:
        icon = Icons.wifi_off_rounded;
        color = Colors.red;
        break;
    }

    await CenterToast.show(
      context,
      message: outcome.message ?? 'Something went wrong.',
      icon: icon,
      color: color,
    );
  }

  Future<void> _pickAndScanImage() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      setState(() => _isProcessing = true);

      final BarcodeCapture? result = await _controller.analyzeImage(file.path);

      if (!mounted) return;

      final raw = result?.barcodes.firstOrNull?.rawValue;
      if (raw == null) {
        await CenterToast.show(
          context,
          message: 'No QR code found in the selected image.',
          icon: Icons.image_search_rounded,
          color: Colors.orange,
        );
        setState(() => _isProcessing = false);
        return;
      }

      setState(() => _isProcessing = false);
      await _processRawValue(raw);
    } catch (e) {
      if (mounted) {
        await CenterToast.show(
          context,
          message: 'Could not read the image: $e',
          icon: Icons.broken_image_outlined,
          color: Colors.red,
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera feed always running in background ───────────────
          MobileScanner(controller: _controller, onDetect: _onDetect),

          _ScanOverlay(),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Scan QR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Point your camera at a course or attendance QR code',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),

                const Spacer(),

                if (_isProcessing)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Processing…',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _BottomActionButton(
                        onTap: () => _controller.toggleTorch(),
                        icon: ValueListenableBuilder(
                          valueListenable: _controller,
                          builder: (_, value, __) => Icon(
                            value.torchState == TorchState.on
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        label: 'Flashlight',
                      ),
                      const SizedBox(width: 100),
                      _BottomActionButton(
                        onTap: _isProcessing ? null : _pickAndScanImage,
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                        label: 'Upload',
                      ),
                    ],
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

class _BottomActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget icon;
  final String label;

  const _BottomActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cutoutSize = 260.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final left = cx - cutoutSize / 2;
    final top = cy - cutoutSize / 2;
    final cutout = Rect.fromLTWH(left, top, cutoutSize, cutoutSize);

    final overlay = Paint()..color = Colors.black.withOpacity(0.62);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cutout, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlay);

    const cornerLen = 28.0;
    const strokeW = 3.5;
    final corner = Paint()
      ..color = AppColors.primary
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final r = 16.0;

    canvas.drawLine(
      Offset(left + r, top),
      Offset(left + r + cornerLen, top),
      corner,
    );
    canvas.drawLine(
      Offset(left, top + r),
      Offset(left, top + r + cornerLen),
      corner,
    );
    canvas.drawLine(
      Offset(left + cutoutSize - r, top),
      Offset(left + cutoutSize - r - cornerLen, top),
      corner,
    );
    canvas.drawLine(
      Offset(left + cutoutSize, top + r),
      Offset(left + cutoutSize, top + r + cornerLen),
      corner,
    );
    canvas.drawLine(
      Offset(left + r, top + cutoutSize),
      Offset(left + r + cornerLen, top + cutoutSize),
      corner,
    );
    canvas.drawLine(
      Offset(left, top + cutoutSize - r),
      Offset(left, top + cutoutSize - r - cornerLen),
      corner,
    );
    canvas.drawLine(
      Offset(left + cutoutSize - r, top + cutoutSize),
      Offset(left + cutoutSize - r - cornerLen, top + cutoutSize),
      corner,
    );
    canvas.drawLine(
      Offset(left + cutoutSize, top + cutoutSize - r),
      Offset(left + cutoutSize, top + cutoutSize - r - cornerLen),
      corner,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
