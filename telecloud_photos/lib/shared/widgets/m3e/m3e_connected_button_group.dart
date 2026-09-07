import 'package:flutter/material.dart';

class M3EConnectedButtonItem {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isFilled; // true = filled (primary), false = tonal (secondaryContainer)

  const M3EConnectedButtonItem({
    required this.label,
    this.icon,
    this.onPressed,
    this.isFilled = true,
  });
}

/// Material 3 Expressive Connected Button Group
/// A row with 3dp gaps where outer corners are pill-rounded and inner adjoining
/// corners shrink to 8dp.
class M3EConnectedButtonGroup extends StatelessWidget {
  final List<M3EConnectedButtonItem> items;
  final double height;

  const M3EConnectedButtonGroup({
    super.key,
    required this.items,
    this.height = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: _buildButton(
                context: context,
                item: items[i],
                index: i,
                total: items.length,
                scheme: scheme,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required M3EConnectedButtonItem item,
    required int index,
    required int total,
    required ColorScheme scheme,
  }) {
    final isFirst = index == 0;
    final isLast = index == total - 1;

    // Outer corners stay fully rounded (pill: radius = height / 2 = 28dp)
    // Inner adjoining corners shrink to 8dp
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 28 : 8),
      bottomLeft: Radius.circular(isFirst ? 28 : 8),
      topRight: Radius.circular(isLast ? 28 : 8),
      bottomRight: Radius.circular(isLast ? 28 : 8),
    );

    final bg = item.isFilled ? scheme.primary : scheme.secondaryContainer;
    final fg = item.isFilled ? scheme.onPrimary : scheme.onSecondaryContainer;

    return Material(
      color: bg,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: item.onPressed,
        borderRadius: borderRadius,
        child: Container(
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: fg,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
