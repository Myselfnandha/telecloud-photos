import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../shared/theme/app_radii.dart';

enum GestureHudType { none, seekForward, seekBackward }

class VideoGestureOverlay extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onTap;
  final Widget child;

  const VideoGestureOverlay({
    super.key,
    required this.controller,
    required this.onTap,
    required this.child,
  });

  @override
  State<VideoGestureOverlay> createState() => _VideoGestureOverlayState();
}

class _VideoGestureOverlayState extends State<VideoGestureOverlay>
    with SingleTickerProviderStateMixin {
  GestureHudType _hudType = GestureHudType.none;
  Timer? _hideTimer;
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _showHud(GestureHudType type) {
    _hideTimer?.cancel();
    setState(() => _hudType = type);
    _fadeController.forward();
    _hideTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _fadeController.reverse().then((_) {
          if (mounted) setState(() => _hudType = GestureHudType.none);
        });
      }
    });
  }

  void _handleDoubleTap(Offset position, double screenWidth) {
    final isLeft = position.dx < screenWidth / 2;
    HapticFeedback.lightImpact();

    final currentPos = widget.controller.value.position;
    final duration = widget.controller.value.duration;

    if (isLeft) {
      final target = currentPos - const Duration(seconds: 10);
      widget.controller.seekTo(target < Duration.zero ? Duration.zero : target);
      _showHud(GestureHudType.seekBackward);
    } else {
      final target = currentPos + const Duration(seconds: 10);
      widget.controller.seekTo(target > duration ? duration : target);
      _showHud(GestureHudType.seekForward);
    }
  }

  void _onTapUp(TapUpDetails details, double screenWidth) {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 300 &&
        _lastTapPosition != null &&
        (details.globalPosition - _lastTapPosition!).distance < 40) {
      // Double tap detected
      _lastTapTime = null;
      _lastTapPosition = null;
      _handleDoubleTap(details.globalPosition, screenWidth);
    } else {
      _lastTapTime = now;
      _lastTapPosition = details.globalPosition;
      Future.delayed(const Duration(milliseconds: 310), () {
        if (_lastTapTime != null && now == _lastTapTime) {
          // Single tap confirmed
          widget.onTap();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Base child (Video texture)
        Positioned.fill(child: widget.child),

        // Gesture detector layer
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => _onTapUp(details, size.width),
            child: const SizedBox.expand(),
          ),
        ),

        // HUD Overlay
        if (_hudType != GestureHudType.none)
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: _buildHudContent(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHudContent() {
    switch (_hudType) {
      case GestureHudType.seekForward:
        return _buildSeekHud(isForward: true);
      case GestureHudType.seekBackward:
        return _buildSeekHud(isForward: false);
      case GestureHudType.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSeekHud({required bool isForward}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: AppRadii.borderXL,
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isForward ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 8),
          Text(
            isForward ? '+10s' : '-10s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
