import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/task_template.dart';

/// 任务模板数据仓库
class TaskTemplateRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// 创建任务模板表
  static String get createTableSql => '''
    CREATE TABLE task_templates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      points INTEGER NOT NULL,
      type TEXT NOT NULL,
      priority TEXT DEFAULT 'medium',
      category TEXT,
      created_at TEXT NOT NULL
    )
  ''';

  /// 创建任务模板
  Future<int> createTemplate(TaskTemplate template) async {
    final db = await _dbHelper.database;
    return await db.insert('task_templates', template.toMap());
  }

  /// 获取所有任务模板
  Future<List<TaskTemplate>> getAllTemplates() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'task_templates',
      orderBy: 'category ASC, created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return TaskTemplate.fromMap(maps[i]);
    });
  }

  /// 根据分类获取任务模板
  Future<List<TaskTemplate>> getTemplatesByCategory(String category) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'task_templates',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return TaskTemplate.fromMap(maps[i]);
    });
  }

  /// 根据类型获取任务模板
  Future<List<TaskTemplate>> getTemplatesByType(String type) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'task_templates',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return TaskTemplate.fromMap(maps[i]);
    });
  }

  /// 获取单个任务模板
  Future<TaskTemplate?> getTemplateById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'task_templates',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return TaskTemplate.fromMap(maps.first);
  }

  /// 更新任务模板
  Future<int> updateTemplate(TaskTemplate template) async {
    final db = await _dbHelper.database;
    return await db.update(
      'task_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  /// 删除任务模板
  Future<int> deleteTemplate(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'task_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 搜索任务模板
  Future<List<TaskTemplate>> searchTemplates(String keyword) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'task_templates',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return TaskTemplate.fromMap(maps[i]);
    });
  }

  /// 获取模板总数
  Future<int> getTemplateCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM task_templates');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 按分类统计模板数量
  Future<Map<String, int>> getTemplateCountByCategory() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM task_templates GROUP BY category',
    );

    Map<String, int> result = {};
    for (var map in maps) {
      result[map['category'] ?? 'other'] = map['count'] as int;
    }
    return result;
  }
}
