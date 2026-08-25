import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radii.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import 'video_gesture_overlay.dart';

class ViewerVideoPlayer extends StatelessWidget {
  final VideoPlayerController? controller;
  final bool isInitialized;
  final bool isLoadingStream;
  final bool showControls;
  final int rotationQuarterTurns;
  final double playbackSpeed;
  final bool isMuted;
  final bool isLooping;
  final bool showCenterPlayIndicator;
  final VoidCallback onTap;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleLoop;
  final VoidCallback onCycleSpeed;
  final void Function(Duration delta) onSeekRelative;
  final String? fallbackThumbnailPath;

  const ViewerVideoPlayer({
    super.key,
    required this.controller,
    required this.isInitialized,
    required this.isLoadingStream,
    required this.showControls,
    required this.rotationQuarterTurns,
    required this.playbackSpeed,
    required this.isMuted,
    required this.isLooping,
    required this.showCenterPlayIndicator,
    required this.onTap,
    required this.onTogglePlayPause,
    required this.onToggleMute,
    required this.onToggleLoop,
    required this.onCycleSpeed,
    required this.onSeekRelative,
    this.fallbackThumbnailPath,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final hasThumb = fallbackThumbnailPath != null &&
        fallbackThumbnailPath!.isNotEmpty &&
        File(fallbackThumbnailPath!).existsSync();

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isInitialized && controller != null)
            VideoGestureOverlay(
              controller: controller!,
              onTap: onTap,
              child: Center(
                child: RotatedBox(
                  quarterTurns: rotationQuarterTurns,
                  child: AspectRatio(
                    aspectRatio: controller!.value.aspectRatio,
                    child: VideoPlayer(controller!),
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: onTap,
              child: Center(
                child: RotatedBox(
                  quarterTurns: rotationQuarterTurns,
                  child: hasThumb
                      ? Image.file(
                          File(fallbackThumbnailPath!),
                          fit: BoxFit.contain,
                        )
                      : const ShimmerLoading(
                          width: double.infinity,
                          height: 380,
                        ),
                ),
              ),
            ),

          // Loading Spinner
          if (isLoadingStream || (!isInitialized))
            const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),

          // Play Indicator Overlay
          if (showCenterPlayIndicator && controller != null)
            AnimatedOpacity(
              opacity: showCenterPlayIndicator ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  controller!.value.isPlaying
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),

          // Bottom Floating Apple Player Controls
          if (isInitialized && controller != null)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 240),
                child: IgnorePointer(
                  ignoring: !showControls,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: AppRadii.borderXL,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Scrubber Slider
                        ValueListenableBuilder(
                          valueListenable: controller!,
                          builder: (context, VideoPlayerValue val, _) {
                            final pos = val.position;
                            final dur = val.duration;
                            final posMs = pos.inMilliseconds.toDouble();
                            final durMs = dur.inMilliseconds > 0
                                ? dur.inMilliseconds.toDouble()
                                : 1.0;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3.5,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14,
                                    ),
                                    activeTrackColor: AppColors.primaryBlue,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    value: posMs.clamp(0.0, durMs),
                                    min: 0.0,
                                    max: durMs,
                                    onChanged: (newPos) {
                                      controller!.seekTo(
                                        Duration(
                                          milliseconds: newPos.toInt(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(pos),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '-${_formatDuration(dur > pos ? dur - pos : Duration.zero)}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 2),

                        // Controls Bar: 10s back, Play/Pause, 10s fwd, Mute, Loop, Speed
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 10s Backward
                            IconButton(
                              icon: const Icon(
                                Icons.replay_10_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () =>
                                  onSeekRelative(const Duration(seconds: -10)),
                            ),

                            // Play / Pause
                            IconButton(
                              icon: Icon(
                                controller!.value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                              onPressed: onTogglePlayPause,
                            ),

                            // 10s Forward
                            IconButton(
                              icon: const Icon(
                                Icons.forward_10_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () =>
                                  onSeekRelative(const Duration(seconds: 10)),
                            ),

                            // Mute Toggle
                            IconButton(
                              icon: Icon(
                                isMuted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                color: isMuted
                                    ? AppColors.systemRed
                                    : Colors.white,
                                size: 22,
                              ),
                              onPressed: onToggleMute,
                            ),

                            // Loop Toggle
                            IconButton(
                              icon: Icon(
                                Icons.repeat_rounded,
                                color: isLooping
                                    ? AppColors.primaryBlue
                                    : Colors.white38,
                                size: 22,
                              ),
                              onPressed: onToggleLoop,
                            ),

                            // Speed Chip
                            TextButton(
                              onPressed: onCycleSpeed,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                backgroundColor: AppColors.primaryBlue
                                    .withValues(alpha: 0.15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                '${playbackSpeed}x',
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
