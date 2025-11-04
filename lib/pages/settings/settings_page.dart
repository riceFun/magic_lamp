import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_button.dart';

/// 设置页面 - 个人信息、系统设置
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.settings, size: 24),
            SizedBox(width: AppTheme.spacingSmall),
            Text('设置'),
          ],
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.currentUser;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: AppTheme.spacingLarge),
                  Text(
                    '未登录',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户信息卡片
                CustomCard(
                  child: Column(
                    children: [
                      // 头像
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryDarkColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Icon(
                          _getAvatarIcon(user.avatar),
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingMedium),

                      // 用户名和角色
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeXLarge,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppTheme.spacingSmall),

                      // 角色说明
                      Text(
                        '神灯积分管理系统用户',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),

                      SizedBox(height: AppTheme.spacingMedium),
                      Divider(),
                      SizedBox(height: AppTheme.spacingSmall),

                      // 积分信息
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: 24,
                            color: AppTheme.accentYellow,
                          ),
                          SizedBox(width: AppTheme.spacingSmall),
                          Text(
                            '${user.totalPoints}',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeXLarge,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          SizedBox(width: AppTheme.spacingXSmall),
                          Text(
                            '积分',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeMedium,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppTheme.spacingXSmall),
                      Text(
                        '约等于 ${(user.totalPoints * AppConstants.pointsToRmb).toStringAsFixed(2)} 元',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textHintColor,
                        ),
                      ),

                      SizedBox(height: AppTheme.spacingMedium),

                      // 编辑资料按钮
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push(AppConstants.routeProfile);
                          },
                          icon: Icon(Icons.edit),
                          label: Text('编辑资料'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppTheme.spacingLarge),

                // 设置选项标题
                Text(
                  '设置选项',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                SizedBox(height: AppTheme.spacingMedium),

                // 设置菜单
                CustomCard(
                  child: Column(
                    children: [
                      _SettingItem(
                        icon: Icons.group,
                        iconColor: AppTheme.primaryColor,
                        title: '用户管理',
                        subtitle: '管理所有用户信息',
                        onTap: () {
                          context.push(AppConstants.routeUserManagement);
                        },
                      ),
                      Divider(height: 1),
                      _SettingItem(
                        icon: Icons.card_giftcard,
                        iconColor: AppTheme.accentYellow,
                        title: '商品管理',
                        subtitle: '管理商城奖励商品',
                        onTap: () {
                          context.push(AppConstants.routeRewardManagement);
                        },
                      ),
                      Divider(height: 1),
                      _SettingItem(
                        icon: Icons.lock,
                        iconColor: AppTheme.accentOrange,
                        title: '修改密码',
                        subtitle: '修改登录密码',
                        onTap: () {
                          // TODO: 跳转到修改密码页面
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('修改密码功能开发中...')),
                          );
                        },
                      ),
                      Divider(height: 1),
                      _SettingItem(
                        icon: Icons.backup,
                        iconColor: AppTheme.accentGreen,
                        title: '数据备份',
                        subtitle: '备份和恢复数据',
                        onTap: () {
                          // TODO: 跳转到数据备份页面
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('数据备份功能开发中...')),
                          );
                        },
                      ),
                      Divider(height: 1),
                      _SettingItem(
                        icon: Icons.info,
                        iconColor: AppTheme.textSecondaryColor,
                        title: '关于应用',
                        subtitle: '版本信息和开发者',
                        onTap: () {
                          _showAboutDialog(context);
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppTheme.spacingLarge),

                // 退出登录按钮
                CustomButton.warning(
                  text: '退出登录',
                  onPressed: () {
                    _showLogoutDialog(context, userProvider);
                  },
                  icon: Icons.logout,
                  width: double.infinity,
                ),

                SizedBox(height: AppTheme.spacingLarge),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 显示退出登录确认对话框
  void _showLogoutDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('退出登录'),
        content: Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              // 执行退出登录
              await userProvider.logout();

              // 返回登录页面
              if (context.mounted) {
                context.go(AppConstants.routeLogin);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
            ),
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示关于对话框
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.lightbulb,
              color: AppTheme.accentYellow,
              size: 28,
            ),
            SizedBox(width: AppTheme.spacingSmall),
            Text('关于神灯积分'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '神灯积分管理',
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            Text(
              '版本：1.0.0',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingMedium),
            Text(
              '一款帮助孩子学习经济概念的积分管理应用。通过完成任务获得积分，用积分兑换奖励，同时学习词汇知识。',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppTheme.textPrimaryColor,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppTheme.spacingMedium),
            Text(
              '设计理念：',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            Text(
              '• 10积分 = 1元人民币\n• 每日可获得200-400积分\n• 正向激励，不扣分\n• 寓教于乐，学习词汇',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }
}

/// 设置项组件
class _SettingItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingMedium,
          ),
          child: Row(
            children: [
              // 图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: iconColor,
                ),
              ),
              SizedBox(width: AppTheme.spacingMedium),

              // 标题和副标题
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // 右箭头
              Icon(
                Icons.chevron_right,
                color: AppTheme.textHintColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
