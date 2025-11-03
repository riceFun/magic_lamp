import '../database_helper.dart';
import '../models/point.dart';

/// 预支积分数据访问类
class AdvanceRepository {
  final _db = DatabaseHelper.instance;

  /// 创建预支记录
  Future<int> createAdvance(Advance advance) async {
    final db = await _db.database;
    return await db.insert('advances', advance.toMap());
  }

  /// 根据ID获取预支记录
  Future<Advance?> getAdvanceById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'advances',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Advance.fromMap(maps.first);
  }

  /// 获取用户的预支记录
  Future<List<Advance>> getUserAdvances(int userId) async {
    final db = await _db.database;
    final maps = await db.query(
      'advances',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'advance_at DESC',
    );

    return maps.map((map) => Advance.fromMap(map)).toList();
  }

  /// 获取用户的激活预支记录
  Future<List<Advance>> getUserActiveAdvances(int userId) async {
    final db = await _db.database;
    final maps = await db.query(
      'advances',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'active'],
      orderBy: 'due_date ASC',
    );

    return maps.map((map) => Advance.fromMap(map)).toList();
  }

  /// 更新预支记录
  Future<int> updateAdvance(Advance advance) async {
    final db = await _db.database;
    return await db.update(
      'advances',
      advance.toMap(),
      where: 'id = ?',
      whereArgs: [advance.id],
    );
  }

  /// 还款
  Future<int> repayAdvance(int advanceId) async {
    final db = await _db.database;
    return await db.update(
      'advances',
      {
        'status': 'repaid',
        'repaid_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [advanceId],
    );
  }

  /// 标记为逾期
  Future<int> markAsOverdue(int advanceId) async {
    final db = await _db.database;
    return await db.update(
      'advances',
      {
        'status': 'overdue',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [advanceId],
    );
  }

  /// 检查用户是否有未还清的预支
  Future<bool> hasActiveAdvances(int userId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM advances WHERE user_id = ? AND status = ?',
      [userId, 'active'],
    );

    return (result.first['count'] as int) > 0;
  }

  /// 获取用户预支统计
  Future<Map<String, dynamic>> getUserAdvanceStats(int userId) async {
    final db = await _db.database;

    // 总预支次数
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM advances WHERE user_id = ?',
      [userId],
    );
    final totalCount = countResult.first['count'] as int;

    // 总预支金额
    final amountResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM advances WHERE user_id = ?',
      [userId],
    );
    final totalAmount = amountResult.first['total'] as int? ?? 0;

    // 总利息支付
    final interestResult = await db.rawQuery(
      'SELECT SUM(interest_amount) as total FROM advances WHERE user_id = ? AND status = ?',
      [userId, 'repaid'],
    );
    final totalInterest = interestResult.first['total'] as int? ?? 0;

    // 激活预支数量
    final activeResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM advances WHERE user_id = ? AND status = ?',
      [userId, 'active'],
    );
    final activeCount = activeResult.first['count'] as int;

    // 逾期预支数量
    final overdueResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM advances WHERE user_id = ? AND status = ?',
      [userId, 'overdue'],
    );
    final overdueCount = overdueResult.first['count'] as int;

    return {
      'totalCount': totalCount,
      'totalAmount': totalAmount,
      'totalInterest': totalInterest,
      'activeCount': activeCount,
      'overdueCount': overdueCount,
    };
  }

  /// 获取即将到期的预支（3天内）
  Future<List<Advance>> getUpcomingDueAdvances(int userId) async {
    final db = await _db.database;
    final now = DateTime.now();
    final threeDaysLater = now.add(Duration(days: 3));

    final maps = await db.query(
      'advances',
      where: 'user_id = ? AND status = ? AND due_date <= ?',
      whereArgs: [userId, 'active', threeDaysLater.toIso8601String()],
      orderBy: 'due_date ASC',
    );

    return maps.map((map) => Advance.fromMap(map)).toList();
  }

  /// 检查并更新逾期记录
  Future<void> checkAndUpdateOverdueAdvances() async {
    final db = await _db.database;
    final now = DateTime.now();

    // 查找所有已逾期但状态仍为active的记录
    final maps = await db.query(
      'advances',
      where: 'status = ? AND due_date < ?',
      whereArgs: ['active', now.toIso8601String()],
    );

    // 更新为逾期状态
    for (var map in maps) {
      await markAsOverdue(map['id'] as int);
    }
  }

  /// 删除预支记录
  Future<int> deleteAdvance(int id) async {
    final db = await _db.database;
    return await db.delete(
      'advances',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
