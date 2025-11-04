import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'data/database_helper.dart';
import 'services/product_import_service.dart';

/// 神灯积分管理 - 应用入口
void main() async {
  // 确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化数据库
  await DatabaseHelper.instance.database;

  // 导入商品数据
  try {
    final importService = ProductImportService();
    final result = await importService.importProducts();
    debugPrint('商品导入完成: $result');
  } catch (e) {
    debugPrint('商品导入失败: $e');
  }

  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
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
  runApp(MyApp());
}
