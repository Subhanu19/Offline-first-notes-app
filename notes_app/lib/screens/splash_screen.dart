import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import your existing home screen

// ─────────────────────────────────────────────────────────────────────────────
// ADD TO pubspec.yaml:
//   dependencies:
//     flutter_animate: ^4.5.0
//
// THEN run: flutter pub get
// ─────────────────────────────────────────────────────────────────────────────
// If flutter_animate is not yet available, the fallback AnimatedBuilder
// version below produces identical motion without the dependency.
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color _bg        = Color(0xFF0F172A);
  static const Color _ink       = Color(0xFF8B5CF6);
  static const Color _glow      = Color(0xFFA78BFA);
  static const Color _textColor = Colors.white;

  // ── Timing constants (ms) ──────────────────────────────────────────────────
  static const int _dotAppearMs    = 300;
  static const int _strokeDrawMs   = 1600;
  static const int _textFadeMs     = 500;
  static const int _holdMs         = 600;
  static const int _exitFadeMs     = 600;

  // Total runtime before navigation
  static const int _totalMs =
      _dotAppearMs + _strokeDrawMs + _textFadeMs + _holdMs + _exitFadeMs + 200;

  // ── Controllers ────────────────────────────────────────────────────────────
  late final AnimationController _dotCtrl;
  late final AnimationController _strokeCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _scaleCtrl;
  late final AnimationController _exitCtrl;

  // ── Derived animations ─────────────────────────────────────────────────────
  late final Animation<double> _dotOpacity;
  late final Animation<double> _strokeProgress;
  late final Animation<double> _textOpacity;
  late final Animation<double> _glowIntensity;
  late final Animation<double> _scale;
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();
    _buildControllers();
    _runSequence();
  }

  void _buildControllers() {
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _dotAppearMs),
    );
    _strokeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _strokeDrawMs),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _textFadeMs),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _strokeDrawMs + _textFadeMs + _holdMs),
    );
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _exitFadeMs),
    );

    _dotOpacity = CurvedAnimation(parent: _dotCtrl, curve: Curves.easeOut);

    _strokeProgress = CurvedAnimation(
      parent: _strokeCtrl,
      curve: Curves.easeInOutCubic,
    );

    _textOpacity = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn);

    _glowIntensity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );
  }

  Future<void> _runSequence() async {
    // 1. Dot appears
    await _dotCtrl.forward();

    // 2. Stroke draws + scale begins
    _scaleCtrl.forward();
    await _strokeCtrl.forward();

    // 3. Text fades in; glow pulses
    _glowCtrl.repeat(reverse: true);
    await _textCtrl.forward();

    // 4. Hold (show the completed logo and text)
    await Future.delayed(const Duration(milliseconds: _holdMs));

    // 5. Exit fade (smooth transition to home screen)
    _glowCtrl.stop();
    await _exitCtrl.forward();

    // 6. Navigate to HomeScreen after splash completes
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(), // Your existing home screen
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    _strokeCtrl.dispose();
    _textCtrl.dispose();
    _glowCtrl.dispose();
    _scaleCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _dotOpacity, _strokeProgress, _textOpacity,
          _glowIntensity, _scale, _exitOpacity,
        ]),
        builder: (context, _) {
          return FadeTransition(
            opacity: _exitOpacity,
            child: Container(
              color: _bg,
              child: Center(
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LogoCanvas(
                        dotOpacity:      _dotOpacity.value,
                        strokeProgress:  _strokeProgress.value,
                        glowIntensity:   _glowIntensity.value,
                        inkColor:        _ink,
                        glowColor:       _glow,
                      ),
                      const SizedBox(height: 28),
                      Opacity(
                        opacity: _textOpacity.value,
                        child: Column(
                          children: [
                            Text(
                              'Noto',
                              style: TextStyle(
                                color: _textColor,
                                fontSize: 38,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 10,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Capture ideas instantly.',
                              style: TextStyle(
                                color: _glow.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 2.2,
                              ),
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
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo canvas — draws the animated "N" stroke over a 120×120 area
// ─────────────────────────────────────────────────────────────────────────────
class _LogoCanvas extends StatelessWidget {
  const _LogoCanvas({
    required this.dotOpacity,
    required this.strokeProgress,
    required this.glowIntensity,
    required this.inkColor,
    required this.glowColor,
  });

  final double dotOpacity;
  final double strokeProgress;
  final double glowIntensity;
  final Color inkColor;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(
        painter: _NLogoPainter(
          dotOpacity:     dotOpacity,
          strokeProgress: strokeProgress,
          glowIntensity:  glowIntensity,
          inkColor:       inkColor,
          glowColor:      glowColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter — single-stroke liquid-ink "N"
// ─────────────────────────────────────────────────────────────────────────────
class _NLogoPainter extends CustomPainter {
  _NLogoPainter({
    required this.dotOpacity,
    required this.strokeProgress,
    required this.glowIntensity,
    required this.inkColor,
    required this.glowColor,
  });

  final double dotOpacity;
  final double strokeProgress;
  final double glowIntensity;
  final Color inkColor;
  final Color glowColor;

  // ── Stroke definition ──────────────────────────────────────────────────────
  // The "N" is drawn as one continuous cubic-bezier path.
  // Normalised to a 100×100 grid, centred on the 120×120 canvas (offset 10,10).
  //
  //  Path narrative:
  //   • Start bottom-left leg  (10, 82)
  //   • Curve up left side     → (10, 18)   [vertical, slight lean]
  //   • Diagonal sweep         → (90, 82)   [the "cross-bar" of the N]
  //   • Curve up right side    → (90, 18)   [vertical, slight lean]
  //
  static Path _buildFullPath(Size size) {
    final double ox = (size.width  - 100) / 2;
    final double oy = (size.height - 100) / 2;

    Offset o(double x, double y) => Offset(ox + x, oy + y);

    final path = Path();

    // ── Left leg: bottom → top ────────────────────────────────────────────
    path.moveTo(o(12, 84).dx, o(12, 84).dy);

    path.cubicTo(
      o(10, 70).dx, o(10, 70).dy,   // ctrl 1
      o(10, 30).dx, o(10, 30).dy,   // ctrl 2
      o(12, 16).dx, o(12, 16).dy,   // end
    );

    // ── Rounded top-left cap (small curve outward) ───────────────────────
    path.cubicTo(
      o(12,  8).dx, o(12,  8).dy,
      o(16,  5).dx, o(16,  5).dy,
      o(20, 10).dx, o(20, 10).dy,
    );

    // ── Diagonal cross-stroke: top-left → bottom-right ───────────────────
    path.cubicTo(
      o(35, 30).dx, o(35, 30).dy,
      o(65, 72).dx, o(65, 72).dy,
      o(80, 90).dx, o(80, 90).dy,
    );

    // ── Rounded bottom-right corner ───────────────────────────────────────
    path.cubicTo(
      o(84, 96).dx, o(84, 96).dy,
      o(90, 96).dx, o(90, 96).dy,
      o(90, 88).dx, o(90, 88).dy,
    );

    // ── Right leg: bottom → top ────────────────────────────────────────────
    path.cubicTo(
      o(90, 72).dx, o(90, 72).dy,
      o(90, 28).dx, o(90, 28).dy,
      o(88, 14).dx, o(88, 14).dy,
    );

    return path;
  }

  // ── Path metrics helper ────────────────────────────────────────────────────
  static Path? _cachedPath;
  static Size?  _cachedSize;

  Path _getPath(Size size) {
    if (_cachedSize != size) {
      _cachedPath = _buildFullPath(size);
      _cachedSize = size;
    }
    return _cachedPath!;
  }

  /// Extract a sub-path from `t=0` to `t=progress` using PathMetrics.
  Path _extractPartial(Path full, double progress) {
    if (progress <= 0) return Path();
    if (progress >= 1) return full;

    final metrics = full.computeMetrics().toList();
    final totalLen = metrics.fold<double>(0, (s, m) => s + m.length);
    final targetLen = totalLen * progress;

    final result = Path();
    double consumed = 0;

    for (final metric in metrics) {
      if (consumed >= targetLen) break;
      final remaining = targetLen - consumed;
      if (remaining >= metric.length) {
        result.addPath(metric.extractPath(0, metric.length), Offset.zero);
        consumed += metric.length;
      } else {
        result.addPath(metric.extractPath(0, remaining), Offset.zero);
        consumed = targetLen;
      }
    }
    return result;
  }

  // ── Ink dot position (start of stroke) ────────────────────────────────────
  Offset _dotPosition(Size size) {
    final double ox = (size.width  - 100) / 2;
    final double oy = (size.height - 100) / 2;
    return Offset(ox + 12, oy + 84);
  }

  // ── Tip of drawn stroke (for the moving dot) ──────────────────────────────
  Offset _tipPosition(Path full, double progress, Size size) {
    if (progress <= 0) return _dotPosition(size);
    final metrics = full.computeMetrics().toList();
    final totalLen = metrics.fold<double>(0, (s, m) => s + m.length);
    final targetLen = (totalLen * math.min(progress, 1)).clamp(0, totalLen);

    double consumed = 0;
    for (final metric in metrics) {
      if (consumed + metric.length >= targetLen) {
        final localT = targetLen - consumed;
        final tangent = metric.getTangentForOffset(localT.clamp(0, metric.length));
        return tangent?.position ?? _dotPosition(size);
      }
      consumed += metric.length;
    }
    return _dotPosition(size);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fullPath = _getPath(size);

    // ── 1. Glow halo behind stroke (only once stroke has started) ─────────
    if (strokeProgress > 0.05) {
      final glowPaint = Paint()
        ..color        = glowColor.withOpacity(0.12 * glowIntensity)
        ..strokeWidth  = 22
        ..strokeCap    = StrokeCap.round
        ..strokeJoin   = StrokeJoin.round
        ..style        = PaintingStyle.stroke
        ..maskFilter   = const MaskFilter.blur(BlurStyle.normal, 18);

      canvas.drawPath(_extractPartial(fullPath, strokeProgress), glowPaint);
    }

    // ── 2. Main ink stroke ────────────────────────────────────────────────
    if (strokeProgress > 0) {
      // Outer soft edge
      final softPaint = Paint()
        ..color       = inkColor.withOpacity(0.22)
        ..strokeWidth = 9
        ..strokeCap   = StrokeCap.round
        ..strokeJoin  = StrokeJoin.round
        ..style       = PaintingStyle.stroke
        ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(_extractPartial(fullPath, strokeProgress), softPaint);

      // Core crisp stroke
      final inkPaint = Paint()
        ..color       = inkColor
        ..strokeWidth = 5.5
        ..strokeCap   = StrokeCap.round
        ..strokeJoin  = StrokeJoin.round
        ..style       = PaintingStyle.stroke;
      canvas.drawPath(_extractPartial(fullPath, strokeProgress), inkPaint);

      // Bright centre line for premium look
      final brightPaint = Paint()
        ..color       = glowColor.withOpacity(0.55)
        ..strokeWidth = 2
        ..strokeCap   = StrokeCap.round
        ..strokeJoin  = StrokeJoin.round
        ..style       = PaintingStyle.stroke;
      canvas.drawPath(_extractPartial(fullPath, strokeProgress), brightPaint);
    }

    // ── 3. Moving ink tip dot ──────────────────────────────────────────────
    final tipVisible = strokeProgress < 0.98 ? 1.0 : (1.0 - (strokeProgress - 0.98) / 0.02).clamp(0, 1);
    final tipPos     = strokeProgress > 0
        ? _tipPosition(fullPath, strokeProgress, size)
        : _dotPosition(size);
    final combinedDotOpacity = strokeProgress < 0.01 ? dotOpacity : tipVisible;

    if (combinedDotOpacity > 0) {
      // Outer glow
      canvas.drawCircle(
        tipPos,
        12,
        Paint()
          ..color      = glowColor.withOpacity(0.18 * combinedDotOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      // Dot body
      canvas.drawCircle(
        tipPos,
        5,
        Paint()
          ..color = glowColor.withOpacity(0.9 * combinedDotOpacity),
      );
      // Bright centre
      canvas.drawCircle(
        tipPos,
        2.5,
        Paint()
          ..color = Colors.white.withOpacity(0.85 * combinedDotOpacity),
      );
    }
  }

  @override
  bool shouldRepaint(_NLogoPainter old) =>
      old.dotOpacity     != dotOpacity     ||
      old.strokeProgress != strokeProgress ||
      old.glowIntensity  != glowIntensity;
}