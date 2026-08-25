import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/providers.dart';
import '../../../core/telegram/telegram_auth_manager.dart';

class AuthMethodScreen extends ConsumerStatefulWidget {
  const AuthMethodScreen({super.key});

  @override
  ConsumerState<AuthMethodScreen> createState() => _AuthMethodScreenState();
}

class _AuthMethodScreenState extends ConsumerState<AuthMethodScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen<TelegramAuthManager>(telegramAuthManagerProvider, (prev, next) {
      if (next.state == AuthState.authenticated && mounted) {
        context.go('/quick-settings');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/setup'),
        ),
        title: const Text(
          'Step 2 of 3 · Authentication',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Progress Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF30D158).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF30D158).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_person_rounded,
                        color: Color(0xFF30D158), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'STEP 2 OF 3 · AUTHENTICATION METHOD',
                      style: TextStyle(
                        color: Color(0xFF30D158),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Title & Subtitle
              const Text(
                'Choose Login Method',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign into your Telegram account to access your unlimited cloud storage.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // CARD 1: Instant QR & Telegram App Login (1-Click Device Link)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/login-qr'),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color:
                              const Color(0xFFFF9F0A).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9F0A), Color(0xFFFF6D00)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Instant QR & App Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF9F0A)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'INSTANT',
                                      style: TextStyle(
                                        color: Color(0xFFFF9F0A),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Scan QR code or link device directly from your Telegram App.',
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13,
                                    height: 1.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white38, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // CARD 2: Phone Number & Code (Standard)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/login'),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color:
                              const Color(0xFF0A84FF).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A84FF), Color(0xFF0051A8)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.phone_android_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Phone Number & Code',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A84FF)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'STANDARD',
                                      style: TextStyle(
                                        color: Color(0xFF0A84FF),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Receive verification code directly inside your Telegram messages or SMS.',
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13,
                                    height: 1.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white38, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Helper Privacy Note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: Color(0xFF30D158), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your session is end-to-end secured directly with Telegram servers. TeleCloud never sees your password or chat messages.',
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                            height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
