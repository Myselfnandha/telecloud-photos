import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/providers.dart';
import '../../../core/telegram/telegram_auth_manager.dart';
import '../../../shared/widgets/m3e/m3e_card.dart';
import '../widgets/telegram_web_setup_sheet.dart';

/// Screen 1: "Onboarding & Auth"
/// Material 3 Expressive first-run welcome screen highlighting unlimited E2EE
/// Telegram photo storage, chip group, and single-tap Automated Web Assistant setup.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final Set<String> _selectedChips = {
    'Unlimited Storage',
    'Zero Compression',
    'E2EE Privacy',
  };

  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Listen to Telegram auth state changes to transition straight to OTP
    ref.listen<TelegramAuthManager>(telegramAuthManagerProvider, (prev, next) {
      if (!mounted) return;
      if (next.state == AuthState.waitingForCode) {
        setState(() => _isConnecting = false);
        context.go('/otp', extra: next.lastPhoneNumber ?? '');
      } else if (next.state == AuthState.waitingForPassword) {
        setState(() => _isConnecting = false);
        context.go('/password');
      } else if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: const Color(0xFFFF453A),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.cloud_outlined),
          tooltip: 'TeleCloud',
          onPressed: () {},
        ),
        title: const Text('TeleCloud Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 210dp tall filled card with lock_person icon placeholder on top
              M3ECard(
                height: 210,
                variant: M3ECardVariant.filled,
                placeholderIcon: Icons.lock_person,
                headline: 'Unlimited Private Photo Cloud',
                body:
                    'Original quality backup to your private Telegram Supergroup with zero compression, E2E encryption, and no subscriptions.',
              ),
              const SizedBox(height: 16),

              // Chip Group: "Unlimited Storage", "Zero Compression", "E2EE Privacy"
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChip('Unlimited Storage', scheme),
                    const SizedBox(width: 8),
                    _buildChip('Zero Compression', scheme),
                    const SizedBox(width: 8),
                    _buildChip('E2EE Privacy', scheme),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Hero Primary Button: "Connect Telegram Cloud"
              SizedBox(
                width: 380,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isConnecting ? null : _launchWebAssistant,
                  icon: _isConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.cloud_sync_rounded),
                  label: Text(
                    _isConnecting
                        ? 'Connecting to Telegram Cloud...'
                        : 'Connect Telegram Cloud',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Button: "Enter Credentials Manually"
              SizedBox(
                width: 380,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _isConnecting ? null : _navigateToManualSetup,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text(
                    'Enter Credentials Manually',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Centered caption at 13sp
              Text(
                'Instant setup • Powered by TDLib & MTProto Client',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchWebAssistant() async {
    HapticFeedback.lightImpact();
    final credentials = await TelegramWebSetupSheet.show(context);
    if (credentials != null && credentials.isValid && mounted) {
      if (credentials.phoneNumber != null &&
          credentials.phoneNumber!.isNotEmpty) {
        // Direct single-shot straight to OTP
        setState(() => _isConnecting = true);
        final authManager = ref.read(telegramAuthManagerProvider);
        await authManager.setupAndSendPhone(
          apiId: credentials.apiId!,
          apiHash: credentials.apiHash!,
          phoneNumber: credentials.phoneNumber!,
        );
      } else {
        // Credentials extracted without phone -> go to unified manual screen with prefill
        context.push('/setup', extra: credentials);
      }
    }
  }

  void _navigateToManualSetup() {
    HapticFeedback.lightImpact();
    context.push('/setup');
  }

  Widget _buildChip(String label, ColorScheme scheme) {
    final isSelected = _selectedChips.contains(label);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        HapticFeedback.selectionClick();
        setState(() {
          if (selected) {
            _selectedChips.add(label);
          } else {
            _selectedChips.remove(label);
          }
        });
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About TeleCloud Photos'),
        content: const Text(
          'TeleCloud Photos uses Telegram MTProto and TDLib to back up original quality photos and videos directly to your private Telegram Supergroup. No subscriptions, no storage limits, full privacy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
