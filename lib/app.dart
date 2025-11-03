import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/router.dart';
import 'providers/user_provider.dart';
import 'providers/reward_provider.dart';
import 'providers/point_record_provider.dart';
import 'providers/task_provider.dart';
import 'providers/exchange_provider.dart';
import 'providers/advance_provider.dart';

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
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ExchangeProvider()),
        ChangeNotifierProvider(create: (_) => AdvanceProvider()),
      ],
      child: MaterialApp.router(
        // 应用标题
        title: '神灯积分管理',

        // 主题配置
        theme: AppTheme.lightTheme,

        // 禁用调试标签
        debugShowCheckedModeBanner: false,

        // GoRouter 配置
        routerConfig: AppRouter.router,

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
