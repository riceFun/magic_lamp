import 'package:flutter/foundation.dart';
import '../data/models/penalty.dart';
import '../data/models/point.dart';
import '../data/repositories/penalty_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/point_record_repository.dart';

/// 惩罚状态管理
class PenaltyProvider extends ChangeNotifier {
  final PenaltyRepository _penaltyRepository = PenaltyRepository();
  final UserRepository _userRepository = UserRepository();
  final PointRecordRepository _pointRecordRepository = PointRecordRepository();

  /// 所有惩罚项目列表
  List<Penalty> _allPenalties = [];

  /// 惩罚记录列表
  List<PenaltyRecord> _penaltyRecords = [];

  /// 加载状态
  bool _isLoading = false;

  /// 错误信息
  String? _errorMessage;

  // Getters
  List<Penalty> get allPenalties => _allPenalties;
  List<PenaltyRecord> get penaltyRecords => _penaltyRecords;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 获取激活的惩罚项目
  List<Penalty> get activePenalties =>
      _allPenalties.where((p) => p.isActive).toList();

  /// 加载所有激活的惩罚项目
  Future<void> loadActivePenalties() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allPenalties = await _penaltyRepository.getActivePenalties();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '加载惩罚项目失败: $e';
      debugPrint('PenaltyProvider loadActivePenalties error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载所有惩罚项目（包括未激活）
  Future<void> loadAllPenalties() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allPenalties = await _penaltyRepository.getAllPenalties();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '加载惩罚项目失败: $e';
      debugPrint('PenaltyProvider loadAllPenalties error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 根据分类筛选
  List<Penalty> getPenaltiesByCategory(String category) {
    return _allPenalties
        .where((p) => p.category == category && p.isActive)
        .toList();
  }

  /// 获取惩罚项目详情
  Future<Penalty?> getPenaltyById(int id) async {
    try {
      return await _penaltyRepository.getPenaltyById(id);
    } catch (e) {
      debugPrint('PenaltyProvider getPenaltyById error: $e');
      return null;
    }
  }

  /// 创建惩罚项目
  Future<int?> createPenalty(Penalty penalty) async {
    try {
      final id = await _penaltyRepository.createPenalty(penalty);

      // 刷新列表
      await loadAllPenalties();

      _errorMessage = null;
      return id;
    } catch (e) {
      _errorMessage = '创建惩罚项目失败: $e';
      debugPrint('PenaltyProvider createPenalty error: $e');
      notifyListeners();
      return null;
    }
  }

  /// 更新惩罚项目
  Future<bool> updatePenalty(Penalty penalty) async {
    try {
      final count = await _penaltyRepository.updatePenalty(penalty);

      // 刷新列表
      await loadAllPenalties();

      _errorMessage = null;
      return count > 0;
    } catch (e) {
      _errorMessage = '更新惩罚项目失败: $e';
      debugPrint('PenaltyProvider updatePenalty error: $e');
      notifyListeners();
      return false;
    }
  }

  /// 删除惩罚项目
  Future<bool> deletePenalty(int id) async {
    try {
      final count = await _penaltyRepository.deletePenalty(id);

      // 刷新列表
      await loadAllPenalties();

      _errorMessage = null;
      return count > 0;
    } catch (e) {
      _errorMessage = '删除惩罚项目失败: $e';
      debugPrint('PenaltyProvider deletePenalty error: $e');
      notifyListeners();
      return false;
    }
  }

  /// 执行惩罚（扣除积分并创建记录）
  Future<int?> applyPenalty({
    required int userId,
    required int penaltyId,
    String? reason,
  }) async {
    try {
      // 获取惩罚项目信息
      final penalty = await _penaltyRepository.getPenaltyById(penaltyId);
      if (penalty == null) {
        _errorMessage = '惩罚项目不存在';
        notifyListeners();
        return null;
      }

      // 检查惩罚项目是否激活
      if (penalty.status != 'active') {
        _errorMessage = '该惩罚项目已停用';
        notifyListeners();
        return null;
      }

      // 获取用户信息
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        _errorMessage = '用户不存在';
        notifyListeners();
        return null;
      }

      // 扣除积分（即使积分不足也要扣除，积分可以为负数）
      await _userRepository.subtractUserPoints(userId, penalty.points);

      // 创建惩罚记录
      final penaltyRecord = PenaltyRecord(
        userId: userId,
        penaltyId: penaltyId,
        penaltyName: penalty.name,
        pointsDeducted: penalty.points,
        reason: reason,
      );
      final recordId = await _penaltyRepository.applyPenalty(penaltyRecord);

      // 创建积分记录
      final updatedUser = await _userRepository.getUserById(userId);
      if (updatedUser != null) {
        final pointRecord = PointRecord(
          userId: userId,
          type: 'penalty',
          points: -penalty.points,
          balance: updatedUser.totalPoints,
          sourceType: 'penalty',
          sourceId: recordId,
          description: '惩罚：${penalty.name}${reason != null ? "（$reason）" : ""}',
        );
        await _pointRecordRepository.createPointRecord(pointRecord);
      }

      // 刷新惩罚记录列表
      await loadUserPenaltyRecords(userId);

      _errorMessage = null;
      return recordId;
    } catch (e) {
      _errorMessage = '执行惩罚失败：$e';
      debugPrint('PenaltyProvider applyPenalty error: $e');
      notifyListeners();
      return null;
    }
  }

  /// 加载用户的惩罚记录
  Future<void> loadUserPenaltyRecords(int userId) async {
    try {
      _penaltyRecords = await _penaltyRepository.getUserPenaltyRecords(userId);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载惩罚记录失败: $e';
      debugPrint('PenaltyProvider loadUserPenaltyRecords error: $e');
      notifyListeners();
    }
  }

  /// 获取用户惩罚统计
  Future<Map<String, int>> getUserPenaltyStats(int userId) async {
    try {
      return await _penaltyRepository.getUserPenaltyStats(userId);
    } catch (e) {
      debugPrint('PenaltyProvider getUserPenaltyStats error: $e');
      return {
        'totalPoints': 0,
        'totalCount': 0,
        'monthPoints': 0,
      };
    }
  }

  /// 获取惩罚分类统计
  Future<Map<String, int>> getPenaltyCategoryStats(int userId) async {
    try {
      return await _penaltyRepository.getPenaltyCategoryStats(userId);
    } catch (e) {
      debugPrint('PenaltyProvider getPenaltyCategoryStats error: $e');
      return {};
    }
  }

  /// 搜索惩罚项目
  Future<List<Penalty>> searchPenalties(String keyword) async {
    try {
      return await _penaltyRepository.searchPenalties(keyword);
    } catch (e) {
      debugPrint('PenaltyProvider searchPenalties error: $e');
      return [];
    }
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 获取惩罚项目的使用次数
  Future<int> getPenaltyUsageCount(int penaltyId) async {
    try {
      return await _penaltyRepository.getPenaltyUsageCount(penaltyId);
    } catch (e) {
      debugPrint('PenaltyProvider getPenaltyUsageCount error: $e');
      return 0;
    }
  }
}
