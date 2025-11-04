import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/story.dart';

/// 故事学习记录仓库
class StoryRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// 创建学习记录
  Future<int> createStoryRecord(StoryRecord record) async {
    final db = await _db.database;
    return await db.insert('story_records', record.toMap());
  }

  /// 获取用户所有学习记录
  Future<List<StoryRecord>> getUserRecords(int userId) async {
    final db = await _db.database;
    final maps = await db.query(
      'story_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'learned_at DESC',
    );
    return maps.map((map) => StoryRecord.fromMap(map)).toList();
  }

  /// 检查用户今天是否已学习某个故事
  Future<bool> hasLearnedToday(int userId, int storyId) async {
    final db = await _db.database;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(Duration(days: 1));

    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM story_records WHERE user_id = ? AND story_id = ? AND learned_at >= ? AND learned_at < ?',
      [userId, storyId, todayStart.toIso8601String(), todayEnd.toIso8601String()],
    ));

    return (count ?? 0) > 0;
  }

  /// 获取用户今天学习的故事数量
  Future<int> getTodayLearnCount(int userId) async {
    final db = await _db.database;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(Duration(days: 1));

    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM story_records WHERE user_id = ? AND learned_at >= ? AND learned_at < ?',
      [userId, todayStart.toIso8601String(), todayEnd.toIso8601String()],
    ));

    return count ?? 0;
  }

  /// 获取用户已学习的故事ID列表
  Future<Set<int>> getLearnedStoryIds(int userId) async {
    final db = await _db.database;
    final maps = await db.query(
      'story_records',
      columns: ['story_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      distinct: true,
    );
    return maps.map((map) => map['story_id'] as int).toSet();
  }
}
