import 'package:flutter/foundation.dart';
import '../data/models/point.dart';
import '../data/repositories/advance_repository.dart';
import '../data/repositories/point_record_repository.dart';
import '../data/repositories/user_repository.dart';
import '../config/constants.dart';

/// 预支积分状态管理
class AdvanceProvider with ChangeNotifier {
  final _advanceRepository = AdvanceRepository();
  final _pointRecordRepository = PointRecordRepository();
  final _userRepository = UserRepository();

  List<Advance> _advances = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Advance> get advances => _advances;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 获取激活的预支
  List<Advance> get activeAdvances =>
      _advances.where((advance) => advance.isActive).toList();

  /// 获取逾期的预支
  List<Advance> get overdueAdvances =>
      _advances.where((advance) => advance.isOverdue).toList();

  /// 申请预支积分
  /// amount: 预支金额
  /// days: 预支天数（7、10、30天）
  /// interestRate: 日利率（小数，例如 0.01 表示 1%）
  /// 返回预支ID，失败返回null
  Future<int?> applyAdvance({
    required int userId,
    required int amount,
    required int days,
    required double interestRate,
  }) async {
    try {
      // 检查是否有未还清的预支
      final hasActive = await _advanceRepository.hasActiveAdvances(userId);
      if (hasActive) {
        _errorMessage = '你还有未还清的预支，请先还清后再申请';
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

      // 检查预支金额是否合理（不超过10000积分）
      if (amount > AppConstants.advanceMaxAmount) {
        _errorMessage = '预支金额不能超过${AppConstants.advanceMaxAmount}积分';
        notifyListeners();
        return null;
      }

      // 检查还款周期
      if (!AppConstants.advanceRepaymentDays.contains(days)) {
        _errorMessage = '还款周期仅支持7天、10天和30天';
        notifyListeners();
        return null;
      }

      // 检查利率范围（0.01% - 100%）
      final interestRatePercent = interestRate * 100;
      if (interestRatePercent <
              AppConstants.advanceMinDailyInterestRatePercent ||
          interestRatePercent >
              AppConstants.advanceMaxDailyInterestRatePercent) {
        _errorMessage =
            '日利率需在${AppConstants.advanceMinDailyInterestRatePercent}%到${AppConstants.advanceMaxDailyInterestRatePercent}%之间';
        notifyListeners();
        return null;
      }

      // 计算利息（按日单利）
      final interestAmount = (amount * interestRate * days).round();
      final totalAmount = amount + interestAmount;

      // 计算到期日期
      final advanceAt = DateTime.now();
      final dueDate = advanceAt.add(Duration(days: days));

      // 创建预支记录
      final advance = Advance(
        userId: userId,
        amount: amount,
        interestRate: interestRate,
        interestAmount: interestAmount,
        totalAmount: totalAmount,
        status: 'active',
        advanceAt: advanceAt,
        dueDate: dueDate,
      );

      final advanceId = await _advanceRepository.createAdvance(advance);

      // 增加用户积分
      await _userRepository.addUserPoints(userId, amount);

      // 创建积分记录
      final updatedUser = await _userRepository.getUserById(userId);
      if (updatedUser != null) {
        final pointRecord = PointRecord(
          userId: userId,
          type: 'earn',
          points: amount,
          balance: updatedUser.totalPoints,
          sourceType: 'advance',
          sourceId: advanceId,
          description:
              '预支积分（$days天，日利率${interestRatePercent.toStringAsFixed(2)}%，利息$interestAmount）',
        );
        await _pointRecordRepository.createPointRecord(pointRecord);
      }

      // 刷新预支列表
      await loadUserAdvances(userId);

      _errorMessage = null;
      return advanceId;
    } catch (e) {
      _errorMessage = '申请预支失败：$e';
      notifyListeners();
      debugPrint('AdvanceProvider applyAdvance error: $e');
      return null;
    }
  }

  /// 还款
  Future<bool> repayAdvance(int advanceId, int userId) async {
    try {
      // 获取预支记录
      final advance = await _advanceRepository.getAdvanceById(advanceId);
      if (advance == null) {
        _errorMessage = '预支记录不存在';
        notifyListeners();
        return false;
      }

      // 检查是否已还款
      if (advance.isRepaid) {
        _errorMessage = '该预支已还清';
        notifyListeners();
        return false;
      }

      // 获取用户信息
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        _errorMessage = '用户不存在';
        notifyListeners();
        return false;
      }

      // 检查积分是否足够还款
      if (user.totalPoints < advance.totalAmount) {
        _errorMessage = '积分不足，还需 ${advance.totalAmount - user.totalPoints} 积分';
        notifyListeners();
        return false;
      }

      // 扣除积分
      await _userRepository.subtractUserPoints(userId, advance.totalAmount);

      // 更新预支状态为已还清
      await _advanceRepository.repayAdvance(advanceId);

      // 创建积分记录
      final updatedUser = await _userRepository.getUserById(userId);
      if (updatedUser != null) {
        final pointRecord = PointRecord(
          userId: userId,
          type: 'spend',
          points: -advance.totalAmount,
          balance: updatedUser.totalPoints,
          sourceType: 'advance',
          sourceId: advanceId,
          description: '还款（本金${advance.amount}+利息${advance.interestAmount}）',
        );
        await _pointRecordRepository.createPointRecord(pointRecord);
      }

      // 刷新预支列表
      await loadUserAdvances(userId);

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = '还款失败：$e';
      notifyListeners();
      debugPrint('AdvanceProvider repayAdvance error: $e');
      return false;
    }
  }

  /// 加载用户预支记录
  Future<void> loadUserAdvances(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 先检查并更新逾期记录
      await _advanceRepository.checkAndUpdateOverdueAdvances();

      _advances = await _advanceRepository.getUserAdvances(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载预支记录失败：$e';
      _isLoading = false;
      notifyListeners();
      debugPrint('AdvanceProvider loadUserAdvances error: $e');
    }
  }

  /// 获取即将到期的预支
  Future<List<Advance>> getUpcomingDueAdvances(int userId) async {
    try {
      return await _advanceRepository.getUpcomingDueAdvances(userId);
    } catch (e) {
      debugPrint('AdvanceProvider getUpcomingDueAdvances error: $e');
      return [];
    }
  }

  /// 获取预支统计
  Future<Map<String, dynamic>> getAdvanceStats(int userId) async {
    try {
      return await _advanceRepository.getUserAdvanceStats(userId);
    } catch (e) {
      debugPrint('AdvanceProvider getAdvanceStats error: $e');
      return {
        'totalCount': 0,
        'totalAmount': 0,
        'totalInterest': 0,
        'activeCount': 0,
        'overdueCount': 0,
      };
    }
  }

  /// 计算预支金额的利息
  static int calculateInterest(int amount, double interestRate, int days) {
    return (amount * interestRate * days).round();
  }

  /// 计算总还款金额
  static int calculateTotalAmount(int amount, double interestRate, int days) {
    return amount + calculateInterest(amount, interestRate, days);
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
