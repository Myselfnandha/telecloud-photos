import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/m3e/m3e_card.dart';

/// Screen 1: "Onboarding & Auth"
/// Material 3 Expressive first-run welcome screen highlighting unlimited E2EE
/// Telegram photo storage, chip group, phone input, and instant setup triggers.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final Set<String> _selectedChips = {
    'Unlimited Storage',
    'Zero Compression',
    'E2EE Privacy',
  };

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _navigateToTimeline() {
    HapticFeedback.lightImpact();
    // Navigate with fade to Photos Timeline
    context.go('/timeline');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
              const SizedBox(height: 20),

              // Outlined text field: Telegram Phone Number
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'Telegram Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  helperText: 'Include country code (e.g. +1 555-0199)',
                  hintText: '+1 555-0199',
                ),
              ),
              const SizedBox(height: 24),

              // Filled Button (380dp wide): "Continue with Telegram Code"
              SizedBox(
                width: 380,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _navigateToTimeline,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue with Telegram Code'),
                ),
              ),
              const SizedBox(height: 12),

              // Outlined Button (380dp wide): "Enter Telegram API ID & Hash Key"
              SizedBox(
                width: 380,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _navigateToTimeline,
                  icon: const Icon(Icons.edit_square),
                  label: const Text('Enter Telegram API ID & Hash Key'),
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
}
