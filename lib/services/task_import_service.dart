import 'dart:convert';
import 'package:flutter/services.dart';
import '../data/models/task_template.dart';
import '../data/repositories/task_template_repository.dart';

/// 导入结果统计
class TaskImportResult {
  final int successCount; // 成功导入数量
  final int skippedCount; // 跳过数量（已存在）
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
    return 'TaskImportResult{总计: $totalProcessed, 成功: $successCount, 跳过: $skippedCount, 失败: $failedCount}';
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
      // 1. 读取 JSON 文件
      final String jsonString =
          await rootBundle.loadString('assets/tasks.json');

      // 2. 解析 JSON 数据
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> tasksJson = jsonData['tasks'];

      // 3. 遍历每个任务
      for (var taskJson in tasksJson) {
        try {
          final Map<String, dynamic> taskMap = taskJson;
          final String title = taskMap['title'] as String;

          // 4. 检查任务模板是否已存在（通过标题）
          if (await _isTaskTemplateExists(title)) {
            skippedCount++;
            continue;
          }

          // 5. 创建 TaskTemplate 对象
          final TaskTemplate template = TaskTemplate(
            title: title,
            description: taskMap['description'] as String?,
            points: taskMap['points'] as int,
            type: taskMap['type'] as String,
            priority: taskMap['priority'] as String? ?? 'medium',
            category: taskMap['category'] as String?,
            icon: taskMap['icon'] as String?,
          );

          // 6. 添加到数据库
          await _taskTemplateRepository.createTemplate(template);
          successCount++;
        } catch (e) {
          failedCount++;
          errors.add('导入任务失败: ${taskJson['title'] ?? 'Unknown'} - $e');
        }
      }
    } catch (e) {
      errors.add('读取或解析 JSON 文件失败: $e');
    }

    return TaskImportResult(
      successCount: successCount,
      skippedCount: skippedCount,
      failedCount: failedCount,
      errors: errors,
    );
  }

  /// 检查任务模板是否已存在（通过标题）
  Future<bool> _isTaskTemplateExists(String title) async {
    final templates = await _taskTemplateRepository.getAllTemplates();
    return templates.any((template) => template.title == title);
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
