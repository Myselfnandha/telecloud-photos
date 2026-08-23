import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tdlib/td_api.dart' as td;
import '../../../core/di/providers.dart';
import '../../../core/telegram/telegram_auth_manager.dart';

class LoginHubScreen extends ConsumerWidget {
  const LoginHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authManager = ref.watch(telegramAuthManagerProvider);
    final connState = authManager.connectionState;

    ref.listen<TelegramAuthManager>(telegramAuthManagerProvider, (prev, next) {
      if (next.state == AuthState.authenticated) {
        context.go('/timeline');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: const Text(
          'Connect Telegram',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white70),
            tooltip: 'API & Proxy Settings',
            onPressed: () => context.push('/setup'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Brand Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0A84FF).withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sign In to TeleCloud',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Unlimited, lossless photo & video storage powered by Telegram Cloud.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Live Connection Status Pill
              _buildConnectionPill(context, connState),
              const SizedBox(height: 20),

              const Text(
                'CHOOSE LOGIN METHOD',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Card 1: Instant QR Code Scan (Fastest / Zero SMS)
              _buildLoginCard(
                context: context,
                badge: 'RECOMMENDED · INSTANT',
                badgeColor: const Color(0xFF30D158),
                icon: Icons.qr_code_scanner_rounded,
                iconGradient: const [Color(0xFF0A84FF), Color(0xFF5E5CE6)],
                title: 'Instant QR Code Scan',
                subtitle:
                    'Scan with your Telegram app on your phone. No SMS, OTP code, or typing required.',
                onTap: () => context.push('/login-qr'),
              ),
              const SizedBox(height: 14),

              // Card 2: Phone Number & OTP
              _buildLoginCard(
                context: context,
                badge: 'STANDARD',
                badgeColor: const Color(0xFF0A84FF),
                icon: Icons.phone_android_rounded,
                iconGradient: const [Color(0xFF0A84FF), Color(0xFF007AFF)],
                title: 'Phone Number & Code',
                subtitle:
                    'Receive a 5-digit verification code directly inside your Telegram messages.',
                onTap: () => context.push('/login'),
              ),
              const SizedBox(height: 14),

              // Card 3: Telegram Web OAuth
              _buildLoginCard(
                context: context,
                badge: 'WEB AUTH',
                badgeColor: const Color(0xFFFF9F0A),
                icon: Icons.public_rounded,
                iconGradient: const [Color(0xFFFF9F0A), Color(0xFFFF453A)],
                title: 'Telegram Web OAuth',
                subtitle:
                    'Authenticate in browser via official Telegram Web authorization portal.',
                onTap: () => context.push('/login-oauth'),
              ),
              const SizedBox(height: 24),

              // Bottom Settings & Diagnostic Trigger
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  label: const Text(
                    'Configure Custom API ID, Hash & Proxy',
                    style: TextStyle(fontSize: 13),
                  ),
                  onPressed: () => context.push('/setup'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionPill(BuildContext context, td.ConnectionState state) {
    Color dotColor = const Color(0xFF30D158);
    String statusText = 'Connected to Telegram DC';

    if (state is td.ConnectionStateConnecting) {
      dotColor = const Color(0xFFFF9F0A);
      statusText = 'Connecting to Telegram servers...';
    } else if (state is td.ConnectionStateConnectingToProxy) {
      dotColor = const Color(0xFF0A84FF);
      statusText = 'Connecting via MTProto proxy...';
    } else if (state is td.ConnectionStateWaitingForNetwork) {
      dotColor = const Color(0xFFFF453A);
      statusText = 'Waiting for network connection...';
    } else if (state is td.ConnectionStateUpdating) {
      dotColor = const Color(0xFF0A84FF);
      statusText = 'Syncing Telegram data...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              statusText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/setup'),
            child: const Text(
              'Settings',
              style: TextStyle(
                color: Color(0xFF0A84FF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard({
    required BuildContext context,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFF0A84FF).withValues(alpha: 0.15),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: iconGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: badgeColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white30,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
