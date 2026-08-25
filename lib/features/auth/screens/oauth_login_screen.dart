import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/providers.dart';
import '../../../core/telegram/telegram_auth_manager.dart';

class OAuthLoginScreen extends ConsumerStatefulWidget {
  const OAuthLoginScreen({super.key});

  @override
  ConsumerState<OAuthLoginScreen> createState() => _OAuthLoginScreenState();
}

class _OAuthLoginScreenState extends ConsumerState<OAuthLoginScreen> {
  bool _isAwaitingConfirmation = false;

  Future<void> _launchTelegramOAuth() async {
    setState(() => _isAwaitingConfirmation = true);
    final uri = Uri.parse('https://oauth.telegram.org/auth');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
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
          'Telegram Web OAuth',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9F0A).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF9F0A).withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.public_rounded,
                  color: Color(0xFFFF9F0A),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Telegram Web Authorization',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Authenticate through official Telegram Web gateway with 1-tap confirmation popup.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Step by Step
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildStepRow(
                      icon: Icons.open_in_browser_rounded,
                      title: '1. Launch Web Portal',
                      subtitle:
                          'Tap the button below to open Telegram OAuth authorization.',
                    ),
                    const Divider(color: Colors.white10, height: 28),
                    _buildStepRow(
                      icon: Icons.check_circle_outline_rounded,
                      title: '2. Accept Service Message',
                      subtitle:
                          'Telegram will send a notification message asking for your confirmation.',
                    ),
                    const Divider(color: Colors.white10, height: 28),
                    _buildStepRow(
                      icon: Icons.auto_awesome_rounded,
                      title: '3. Return & Enjoy TeleCloud',
                      subtitle:
                          'Once confirmed, return to TeleCloud Photos to start cloud syncing.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.launch_rounded, color: Colors.white),
                  label: Text(
                    _isAwaitingConfirmation
                        ? 'Reopen Telegram OAuth'
                        : 'Launch Telegram OAuth',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _launchTelegramOAuth,
                ),
              ),
              const SizedBox(height: 16),

              // Fallback to QR or Phone
              TextButton(
                onPressed: () => context.push('/login-qr'),
                child: const Text(
                  'Prefer Instant QR Code Scan instead?',
                  style: TextStyle(
                    color: Color(0xFF0A84FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF0A84FF).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF0A84FF), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
