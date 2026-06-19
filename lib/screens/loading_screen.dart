// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../widgets/logo_app.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late AnimationController _sparkleController;
  late AnimationController _decorController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _taglineFade;
  late Animation<double> _progress;
  late Animation<double> _sparkleFade;
  late Animation<double> _sparkleScale;
  late Animation<double> _decorFade;

  String _statusText = 'INITIALIZING';

  // Light green tinted background
  static const Color _bgColor = Color(0xFFEFF7F1);

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.75, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _progress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _sparkleFade = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
    _sparkleScale = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    _decorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _decorFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _decorController, curve: Curves.easeOut));

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoController.forward();
    _decorController.forward();

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _progressController.forward();

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _statusText = 'LOADING ASSETS');

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _statusText = 'ALMOST READY');

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _statusText = 'DONE');

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    context.go('/start'); // ← navigates after loading
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    _sparkleController.dispose();
    _decorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Subtle green radial glow in center
          Center(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    _bgColor.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          // Top-right sparkles
          Positioned(
            top: 80,
            right: 30,
            child: FadeTransition(
              opacity: _decorFade,
              child: AnimatedBuilder(
                animation: _sparkleController,
                builder: (_, __) => Opacity(
                  opacity: _sparkleFade.value,
                  child: Transform.scale(
                    scale: _sparkleScale.value,
                    child: _SparkleGroup(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom-left decor diamond
          Positioned(
            bottom: 100,
            left: 20,
            child: FadeTransition(
              opacity: _decorFade,
              child: _DiamondDecor(color: AppColors.primary.withOpacity(0.2)),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (_, __) => FadeTransition(
                    opacity: _logoFade,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: const LogoApp(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    'Focus on what matters.',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: AppColors.caption,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom progress
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress.value,
                        minHeight: 5,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _statusText,
                    key: ValueKey(_statusText),
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.caption,
                      letterSpacing: 2,
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

// ── Sparkle group ──────────────────────────────────────────────────────────

class _SparkleGroup extends StatelessWidget {
  final Color color;
  const _SparkleGroup({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 20,
            child: _Sparkle(size: 42, color: color),
          ),
          Positioned(top: 0, right: 0, child: _Sparkle(size: 24, color: color)),
          Positioned(
            bottom: 0,
            right: 20,
            child: _Sparkle(size: 18, color: color),
          ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  final double size;
  final Color color;
  const _Sparkle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparklePainter(color: color),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;
  const _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final path = Path();
    path.moveTo(cx, 0);
    path.quadraticBezierTo(cx * 1.15, cy * 0.85, cx, cy);
    path.quadraticBezierTo(cx * 0.85, cy * 0.85, 0, cy);
    path.quadraticBezierTo(cx * 0.85, cy * 1.15, cx, size.height);
    path.quadraticBezierTo(cx * 1.15, cy * 1.15, size.width, cy);
    path.quadraticBezierTo(cx * 1.15, cy * 0.85, cx, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.color != color;
}

// ── Diamond decor ──────────────────────────────────────────────────────────

class _DiamondDecor extends StatelessWidget {
  final Color color;
  const _DiamondDecor({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Diamond(size: 90, color: color),
          _Diamond(size: 58, color: color),
        ],
      ),
    );
  }
}

class _Diamond extends StatelessWidget {
  final double size;
  final Color color;
  const _Diamond({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785398,
      child: Container(
        width: size * 0.65,
        height: size * 0.65,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
