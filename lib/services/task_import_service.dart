import 'dart:convert';
import 'package:flutter/services.dart';
import '../data/models/task_template.dart';
import '../data/repositories/task_template_repository.dart';

/// 导入结果统计
class TaskImportResult {
  final int successCount; // 成功导入数量（新增）
  final int skippedCount; // 更新数量（已存在的任务）
  final int failedCount; // 失败数量
  final List<String> errors; // 错误信息列表

  TaskImportResult({
    required this.successCount,
    required this.skippedCount,
    required this.failedCount,
    required this.errors,
  });

  int get totalProcessed => successCount + skippedCount + failedCount;

  @override
  String toString() {
    return 'TaskImportResult{总计: $totalProcessed, 新增: $successCount, 更新: $skippedCount, 失败: $failedCount}';
  }
}

/// 任务模板导入服务
/// 负责从 assets/tasks.json 导入任务模板数据到数据库
class TaskImportService {
  final TaskTemplateRepository _taskTemplateRepository = TaskTemplateRepository();

  /// 从 assets/tasks.json 导入任务模板
  Future<TaskImportResult> importTasks() async {
    int successCount = 0;
    int skippedCount = 0;
    int failedCount = 0;
    List<String> errors = [];

    try {
      print('开始导入任务模板...');

      // 1. 读取 JSON 文件
      final String jsonString =
          await rootBundle.loadString('assets/tasks.json');
      print('成功读取 tasks.json 文件');

      // 2. 解析 JSON 数据
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> tasksJson = jsonData['tasks'];
      print('解析到 ${tasksJson.length} 个任务模板');

      // 3. 遍历每个任务
      for (var taskJson in tasksJson) {
        try {
          final Map<String, dynamic> taskMap = taskJson;
          final String title = taskMap['title'] as String;

          // 4. 检查任务模板是否已存在（通过标题）
          final existingTemplate = await _getTaskTemplateByTitle(title);

          // 5. 创建 TaskTemplate 对象
          final TaskTemplate template = TaskTemplate(
            id: existingTemplate?.id, // 如果存在则使用现有ID
            title: title,
            description: taskMap['description'] as String?,
            points: taskMap['points'] as int,
            type: taskMap['type'] as String,
            priority: taskMap['priority'] as String? ?? 'medium',
            category: taskMap['category'] as String?,
            icon: taskMap['icon'] as String?,
          );

          // 6. 添加或更新到数据库
          if (existingTemplate != null) {
            // 更新现有模板
            await _taskTemplateRepository.updateTemplate(template);
            skippedCount++;
            print('更新任务模板: $title');
          } else {
            // 创建新模板
            await _taskTemplateRepository.createTemplate(template);
            successCount++;
            print('创建任务模板: $title');
          }
        } catch (e) {
          failedCount++;
          final errorMsg = '导入任务失败: ${taskJson['title'] ?? 'Unknown'} - $e';
          errors.add(errorMsg);
          print(errorMsg);
        }
      }
    } catch (e, stackTrace) {
      final errorMsg = '读取或解析 JSON 文件失败: $e';
      errors.add(errorMsg);
      print(errorMsg);
      print('堆栈跟踪: $stackTrace');
    }

    final result = TaskImportResult(
      successCount: successCount,
      skippedCount: skippedCount,
      failedCount: failedCount,
      errors: errors,
    );

    print('任务模板导入完成: $result');
    return result;
  }

  /// 根据标题获取任务模板（如果存在）
  Future<TaskTemplate?> _getTaskTemplateByTitle(String title) async {
    final templates = await _taskTemplateRepository.getAllTemplates();
    try {
      return templates.firstWhere((template) => template.title == title);
    } catch (e) {
      return null;
    }
  }

  /// 清空所有任务模板（危险操作，仅用于测试）
  Future<void> clearAllTasks() async {
    final templates = await _taskTemplateRepository.getAllTemplates();
    for (var template in templates) {
      if (template.id != null) {
        await _taskTemplateRepository.deleteTemplate(template.id!);
      }
    }
  }

  /// 重新导入所有任务模板（清空后重新导入）
  Future<TaskImportResult> reimportTasks() async {
    await clearAllTasks();
    return await importTasks();
  }
}
