import '../database_helper.dart';
import '../models/reward.dart';
import '../models/user_word.dart';

/// 兑换记录数据访问类
class ExchangeRepository {
  final _db = DatabaseHelper.instance;

  /// 创建兑换记录
  Future<int> createExchange(Exchange exchange) async {
    final db = await _db.database;
    return await db.insert('exchanges', exchange.toMap());
  }

  /// 根据ID获取兑换记录
  Future<Exchange?> getExchangeById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'exchanges',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Exchange.fromMap(maps.first);
  }

  /// 获取用户的兑换记录
  Future<List<Exchange>> getUserExchanges(int userId) async {
    final db = await _db.database;
    final maps = await db.query(
      'exchanges',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'exchanged_at DESC',
    );

    return maps.map((map) => Exchange.fromMap(map)).toList();
  }

  /// 获取奖励的兑换记录
  Future<List<Exchange>> getRewardExchanges(int rewardId) async {
    final db = await _db.database;
    final maps = await db.query(
      'exchanges',
      where: 'reward_id = ?',
      whereArgs: [rewardId],
      orderBy: 'exchanged_at DESC',
    );

    return maps.map((map) => Exchange.fromMap(map)).toList();
  }

  /// 更新兑换记录状态
  Future<int> updateExchangeStatus(int exchangeId, String status) async {
    final db = await _db.database;
    return await db.update(
      'exchanges',
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [exchangeId],
    );
  }

  /// 获取用户兑换统计
  Future<Map<String, int>> getUserExchangeStats(int userId) async {
    final db = await _db.database;

    // 总兑换次数
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM exchanges WHERE user_id = ?',
      [userId],
    );
    final totalCount = countResult.first['count'] as int;

    // 总消费积分
    final pointsResult = await db.rawQuery(
      'SELECT SUM(points_spent) as total FROM exchanges WHERE user_id = ?',
      [userId],
    );
    final totalPoints = pointsResult.first['total'] as int? ?? 0;

    // 待领取数量
    final pendingResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM exchanges WHERE user_id = ? AND status = ?',
      [userId, 'pending'],
    );
    final pendingCount = pendingResult.first['count'] as int;

    return {
      'totalCount': totalCount,
      'totalPoints': totalPoints,
      'pendingCount': pendingCount,
    };
  }

  /// 获取今日兑换记录
  Future<List<Exchange>> getTodayExchanges(int userId) async {
    final db = await _db.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    final maps = await db.query(
      'exchanges',
      where: 'user_id = ? AND exchanged_at >= ? AND exchanged_at < ?',
      whereArgs: [
        userId,
        today.toIso8601String(),
        tomorrow.toIso8601String(),
      ],
      orderBy: 'exchanged_at DESC',
    );

    return maps.map((map) => Exchange.fromMap(map)).toList();
  }
}

/// 用户词汇学习记录数据访问类
class UserWordRepository {
  final _db = DatabaseHelper.instance;

  /// 添加学习记录
  Future<int> createUserWord(UserWord userWord) async {
    final db = await _db.database;
    return await db.insert('user_words', userWord.toMap());
  }

  /// 检查词汇是否已学习
  Future<bool> hasLearnedWord(int userId, String word) async {
    final db = await _db.database;
    final maps = await db.query(
      'user_words',
      where: 'user_id = ? AND word = ?',
      whereArgs: [userId, word],
    );

    return maps.isNotEmpty;
  }

  /// 获取用户学习的词汇
  Future<List<UserWord>> getUserWords(int userId) async {
    final db = await _db.database;
    final maps = await db.query(
      'user_words',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'learned_at DESC',
    );

    return maps.map((map) => UserWord.fromMap(map)).toList();
  }

  /// 根据类型获取用户词汇
  Future<List<UserWord>> getUserWordsByType(int userId, String type) async {
    final db = await _db.database;
    final maps = await db.query(
      'user_words',
      where: 'user_id = ? AND word_type = ?',
      whereArgs: [userId, type],
      orderBy: 'learned_at DESC',
    );

    return maps.map((map) => UserWord.fromMap(map)).toList();
  }

  /// 获取用户学习统计
  Future<Map<String, int>> getUserWordStats(int userId) async {
    final db = await _db.database;

    // 总词汇数
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM user_words WHERE user_id = ?',
      [userId],
    );
    final totalCount = totalResult.first['count'] as int;

    // 中文成语数
    final chineseResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM user_words WHERE user_id = ? AND word_type = ?',
      [userId, 'chinese'],
    );
    final chineseCount = chineseResult.first['count'] as int;

    // 英文单词数
    final englishResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM user_words WHERE user_id = ? AND word_type = ?',
      [userId, 'english'],
    );
    final englishCount = englishResult.first['count'] as int;

    return {
      'totalCount': totalCount,
      'chineseCount': chineseCount,
      'englishCount': englishCount,
    };
  }

  /// 获取最近学习的词汇
  Future<List<UserWord>> getRecentWords(int userId, {int limit = 10}) async {
    final db = await _db.database;
    final maps = await db.query(
      'user_words',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'learned_at DESC',
      limit: limit,
    );

    return maps.map((map) => UserWord.fromMap(map)).toList();
  }

  /// 删除词汇学习记录
  Future<int> deleteUserWord(int id) async {
    final db = await _db.database;
    return await db.delete(
      'user_words',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
