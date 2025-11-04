import 'package:flutter/material.dart';
import 'dart:math';
import '../data/models/slot_game_record.dart';
import '../data/database_helper.dart';
import '../data/repositories/user_repository.dart';

/// 老虎机游戏Provider
class SlotGameProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final UserRepository _userRepository = UserRepository();

  ///77777 调整中奖概率：修改这个列表可以改变各符号出现的概率
  /// 例如：如果想让7更容易出现，可以在列表中多次添加'7'
  /// 如：['0','1','2','3','4','5','6','7','7','7','8','9','💎','⭐','🍀']
  // 转盘选项
  static const List<String> slotItems = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    '💎', '⭐', '🍀'
  ];

  // 游戏状态
  bool _isPlaying = false;
  String _currentSlot1 = '7';
  String _currentSlot2 = '7';
  String _currentSlot3 = '7';

  // 今日游戏记录
  List<SlotGameRecord> _todayRecords = [];
  bool _isLoading = false;
  String? _errorMessage;

  ///77777 调整每日可玩次数：修改这里的数值即可（当前为10次）
  // 每日限制
  static const int dailyLimit =  10;

  // Getters
  bool get isPlaying => _isPlaying;
  String get currentSlot1 => _currentSlot1;
  String get currentSlot2 => _currentSlot2;
  String get currentSlot3 => _currentSlot3;
  List<SlotGameRecord> get todayRecords => _todayRecords;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get todayPlayCount => _todayRecords.length;
  int get remainingPlays => dailyLimit - todayPlayCount;
  bool get canPlay => remainingPlays > 0;

  /// 加载今日游戏记录
  Future<void> loadTodayRecords(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final db = await _db.database;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final maps = await db.query(
        'slot_game_records',
        where: 'user_id = ? AND created_at >= ? AND created_at < ?',
        whereArgs: [
          userId,
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String(),
        ],
        orderBy: 'created_at DESC',
      );

      _todayRecords = maps.map((map) => SlotGameRecord.fromMap(map)).toList();
    } catch (e) {
      _errorMessage = '加载游戏记录失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 开始游戏
  Future<Map<String, dynamic>> playGame(int userId, int currentPoints) async {
    if (!canPlay) {
      return {'success': false, 'message': '今日游戏次数已用完'};
    }

    if (currentPoints < 1) {
      return {'success': false, 'message': '积分不足，无法开始游戏'};
    }

    _isPlaying = true;
    notifyListeners();

    try {
      final db = await _db.database;
      final random = Random();

      ///77777 调整中奖概率：
      /// 当前为完全随机（每个符号概率相等）
      /// 如需调整概率，可以：
      /// 1. 修改 slotItems 列表（增加某个符号的数量来提高其出现概率）
      /// 2. 或者使用权重随机算法替换下面的 random.nextInt
      // 生成随机结果
      final result1 = slotItems[random.nextInt(slotItems.length)];
      final result2 = slotItems[random.nextInt(slotItems.length)];
      final result3 = slotItems[random.nextInt(slotItems.length)];

      _currentSlot1 = result1;
      _currentSlot2 = result2;
      _currentSlot3 = result3;

      // 判断中奖类型和奖励
      final prizeResult = _calculatePrize(result1, result2, result3);
      final prizeType = prizeResult['type'] as String;
      final reward = prizeResult['reward'] as int;

      // 计算最终积分
      final finalPoints = currentPoints - 1 + reward;

      // 1. 扣除1积分（投入）
      await db.insert('point_records', {
        'user_id': userId,
        'points': -1,
        'balance': currentPoints - 1,
        'type': 'spend',
        'source_type': 'slot_game',
        'description': '积分大富翁游戏投入',
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. 如果中奖，发放奖励
      if (reward > 0) {
        await db.insert('point_records', {
          'user_id': userId,
          'points': reward,
          'balance': finalPoints,
          'type': 'earn',
          'source_type': 'slot_game',
          'description': '积分大富翁中奖: ${prizeResult['name']}',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 3. 更新用户表的总积分
      await _userRepository.updateUserPoints(userId, finalPoints);

      // 4. 保存游戏记录
      final gameRecord = SlotGameRecord(
        userId: userId,
        result1: result1,
        result2: result2,
        result3: result3,
        reward: reward,
        prizeType: prizeType,
        createdAt: DateTime.now(),
      );

      await db.insert('slot_game_records', gameRecord.toMap());

      // 5. 刷新今日记录
      await loadTodayRecords(userId);

      _isPlaying = false;
      notifyListeners();

      return {
        'success': true,
        'result1': result1,
        'result2': result2,
        'result3': result3,
        'prizeType': prizeType,
        'prizeName': prizeResult['name'],
        'reward': reward,
        'netProfit': reward - 1, // 净收益
      };
    } catch (e) {
      _isPlaying = false;
      _errorMessage = '游戏出错: $e';
      notifyListeners();
      return {'success': false, 'message': '游戏出错: $e'};
    }
  }

  /// 计算中奖类型和奖励
  Map<String, dynamic> _calculatePrize(String r1, String r2, String r3) {
    // 超级大奖 777
    if (r1 == '7' && r2 == '7' && r3 == '7') {
      return {'type': 'jackpot777', 'name': '超级大奖 777', 'reward': 20};
    }

    // 钻石三连
    if (r1 == '💎' && r2 == '💎' && r3 == '💎') {
      return {'type': 'diamond', 'name': '钻石三连', 'reward': 15};
    }

    // 星星三连
    if (r1 == '⭐' && r2 == '⭐' && r3 == '⭐') {
      return {'type': 'star', 'name': '星星三连', 'reward': 10};
    }

    // 幸运三连
    if (r1 == '🍀' && r2 == '🍀' && r3 == '🍀') {
      return {'type': 'clover', 'name': '幸运三连', 'reward': 8};
    }

    // 三个相同数字（豹子）
    if (r1 == r2 && r2 == r3) {
      return {'type': 'triple', 'name': '豹子 $r1$r2$r3', 'reward': 5};
    }

    // 两个相同（对子）
    if (r1 == r2 || r2 == r3 || r1 == r3) {
      return {'type': 'double', 'name': '对子', 'reward': 2};
    }

    // 未中奖
    return {'type': 'none', 'name': '未中奖', 'reward': 0};
  }

  /// 重置错误消息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 测试用：公开的计算奖励方法（仅用于调试模式模拟中奖）
  Map<String, dynamic> calculatePrizeForTest(String r1, String r2, String r3) {
    return _calculatePrize(r1, r2, r3);
  }
}
