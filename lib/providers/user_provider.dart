import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user.dart';
import '../data/repositories/user_repository.dart';
import '../config/constants.dart';

/// 用户状态管理
class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();

  /// 当前登录的用户
  User? _currentUser;

  /// 所有用户列表
  List<User> _allUsers = [];

  /// 加载状态
  bool _isLoading = false;

  /// 错误信息
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  List<User> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  // bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isChild => _currentUser?.isChild ?? true;

  /// 初始化 - 从SharedPreferences恢复登录状态
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(AppConstants.keyCurrentUserId);

      if (userId != null) {
        _currentUser = await _userRepository.getUserById(userId);
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = '初始化失败: $e';
      debugPrint('UserProvider init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载所有用户
  Future<void> loadAllUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allUsers = await _userRepository.getAllUsers();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '加载用户列表失败: $e';
      debugPrint('UserProvider loadAllUsers error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取所有用户（如果列表为空则加载）
  Future<List<User>> getAllUsers() async {
    if (_allUsers.isEmpty) {
      await loadAllUsers();
    }
    return _allUsers;
  }

  /// 用户登录
  Future<bool> login(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        _errorMessage = '用户不存在';
        return false;
      }

      _currentUser = user;

      // 保存登录状态到SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.keyCurrentUserId, userId);

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = '登录失败: $e';
      debugPrint('UserProvider login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 用户登出
  Future<void> logout() async {
    _currentUser = null;

    // 清除SharedPreferences中的登录状态
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyCurrentUserId);

    notifyListeners();
  }

  /// 创建新用户
  Future<int?> createUser({
    required String name,
    String? avatar,
    String role = 'child',
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 检查用户名是否已存在
      final exists = await _userRepository.isUsernameExists(name);
      if (exists) {
        _errorMessage = '用户名已存在';
        return null;
      }

      final user = User(
        name: name,
        avatar: avatar,
        role: role,
        password: password,
      );

      final userId = await _userRepository.createUser(user);

      // 重新加载用户列表
      await loadAllUsers();

      _errorMessage = null;
      return userId;
    } catch (e) {
      _errorMessage = '创建用户失败: $e';
      debugPrint('UserProvider createUser error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 更新当前用户信息
  Future<bool> updateCurrentUser({
    String? name,
    String? avatar,
    String? password,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name,
        avatar: avatar,
        password: password,
      );

      await _userRepository.updateUser(updatedUser);
      _currentUser = updatedUser;

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = '更新用户信息失败: $e';
      debugPrint('UserProvider updateCurrentUser error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 刷新当前用户数据（从数据库重新加载）
  Future<void> refreshCurrentUser() async {
    if (_currentUser?.id == null) return;

    try {
      final user = await _userRepository.getUserById(_currentUser!.id!);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('UserProvider refreshCurrentUser error: $e');
    }
  }

  /// 更新用户积分（内部使用）
  Future<void> _updatePoints(int points) async {
    if (_currentUser == null) return;

    try {
      await _userRepository.updateUserPoints(_currentUser!.id!, points);
      await refreshCurrentUser();
    } catch (e) {
      debugPrint('UserProvider _updatePoints error: $e');
      rethrow;
    }
  }

  /// 增加积分
  Future<void> addPoints(int points) async {
    if (_currentUser == null) return;
    final newPoints = _currentUser!.totalPoints + points;
    await _updatePoints(newPoints);
  }

  /// 减少积分
  Future<void> subtractPoints(int points) async {
    if (_currentUser == null) return;
    final newPoints = _currentUser!.totalPoints - points;
    await _updatePoints(newPoints);
  }

  /// 检查是否有足够积分
  bool hasEnoughPoints(int requiredPoints) {
    if (_currentUser == null) return false;
    return _currentUser!.totalPoints >= requiredPoints;
  }

  /// 更新用户信息（通用方法）
  Future<bool> updateUser(User user) async {
    try {
      await _userRepository.updateUser(user);

      // 如果更新的是当前用户，同步更新currentUser
      if (_currentUser?.id == user.id) {
        _currentUser = user;
      }

      // 刷新用户列表
      if (_allUsers.isNotEmpty) {
        final index = _allUsers.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _allUsers[index] = user;
        }
      }

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '更新用户失败: $e';
      debugPrint('UserProvider updateUser error: $e');
      notifyListeners();
      return false;
    }
  }

  /// 删除用户
  Future<bool> deleteUser(int userId) async {
    // 不能删除当前登录的用户
    if (_currentUser?.id == userId) {
      _errorMessage = '不能删除当前登录的用户';
      notifyListeners();
      return false;
    }

    try {
      await _userRepository.deleteUser(userId);

      // 从用户列表中移除
      _allUsers.removeWhere((user) => user.id == userId);

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '删除用户失败: $e';
      debugPrint('UserProvider deleteUser error: $e');
      notifyListeners();
      return false;
    }
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
