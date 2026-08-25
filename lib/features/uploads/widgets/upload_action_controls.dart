import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/sync/upload_telemetry.dart';
import '../../../../shared/theme/app_colors.dart';

class UploadActionControls extends StatelessWidget {
  final UploadTelemetryState telemetry;
  final VoidCallback onStartUpload;
  final VoidCallback onStopUpload;
  final VoidCallback onCancelAndClearQueue;

  const UploadActionControls({
    super.key,
    required this.telemetry,
    required this.onStartUpload,
    required this.onStopUpload,
    required this.onCancelAndClearQueue,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (telemetry.isUploading)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isLight ? AppColors.lightBackground : AppColors.darkCard,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.stop_rounded,
                color: AppColors.errorRed,
                size: 20,
              ),
              label: const Text(
                'Stop Upload',
                style: TextStyle(
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              onPressed: () {
                onStopUpload();
                final messenger = ScaffoldMessenger.of(context);
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Upload stopped.'),
                    backgroundColor: AppColors.card(context),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          )
        else if (telemetry.pendingCount > 0)
          Column(
            children: [
              _AnimatedStartUploadButton(
                pendingCount: telemetry.pendingCount,
                onPressed: onStartUpload,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLight
                        ? AppColors.lightBackground
                        : AppColors.darkCard,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.stop_rounded,
                    color: AppColors.errorRed,
                    size: 20,
                  ),
                  label: const Text(
                    'Stop Upload',
                    style: TextStyle(
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () {
                    onCancelAndClearQueue();
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Upload stopped and queue cleared.',
                        ),
                        backgroundColor: AppColors.card(context),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.successGreen.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.successGreen,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'All Photos & Videos Synced',
                  style: TextStyle(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

        // Activity Logs
        if (telemetry.activityLogs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border(context),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: AppColors.primaryBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Self-Healing & Sync Activity',
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...telemetry.activityLogs.take(3).map(
                      (log) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          log,
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AnimatedStartUploadButton extends StatefulWidget {
  final int pendingCount;
  final VoidCallback onPressed;

  const _AnimatedStartUploadButton({
    required this.pendingCount,
    required this.onPressed,
  });

  @override
  State<_AnimatedStartUploadButton> createState() =>
      _AnimatedStartUploadButtonState();
}

class _AnimatedStartUploadButtonState extends State<_AnimatedStartUploadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [AppColors.primaryBlue, AppColors.primaryBlueDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTapDown: (_) => _animController.forward(),
            onTapUp: (_) => _animController.reverse(),
            onTapCancel: () => _animController.reverse(),
            onTap: () {
              HapticFeedback.heavyImpact();
              widget.onPressed();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Resume Upload (${widget.pendingCount})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
