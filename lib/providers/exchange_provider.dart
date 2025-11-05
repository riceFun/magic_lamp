import 'package:flutter/foundation.dart';
import '../data/models/reward.dart';
import '../data/models/point.dart';
import '../data/models/user_word.dart';
import '../data/repositories/exchange_repository.dart';
import '../data/repositories/point_record_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/reward_repository.dart';

/// 兑换状态管理
class ExchangeProvider with ChangeNotifier {
  final _exchangeRepository = ExchangeRepository();
  final _userWordRepository = UserWordRepository();
  final _pointRecordRepository = PointRecordRepository();
  final _userRepository = UserRepository();
  final _rewardRepository = RewardRepository();

  List<Exchange> _exchanges = [];
  List<UserWord> _userWords = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Exchange> get exchanges => _exchanges;
  List<UserWord> get userWords => _userWords;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 兑换奖励
  /// 返回兑换ID，失败返回null
  Future<int?> exchangeReward({
    required int userId,
    required int rewardId,
    String? note,
  }) async {
    try {
      // 获取奖励信息
      final reward = await _rewardRepository.getRewardById(rewardId);
      if (reward == null) {
        _errorMessage = '奖励不存在';
        notifyListeners();
        return null;
      }

      // 检查奖励是否激活
      if (reward.status != 'active') {
        _errorMessage = '该奖励已下架';
        notifyListeners();
        return null;
      }

      // 检查库存
      if (reward.stock != -1 && reward.stock <= 0) {
        _errorMessage = '该奖励已售罄';
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

      // 检查积分是否足够
      if (user.totalPoints < reward.points) {
        _errorMessage = '积分不足，还需 ${reward.points - user.totalPoints} 积分';
        notifyListeners();
        return null;
      }

      // 检查兑换频率和次数限制
      if (reward.exchangeFrequency != null || reward.maxExchangeCount != null) {
        final isAllowed = await _checkExchangeLimit(
          userId: userId,
          rewardId: rewardId,
          frequency: reward.exchangeFrequency,
          maxCount: reward.maxExchangeCount,
        );

        if (!isAllowed) {
          // _errorMessage 已在 _checkExchangeLimit 中设置
          notifyListeners();
          return null;
        }
      }

      // 扣除积分
      await _userRepository.subtractUserPoints(userId, reward.points);

      // 创建兑换记录
      final exchange = Exchange(
        userId: userId,
        rewardId: rewardId,
        rewardName: reward.name,
        pointsSpent: reward.points,
        wordCode: reward.wordCode,
        status: 'pending',
        exchangeAt: DateTime.now(),
        note: note,
      );

      final exchangeId = await _exchangeRepository.createExchange(exchange);

      // 创建积分记录
      final updatedUser = await _userRepository.getUserById(userId);
      if (updatedUser != null) {
        final pointRecord = PointRecord(
          userId: userId,
          type: 'spend',
          points: -reward.points,
          balance: updatedUser.totalPoints,
          sourceType: 'exchange',
          sourceId: exchangeId,
          description: '兑换：${reward.name}',
        );
        await _pointRecordRepository.createPointRecord(pointRecord);
      }

      // 减少库存（如果有库存限制）
      if (reward.stock != -1) {
        await _rewardRepository.updateReward(
          reward.copyWith(stock: reward.stock - 1),
        );
      }

      // 学习词汇
      if (reward.wordCode.isNotEmpty) {
        await _learnWord(
          userId: userId,
          wordCode: reward.wordCode,
          sourceType: 'exchange',
          sourceId: exchangeId,
        );
      }

      // 刷新兑换列表
      await loadUserExchanges(userId);

      _errorMessage = null;
      return exchangeId;
    } catch (e) {
      _errorMessage = '兑换失败：$e';
      notifyListeners();
      debugPrint('ExchangeProvider exchangeReward error: $e');
      return null;
    }
  }

  /// 判断词汇类型（根据字符判断是成语还是英文）
  String _determineWordType(String wordCode) {
    // 检查是否包含中文字符
    final chinesePattern = RegExp(r'[\u4e00-\u9fa5]');
    return chinesePattern.hasMatch(wordCode) ? 'idiom' : 'english';
  }

  /// 学习词汇
  Future<void> _learnWord({
    required int userId,
    required String wordCode,
    required String sourceType,
    required int sourceId,
  }) async {
    try {
      // 检查是否已学习
      final hasLearned = await _userWordRepository.hasLearnedWord(userId, wordCode);
      if (hasLearned) {
        debugPrint('Word already learned: $wordCode');
        return;
      }

      // 自动判断词汇类型
      final wordType = _determineWordType(wordCode);

      // 创建学习记录
      final userWord = UserWord(
        userId: userId,
        wordCode: wordCode,
        wordType: wordType,
        learnedAt: DateTime.now(),
        sourceType: sourceType,
        sourceId: sourceId,
      );

      await _userWordRepository.createUserWord(userWord);

      // 刷新词汇列表
      await loadUserWords(userId);
    } catch (e) {
      debugPrint('ExchangeProvider _learnWord error: $e');
    }
  }

  /// 加载用户兑换记录
  Future<void> loadUserExchanges(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _exchanges = await _exchangeRepository.getUserExchanges(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载兑换记录失败：$e';
      _isLoading = false;
      notifyListeners();
      debugPrint('ExchangeProvider loadUserExchanges error: $e');
    }
  }

  /// 加载用户学习的词汇
  Future<void> loadUserWords(int userId) async {
    try {
      _userWords = await _userWordRepository.getUserWords(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载词汇列表失败：$e';
      notifyListeners();
      debugPrint('ExchangeProvider loadUserWords error: $e');
    }
  }

  /// 更新兑换状态
  Future<bool> updateExchangeStatus(int exchangeId, String status) async {
    try {
      final count = await _exchangeRepository.updateExchangeStatus(exchangeId, status);
      if (count > 0) {
        // 更新本地列表
        final index = _exchanges.indexWhere((e) => e.id == exchangeId);
        if (index != -1) {
          _exchanges[index] = _exchanges[index].copyWith(status: status);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = '更新状态失败：$e';
      notifyListeners();
      debugPrint('ExchangeProvider updateExchangeStatus error: $e');
      return false;
    }
  }

  /// 获取兑换统计
  Future<Map<String, int>> getExchangeStats(int userId) async {
    try {
      return await _exchangeRepository.getUserExchangeStats(userId);
    } catch (e) {
      debugPrint('ExchangeProvider getExchangeStats error: $e');
      return {
        'totalCount': 0,
        'totalPoints': 0,
        'pendingCount': 0,
      };
    }
  }

  /// 获取词汇学习统计
  Future<Map<String, int>> getWordStats(int userId) async {
    try {
      return await _userWordRepository.getUserWordStats(userId);
    } catch (e) {
      debugPrint('ExchangeProvider getWordStats error: $e');
      return {
        'totalCount': 0,
        'chineseCount': 0,
        'englishCount': 0,
      };
    }
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 检查用户是否可以兑换指定奖励（考虑积分、频率、次数等所有限制）
  /// 返回 true 表示可以兑换，false 表示不可以兑换
  Future<bool> canUserExchangeReward({
    required int userId,
    required int rewardId,
    required int userPoints,
    required int requiredPoints,
    String? exchangeFrequency,
    int? maxExchangeCount,
  }) async {
    try {
      // 首先检查积分是否足够
      if (userPoints < requiredPoints) {
        return false;
      }

      // 如果没有频率和次数限制，直接返回 true
      if (exchangeFrequency == null && maxExchangeCount == null) {
        return true;
      }

      // 检查频率和次数限制
      return await _checkExchangeLimit(
        userId: userId,
        rewardId: rewardId,
        frequency: exchangeFrequency,
        maxCount: maxExchangeCount,
      );
    } catch (e) {
      debugPrint('ExchangeProvider canUserExchangeReward error: $e');
      return false;
    }
  }

  /// 检查兑换频率和次数限制
  /// 返回 true 表示允许兑换，false 表示不允许
  Future<bool> _checkExchangeLimit({
    required int userId,
    required int rewardId,
    String? frequency,
    int? maxCount,
  }) async {
    // 如果没有限制，直接允许
    if (frequency == null && maxCount == null) {
      return true;
    }

    // 计算时间范围
    final now = DateTime.now();
    final (startTime, endTime) = _calculatePeriodRange(now, frequency);

    // 查询该时间段内的兑换记录
    final exchanges = await _exchangeRepository.getUserRewardExchangesInRange(
      userId: userId,
      rewardId: rewardId,
      startTime: startTime,
      endTime: endTime,
    );

    final exchangeCount = exchanges.length;

    // 检查是否超过最大次数限制
    if (maxCount != null && exchangeCount >= maxCount) {
      final periodText = _getPeriodText(frequency);
      _errorMessage = '该商品$periodText最多兑换 $maxCount 次，您已兑换 $exchangeCount 次';
      return false;
    }

    return true;
  }

  /// 根据频率计算时间范围
  /// 返回 (startTime, endTime)
  (DateTime, DateTime) _calculatePeriodRange(DateTime now, String? frequency) {
    if (frequency == null) {
      // 如果没有频率限制，返回一个很大的时间范围（从很久之前到现在）
      return (DateTime(2000, 1, 1), now);
    }

    switch (frequency) {
      case 'daily':
        // 今天 00:00:00 到明天 00:00:00
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(Duration(days: 1));
        return (today, tomorrow);

      case 'weekly':
        // 本周一 00:00:00 到下周一 00:00:00
        final weekday = now.weekday; // 1=周一, 7=周日
        final monday = now.subtract(Duration(days: weekday - 1));
        final thisMonday = DateTime(monday.year, monday.month, monday.day);
        final nextMonday = thisMonday.add(Duration(days: 7));
        return (thisMonday, nextMonday);

      case 'monthly':
        // 本月1号 00:00:00 到下月1号 00:00:00
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        final firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);
        return (firstDayOfMonth, firstDayOfNextMonth);

      case 'quarterly':
        // 本季度第一天到下季度第一天
        final currentQuarter = ((now.month - 1) ~/ 3) + 1; // 1-4
        final firstMonthOfQuarter = (currentQuarter - 1) * 3 + 1;
        final firstDayOfQuarter = DateTime(now.year, firstMonthOfQuarter, 1);
        final firstDayOfNextQuarter = DateTime(now.year, firstMonthOfQuarter + 3, 1);
        return (firstDayOfQuarter, firstDayOfNextQuarter);

      case 'yearly':
        // 今年1月1日 00:00:00 到明年1月1日 00:00:00
        final firstDayOfYear = DateTime(now.year, 1, 1);
        final firstDayOfNextYear = DateTime(now.year + 1, 1, 1);
        return (firstDayOfYear, firstDayOfNextYear);

      default:
        // 未知频率，返回一个很大的时间范围
        return (DateTime(2000, 1, 1), now);
    }
  }

  /// 获取周期文本描述
  String _getPeriodText(String? frequency) {
    switch (frequency) {
      case 'daily':
        return '每日';
      case 'weekly':
        return '每周';
      case 'monthly':
        return '每月';
      case 'quarterly':
        return '每季度';
      case 'yearly':
        return '每年';
      default:
        return '';
    }
  }
}
