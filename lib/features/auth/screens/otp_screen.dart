import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../core/di/providers.dart';
import '../../../core/telegram/telegram_auth_manager.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _resendCode({bool viaSms = false}) {
    if (viaSms) {
      ref.read(telegramAuthManagerProvider).resendAuthenticationCode();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📱 Requested verification code via SMS...'),
          backgroundColor: Color(0xFF0A84FF),
        ),
      );
    } else {
      ref.read(telegramAuthManagerProvider).sendPhoneNumber(widget.phoneNumber);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💬 Verification code re-sent to Telegram chat'),
          backgroundColor: Color(0xFF0A84FF),
        ),
      );
    }
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TelegramAuthManager>(telegramAuthManagerProvider, (prev, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (next.state == AuthState.authenticated) {
          setState(() => _isLoading = false);
          context.go('/timeline');
        } else if (next.state == AuthState.waitingForPassword) {
          setState(() => _isLoading = false);
          context.go('/password');
        } else if (next.errorMessage != null) {
          setState(() {
            _isLoading = false;
            _pinController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: const Color(0xFFFF453A),
            ),
          );
        }
      });
    });

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0A84FF), width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        title: const Text('Verify Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Verification Code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sent to ${widget.phoneNumber}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Info card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.mark_chat_unread_outlined,
                      color: Color(0xFF0A84FF),
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Check your Telegram app messages for the 5-digit login code from official "Telegram".',
                        style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // PIN Input
              Center(
                child: Pinput(
                  length: 5,
                  controller: _pinController,
                  focusNode: _focusNode,
                  autofocus: true,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  onCompleted: (pin) {
                    setState(() => _isLoading = true);
                    ref.read(telegramAuthManagerProvider).sendCode(pin);
                  },
                ),
              ),

              if (_isLoading) ...[
                const SizedBox(height: 28),
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
                ),
              ],

              const Spacer(),

              // Resend options & Countdown
              Center(
                child: Column(
                  children: [
                    if (_countdown > 0)
                      Text(
                        'Resend code in ${_countdown}s',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.telegram, size: 18, color: Color(0xFF0A84FF)),
                            label: const Text(
                              'Resend Code',
                              style: TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _resendCode(viaSms: false),
                          ),
                          const SizedBox(width: 12),
                          TextButton.icon(
                            icon: const Icon(Icons.sms_rounded, size: 18, color: Color(0xFF30D158)),
                            label: const Text(
                              'Send via SMS',
                              style: TextStyle(color: Color(0xFF30D158), fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _resendCode(viaSms: true),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Change Phone Number',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
