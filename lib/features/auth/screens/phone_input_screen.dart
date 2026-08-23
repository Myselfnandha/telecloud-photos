import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:tdlib/td_api.dart' as td;
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
                    color: const Color(0xFF30D158).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF30D158)),
                ),
                title: const Text('Try Instant QR Code Scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Scan with your mobile Telegram app — 0 SMS or codes needed.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/login-qr');
                },
              ),
              const Divider(color: Colors.white10),
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
                subtitle: const Text('Set custom API ID/Hash, configure MTProto proxy, or clear session cache.', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
    final authManager = ref.watch(telegramAuthManagerProvider);
    final connState = authManager.connectionState;

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/login-hub');
            }
          },
        ),
        title: const Text('Enter Phone Number'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white70),
            tooltip: 'Telegram API & Proxy',
            onPressed: () => context.push('/setup'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
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
              const SizedBox(height: 16),

              // Network Connection Status Indicator
              _buildConnectionStatePill(connState),
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
                initialCountryCode: 'IN',
                onChanged: (phone) {
                  setState(() {
                    _phoneNumber = phone.completeNumber;
                    _rawController.text = phone.number;
                  });
                },
              ),
              InkWell(
                onTap: () => context.push('/setup'),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.vpn_key_outlined,
                        size: 18,
                        color: Color(0xFF0A84FF),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Configure Custom API ID, Hash & Proxy in Settings',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
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

                            // Safety timeout to prevent permanent loading spinner
                            Future.delayed(const Duration(seconds: 10), () {
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

  Widget _buildConnectionStatePill(td.ConnectionState state) {
    Color dotColor = const Color(0xFF30D158);
    String status = 'Telegram DC Connected';

    if (state is td.ConnectionStateConnecting) {
      dotColor = const Color(0xFFFF9F0A);
      status = 'Connecting to Telegram servers...';
    } else if (state is td.ConnectionStateConnectingToProxy) {
      dotColor = const Color(0xFF0A84FF);
      status = 'Connected via MTProto Proxy';
    } else if (state is td.ConnectionStateWaitingForNetwork) {
      dotColor = const Color(0xFFFF453A);
      status = 'Network unreachable';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showConnectionTroubleshootSheet,
            child: const Text(
              'Troubleshoot',
              style: TextStyle(
                color: Color(0xFF0A84FF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
