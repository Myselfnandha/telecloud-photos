import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class TimelineDateHeader extends StatelessWidget {
  final String dateLabel;
  final int itemCount;
  final bool isYearly;
  final bool isSingle;

  const TimelineDateHeader({
    super.key,
    required this.dateLabel,
    required this.itemCount,
    this.isYearly = false,
    this.isSingle = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = AppColors.textPrimary(context);
    final secondaryTextColor = AppColors.textSecondary(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isSingle ? 16 : 8,
        isYearly ? 10 : (isSingle ? 24 : 16),
        isSingle ? 16 : 8,
        isYearly ? 4 : (isSingle ? 10 : 6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateLabel,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: isYearly ? 14 : (isSingle ? 20 : 18),
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: isYearly ? 11 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
