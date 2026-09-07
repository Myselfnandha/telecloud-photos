import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Material 3 Expressive Wavy Linear Progress Indicator
/// Features a sine-wave animated waveform on the active progress segment
/// with rounded caps, secondaryContainer track, and primary wave fill.
class M3EWavyProgressIndicator extends StatefulWidget {
  final double? progress; // 0.0 to 1.0, or null for indeterminate
  final double height;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;

  const M3EWavyProgressIndicator({
    super.key,
    this.progress,
    this.height = 16.0,
    this.strokeWidth = 4.0,
    this.color,
    this.backgroundColor,
  });

  @override
  State<M3EWavyProgressIndicator> createState() =>
      _M3EWavyProgressIndicatorState();
}

class _M3EWavyProgressIndicatorState extends State<M3EWavyProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trackColor =
        widget.backgroundColor ?? theme.colorScheme.secondaryContainer;
    final waveColor = widget.color ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _M3EWavyPainter(
            progress: widget.progress?.clamp(0.0, 1.0),
            animationPhase: _waveController.value * 2 * math.pi,
            trackColor: trackColor,
            waveColor: waveColor,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class _M3EWavyPainter extends CustomPainter {
  final double? progress;
  final double animationPhase;
  final Color trackColor;
  final Color waveColor;
  final double strokeWidth;

  _M3EWavyPainter({
    required this.progress,
    required this.animationPhase,
    required this.trackColor,
    required this.waveColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    // 1. Draw track (straight line with round caps)
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(strokeWidth / 2, centerY),
      Offset(size.width - strokeWidth / 2, centerY),
      trackPaint,
    );

    // 2. Draw active wavy portion
    final wavePaint = Paint()
      ..color = waveColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final isIndeterminate = progress == null;
    final activeWidth = isIndeterminate
        ? size.width * 0.4
        : (size.width - strokeWidth) * progress!;

    if (activeWidth <= 0) return;

    final startX = isIndeterminate
        ? ((size.width + activeWidth) *
                ((animationPhase / (2 * math.pi)) % 1.0)) -
            activeWidth
        : strokeWidth / 2;
    final endX = startX + activeWidth;

    final clampedStartX = startX.clamp(strokeWidth / 2, size.width - strokeWidth / 2);
    final clampedEndX = endX.clamp(strokeWidth / 2, size.width - strokeWidth / 2);

    if (clampedEndX <= clampedStartX) return;

    final path = Path();
    const wavelength = 28.0;
    final amplitude = (size.height / 2 - strokeWidth).clamp(2.0, 5.0);

    bool firstPoint = true;
    for (double x = clampedStartX; x <= clampedEndX; x += 2.0) {
      final normalizedX = (x - clampedStartX) / wavelength;
      final y = centerY + math.sin(normalizedX * 2 * math.pi - animationPhase) * amplitude;

      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _M3EWavyPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationPhase != animationPhase ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.waveColor != waveColor;
  }
}
