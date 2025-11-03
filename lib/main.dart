import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

/// 神灯积分管理 - 应用入口
void main() async {
  // 确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 设置屏幕方向为竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 配置 EasyLoading 样式
  configureEasyLoading();

  // 启动应用
  runApp(const MyApp());
}
