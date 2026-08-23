import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';

class ApiSetupScreen extends ConsumerStatefulWidget {
  const ApiSetupScreen({super.key});

  @override
  ConsumerState<ApiSetupScreen> createState() => _ApiSetupScreenState();
}

class _ApiSetupScreenState extends ConsumerState<ApiSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiIdController = TextEditingController();
  final _apiHashController = TextEditingController();
  bool _obscureHash = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (AppConstants.telegramApiId > 0) {
      _apiIdController.text = AppConstants.telegramApiId.toString();
    }
    if (AppConstants.telegramApiHash.isNotEmpty) {
      _apiHashController.text = AppConstants.telegramApiHash;
    }
  }

  @override
  void dispose() {
    _apiIdController.dispose();
    _apiHashController.dispose();
    super.dispose();
  }

  Future<void> _openTelegramPortal() async {
    final uri = Uri.parse('https://my.telegram.org');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final apiId = int.parse(_apiIdController.text.trim());
    final apiHash = _apiHashController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    await AppConstants.saveCredentials(apiId, apiHash);

    if (!mounted) return;

    final authManager = ref.read(telegramAuthManagerProvider);
    authManager.clearError();
    await authManager.restartClient();

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Telegram API credentials saved successfully!'),
        backgroundColor: Color(0xFF30D158),
      ),
    );

    router.go('/login');
  }

  Future<void> _useDefaultCredentials() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    await AppConstants.saveCredentials(
      2496,
      '8da85b0d5b1652522bc46057082da478',
    );

    if (!mounted) return;

    final authManager = ref.read(telegramAuthManagerProvider);
    authManager.clearError();
    await authManager.restartClient();

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Using official Telegram API credentials.'),
        backgroundColor: Color(0xFF30D158),
      ),
    );

    router.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: const Text(
          'Step 1 · Telegram API Setup',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Indicator Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0A84FF).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.vpn_key_rounded, color: Color(0xFF0A84FF), size: 14),
                      SizedBox(width: 6),
                      Text(
                        'STEP 1 OF 2 · API CREDENTIALS',
                        style: TextStyle(
                          color: Color(0xFF0A84FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Header
                const Text(
                  'Configure Telegram API',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter your Telegram App credentials to connect your private cloud storage.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // Interactive Instructions Guide Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF0A84FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.help_outline,
                            color: Color(0xFF0A84FF),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'How to get API ID & Hash',
                            style: TextStyle(
                              color: Color(0xFF0A84FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '1. Open my.telegram.org & log in with your phone.\n'
                        '2. Go to "API development tools".\n'
                        '3. Create an application & copy your API ID and API Hash.',
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0A84FF)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.open_in_browser,
                            color: Color(0xFF0A84FF),
                            size: 18,
                          ),
                          label: const Text(
                            'Open my.telegram.org',
                            style: TextStyle(
                              color: Color(0xFF0A84FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _openTelegramPortal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // API ID Input Field
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'API ID (App ID)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      icon: const Icon(
                        Icons.content_paste_rounded,
                        size: 14,
                        color: Color(0xFF0A84FF),
                      ),
                      label: const Text(
                        'Paste',
                        style: TextStyle(
                          color: Color(0xFF0A84FF),
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () async {
                        final data = await Clipboard.getData(
                          Clipboard.kTextPlain,
                        );
                        if (data?.text != null) {
                          _apiIdController.text = data!.text!.trim();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _apiIdController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'e.g. 2040',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color(0xFF1C1C1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF0A84FF),
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.tag, color: Colors.grey),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your Telegram API ID';
                    }
                    if (int.tryParse(val.trim()) == null) {
                      return 'API ID must be a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // API HASH Input Field
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'API HASH',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      icon: const Icon(
                        Icons.content_paste_rounded,
                        size: 14,
                        color: Color(0xFF0A84FF),
                      ),
                      label: const Text(
                        'Paste',
                        style: TextStyle(
                          color: Color(0xFF0A84FF),
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () async {
                        final data = await Clipboard.getData(
                          Clipboard.kTextPlain,
                        );
                        if (data?.text != null) {
                          _apiHashController.text = data!.text!.trim();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _apiHashController,
                  obscureText: _obscureHash,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'e.g. b18441a1b608e3cdeec510d3f026fb29',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color(0xFF1C1C1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF0A84FF),
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.key, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureHash ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscureHash = !_obscureHash),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your Telegram API Hash';
                    }
                    if (val.trim().length < 16) {
                      return 'API Hash is too short (usually 32 hex characters)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                // Save & Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A84FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveAndContinue,
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save & Apply Credentials',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Default Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade800),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.flash_on_rounded, color: Colors.white70, size: 18),
                    label: const Text(
                      'Reset to Official Defaults (2496)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _isSaving ? null : _useDefaultCredentials,
                  ),
                ),
                const SizedBox(height: 32),

                // Diagnostics & Maintenance Section
                const Text(
                  'TROUBLESHOOTING & MAINTENANCE',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Clear TDLib Session Database',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fixes locked session binlog files and connection timeout freezes caused by stale cache.',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFF453A)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFFF453A), size: 18),
                          label: const Text(
                            'Wipe Cache & Restart Client',
                            style: TextStyle(color: Color(0xFFFF453A), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await ref.read(telegramAuthManagerProvider).clearSessionAndRestart();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('TDLib session cache cleared! Restarted cleanly.'),
                                backgroundColor: Color(0xFF30D158),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
