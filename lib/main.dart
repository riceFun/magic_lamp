import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'data/database_helper.dart';
import 'services/product_import_service.dart';
import 'services/task_import_service.dart';

/// 神灯积分管理 - 应用入口
void main() async {
  // 确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化数据库
  final db = await DatabaseHelper.instance.database;

  // 导入商品数据（获取第一个用户的ID）
  try {
    final users = await db.query('users', orderBy: 'id ASC', limit: 1);
    if (users.isNotEmpty) {
      final userId = users.first['id'] as int;
      final importService = ProductImportService();
      final result = await importService.importProducts(userId);
      debugPrint('商品导入完成: $result');
    } else {
      debugPrint('跳过商品导入: 暂无用户');
    }
  } catch (e) {
    debugPrint('商品导入失败: $e');
  }

  // 导入任务模板数据
  try {
    final taskImportService = TaskImportService();
    final result = await taskImportService.importTasks();
    debugPrint('任务模板导入完成: $result');
  } catch (e) {
    debugPrint('任务模板导入失败: $e');
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
