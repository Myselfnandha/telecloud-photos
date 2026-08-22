import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../theme/app_elevation.dart';
import '../theme/app_motion.dart';

class FastScroller extends StatefulWidget {
  final ScrollController scrollController;
  final Widget child;
  final List<String> dateLabels;
  final bool isLight;

  const FastScroller({
    super.key,
    required this.scrollController,
    required this.child,
    required this.dateLabels,
    required this.isLight,
  });

  @override
  State<FastScroller> createState() => _FastScrollerState();
}

class _FastScrollerState extends State<FastScroller> {
  bool _isDragging = false;
  double _thumbPosition = 0.0; // 0.0 to 1.0
  String _currentDateLabel = '';
  Timer? _hideBubbleTimer;
  int _lastDateIndex = -1;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant FastScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _hideBubbleTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isDragging) return;
    if (!widget.scrollController.hasClients) return;
    final maxScroll = widget.scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    final current = widget.scrollController.position.pixels;
    final progress = (current / maxScroll).clamp(0.0, 1.0);
    if (mounted) {
      setState(() {
        _thumbPosition = progress;
      });
    }
  }

  void _handleDrag(double localY, double totalHeight) {
    if (totalHeight <= 0 || !widget.scrollController.hasClients) return;
    final progress = (localY / totalHeight).clamp(0.0, 1.0);
    final maxScroll = widget.scrollController.position.maxScrollExtent;
    final targetOffset = progress * maxScroll;

    widget.scrollController.jumpTo(targetOffset);

    // Calculate active date label
    if (widget.dateLabels.isNotEmpty) {
      final index = (progress * (widget.dateLabels.length - 1)).round().clamp(
        0,
        widget.dateLabels.length - 1,
      );
      final label = widget.dateLabels[index];
      if (index != _lastDateIndex) {
        _lastDateIndex = index;
        HapticFeedback.selectionClick();
      }
      _currentDateLabel = label;
    }

    setState(() {
      _thumbPosition = progress;
      _isDragging = true;
    });

    _hideBubbleTimer?.cancel();
  }

  void _handleDragEnd() {
    _hideBubbleTimer?.cancel();
    _hideBubbleTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _isDragging = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight =
            constraints.maxHeight - 100; // Leave margin top/bottom
        final thumbTop =
            50 + (_thumbPosition * (availableHeight > 0 ? availableHeight : 1));

        return Stack(
          children: [
            widget.child,

            // Right edge touch & drag scrubber track
            Positioned(
              right: 0,
              top: 50,
              bottom: 50,
              width: 32,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragStart: (details) =>
                    _handleDrag(details.localPosition.dy, availableHeight),
                onVerticalDragUpdate: (details) =>
                    _handleDrag(details.localPosition.dy, availableHeight),
                onVerticalDragEnd: (_) => _handleDragEnd(),
                onVerticalDragCancel: () => _handleDragEnd(),
                child: const SizedBox.expand(),
              ),
            ),

            // Draggable Thumb Indicator
            Positioned(
              right: AppSpacing.xs,
              top: thumbTop - 18,
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: AppMotion.durationFast,
                  width: _isDragging ? AppSpacing.s : AppSpacing.xs,
                  height: _isDragging ? 42 : 32,
                  decoration: BoxDecoration(
                    color: _isDragging
                        ? AppColors.primaryBlue
                        : (widget.isLight ? Colors.black38 : Colors.white38),
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                    boxShadow: _isDragging
                        ? [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: AppSpacing.s,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),

            // Floating Date Bubble Tooltip (Apple Photos style)
            if (_isDragging && _currentDateLabel.isNotEmpty)
              Positioned(
                right: AppSpacing.xxl,
                top: (thumbTop - 20).clamp(60.0, constraints.maxHeight - 70),
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _isDragging ? 1.0 : 0.0,
                    duration: AppMotion.durationFast,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m + 2,
                        vertical: AppSpacing.s,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isLight
                            ? AppColors.darkSurface.withValues(alpha: 0.92)
                            : AppColors.darkCard.withValues(alpha: 0.95),
                        borderRadius: AppRadii.borderXL,
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: AppElevation.softShadowDark,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: AppColors.primaryBlue,
                          ),
                          AppSpacing.gapHorizontalS,
                          Text(
                            _currentDateLabel,
                            style: AppTypography.labelLarge(color: Colors.white)
                                .copyWith(
                                  fontWeight: AppTypography.bold,
                                  letterSpacing: 0.3,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
