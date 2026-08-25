import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_elevation.dart';
import '../../../../shared/theme/app_icons.dart';
import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_radii.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../controllers/timeline_zoom_controller.dart';

class TierBadgeOverlay extends StatelessWidget {
  final TimelineTier activeTier;
  final bool isVisible;

  const TierBadgeOverlay({
    super.key,
    required this.activeTier,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Positioned(
      top: AppSpacing.m,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: AppMotion.durationMedium,
        curve: AppMotion.curveStandard,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.s,
            ),
            decoration: BoxDecoration(
              color:
                  isLight ? const Color(0xF2FFFFFF) : const Color(0xF01C1C1E),
              borderRadius: AppRadii.borderFull,
              border: Border.all(
                color: isLight
                    ? AppColors.glassBorderLight
                    : AppColors.glassBorderDark,
                width: 0.8,
              ),
              boxShadow: AppElevation.glassPillShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  activeTier.icon,
                  color: AppColors.primaryBlue,
                  size: AppIcons.s,
                ),
                AppSpacing.gapHorizontalS,
                Text(
                  activeTier.label,
                  style: AppTypography.labelLarge(
                    color: isLight
                        ? AppColors.lightTextPrimary
                        : AppColors.darkTextPrimary,
                  ).copyWith(
                    fontWeight: AppTypography.bold,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
