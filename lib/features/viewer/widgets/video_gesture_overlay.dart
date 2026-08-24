import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radii.dart';

enum GestureHudType { none, volume, brightness, seekForward, seekBackward }

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
  double _volume = 1.0;
  double _brightness = 0.5;
  Timer? _hideTimer;
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _volume = widget.controller.value.volume;
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
    _hideTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _fadeController.reverse().then((_) {
          if (mounted) setState(() => _hudType = GestureHudType.none);
        });
      }
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details, double screenWidth, double screenHeight) {
    final isLeft = details.globalPosition.dx < screenWidth / 2;
    final delta = -details.primaryDelta! / (screenHeight * 0.4);

    if (isLeft) {
      // Adjust Brightness
      setState(() {
        _brightness = (_brightness + delta).clamp(0.0, 1.0);
      });
      _showHud(GestureHudType.brightness);
    } else {
      // Adjust Volume
      setState(() {
        _volume = (_volume + delta).clamp(0.0, 1.0);
        widget.controller.setVolume(_volume);
      });
      _showHud(GestureHudType.volume);
    }
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
            onVerticalDragUpdate: (details) =>
                _onVerticalDragUpdate(details, size.width, size.height),
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
      case GestureHudType.volume:
        return _buildLevelHud(
          icon: _volume <= 0
              ? Icons.volume_off_rounded
              : (_volume < 0.5
                  ? Icons.volume_down_rounded
                  : Icons.volume_up_rounded),
          label: 'Volume',
          level: _volume,
          color: AppColors.primaryBlue,
        );
      case GestureHudType.brightness:
        return _buildLevelHud(
          icon: _brightness < 0.3
              ? Icons.brightness_low_rounded
              : (_brightness < 0.7
                  ? Icons.brightness_medium_rounded
                  : Icons.brightness_high_rounded),
          label: 'Brightness',
          level: _brightness,
          color: const Color(0xFFFF9F0A),
        );
      case GestureHudType.seekForward:
        return _buildSeekHud(isForward: true);
      case GestureHudType.seekBackward:
        return _buildSeekHud(isForward: false);
      case GestureHudType.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLevelHud({
    required IconData icon,
    required String label,
    required double level,
    required Color color,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: level,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(level * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
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
