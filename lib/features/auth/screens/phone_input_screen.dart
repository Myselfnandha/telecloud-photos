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

  void _showConnectionTroubleshootSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.wifi_tethering_error_rounded, color: Color(0xFFFF9F0A), size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Connection Diagnostics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Telegram servers are taking longer than usual to respond. Choose a solution below:',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Color(0xFF0A84FF)),
                ),
                title: const Text('API Credentials & Proxy Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Set custom API ID/Hash, launch In-App Web Assistant, or clear TDLib cache.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/setup');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TelegramAuthManager>(telegramAuthManagerProvider, (prev, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (next.state == AuthState.authenticated) {
          setState(() => _isLoading = false);
          context.go('/quick-settings');
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
          final errorMsg = next.errorMessage!;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          final isApiError = errorMsg.toUpperCase().contains('API_ID') ||
              errorMsg.toUpperCase().contains('API_HASH') ||
              errorMsg.toUpperCase().contains('SETTDLIBPARAMETERS');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isApiError
                    ? 'Invalid Telegram API credentials. Please configure your custom API ID & Hash from my.telegram.org.'
                    : errorMsg,
              ),
              backgroundColor: const Color(0xFFFF453A),
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: isApiError ? 'Setup API' : 'Diagnostics',
                textColor: Colors.white,
                onPressed: () {
                  if (isApiError) {
                    context.push('/setup');
                  } else {
                    _showConnectionTroubleshootSheet();
                  }
                },
              ),
            ),
          );
        }
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/setup');
            }
          },
        ),
        title: const Text(
          'Step 2 of 3 · Phone Login',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Progress Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF30D158).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF30D158).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_android_rounded, color: Color(0xFF30D158), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'STEP 2 OF 3 · PHONE AUTHENTICATION',
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

              const Text(
                'Enter Phone Number',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Connect your Telegram account for unlimited photo cloud storage.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
              Builder(
                builder: (context) {
                  final rawDigits = _rawController.text.replaceAll(RegExp(r'\D'), '');
                  final hasEnteredEnoughDigits = rawDigits.length >= 10;
                  final isNumberTooLong = rawDigits.length > 15;
                  final String? errorMsg = hasEnteredEnoughDigits && isNumberTooLong
                      ? 'Phone number is too long (max 15 digits)'
                      : null;

                  return IntlPhoneField(
                    style: const TextStyle(color: Colors.white),
                    dropdownTextStyle: const TextStyle(color: Colors.white),
                    disableLengthCheck: true,
                    autovalidateMode: AutovalidateMode.disabled,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(color: Colors.grey.shade400),
                      suffixIcon: hasEnteredEnoughDigits && !isNumberTooLong
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF30D158),
                              size: 20,
                            )
                          : null,
                      errorText: errorMsg,
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
                    initialCountryCode: 'IN',
                    onChanged: (phone) {
                      setState(() {
                        _phoneNumber = phone.completeNumber;
                        _rawController.text = phone.number;
                      });
                    },
                  );
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
                              10 ||
                          _rawController.text
                                  .replaceAll(RegExp(r'\D'), '')
                                  .length >
                              15)
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

                            // Safety timeout to prevent permanent loading spinner
                            Future.delayed(const Duration(seconds: 25), () {
                              if (mounted && _isLoading) {
                                setState(() => _isLoading = false);
                                _showConnectionTroubleshootSheet();
                              }
                            });
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
      ),
    );
  }

}
