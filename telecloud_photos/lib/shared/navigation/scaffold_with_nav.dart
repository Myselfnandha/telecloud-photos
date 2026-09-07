import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_bottom_nav.dart';

class ScaffoldWithNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  late final AnimationController _snapController;
  Animation<double>? _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_snapAnimation != null && mounted) {
          setState(() {
            _dragOffset = _snapAnimation!.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final currentIdx = widget.navigationShell.currentIndex;
    final delta = details.primaryDelta ?? 0;

    // Boundary check: cannot swipe right on first tab, cannot swipe left on last tab
    if (currentIdx == 0 && delta > 0 && _dragOffset >= 0) return;
    if (currentIdx == 3 && delta < 0 && _dragOffset <= 0) return;

    setState(() {
      _dragOffset += delta;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final currentIdx = widget.navigationShell.currentIndex;
    const threshold = 70.0;

    int targetIndex = currentIdx;

    if (velocity < -400 || _dragOffset < -threshold) {
      // Swiped Left -> Move to next tab
      if (currentIdx < 3) {
        targetIndex = currentIdx + 1;
      }
    } else if (velocity > 400 || _dragOffset > threshold) {
      // Swiped Right -> Move to previous tab
      if (currentIdx > 0) {
        targetIndex = currentIdx - 1;
      }
    }

    if (targetIndex != currentIdx) {
      widget.navigationShell.goBranch(
        targetIndex,
        initialLocation: false,
      );
    }

    // Spring snap back to center
    _snapAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    _snapController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.navigationShell.currentIndex != 0) {
          widget.navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: GestureDetector(
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          behavior: HitTestBehavior.translucent,
          child: Transform.translate(
            offset: Offset(_dragOffset * 0.4, 0),
            child: widget.navigationShell,
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: widget.navigationShell.currentIndex,
          onTap: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }
}
