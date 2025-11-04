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

  /// 获取所有奖励商品（包括未激活的）
  List<Reward> get rewards => _allRewards;

  /// 加载所有商品（包括未激活）
  Future<void> loadAllRewardsIncludingInactive() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allRewards = await _rewardRepository.getAllRewards();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '加载商品失败: $e';
      debugPrint('RewardProvider loadAllRewardsIncludingInactive error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 创建奖励商品
  Future<int?> createReward(Reward reward) async {
    try {
      final id = await _rewardRepository.createReward(reward);

      // 刷新列表
      await loadAllRewardsIncludingInactive();

      _errorMessage = null;
      return id;
    } catch (e) {
      _errorMessage = '创建商品失败: $e';
      debugPrint('RewardProvider createReward error: $e');
      notifyListeners();
      return null;
    }
  }

  /// 更新奖励商品
  Future<bool> updateReward(Reward reward) async {
    try {
      await _rewardRepository.updateReward(reward);

      // 刷新列表
      await loadAllRewardsIncludingInactive();

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = '更新商品失败: $e';
      debugPrint('RewardProvider updateReward error: $e');
      notifyListeners();
      return false;
    }
  }

  /// 删除奖励商品
  Future<bool> deleteReward(int id) async {
    try {
      await _rewardRepository.deleteReward(id);

      // 从列表中移除
      _allRewards.removeWhere((reward) => reward.id == id);

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '删除商品失败: $e';
      debugPrint('RewardProvider deleteReward error: $e');
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
