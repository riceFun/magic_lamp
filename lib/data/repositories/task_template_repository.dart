import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/task_template.dart';

/// 任务模板数据仓库
class TaskTemplateRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

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

  /// 插入初始模板数据
  static Future<void> insertInitialTemplates(Database db) async {
    final templates = [
      // 学习类
      {
        'title': '完成作业',
        'description': '认真完成当天的学校作业',
        'points': 50,
        'type': 'daily',
        'priority': 'high',
        'category': 'study',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'title': '阅读30分钟',
        'description': '每天阅读课外书籍30分钟',
        'points': 30,
        'type': 'daily',
        'priority': 'medium',
        'category': 'reading',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'title': '背诵单词',
        'description': '背诵10个新单词',
        'points': 40,
        'type': 'daily',
        'priority': 'medium',
        'category': 'study',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'title': '完成周测试',
        'description': '完成本周的复习测试',
        'points': 100,
        'type': 'weekly',
        'priority': 'high',
        'category': 'study',
        'created_at': DateTime.now().toIso8601String(),
      },

      // 健康类
      {
        'title': '早睡早起',
        'description': '晚上9点前睡觉，早上7点前起床',
        'points': 30,
        'type': 'daily',
        'priority': 'high',
        'category': 'health',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'title': '喝水8杯',
        'description': '每天喝足8杯水',
        'points': 20,
        'type': 'daily',
        'priority': 'medium',
        'category': 'health',
        'created_at': DateTime.now().toIso8601String(),
      },

      // 运动类
      {
        'title': '跑步30分钟',
        'description': '户外跑步或跑步机运动30分钟',
        'points': 40,
        'type': 'daily',
        'priority': 'medium',
        'category': 'exercise',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'title': '做眼保健操',
        'description': '保护视力，完成眼保健操',
        'points': 20,
        'type': 'daily',
        'priority': 'medium',
        'category': 'exercise',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'title': '户外活动1小时',
        'description': '每周进行户外活动至少1小时',
        'points': 60,
        'type': 'weekly',
        'priority': 'medium',
        'category': 'exercise',
        'created_at': DateTime.now().toIso8601String(),
      },

      // 家务类
      {
        'title': '整理房间',
        'description': '打扫整理自己的房间',
        'points': 30,
        'type': 'daily',
        'priority': 'low',
        'category': 'housework',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'title': '帮忙洗碗',
        'description': '帮助家人清洗餐具',
        'points': 20,
        'type': 'daily',
        'priority': 'low',
        'category': 'housework',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'title': '打扫卫生',
        'description': '帮助打扫家里的公共区域',
        'points': 40,
        'type': 'weekly',
        'priority': 'low',
        'category': 'housework',
        'created_at': DateTime.now().toIso8601String(),
      },

      // 其他
      {
        'title': '学习新技能',
        'description': '学习一项新的技能或爱好',
        'points': 80,
        'type': 'weekly',
        'priority': 'low',
        'category': 'other',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'title': '帮助他人',
        'description': '主动帮助需要帮助的人',
        'points': 50,
        'type': 'once',
        'priority': 'medium',
        'category': 'other',
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (var template in templates) {
      await db.insert('task_templates', template);
    }
  }

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
