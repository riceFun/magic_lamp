import '../database_helper.dart';
import '../models/task.dart';

/// 任务数据访问类
class TaskRepository {
  final _db = DatabaseHelper.instance;

  /// 创建任务
  Future<int> createTask(Task task) async {
    final db = await _db.database;
    return await db.insert('tasks', task.toMap());
  }

  /// 根据ID获取任务
  Future<Task?> getTaskById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  /// 获取用户的所有任务（不包括已替换的任务）
  Future<List<Task>> getUserTasks(int userId) async {
    final db = await _db.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND status != ?',
      whereArgs: [userId, 'replaced'],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// 获取用户的激活任务
  Future<List<Task>> getUserActiveTasks(int userId) async {
    final db = await _db.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'active'],
      orderBy: 'priority DESC, created_at DESC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// 根据类型获取任务
  Future<List<Task>> getUserTasksByType(int userId, String type) async {
    final db = await _db.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND type = ? AND status = ?',
      whereArgs: [userId, type, 'active'],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// 更新任务
  Future<int> updateTask(Task task) async {
    final db = await _db.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// 更新任务状态
  Future<int> updateTaskStatus(int taskId, String status) async {
    final db = await _db.database;
    return await db.update(
      'tasks',
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// 删除任务
  Future<int> deleteTask(int id) async {
    final db = await _db.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取今日任务
  Future<List<Task>> getTodayTasks(int userId) async {
    final db = await _db.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    final maps = await db.query(
      'tasks',
      where: '''
        user_id = ?
        AND status = ?
        AND (
          (start_date IS NULL OR start_date <= ?)
          AND (end_date IS NULL OR end_date >= ?)
        )
      ''',
      whereArgs: [userId, 'active', tomorrow.toIso8601String(), today.toIso8601String()],
      orderBy: 'priority DESC, created_at DESC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  // ========== 任务完成记录相关 ==========

  /// 创建任务完成记录
  Future<int> createTaskRecord(TaskRecord record) async {
    final db = await _db.database;
    return await db.insert('task_records', record.toMap());
  }

  /// 获取任务的完成记录
  Future<List<TaskRecord>> getTaskRecords(int taskId) async {
    final db = await _db.database;
    final maps = await db.query(
      'task_records',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'completed_at DESC',
    );

    return maps.map((map) => TaskRecord.fromMap(map)).toList();
  }

  /// 获取用户的任务完成记录
  Future<List<TaskRecord>> getUserTaskRecords(int userId) async {
    final db = await _db.database;
    final maps = await db.query(
      'task_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'completed_at DESC',
    );

    return maps.map((map) => TaskRecord.fromMap(map)).toList();
  }

  /// 获取今日完成记录
  Future<List<TaskRecord>> getTodayCompletedTasks(int userId) async {
    final db = await _db.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    final maps = await db.query(
      'task_records',
      where: 'user_id = ? AND completed_at >= ? AND completed_at < ?',
      whereArgs: [
        userId,
        today.toIso8601String(),
        tomorrow.toIso8601String(),
      ],
      orderBy: 'completed_at DESC',
    );

    return maps.map((map) => TaskRecord.fromMap(map)).toList();
  }

  /// 检查任务今天是否已完成
  Future<bool> isTaskCompletedToday(int taskId, int userId) async {
    final records = await getTodayCompletedTasks(userId);
    return records.any((record) => record.taskId == taskId);
  }

  /// 获取任务的连续完成天数
  Future<int> getTaskStreakCount(int taskId, int userId) async {
    final db = await _db.database;
    final maps = await db.query(
      'task_records',
      where: 'task_id = ? AND user_id = ?',
      whereArgs: [taskId, userId],
      orderBy: 'completed_at DESC',
      limit: 30, // 最多查询30天
    );

    if (maps.isEmpty) return 0;

    final records = maps.map((map) => TaskRecord.fromMap(map)).toList();
    int streak = 0;
    DateTime? lastDate;

    for (var record in records) {
      final recordDate = DateTime(
        record.completedAt.year,
        record.completedAt.month,
        record.completedAt.day,
      );

      if (lastDate == null) {
        // 第一条记录
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);

        if (recordDate.isAtSameMomentAs(todayDate) ||
            recordDate.isAtSameMomentAs(todayDate.subtract(Duration(days: 1)))) {
          streak = 1;
          lastDate = recordDate;
        } else {
          break; // 不连续
        }
      } else {
        // 检查是否连续
        final expectedDate = lastDate.subtract(Duration(days: 1));
        if (recordDate.isAtSameMomentAs(expectedDate)) {
          streak++;
          lastDate = recordDate;
        } else {
          break; // 不连续
        }
      }
    }

    return streak;
  }

  /// 获取任务总完成次数
  Future<int> getTaskCompletionCount(int taskId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM task_records WHERE task_id = ?',
      [taskId],
    );

    return result.first['count'] as int;
  }

  /// 获取用户任务统计
  Future<Map<String, int>> getUserTaskStats(int userId) async {
    final db = await _db.database;

    // 总任务数
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE user_id = ?',
      [userId],
    );
    final totalCount = totalResult.first['count'] as int;

    // 已完成任务数
    final completedResult = await db.rawQuery(
      'SELECT COUNT(DISTINCT task_id) as count FROM task_records WHERE user_id = ?',
      [userId],
    );
    final completedCount = completedResult.first['count'] as int;

    // 激活任务数
    final activeResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE user_id = ? AND status = ?',
      [userId, 'active'],
    );
    final activeCount = activeResult.first['count'] as int;

    // 总获得积分
    final pointsResult = await db.rawQuery(
      'SELECT SUM(points_earned) as total FROM task_records WHERE user_id = ?',
      [userId],
    );
    final totalPoints = pointsResult.first['total'] as int? ?? 0;

    // 最大连续完成天数 - 需要遍历所有任务找到最大值
    int maxStreak = 0;
    final tasks = await getUserTasks(userId);
    for (var task in tasks) {
      final streak = await getTaskStreakCount(task.id!, userId);
      if (streak > maxStreak) {
        maxStreak = streak;
      }
    }

    return {
      'totalCount': totalCount,
      'completedCount': completedCount,
      'activeCount': activeCount,
      'totalPoints': totalPoints,
      'maxStreak': maxStreak,
    };
  }
}
