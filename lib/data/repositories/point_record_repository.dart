import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/point.dart';

/// 积分记录数据访问层
class PointRecordRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// 获取用户的所有积分记录
  Future<List<PointRecord>> getUserPointRecords(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'point_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => PointRecord.fromMap(maps[i]));
  }

  /// 获取用户的收入记录
  Future<List<PointRecord>> getUserEarnRecords(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'point_records',
      where: 'user_id = ? AND type = ?',
      whereArgs: [userId, 'earn'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => PointRecord.fromMap(maps[i]));
  }

  /// 获取用户的支出记录
  Future<List<PointRecord>> getUserSpendRecords(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'point_records',
      where: 'user_id = ? AND type = ?',
      whereArgs: [userId, 'spend'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => PointRecord.fromMap(maps[i]));
  }

  /// 根据来源类型获取记录
  Future<List<PointRecord>> getRecordsBySource(
    int userId,
    String sourceType,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'point_records',
      where: 'user_id = ? AND source_type = ?',
      whereArgs: [userId, sourceType],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => PointRecord.fromMap(maps[i]));
  }

  /// 根据日期范围获取记录
  Future<List<PointRecord>> getRecordsByDateRange(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'point_records',
      where: 'user_id = ? AND created_at >= ? AND created_at <= ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => PointRecord.fromMap(maps[i]));
  }

  /// 创建积分记录
  Future<int> createPointRecord(PointRecord record) async {
    final db = await _dbHelper.database;
    return await db.insert('point_records', record.toMap());
  }

  /// 删除积分记录
  Future<int> deletePointRecord(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'point_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取用户总收入
  Future<int> getUserTotalEarned(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(points) as total FROM point_records WHERE user_id = ? AND type = ?',
      [userId, 'earn'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取用户总支出
  Future<int> getUserTotalSpent(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(ABS(points)) as total FROM point_records WHERE user_id = ? AND type = ?',
      [userId, 'spend'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取记录总数
  Future<int> getUserRecordCount(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM point_records WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取今日记录
  Future<List<PointRecord>> getTodayRecords(int userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    return await getRecordsByDateRange(userId, startOfDay, endOfDay);
  }

  /// 获取本周记录
  Future<List<PointRecord>> getThisWeekRecords(int userId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return await getRecordsByDateRange(userId, startOfDay, DateTime.now());
  }

  /// 获取本月记录
  Future<List<PointRecord>> getThisMonthRecords(int userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return await getRecordsByDateRange(userId, startOfMonth, DateTime.now());
  }
}
