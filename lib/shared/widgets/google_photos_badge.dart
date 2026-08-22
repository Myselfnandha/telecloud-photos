import 'package:flutter/material.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../theme/app_elevation.dart';

class GooglePhotosBadge extends StatelessWidget {
  final bool compact;

  const GooglePhotosBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : AppSpacing.s - 1,
        vertical: compact ? 3 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: AppRadii.borderS,
        border: Border.all(
          color: const Color(0xFF4285F4).withValues(alpha: 0.4),
          width: 0.75,
        ),
        boxShadow: AppElevation.softShadowDark,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 4-Color Google Photos Pinwheel Icon
          SizedBox(
            width: compact ? 11 : 13,
            height: compact ? 11 : 13,
            child: CustomPaint(painter: _GooglePhotosIconPainter()),
          ),
          if (!compact) ...[
            AppSpacing.gapHorizontalXS,
            Text(
              'Google Photos',
              style: AppTypography.labelSmall(color: Colors.white).copyWith(
                fontSize: 10,
                fontWeight: AppTypography.bold,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GooglePhotosIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 4;

    // Google Red
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    // Google Yellow
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    // Google Green
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    // Google Blue
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    // Top Leaf (Red)
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(center.dx - radius, 0, radius * 2, radius * 2),
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
      ),
      redPaint,
    );

    // Right Leaf (Yellow)
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(center.dx, center.dy - radius, radius * 2, radius * 2),
        topRight: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
      ),
      yellowPaint,
    );

    // Bottom Leaf (Green)
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(center.dx - radius, center.dy, radius * 2, radius * 2),
        bottomLeft: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
      ),
      greenPaint,
    );

    // Left Leaf (Blue)
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, center.dy - radius, radius * 2, radius * 2),
        topLeft: Radius.circular(radius),
        bottomLeft: Radius.circular(radius),
      ),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
