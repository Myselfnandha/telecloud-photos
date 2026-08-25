import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecloud_photos/shared/theme/app_colors.dart';

void main() {
  group('AppColors Theme & Context-Aware Tokens Tests', () {
    test('AppColors static status badge tokens are properly defined', () {
      expect(AppColors.activeUpload, const Color(0xFF0A84FF));
      expect(AppColors.syncedBadge, const Color(0xFF30D158));
      expect(AppColors.failedUpload, const Color(0xFFFF453A));
      expect(AppColors.cloudOnlyBadge, const Color(0xFF5AC8FA));
      expect(AppColors.localOnlyBadge, const Color(0xFFFF9F0A));
      expect(AppColors.uploadingBadge, const Color(0xFF0A84FF));
    });

    testWidgets(
        'AppColors context-aware colors return correct dark mode values',
        (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(AppColors.surface(capturedContext), AppColors.darkSurface);
      expect(AppColors.card(capturedContext), AppColors.darkCard);
      expect(AppColors.textPrimary(capturedContext), AppColors.darkTextPrimary);
      expect(
        AppColors.textSecondary(capturedContext),
        AppColors.darkTextSecondary,
      );
      expect(AppColors.background(capturedContext), AppColors.darkBackground);
    });

    testWidgets(
        'AppColors context-aware colors return correct light mode values',
        (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(AppColors.surface(capturedContext), AppColors.lightSurface);
      expect(AppColors.card(capturedContext), AppColors.lightCard);
      expect(
        AppColors.textPrimary(capturedContext),
        AppColors.lightTextPrimary,
      );
      expect(
        AppColors.textSecondary(capturedContext),
        AppColors.lightTextSecondary,
      );
      expect(AppColors.background(capturedContext), AppColors.lightBackground);
    });
  });
}
