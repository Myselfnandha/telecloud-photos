import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_motion.dart';
import 'transition_preference_provider.dart';

/// Helper to build a [CustomTransitionPage] based on the selected [PageTransitionStyle].
Page<dynamic> buildTransitionPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  PageTransitionStyle? style,
}) {
  final resolvedStyle = style ?? () {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      return container.read(pageTransitionProvider);
    } catch (_) {
      return PageTransitionStyle.fadeSlideUp;
    }
  }();

  switch (resolvedStyle) {
    case PageTransitionStyle.fadeSlideUp:
      return CustomTransitionPage<void>(
        key: state.pageKey,
        child: child,
        transitionDuration: AppMotion.durationMedium,
        reverseTransitionDuration: AppMotion.durationFast,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.0, 0.04),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: AppMotion.curveStandard,
              reverseCurve: Curves.easeInQuad,
            ),
          );

          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: AppMotion.curveStandard,
            reverseCurve: Curves.easeInQuad,
          );

          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
      );

    case PageTransitionStyle.sharedAxis:
      return CustomTransitionPage<void>(
        key: state.pageKey,
        child: child,
        transitionDuration: AppMotion.durationHero,
        reverseTransitionDuration: AppMotion.durationMedium,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final forwardSlide = Tween<Offset>(
            begin: const Offset(0.12, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: AppMotion.curveEmphasized,
              reverseCurve: Curves.easeInCubic,
            ),
          );

          final scaleAnimation = Tween<double>(
            begin: 0.96,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: AppMotion.curveStandard,
            ),
          );

          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );

          return SlideTransition(
            position: forwardSlide,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            ),
          );
        },
      );

    case PageTransitionStyle.cupertinoSlide:
      return CustomTransitionPage<void>(
        key: state.pageKey,
        child: child,
        transitionDuration: AppMotion.durationPage,
        reverseTransitionDuration: AppMotion.durationMedium,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final primarySlide = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: AppMotion.curveStandard,
            ),
          );

          final secondarySlide = Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.3, 0.0),
          ).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: AppMotion.curveStandard,
            ),
          );

          return SlideTransition(
            position: secondarySlide,
            child: SlideTransition(
              position: primarySlide,
              child: child,
            ),
          );
        },
      );
  }
}

/// Dedicated transparent [CustomTransitionPage] for the Media Viewer
/// to ensure Flutter Hero animations transition seamlessly without solid background flashes.
Page<dynamic> buildViewerTransitionPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    opaque: false,
    barrierColor: Colors.transparent,
    transitionDuration: AppMotion.durationHero,
    reverseTransitionDuration: AppMotion.durationDismiss,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        ),
        child: child,
      );
    },
  );
}
