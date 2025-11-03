import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/custom_card.dart';

/// 首页 - 显示积分概况和快捷操作
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// 获取头像图标
  IconData _getAvatarIcon(String? avatar) {
    switch (avatar) {
      case 'face':
        return Icons.face;
      case 'face_2':
        return Icons.face_2;
      case 'person':
        return Icons.person;
      case 'child_care':
        return Icons.child_care;
      case 'emoji_people':
        return Icons.emoji_people;
      default:
        return Icons.account_circle;
    }
  }

  /// 获取问候语
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      return '夜深了';
    } else if (hour < 12) {
      return '早上好';
    } else if (hour < 14) {
      return '中午好';
    } else if (hour < 18) {
      return '下午好';
    } else {
      return '晚上好';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.currentUser;

          if (user == null) {
            return Center(
              child: Text(
                '未登录',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    '${_getGreeting()}，${user.name}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryDarkColor,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingLarge),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // 用户头像
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                  ),
                                  child: Icon(
                                    _getAvatarIcon(user.avatar),
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingMedium),
                                // 用户信息
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            user.name,
                                            style: const TextStyle(
                                              fontSize: AppTheme.fontSizeXLarge,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          if (user.isAdmin) ...[
                                            const SizedBox(
                                                width: AppTheme.spacingSmall),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: AppTheme.spacingSmall,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentYellow,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  AppTheme.radiusSmall,
                                                ),
                                              ),
                                              child: const Text(
                                                '管理员',
                                                style: TextStyle(
                                                  fontSize:
                                                      AppTheme.fontSizeXSmall,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 内容区域
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 积分卡片（可点击）
                      GestureDetector(
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
                                '约等于 ${(user.totalPoints * 0.1).toStringAsFixed(2)} 元',
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
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),

                      // 快捷操作
                      const Text(
                        '快捷操作',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),

                      // 操作按钮网格
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.task_alt,
                              title: '完成任务',
                              color: AppTheme.accentGreen,
                              onTap: () {
                                // 跳转到任务列表
                                context.push(AppConstants.routeTaskList);
                              },
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMedium),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.card_giftcard,
                              title: '兑换奖励',
                              color: AppTheme.accentYellow,
                              onTap: () {
                                // TODO: 跳转到商城
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('商城功能开发中...')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.spacingLarge),

                      // 今日任务预览
                      const Text(
                        '今日任务',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),
                      CustomCard(
                        child: Column(
                          children: [
                            Icon(
                              Icons.task,
                              size: 60,
                              color: AppTheme.textHintColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: AppTheme.spacingSmall),
                            const Text(
                              '暂无任务',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeMedium,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingXSmall),
                            const Text(
                              '点击"完成任务"开始添加任务',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeSmall,
                                color: AppTheme.textHintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 快捷操作卡片
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
