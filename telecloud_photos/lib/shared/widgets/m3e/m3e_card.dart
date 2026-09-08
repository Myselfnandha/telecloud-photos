import 'package:flutter/material.dart';

enum M3ECardVariant { filled, elevated, outlined }

/// Material 3 Expressive Card
/// 32dp (or 20dp) rounded corners, top image/placeholder container,
/// headline in titleMedium, body in bodyMedium, 16dp inner padding.
class M3ECard extends StatelessWidget {
  final String headline;
  final String body;
  final Widget? imageWidget;
  final IconData? placeholderIcon;
  final double? height;
  final M3ECardVariant variant;
  final VoidCallback? onTap;
  final Widget? child;
  final double borderRadius;

  const M3ECard({
    super.key,
    required this.headline,
    required this.body,
    this.imageWidget,
    this.placeholderIcon,
    this.height,
    this.variant = M3ECardVariant.filled,
    this.onTap,
    this.child,
    this.borderRadius = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Color bg;
    Border? border;
    List<BoxShadow>? shadows;

    switch (variant) {
      case M3ECardVariant.filled:
        bg = scheme.surfaceContainerHighest;
        break;
      case M3ECardVariant.elevated:
        bg = scheme.surfaceContainerLow;
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
        break;
      case M3ECardVariant.outlined:
        bg = scheme.surface;
        border = Border.all(color: scheme.outlineVariant, width: 1);
        break;
    }

    final cardContent = Container(
      constraints: height != null ? BoxConstraints(minHeight: height!) : null,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Image / Placeholder area
          if (imageWidget != null)
            imageWidget!
          else if (placeholderIcon != null)
            Container(
              height: height != null ? (height! * 0.38) : 72,
              width: double.infinity,
              color: scheme.primaryContainer.withValues(alpha: 0.35),
              alignment: Alignment.center,
              child: Icon(
                placeholderIcon,
                size: 36,
                color: scheme.primary,
              ),
            ),

          // Content body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (child != null) ...[
                  const SizedBox(height: 12),
                  child!,
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
