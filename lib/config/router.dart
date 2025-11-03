import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/splash/splash_page.dart';
import '../pages/login/login_page.dart';
import '../pages/main_navigation_page.dart';
import '../pages/task/task_list_page.dart';
import '../pages/task/create_task_page.dart';
import '../pages/user/create_user_page.dart';
import '../pages/user/user_list_page.dart';
import '../pages/settings/edit_profile_page.dart';
import '../pages/advance/advance_apply_page.dart';
import '../pages/advance/advance_list_page.dart';
import '../pages/shop/reward_management_page.dart';
import '../pages/shop/edit_reward_page.dart';
import 'constants.dart';

/// 应用路由配置
class AppRouter {
  AppRouter._();

  /// 创建 GoRouter 实例
  static final GoRouter router = GoRouter(
    initialLocation: AppConstants.routeSplash,
    routes: [
      // 启动页
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (context, state) => SplashPage(),
      ),

      // 登录页
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (context, state) => LoginPage(),
      ),

      // 主页（含底部导航的5个tab）
      GoRoute(
        path: AppConstants.routeMain,
        builder: (context, state) => MainNavigationPage(),
      ),

      // 任务列表
      GoRoute(
        path: AppConstants.routeTaskList,
        builder: (context, state) => TaskListPage(),
      ),

      // 任务创建
      GoRoute(
        path: AppConstants.routeTaskCreate,
        builder: (context, state) => CreateTaskPage(),
      ),

      // 用户管理
      GoRoute(
        path: AppConstants.routeUserManagement,
        builder: (context, state) => UserListPage(),
      ),

      // 创建用户
      GoRoute(
        path: AppConstants.routeUserCreate,
        builder: (context, state) => CreateUserPage(),
      ),

      // 编辑个人资料
      GoRoute(
        path: AppConstants.routeProfile,
        builder: (context, state) => EditProfilePage(),
      ),

      // 预支申请
      GoRoute(
        path: AppConstants.routeAdvanceApply,
        builder: (context, state) => AdvanceApplyPage(),
      ),

      // 预支列表
      GoRoute(
        path: AppConstants.routeAdvanceList,
        builder: (context, state) => AdvanceListPage(),
      ),

      // 商品管理
      GoRoute(
        path: AppConstants.routeRewardManagement,
        builder: (context, state) => RewardManagementPage(),
      ),

      // 编辑商品
      GoRoute(
        path: AppConstants.routeRewardEdit,
        builder: (context, state) {
          final idParam = state.uri.queryParameters['id'];
          final rewardId = idParam != null ? int.tryParse(idParam) : null;
          return EditRewardPage(rewardId: rewardId);
        },
      ),
    ],

    // 错误页面
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              '页面未找到',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              state.error?.toString() ?? '未知错误',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppConstants.routeMain),
              child: Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
}
