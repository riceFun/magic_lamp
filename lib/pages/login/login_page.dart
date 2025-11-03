import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../providers/user_provider.dart';
import '../../data/models/user.dart';

/// 登录页面 - 用户选择或创建
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    // 加载用户列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadAllUsers();
    });
  }

  /// 选择用户登录
  Future<void> _selectUser(User user) async {
    final userProvider = context.read<UserProvider>();

    // 执行登录
    final success = await userProvider.login(user.id!);

    if (success && mounted) {
      // 跳转到主页面
      context.go(AppConstants.routeMain);
    } else if (mounted) {
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userProvider.errorMessage ?? '登录失败')),
      );
    }
  }

  /// 创建新用户
  Future<void> _createNewUser() async {
    await context.push(AppConstants.routeUserCreate);
    // 返回后重新加载用户列表
    if (mounted) {
      context.read<UserProvider>().loadAllUsers();
    }
  }

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            children: [
              const SizedBox(height: AppTheme.spacingXLarge),

              // 欢迎标题
              const Text(
                '欢迎使用',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXLarge,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),

              // 应用名称
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: AppTheme.fontSizeTitle,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeTitle,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXLarge),

              // 选择用户提示
              const Text(
                '选择用户登录',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLarge),

              // 用户列表
              Expanded(
                child: Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    if (userProvider.isLoading) {
                      return LoadingWidget.medium(
                        message: '加载用户列表中...',
                      );
                    }

                    if (userProvider.allUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 80,
                              color: AppTheme.textHintColor,
                            ),
                            const SizedBox(height: AppTheme.spacingMedium),
                            const Text(
                              '暂无用户',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeLarge,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingSmall),
                            const Text(
                              '请创建第一个用户',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeMedium,
                                color: AppTheme.textHintColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: userProvider.allUsers.length,
                      itemBuilder: (context, index) {
                        final user = userProvider.allUsers[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingMedium,
                          ),
                          child: CustomCard(
                            onTap: () => _selectUser(user),
                            child: Row(
                              children: [
                                // 头像
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: user.isAdmin
                                        ? AppTheme.accentOrange
                                            .withValues(alpha: 0.2)
                                        : AppTheme.primaryLightColor
                                            .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                  ),
                                  child: Icon(
                                    _getAvatarIcon(user.avatar),
                                    size: 36,
                                    color: user.isAdmin
                                        ? AppTheme.accentOrange
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingMedium),

                                // 用户信息
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            user.name,
                                            style: const TextStyle(
                                              fontSize: AppTheme.fontSizeLarge,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimaryColor,
                                            ),
                                          ),
                                          if (user.isAdmin) ...[
                                            const SizedBox(
                                                width:
                                                    AppTheme.spacingSmall),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal:
                                                    AppTheme.spacingSmall,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentOrange,
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
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.monetization_on,
                                            size: 16,
                                            color: AppTheme.accentYellow,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${user.totalPoints} 积分',
                                            style: const TextStyle(
                                              fontSize: AppTheme.fontSizeMedium,
                                              color:
                                                  AppTheme.textSecondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // 箭头图标
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 20,
                                  color: AppTheme.textHintColor,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // 创建新用户按钮
              CustomButton.secondary(
                text: '创建新用户',
                icon: Icons.person_add,
                width: double.infinity,
                onPressed: _createNewUser,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
