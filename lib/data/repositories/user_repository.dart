import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/user.dart';

/// 用户数据访问层
class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// 获取所有用户
  Future<List<User>> getAllUsers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      orderBy: 'id ASC',
    );
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  /// 根据ID获取用户
  Future<User?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  /// 根据角色获取用户列表
  Future<List<User>> getUsersByRole(String role) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: [role],
      orderBy: 'id ASC',
    );
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  /// 获取所有儿童用户
  Future<List<User>> getChildUsers() async {
    return getUsersByRole('child');
  }

  /// 获取所有管理员用户
  Future<List<User>> getAdminUsers() async {
    return getUsersByRole('admin');
  }

  /// 创建用户
  Future<int> createUser(User user) async {
    final db = await _dbHelper.database;
    return await db.insert('users', user.toMap());
  }

  /// 更新用户信息
  Future<int> updateUser(User user) async {
    if (user.id == null) {
      throw ArgumentError('User id cannot be null for update');
    }
    final db = await _dbHelper.database;
    final updatedUser = user.copyWith(updatedAt: DateTime.now());
    return await db.update(
      'users',
      updatedUser.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// 更新用户积分
  Future<int> updateUserPoints(int userId, int newPoints) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      {
        'total_points': newPoints,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// 增加用户积分
  Future<int> addUserPoints(int userId, int points) async {
    final user = await getUserById(userId);
    if (user == null) {
      throw ArgumentError('User not found with id: $userId');
    }
    final newPoints = user.totalPoints + points;
    return await updateUserPoints(userId, newPoints);
  }

  /// 减少用户积分
  Future<int> subtractUserPoints(int userId, int points) async {
    final user = await getUserById(userId);
    if (user == null) {
      throw ArgumentError('User not found with id: $userId');
    }
    final newPoints = user.totalPoints - points;
    return await updateUserPoints(userId, newPoints);
  }

  /// 删除用户
  Future<int> deleteUser(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 检查用户名是否存在
  Future<bool> isUsernameExists(String name, {int? excludeId}) async {
    final db = await _dbHelper.database;
    final whereClause = excludeId != null ? 'name = ? AND id != ?' : 'name = ?';
    final whereArgs =
        excludeId != null ? [name, excludeId] : [name];

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: whereClause,
      whereArgs: whereArgs,
    );
    return maps.isNotEmpty;
  }

  /// 获取用户总数
  Future<int> getUserCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取儿童用户总数
  Future<int> getChildUserCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE role = ?',
      ['child'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 验证用户密码（如果有设置密码）
  Future<bool> verifyPassword(int userId, String password) async {
    final user = await getUserById(userId);
    if (user == null) return false;
    if (user.password == null || user.password!.isEmpty) return true;
    return user.password == password;
  }

  /// 设置用户密码
  Future<int> setPassword(int userId, String password) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      {
        'password': password,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// 清除用户密码
  Future<int> clearPassword(int userId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      {
        'password': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
