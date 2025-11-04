/// 老虎机游戏记录模型
class SlotGameRecord {
  final int? id;
  final int userId;
  final String result1; // 第一个转盘结果
  final String result2; // 第二个转盘结果
  final String result3; // 第三个转盘结果
  final int reward; // 奖励积分（0表示未中奖）
  final String prizeType; // 中奖类型：jackpot777, diamond, star, clover, triple, double, none
  final DateTime createdAt;

  SlotGameRecord({
    this.id,
    required this.userId,
    required this.result1,
    required this.result2,
    required this.result3,
    required this.reward,
    required this.prizeType,
    required this.createdAt,
  });

  /// 从数据库映射创建实例
  factory SlotGameRecord.fromMap(Map<String, dynamic> map) {
    return SlotGameRecord(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      result1: map['result1'] as String,
      result2: map['result2'] as String,
      result3: map['result3'] as String,
      reward: map['reward'] as int,
      prizeType: map['prize_type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'result1': result1,
      'result2': result2,
      'result3': result3,
      'reward': reward,
      'prize_type': prizeType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 获取中奖类型的显示名称
  String getPrizeTypeName() {
    switch (prizeType) {
      case 'jackpot777':
        return '超级大奖 777';
      case 'diamond':
        return '钻石三连';
      case 'star':
        return '星星三连';
      case 'clover':
        return '幸运三连';
      case 'triple':
        return '豹子';
      case 'double':
        return '对子';
      default:
        return '未中奖';
    }
  }
}
