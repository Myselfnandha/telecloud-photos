import 'package:flutter/material.dart';

class M3EToolbarAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const M3EToolbarAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });
}

/// Material 3 Expressive Horizontal Floating Toolbar
/// 64dp tall, fully rounded (pill), floating 16dp above bottom edge.
/// Vibrant uses primaryContainer with 48dp icon buttons.
class M3EFloatingToolbar extends StatelessWidget {
  final List<M3EToolbarAction> actions;
  final bool isVibrant;

  const M3EFloatingToolbar({
    super.key,
    required this.actions,
    this.isVibrant = true,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bg = isVibrant ? scheme.primaryContainer : scheme.surfaceContainer;
    final fg = isVibrant ? scheme.onPrimaryContainer : scheme.onSurface;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ShapeDecoration(
        color: bg,
        shape: const StadiumBorder(),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                icon: Icon(actions[i].icon, size: 24),
                color: actions[i].color ?? fg,
                tooltip: actions[i].tooltip,
                onPressed: actions[i].onPressed,
                style: IconButton.styleFrom(
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
