import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/providers.dart';
import '../../../core/telegram/telegram_auth_manager.dart';

class QrLoginScreen extends ConsumerStatefulWidget {
  const QrLoginScreen({super.key});

  @override
  ConsumerState<QrLoginScreen> createState() => _QrLoginScreenState();
}

class _QrLoginScreenState extends ConsumerState<QrLoginScreen> {
  Timer? _refreshTimer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestQrCode();
    });
    _startTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _refreshTimer?.cancel();
    _secondsRemaining = 60;
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _requestQrCode();
        }
      });
    });
  }

  void _requestQrCode() {
    _secondsRemaining = 60;
    ref.read(telegramAuthManagerProvider).requestQrCodeAuth();
  }

  Future<void> _openTelegramLink(String link) async {
    final uri = Uri.parse(link);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authManager = ref.watch(telegramAuthManagerProvider);
    final qrLink = authManager.qrCodeLink;

    ref.listen<TelegramAuthManager>(telegramAuthManagerProvider, (prev, next) {
      if (next.state == AuthState.authenticated && mounted) {
        context.go('/timeline');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Instant QR Login',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0A84FF)),
            tooltip: 'Refresh QR Code',
            onPressed: _requestQrCode,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Scan QR Code with Telegram',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Zero typing required. Authenticate directly from your mobile Telegram app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
              const SizedBox(height: 28),

              // QR Code Card Frame
              Container(
                width: 280,
                height: 280,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A84FF).withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: qrLink != null && qrLink.isNotEmpty
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          QrImageView(
                            data: qrLink,
                            version: QrVersions.auto,
                            size: 244.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF000000),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF000000),
                            ),
                          ),
                          // Telegram Logo Overlay at center of QR Code
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0088CC),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF0A84FF),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Generating dynamic QR code...',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // Expiry & Countdown Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: _secondsRemaining < 10
                          ? const Color(0xFFFF453A)
                          : const Color(0xFF30D158),
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Refreshes in ${_secondsRemaining}s',
                      style: TextStyle(
                        color: _secondsRemaining < 10
                            ? const Color(0xFFFF453A)
                            : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Step by Step Instructions Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to Scan & Link:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildStepRow(
                      number: '1',
                      title: 'Open Telegram on your phone',
                      subtitle: 'Make sure you are logged into your Telegram account.',
                    ),
                    const SizedBox(height: 12),
                    _buildStepRow(
                      number: '2',
                      title: 'Go to Settings → Devices → Link Desktop Device',
                      subtitle: 'Tap the button to open your camera scanner.',
                    ),
                    const SizedBox(height: 12),
                    _buildStepRow(
                      number: '3',
                      title: 'Point camera at this screen',
                      subtitle: 'You will be logged into TeleCloud Photos immediately.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Open Telegram App Deep Link Button
              if (qrLink != null && qrLink.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0088CC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      color: Color(0xFF0088CC),
                      size: 18,
                    ),
                    label: const Text(
                      'Open in Telegram App directly',
                      style: TextStyle(
                        color: Color(0xFF0088CC),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () => _openTelegramLink(qrLink),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF0A84FF).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF0A84FF)),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF0A84FF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
