import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../core/di/providers.dart';
import '../../../core/telegram/telegram_auth_manager.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final TextEditingController _rawController = TextEditingController();
  String _phoneNumber = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _rawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TelegramAuthManager>(telegramAuthManagerProvider, (prev, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (next.state == AuthState.authenticated) {
          setState(() => _isLoading = false);
          context.go('/timeline');
        } else if (next.state == AuthState.waitingForCode) {
          setState(() => _isLoading = false);
          context.go(
            '/otp',
            extra: _phoneNumber.isNotEmpty ? _phoneNumber : _rawController.text,
          );
        } else if (next.state == AuthState.waitingForPassword) {
          setState(() => _isLoading = false);
          context.go('/password');
        } else if (next.errorMessage != null &&
            next.errorMessage != prev?.errorMessage) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: const Color(0xFFFF453A),
            ),
          );
        }
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        title: const Text('Login with Telegram'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: 'Custom API Settings',
            onPressed: () => context.push('/setup'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Phone Number',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect your Telegram account for unlimited photo cloud storage.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A84FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF0A84FF).withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF0A84FF), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Telegram sends verification codes directly inside your Telegram App messages.',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            IntlPhoneField(
              style: const TextStyle(color: Colors.white),
              dropdownTextStyle: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: Colors.grey.shade400),
                errorText:
                    (_rawController.text.isNotEmpty &&
                        _rawController.text
                                .replaceAll(RegExp(r'\D'), '')
                                .length <
                            10)
                    ? 'Invalid number (minimum 10 digits)'
                    : null,
                errorStyle: const TextStyle(
                  color: Color(0xFFFF453A),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF453A),
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF453A),
                    width: 1,
                  ),
                ),
              ),
              initialCountryCode: 'US',
              onChanged: (phone) {
                setState(() {
                  _phoneNumber = phone.completeNumber;
                  _rawController.text = phone.number;
                });
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  disabledBackgroundColor: const Color(0xFF1C1C1E),
                  disabledForegroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    (_isLoading ||
                        _rawController.text
                                .replaceAll(RegExp(r'\D'), '')
                                .length <
                            10)
                    ? null
                    : () {
                        final targetNumber = _phoneNumber.isNotEmpty
                            ? _phoneNumber
                            : _rawController.text.trim();

                        if (targetNumber.isNotEmpty) {
                          setState(() => _isLoading = true);
                          ref
                              .read(telegramAuthManagerProvider)
                              .sendPhoneNumber(targetNumber);
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
