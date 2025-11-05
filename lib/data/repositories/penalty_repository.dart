import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/penalty.dart';

/// 惩罚项目数据访问层
class PenaltyRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// 获取所有惩罚项目
  Future<List<Penalty>> getAllPenalties(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'penalties',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Penalty.fromMap(maps[i]));
  }

  /// 获取激活的惩罚项目
  Future<List<Penalty>> getActivePenalties(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'penalties',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'active'],
      orderBy: 'points DESC, created_at DESC',
    );
    return List.generate(maps.length, (i) => Penalty.fromMap(maps[i]));
  }

  /// 根据分类获取惩罚项目
  Future<List<Penalty>> getPenaltiesByCategory(int userId, String category) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'penalties',
      where: 'user_id = ? AND category = ? AND status = ?',
      whereArgs: [userId, category, 'active'],
      orderBy: 'points DESC, created_at DESC',
    );
    return List.generate(maps.length, (i) => Penalty.fromMap(maps[i]));
  }

  /// 根据ID获取惩罚项目
  Future<Penalty?> getPenaltyById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'penalties',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Penalty.fromMap(maps.first);
  }

  /// 搜索惩罚项目
  Future<List<Penalty>> searchPenalties(int userId, String keyword) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'penalties',
      where: 'user_id = ? AND status = ? AND (name LIKE ? OR description LIKE ?)',
      whereArgs: [
        userId,
        'active',
        '%$keyword%',
        '%$keyword%',
      ],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Penalty.fromMap(maps[i]));
  }

  /// 创建惩罚项目
  Future<int> createPenalty(Penalty penalty) async {
    final db = await _dbHelper.database;
    return await db.insert('penalties', penalty.toMap());
  }

  /// 更新惩罚项目
  Future<int> updatePenalty(Penalty penalty) async {
    if (penalty.id == null) {
      throw ArgumentError('Penalty id cannot be null for update');
    }
    final db = await _dbHelper.database;
    final updatedPenalty = penalty.copyWith(updatedAt: DateTime.now());
    return await db.update(
      'penalties',
      updatedPenalty.toMap(),
      where: 'id = ?',
      whereArgs: [penalty.id],
    );
  }

  /// 删除惩罚项目
  Future<int> deletePenalty(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'penalties',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 执行惩罚（创建惩罚记录）
  Future<int> applyPenalty(PenaltyRecord record) async {
    final db = await _dbHelper.database;
    return await db.insert('penalty_records', record.toMap());
  }

  /// 获取用户的惩罚记录
  Future<List<PenaltyRecord>> getUserPenaltyRecords(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'penalty_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => PenaltyRecord.fromMap(maps[i]));
  }

  /// 获取用户指定日期范围的惩罚记录
  Future<List<PenaltyRecord>> getUserPenaltyRecordsInRange({
    required int userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'penalty_records',
      where: 'user_id = ? AND created_at >= ? AND created_at <= ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => PenaltyRecord.fromMap(maps[i]));
  }

  /// 获取用户的惩罚统计
  Future<Map<String, int>> getUserPenaltyStats(int userId) async {
    final db = await _dbHelper.database;

    // 总扣除积分
    final totalResult = await db.rawQuery('''
      SELECT COALESCE(SUM(points_deducted), 0) as total
      FROM penalty_records
      WHERE user_id = ?
    ''', [userId]);
    final totalPoints = totalResult.first['total'] as int;

    // 惩罚次数
    final countResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM penalty_records
      WHERE user_id = ?
    ''', [userId]);
    final totalCount = countResult.first['count'] as int;

    // 本月扣除积分
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final monthResult = await db.rawQuery('''
      SELECT COALESCE(SUM(points_deducted), 0) as total
      FROM penalty_records
      WHERE user_id = ? AND created_at >= ?
    ''', [userId, firstDayOfMonth.toIso8601String()]);
    final monthPoints = monthResult.first['total'] as int;

    return {
      'totalPoints': totalPoints,
      'totalCount': totalCount,
      'monthPoints': monthPoints,
    };
  }

  /// 获取惩罚项目统计（各分类的惩罚次数）
  Future<Map<String, int>> getPenaltyCategoryStats(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT p.category, COUNT(*) as count
      FROM penalty_records pr
      INNER JOIN penalties p ON pr.penalty_id = p.id
      WHERE pr.user_id = ?
      GROUP BY p.category
    ''', [userId]);

    Map<String, int> stats = {};
    for (var row in result) {
      stats[row['category'] as String] = row['count'] as int;
    }
    return stats;
  }

  /// 删除惩罚记录
  Future<int> deletePenaltyRecord(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'penalty_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取特定惩罚项目的使用次数
  Future<int> getPenaltyUsageCount(int penaltyId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM penalty_records
      WHERE penalty_id = ?
    ''', [penaltyId]);
    return result.first['count'] as int;
  }
}
