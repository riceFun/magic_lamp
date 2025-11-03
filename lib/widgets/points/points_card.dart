import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../data/models/user.dart';
import '../common/custom_card.dart';

/// 积分卡片组件 - 显示用户积分信息
/// 可点击进入积分详情页
class PointsCard extends StatelessWidget {
  final User user;

  const PointsCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(AppConstants.routePointsDetail);
      },
      child: CustomCard(
        child: Column(
          children: [
            const Text(
              '当前积分',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  Icons.monetization_on,
                  size: 40,
                  color: AppTheme.accentYellow,
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Text(
                  '${user.totalPoints}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    height: 1,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    '积分',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              '约等于 ${(user.totalPoints * AppConstants.pointsToRmb).toStringAsFixed(2)} 元',
              style: const TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textHintColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '点击查看详情',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
