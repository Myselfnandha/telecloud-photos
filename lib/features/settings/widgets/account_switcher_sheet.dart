import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/providers.dart';
import '../../../core/telegram/models/telegram_account.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';

class AccountSwitcherSheet extends ConsumerWidget {
  const AccountSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AccountSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountService = ref.watch(telegramAccountServiceProvider);
    final accounts = accountService.accounts;
    final activeAccount = accountService.activeAccount;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final sheetBg = isLight ? Colors.white : AppColors.darkSurface;
    final primaryTextColor = isLight
        ? AppColors.lightTextPrimary
        : AppColors.darkTextPrimary;
    final secondaryTextColor = isLight
        ? AppColors.lightTextSecondary
        : AppColors.darkTextSecondary;
    final cardBorder = isLight ? AppColors.lightBorder : AppColors.darkBorder;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.switch_account_rounded,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Telegram Accounts',
                      style: AppTypography.titleMedium(
                        color: primaryTextColor,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Switch active cloud storage account',
                      style: AppTypography.bodySmall(color: secondaryTextColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: secondaryTextColor),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Accounts List
          if (accounts.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isLight ? Colors.grey.shade100 : AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryBlue,
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Active Session',
                          style: TextStyle(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Primary Telegram account connected',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primaryBlue,
                    size: 22,
                  ),
                ],
              ),
            ),
          ] else ...[
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: accounts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final acc = accounts[index];
                  final isActive = acc.id == activeAccount?.id || acc.isActive;

                  return _buildAccountTile(
                    context: context,
                    ref: ref,
                    account: acc,
                    isActive: isActive,
                    isLight: isLight,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    cardBorder: cardBorder,
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Add New Account Action
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: AppColors.primaryBlue.withValues(alpha: 0.6),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryBlue),
            label: Text(
              'Add Telegram Account',
              style: AppTypography.labelLarge(
                color: AppColors.primaryBlue,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/auth');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile({
    required BuildContext context,
    required WidgetRef ref,
    required TelegramAccount account,
    required bool isActive,
    required bool isLight,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color cardBorder,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        if (!isActive) {
          final accountService = ref.read(telegramAccountServiceProvider);
          await accountService.setActiveAccount(account.id);
          if (context.mounted) {
            Navigator.of(context).pop();
            final messenger = ScaffoldMessenger.of(context);
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Text('Switched to ${account.displayName}'),
                backgroundColor: AppColors.primaryBlue,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryBlue.withValues(alpha: isLight ? 0.1 : 0.15)
              : (isLight ? Colors.grey.shade100 : AppColors.darkCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.primaryBlue : cardBorder,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
              backgroundImage: (account.profilePhotoPath != null &&
                      account.profilePhotoPath!.isNotEmpty &&
                      File(account.profilePhotoPath!).existsSync())
                  ? FileImage(File(account.profilePhotoPath!))
                  : null,
              child: (account.profilePhotoPath != null &&
                      account.profilePhotoPath!.isNotEmpty &&
                      File(account.profilePhotoPath!).existsSync())
                  ? null
                  : Text(
                      account.firstName.isNotEmpty
                          ? account.firstName[0].toUpperCase()
                          : 'T',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        account.displayName,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.phoneNumber.isNotEmpty
                        ? account.phoneNumber
                        : (account.username != null
                              ? '@${account.username}'
                              : 'Telegram User'),
                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isActive)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryBlue,
                size: 22,
              )
            else
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: secondaryTextColor,
                  size: 20,
                ),
                onSelected: (val) async {
                  if (val == 'remove') {
                    final accountService = ref.read(
                      telegramAccountServiceProvider,
                    );
                    await accountService.removeAccount(account.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Remove Account',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
