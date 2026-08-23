import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/di/providers.dart';
import '../../../core/telegram/telegram_auth_manager.dart';
import '../../../core/utils/telecloud_logger.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyAndRoute();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateSafe(String path) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    context.go(path);
  }

  Future<void> _verifyAndRoute() async {
    // Minimum 1.2s delay for smooth premium logo pulsing branding
    final minSplashTimer = Future.delayed(const Duration(milliseconds: 1200));

    // Hard safety timeout guarantee (2.5s maximum so splash screen NEVER freezes)
    Timer(const Duration(milliseconds: 2500), () {
      if (!_hasNavigated && mounted) {
        _navigateSafe('/login-hub');
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final wasAuthenticated =
          prefs.getBool('telecloud_is_authenticated') ?? false;

      await minSplashTimer;
      if (!mounted || _hasNavigated) return;

      if (wasAuthenticated) {
        // Returning logged in user: go directly to timeline
        _navigateSafe('/timeline');
        return;
      }

      // Check TDLib auth state
      final authState = ref.read(telegramAuthManagerProvider).state;
      if (authState == AuthState.authenticated) {
        _navigateSafe('/timeline');
      } else {
        // First-time or logged-out user: Show Login Hub with all methods
        _navigateSafe('/login-hub');
      }
    } catch (e) {
      TeleCloudLogger.log('Splash', 'Splash routing error: $e');
      await minSplashTimer;
      if (mounted && !_hasNavigated) {
        _navigateSafe('/login-hub');
      }
    }
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A84FF).withValues(
                          alpha: 0.2 + (_animController.value * 0.25),
                        ),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            const Text(
              'TeleCloud Photos',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlimited Cloud Storage on Telegram',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF0A84FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
