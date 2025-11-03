import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'pages/splash/splash_page.dart';
import 'pages/login/login_page.dart';
import 'pages/main_navigation_page.dart';
import 'providers/user_provider.dart';
import 'providers/reward_provider.dart';
import 'providers/point_record_provider.dart';

/// 神灯积分管理 - 应用根Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => RewardProvider()),
        ChangeNotifierProvider(create: (_) => PointRecordProvider()),
      ],
      child: MaterialApp(
        // 应用标题
        title: AppConstants.appName,

        // 主题配置
        theme: AppTheme.lightTheme,

        // 禁用调试标签
        debugShowCheckedModeBanner: false,

        // 初始路由
        initialRoute: AppConstants.routeSplash,

        // 路由配置
        routes: {
          AppConstants.routeSplash: (context) => SplashPage(),
          AppConstants.routeLogin: (context) => LoginPage(),
          AppConstants.routeMain: (context) => MainNavigationPage(),
        },

        // EasyLoading 配置
        builder: EasyLoading.init(),
      ),
    );
  }
}

/// 配置 EasyLoading 样式
void configureEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = AppTheme.primaryColor
    ..backgroundColor = Colors.white
    ..indicatorColor = AppTheme.primaryColor
    ..textColor = AppTheme.textPrimaryColor
    ..maskColor = Colors.black.withValues(alpha: 0.5)
    ..userInteractions = false
    ..dismissOnTap = false;
}
