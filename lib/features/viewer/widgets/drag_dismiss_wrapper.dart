import 'package:flutter/material.dart';

class DragDismissWrapper extends StatelessWidget {
  final Widget child;
  final double dragOffsetY;
  final double currentScale;
  final void Function(DragUpdateDetails details) onDragUpdate;
  final void Function(DragEndDetails details) onDragEnd;
  final VoidCallback onDragCancel;

  const DragDismissWrapper({
    super.key,
    required this.child,
    required this.dragOffsetY,
    required this.currentScale,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
      onVerticalDragCancel: onDragCancel,
      child: Transform.translate(
        offset: Offset(0, dragOffsetY),
        child: Transform.scale(
          scale: currentScale,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              (dragOffsetY / 12).clamp(0.0, 24.0),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
