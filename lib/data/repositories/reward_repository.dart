import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/reward.dart';

/// 奖励商品数据访问层
class RewardRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// 获取所有奖励商品
  Future<List<Reward>> getAllRewards() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rewards',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Reward.fromMap(maps[i]));
  }

  /// 获取激活的奖励商品
  Future<List<Reward>> getActiveRewards() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rewards',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Reward.fromMap(maps[i]));
  }

  /// 根据分类获取奖励商品
  Future<List<Reward>> getRewardsByCategory(String category) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rewards',
      where: 'category = ? AND status = ?',
      whereArgs: [category, 'active'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Reward.fromMap(maps[i]));
  }

  /// 获取热门商品
  Future<List<Reward>> getHotRewards() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rewards',
      where: 'is_hot = ? AND status = ?',
      whereArgs: [1, 'active'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Reward.fromMap(maps[i]));
  }

  /// 获取特惠商品
  Future<List<Reward>> getSpecialRewards() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rewards',
      where: 'is_special = ? AND status = ?',
      whereArgs: [1, 'active'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Reward.fromMap(maps[i]));
  }

  /// 根据ID获取奖励商品
  Future<Reward?> getRewardById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rewards',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Reward.fromMap(maps.first);
  }

  /// 搜索奖励商品
  Future<List<Reward>> searchRewards(String keyword) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rewards',
      where: 'status = ? AND (name LIKE ? OR description LIKE ? OR word_code LIKE ?)',
      whereArgs: [
        'active',
        '%$keyword%',
        '%$keyword%',
        '%$keyword%',
      ],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Reward.fromMap(maps[i]));
  }

  /// 创建奖励商品
  Future<int> createReward(Reward reward) async {
    final db = await _dbHelper.database;
    return await db.insert('rewards', reward.toMap());
  }

  /// 更新奖励商品
  Future<int> updateReward(Reward reward) async {
    if (reward.id == null) {
      throw ArgumentError('Reward id cannot be null for update');
    }
    final db = await _dbHelper.database;
    final updatedReward = reward.copyWith(updatedAt: DateTime.now());
    return await db.update(
      'rewards',
      updatedReward.toMap(),
      where: 'id = ?',
      whereArgs: [reward.id],
    );
  }

  /// 更新库存
  Future<int> updateStock(int rewardId, int newStock) async {
    final db = await _dbHelper.database;
    return await db.update(
      'rewards',
      {
        'stock': newStock,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [rewardId],
    );
  }

  /// 减少库存（兑换时使用）
  Future<int> decrementStock(int rewardId, {int quantity = 1}) async {
    final reward = await getRewardById(rewardId);
    if (reward == null) {
      throw ArgumentError('Reward not found with id: $rewardId');
    }

    // 无限库存不需要减少
    if (reward.stock == -1) return 0;

    final newStock = reward.stock - quantity;
    if (newStock < 0) {
      throw ArgumentError('Insufficient stock for reward: ${reward.name}');
    }

    return await updateStock(rewardId, newStock);
  }

  /// 更新奖励商品状态
  Future<int> updateRewardStatus(int rewardId, String status) async {
    final db = await _dbHelper.database;
    return await db.update(
      'rewards',
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [rewardId],
    );
  }

  /// 删除奖励商品
  Future<int> deleteReward(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'rewards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取奖励商品总数
  Future<int> getRewardCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM rewards');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取某个分类的商品数量
  Future<int> getRewardCountByCategory(String category) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM rewards WHERE category = ? AND status = ?',
      [category, 'active'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 检查用户是否有足够积分兑换
  Future<bool> canUserAfford(int userId, int rewardId) async {
    final reward = await getRewardById(rewardId);
    if (reward == null) return false;

    // 简单检查，实际应该通过UserRepository获取用户积分
    // 这里暂时返回true，后续在业务层进行真正的检查
    return true;
  }

  /// 获取所有词汇类型
  Future<List<String>> getAllWordTypes() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT word_type FROM rewards WHERE status = ?',
      ['active'],
    );
    return result
        .map((row) => row['word_type'] as String)
        .toList();
  }

  /// 获取所有分类
  Future<List<String>> getAllCategories() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT category FROM rewards WHERE status = ?',
      ['active'],
    );
    return result
        .map((row) => row['category'] as String)
        .toList();
  }
}
