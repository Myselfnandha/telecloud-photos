import 'package:flutter/material.dart';

class M3EListItemData {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? leadingWidget;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? leadingCircleColor;
  final Color? leadingIconColor;
  final Color? backgroundColor;

  const M3EListItemData({
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.leadingWidget,
    this.trailing,
    this.onTap,
    this.leadingCircleColor,
    this.leadingIconColor,
    this.backgroundColor,
  });
}

/// Material 3 Expressive Stacked List
/// A vertical run with 3dp gaps, 28dp outer corners and 8dp inner corners.
/// Each item is 72dp tall with a 24dp leading icon on a 40dp circle container.
class M3EStackedList extends StatelessWidget {
  final List<M3EListItemData> items;
  final EdgeInsetsGeometry padding;

  const M3EStackedList({
    super.key,
    required this.items,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 3),
            _buildItem(
              context: context,
              item: items[i],
              index: i,
              total: items.length,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required M3EListItemData item,
    required int index,
    required int total,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isFirst = index == 0;
    final isLast = index == total - 1;

    // 28dp outer corners, 8dp inner corners
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 28 : 8),
      topRight: Radius.circular(isFirst ? 28 : 8),
      bottomLeft: Radius.circular(isLast ? 28 : 8),
      bottomRight: Radius.circular(isLast ? 28 : 8),
    );

    final itemBg = item.backgroundColor ?? scheme.surfaceContainerLow;
    final iconCircleBg = item.leadingCircleColor ?? scheme.primaryContainer;
    final iconFg = item.leadingIconColor ?? scheme.onPrimaryContainer;

    return Material(
      color: itemBg,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: borderRadius,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 40dp circle with 24dp leading icon
              if (item.leadingWidget != null)
                item.leadingWidget!
              else if (item.leadingIcon != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconCircleBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    item.leadingIcon,
                    size: 24,
                    color: iconFg,
                  ),
                ),
              if (item.leadingWidget != null || item.leadingIcon != null)
                const SizedBox(width: 16),

              // Title and Subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing action or icon
              if (item.trailing != null) ...[
                const SizedBox(width: 12),
                item.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
