import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

import '../core/theme/app_colors.dart';
import '../models/course_model.dart';
import '../providers/course_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/floating_line_background.dart';

class CourseQrScreen extends StatefulWidget {
  const CourseQrScreen({super.key, this.preselectedCourseCode});
  final String? preselectedCourseCode;

  @override
  State<CourseQrScreen> createState() => _CourseQrScreenState();
}

class _CourseQrScreenState extends State<CourseQrScreen> {
  final GlobalKey _qrCardKey = GlobalKey();
  CourseModel? _selectedCourse;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDefaultCourse());
  }

  void _ensureDefaultCourse() {
    if (_selectedCourse != null) return;
    final teaching = _teachingCourses(context);
    if (teaching.isEmpty) return;

    // If courseCode was passed, select that course directly
    if (widget.preselectedCourseCode != null) {
      final match = teaching.firstWhere(
        (c) => c.courseCode == widget.preselectedCourseCode,
        orElse: () => teaching.first,
      );
      setState(() => _selectedCourse = match);
    } else {
      setState(() => _selectedCourse = teaching.first);
    }
  }

  List<CourseModel> _teachingCourses(BuildContext context) {
    final user = context.read<UserProvider>().user;
    final currentUserName = user?.userName;
    final allCourses = context.read<CourseProvider>().allCourses;
    return allCourses.where((c) => c.createdBy == currentUserName).toList();
  }

  String _qrPayloadFor(CourseModel course) {
    return '{"type":"course","courseCode":"${course.courseCode}"}';
  }

  Future<Uint8List?> _captureQrCardImage() async {
    try {
      final boundary =
          _qrCardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _downloadQr() async {
    if (_selectedCourse == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final bytes = await _captureQrCardImage();
      if (bytes == null) {
        _showSnack('Could not generate the QR image', isError: true);
        return;
      }
      await Gal.putImageBytes(
        bytes,
        name: 'course_qr_${_selectedCourse!.courseCode}',
      );
      _showSnack('QR code saved to your photos');
    } catch (e) {
      _showSnack('Failed to save QR code: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareQr() async {
    if (_selectedCourse == null) return;
    try {
      final bytes = await _captureQrCardImage();
      if (bytes == null) {
        _showSnack('Could not generate the QR image', isError: true);
        return;
      }
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: 'course_qr_${_selectedCourse!.courseCode}.png',
            mimeType: 'image/png',
          ),
        ],
        text:
            'Join "${_selectedCourse!.courseName}" (${_selectedCourse!.courseCode}) — scan this QR code in the app.',
      );
    } catch (e) {
      _showSnack('Failed to share QR code: $e', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teaching = _teachingCourses(context);
    _ensureDefaultCourse();

    return Scaffold(
      backgroundColor: const Color(0xFF111315),
      body: Stack(
        children: [
          // ── Animated background ──────────────────────────────────
          const FloatingLinesBackground(
            colors: [Color(0xFF00FF88), Color(0xFF00DD66), Color(0xFF1E6B2D)],
            lineCount: 6,
            animationSpeed: 0.5,
          ),

          // ── Foreground content ───────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────────────
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

                const SizedBox(height: 4),

                const Text(
                  'Course QR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Students can scan this QR code to join the course',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Body (no scroll) ───────────────────────────────
                Expanded(
                  child: teaching.isEmpty
                      ? _buildEmptyState()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildQrCard(),
                              const SizedBox(height: 40),
                              if (widget.preselectedCourseCode == null)
                                _buildCourseDropdown(teaching),
                              if (widget.preselectedCourseCode == null)
                                const SizedBox(height: 40),
                              _buildActionButtons(),
                            ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, color: Colors.white38, size: 56),
            const SizedBox(height: 12),
            const Text(
              'No courses to show yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create a course first, then come back here to generate its QR code.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                context.pop();
                context.push('/courses');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
              ),
              child: const Text('Go to My Courses'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseDropdown(List<CourseModel> teaching) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedCourse?.courseCode,
          dropdownColor: Colors.white,
          icon: Icon(Icons.expand_more, color: AppColors.primary),
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          items: teaching
              .map(
                (course) => DropdownMenuItem<String>(
                  value: course.courseCode,
                  child: Text(
                    '${course.courseCode} • ${course.courseName}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              )
              .toList(),
          onChanged: (code) {
            if (code == null) return;
            setState(() {
              _selectedCourse = teaching.firstWhere(
                (c) => c.courseCode == code,
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildQrCard() {
    final course = _selectedCourse;
    if (course == null) return const SizedBox.shrink();

    return Center(
      child: SizedBox(
        width: 400,
        child: RepaintBoundary(
          key: _qrCardKey,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header: white bg, primary text ──────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: const BoxDecoration(
                    color: Colors.white, // ← white background
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        course.courseName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary, // ← primary text
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(
                            0.1,
                          ), // ← soft primary tint
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          course.courseCode,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary, // ← primary text
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Divider between header and QR ────────────────────
                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // ── QR body ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
                  child: Column(
                    children: [
                      QrImageView(
                        data: _qrPayloadFor(course),
                        version: QrVersions.auto,
                        size: 300,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF1B3B22),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF1B3B22),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 13,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Scan with the app to join this course',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.download_rounded,
          label: 'Download',
          isLoading: _isSaving,
          onTap: _downloadQr,
        ),
        const SizedBox(width: 80),
        _ActionButton(
          icon: Icons.ios_share_rounded,
          label: 'Share via',
          onTap: _shareQr,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
