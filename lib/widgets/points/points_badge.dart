import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

/// 积分徽章组件 - 显示在导航栏右上角
/// 可点击进入积分详情页
class PointsBadge extends StatelessWidget {
  final int points;

  const PointsBadge({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // context.push(AppConstants.routePointsDetail);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXSmall,
          vertical: AppTheme.spacingXSmall,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_money,
              // Icons.monetization_on,
              size: 20,
              color: AppTheme.accentYellow,
            ),
            SizedBox(width: 0),
            Text(
              '$points',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
