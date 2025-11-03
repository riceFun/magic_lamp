/// 积分记录模型
class PointRecord {
  final int? id;
  final int userId;
  final String type; // 'earn' 或 'spend'
  final int points; // 积分变动数量（正数表示增加，负数表示减少）
  final int balance; // 变动后的积分余额
  final String sourceType; // 'task', 'exchange', 'advance', 'adjustment', 'bonus'
  final int? sourceId; // 来源记录ID
  final String? description;
  final DateTime createdAt;

  PointRecord({
    this.id,
    required this.userId,
    required this.type,
    required this.points,
    required this.balance,
    required this.sourceType,
    this.sourceId,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 是否是收入
  bool get isEarn => type == 'earn';

  /// 是否是支出
  bool get isSpend => type == 'spend';

  /// 从数据库Map创建PointRecord对象
  factory PointRecord.fromMap(Map<String, dynamic> map) {
    return PointRecord(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      type: map['type'] as String,
      points: map['points'] as int,
      balance: map['balance'] as int,
      sourceType: map['source_type'] as String,
      sourceId: map['source_id'] as int?,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'type': type,
      'points': points,
      'balance': balance,
      'source_type': sourceType,
      'source_id': sourceId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PointRecord{id: $id, type: $type, points: $points, balance: $balance}';
  }
}

/// 预支记录模型
class Advance {
  final int? id;
  final int userId;
  final int amount; // 预支金额
  final double interestRate; // 利率
  final int interestAmount; // 利息金额
  final int totalAmount; // 总还款金额
  final String status; // 'active', 'repaid', 'overdue'
  final DateTime advanceAt; // 预支时间
  final DateTime dueDate; // 到期时间
  final DateTime? repaidAt; // 还款时间
  final DateTime createdAt;
  final DateTime updatedAt;

  Advance({
    this.id,
    required this.userId,
    required this.amount,
    required this.interestRate,
    required this.interestAmount,
    required this.totalAmount,
    this.status = 'active',
    required this.advanceAt,
    required this.dueDate,
    this.repaidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 是否激活中
  bool get isActive => status == 'active';

  /// 是否已还清
  bool get isRepaid => status == 'repaid';

  /// 是否已逾期
  bool get isOverdue => status == 'overdue' || (isActive && DateTime.now().isAfter(dueDate));

  /// 剩余天数
  int get daysRemaining {
    if (isRepaid) return 0;
    final now = DateTime.now();
    if (now.isAfter(dueDate)) return 0;
    return dueDate.difference(now).inDays;
  }

  /// 从数据库Map创建Advance对象
  factory Advance.fromMap(Map<String, dynamic> map) {
    return Advance(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      amount: map['amount'] as int,
      interestRate: map['interest_rate'] as double,
      interestAmount: map['interest_amount'] as int,
      totalAmount: map['total_amount'] as int,
      status: map['status'] as String? ?? 'active',
      advanceAt: DateTime.parse(map['advance_at'] as String),
      dueDate: DateTime.parse(map['due_date'] as String),
      repaidAt: map['repaid_at'] != null
          ? DateTime.parse(map['repaid_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'amount': amount,
      'interest_rate': interestRate,
      'interest_amount': interestAmount,
      'total_amount': totalAmount,
      'status': status,
      'advance_at': advanceAt.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'repaid_at': repaidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分属性
  Advance copyWith({
    int? id,
    int? userId,
    int? amount,
    double? interestRate,
    int? interestAmount,
    int? totalAmount,
    String? status,
    DateTime? advanceAt,
    DateTime? dueDate,
    DateTime? repaidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Advance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      interestRate: interestRate ?? this.interestRate,
      interestAmount: interestAmount ?? this.interestAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      advanceAt: advanceAt ?? this.advanceAt,
      dueDate: dueDate ?? this.dueDate,
      repaidAt: repaidAt ?? this.repaidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Advance{id: $id, amount: $amount, totalAmount: $totalAmount, status: $status}';
  }
}
