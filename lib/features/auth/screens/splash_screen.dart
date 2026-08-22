import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/telegram/telegram_auth_manager.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _showManualAction = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _verifyAndRoute();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndRoute() async {
    final hasCreds = await AppConstants.hasSavedCredentials();
    if (!mounted) return;

    if (!hasCreds) {
      context.go('/setup');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final wasAuthenticated =
        prefs.getBool('telecloud_is_authenticated') ?? false;

    if (wasAuthenticated) {
      // Returning authenticated user: go straight to timeline without showing login button
      if (mounted) {
        context.go('/timeline');
        return;
      }
    }

    // Wait briefly for TDLib state to initialize
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final authState = ref.read(telegramAuthManagerProvider).state;
    if (authState == AuthState.authenticated) {
      context.go('/timeline');
    } else if (authState == AuthState.waitingForPhoneNumber ||
        authState == AuthState.uninitialized) {
      if (mounted) {
        setState(() => _showManualAction = true);
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
            if (!_showManualAction)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF0A84FF),
                ),
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  final router = GoRouter.of(context);
                  final hasCreds = await AppConstants.hasSavedCredentials();
                  if (!mounted) return;
                  if (!hasCreds) {
                    router.go('/setup');
                  } else {
                    final authState = ref
                        .read(telegramAuthManagerProvider)
                        .state;
                    if (authState == AuthState.authenticated) {
                      router.go('/timeline');
                    } else {
                      router.go('/login');
                    }
                  }
                },
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'Get Started',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
