import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/utils/telegram_credential_parser.dart';
import '../widgets/telegram_web_setup_sheet.dart';

class ApiSetupScreen extends ConsumerStatefulWidget {
  const ApiSetupScreen({super.key});

  @override
  ConsumerState<ApiSetupScreen> createState() => _ApiSetupScreenState();
}

class _ApiSetupScreenState extends ConsumerState<ApiSetupScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _apiIdController = TextEditingController();
  final _apiHashController = TextEditingController();
  bool _obscureHash = true;
  bool _isSaving = false;

  ParsedCredentials? _detectedClipboardCredentials;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (AppConstants.telegramApiId > 0) {
      _apiIdController.text = AppConstants.telegramApiId.toString();
    }
    if (AppConstants.telegramApiHash.isNotEmpty) {
      _apiHashController.text = AppConstants.telegramApiHash;
    }

    _checkClipboardForCredentials();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboardForCredentials();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _apiIdController.dispose();
    _apiHashController.dispose();
    super.dispose();
  }

  Future<void> _checkClipboardForCredentials() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.trim().isNotEmpty) {
        final parsed = TelegramCredentialParser.parse(data.text!);
        if (parsed.isValid && mounted) {
          setState(() {
            _detectedClipboardCredentials = parsed;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _applyAndSaveCredentials(int apiId, String apiHash) async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    await AppConstants.saveCredentials(apiId, apiHash);

    if (!mounted) return;

    final authManager = ref.read(telegramAuthManagerProvider);
    authManager.clearError();
    await authManager.clearSessionAndRestart();

    messenger.showSnackBar(
      const SnackBar(
        content: Text('🎉 Telegram API credentials configured & client restarted!'),
        backgroundColor: Color(0xFF30D158),
      ),
    );

    router.go('/login');
  }

  Future<void> _pasteBothFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty')),
        );
      }
      return;
    }

    final parsed = TelegramCredentialParser.parse(data.text!);
    if (parsed.apiId != null) {
      _apiIdController.text = parsed.apiId.toString();
    }
    if (parsed.apiHash != null) {
      _apiHashController.text = parsed.apiHash!;
    }

    if (parsed.isValid && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pasted API ID: ${parsed.apiId} and Hash!'),
          backgroundColor: const Color(0xFF30D158),
        ),
      );
    } else if (parsed.hasAny && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pasted partial credential from clipboard'),
          backgroundColor: Color(0xFFFF9F0A),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Telegram API credentials found in clipboard')),
      );
    }
  }

  Future<void> _launchAutomatedWebSetup() async {
    final credentials = await TelegramWebSetupSheet.show(context);
    if (credentials != null && credentials.isValid && mounted) {
      _apiIdController.text = credentials.apiId.toString();
      _apiHashController.text = credentials.apiHash!;
      await _applyAndSaveCredentials(credentials.apiId!, credentials.apiHash!);
    }
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
    final apiId = int.parse(_apiIdController.text.trim());
    final apiHash = _apiHashController.text.trim();
    await _applyAndSaveCredentials(apiId, apiHash);
  }

  Future<void> _useDefaultCredentials() async {
    await _applyAndSaveCredentials(
      2496,
      '8da85b0d5b1652522bc46057082da478',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        title: const Text(
          'API Credentials & Proxy',
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
                // Proactive Detected Clipboard Banner
                if (_detectedClipboardCredentials != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A84FF), Color(0xFF0051A8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0A84FF).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Credentials Detected in Clipboard!',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'App ID: ${_detectedClipboardCredentials!.apiId}',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0051A8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            _apiIdController.text = _detectedClipboardCredentials!.apiId.toString();
                            _apiHashController.text = _detectedClipboardCredentials!.apiHash!;
                            _applyAndSaveCredentials(
                              _detectedClipboardCredentials!.apiId!,
                              _detectedClipboardCredentials!.apiHash!,
                            );
                          },
                          child: const Text('1-Tap Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Automated Web Setup Primary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.flash_on_rounded, color: Color(0xFF38BDF8), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Automated In-App Setup',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  'Zero typing: auto-creates app & auto-closes browser',
                                  style: TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                          label: const Text(
                            'Launch In-App Web Assistant',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: _isSaving ? null : _launchAutomatedWebSetup,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 1-Tap Paste Both Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0A84FF), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: const Color(0xFF0A84FF).withValues(alpha: 0.08),
                    ),
                    icon: const Icon(Icons.content_paste_go_rounded, color: Color(0xFF0A84FF), size: 20),
                    label: const Text(
                      '📋 1-Tap Auto-Paste from Clipboard',
                      style: TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: _pasteBothFromClipboard,
                  ),
                ),
                const SizedBox(height: 24),

                // Manual Input Header
                const Text(
                  'MANUAL CREDENTIALS',
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                ),
                const SizedBox(height: 12),

                // API ID Field
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('API ID (App ID)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 4)),
                      icon: const Icon(Icons.content_paste_rounded, size: 14, color: Color(0xFF0A84FF)),
                      label: const Text('Paste ID', style: TextStyle(color: Color(0xFF0A84FF), fontSize: 12)),
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) {
                          final parsed = TelegramCredentialParser.parse(data!.text!);
                          _apiIdController.text = (parsed.apiId ?? int.tryParse(data.text!.trim()) ?? '').toString();
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
                    hintText: 'e.g. 28910420',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color(0xFF1C1C1E),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0A84FF), width: 1.5),
                    ),
                    prefixIcon: const Icon(Icons.tag, color: Colors.grey),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your Telegram API ID';
                    if (int.tryParse(val.trim()) == null) return 'API ID must be a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // API HASH Field
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('API HASH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 4)),
                      icon: const Icon(Icons.content_paste_rounded, size: 14, color: Color(0xFF0A84FF)),
                      label: const Text('Paste Hash', style: TextStyle(color: Color(0xFF0A84FF), fontSize: 12)),
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) {
                          final parsed = TelegramCredentialParser.parse(data!.text!);
                          _apiHashController.text = parsed.apiHash ?? data.text!.trim();
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
                    hintText: 'e.g. 8da85b0d5b1652522bc46057082da478',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color(0xFF1C1C1E),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0A84FF), width: 1.5),
                    ),
                    prefixIcon: const Icon(Icons.key, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureHash ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscureHash = !_obscureHash),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your Telegram API Hash';
                    if (val.trim().length < 16) return 'API Hash is too short (usually 32 hex characters)';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Save & Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A84FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSaving ? null : _saveAndContinue,
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'Save & Apply Credentials',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Reset to Defaults Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade800),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                    label: const Text(
                      'Reset to Official Defaults (2496)',
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _isSaving ? null : _useDefaultCredentials,
                  ),
                ),
                const SizedBox(height: 32),

                // Diagnostics Section
                const Text(
                  'TROUBLESHOOTING & MAINTENANCE',
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
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
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                const SizedBox(height: 16),

                // External Link to my.telegram.org
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white54),
                    label: const Text('Open my.telegram.org in External Browser', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    onPressed: _openTelegramPortal,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
