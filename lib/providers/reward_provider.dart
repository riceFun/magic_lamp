import 'package:flutter/foundation.dart';
import '../data/models/reward.dart';
import '../data/repositories/reward_repository.dart';

/// 奖励商品状态管理
class RewardProvider extends ChangeNotifier {
  final RewardRepository _rewardRepository = RewardRepository();

  /// 所有奖励商品列表
  List<Reward> _allRewards = [];

  /// 加载状态
  bool _isLoading = false;

  /// 错误信息
  String? _errorMessage;

  // Getters
  List<Reward> get allRewards => _allRewards;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 获取激活的奖励商品
  List<Reward> get activeRewards =>
      _allRewards.where((r) => r.isAvailable).toList();

  /// 获取热门商品
  List<Reward> get hotRewards =>
      _allRewards.where((r) => r.isHot && r.isAvailable).toList();

  /// 获取特惠商品
  List<Reward> get specialRewards =>
      _allRewards.where((r) => r.isSpecial && r.isAvailable).toList();

  /// 加载所有奖励商品
  Future<void> loadAllRewards() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allRewards = await _rewardRepository.getActiveRewards();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '加载奖励商品失败: $e';
      debugPrint('RewardProvider loadAllRewards error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 根据分类筛选
  List<Reward> getRewardsByCategory(String category) {
    return _allRewards
        .where((r) => r.category == category && r.isAvailable)
        .toList();
  }

  /// 搜索奖励商品
  Future<List<Reward>> searchRewards(String keyword) async {
    try {
      return await _rewardRepository.searchRewards(keyword);
    } catch (e) {
      debugPrint('RewardProvider searchRewards error: $e');
      return [];
    }
  }

  /// 获取奖励商品详情
  Future<Reward?> getRewardById(int id) async {
    try {
      return await _rewardRepository.getRewardById(id);
    } catch (e) {
      debugPrint('RewardProvider getRewardById error: $e');
      return null;
    }
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
