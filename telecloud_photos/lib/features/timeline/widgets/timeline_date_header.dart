import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class TimelineDateHeader extends StatelessWidget {
  final String dateLabel;
  final int itemCount;
  final bool isYearly;
  final bool isSingle;
  final bool isAllPhotos;

  const TimelineDateHeader({
    super.key,
    required this.dateLabel,
    required this.itemCount,
    this.isYearly = false,
    this.isSingle = false,
    this.isAllPhotos = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isYearly || isAllPhotos) {
      return const SizedBox.shrink();
    }

    final primaryTextColor = AppColors.textPrimary(context);
    final secondaryTextColor = AppColors.textSecondary(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isSingle ? 16 : 8,
        isSingle ? 20 : 12,
        isSingle ? 16 : 8,
        isSingle ? 8 : 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateLabel,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: isSingle ? 19 : 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

