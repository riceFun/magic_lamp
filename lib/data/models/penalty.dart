/// 惩罚项目模型
class Penalty {
  final int? id;
  final String name;
  final String? description;
  final int points; // 扣除的积分数（正数表示扣除）
  final String? icon; // emoji 图标
  final String category; // 'behavior', 'hygiene', 'study', 'language', 'other'
  final String status; // 'active', 'inactive'
  final String? note; // 备注
  final DateTime createdAt;
  final DateTime updatedAt;

  Penalty({
    this.id,
    required this.name,
    this.description,
    required this.points,
    this.icon,
    required this.category,
    this.status = 'active',
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 是否激活
  bool get isActive => status == 'active';

  /// 从数据库Map创建Penalty对象
  factory Penalty.fromMap(Map<String, dynamic> map) {
    return Penalty(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      points: map['points'] as int,
      icon: map['icon'] as String?,
      category: map['category'] as String,
      status: map['status'] as String? ?? 'active',
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'points': points,
      'icon': icon,
      'category': category,
      'status': status,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  Penalty copyWith({
    int? id,
    String? name,
    String? description,
    int? points,
    String? icon,
    String? category,
    String? status,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Penalty(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      points: points ?? this.points,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 惩罚记录模型
class PenaltyRecord {
  final int? id;
  final int userId;
  final int penaltyId;
  final String penaltyName;
  final int pointsDeducted; // 扣除的积分数
  final String? reason; // 具体原因（可选）
  final DateTime createdAt;

  PenaltyRecord({
    this.id,
    required this.userId,
    required this.penaltyId,
    required this.penaltyName,
    required this.pointsDeducted,
    this.reason,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从数据库Map创建PenaltyRecord对象
  factory PenaltyRecord.fromMap(Map<String, dynamic> map) {
    return PenaltyRecord(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      penaltyId: map['penalty_id'] as int,
      penaltyName: map['penalty_name'] as String,
      pointsDeducted: map['points_deducted'] as int,
      reason: map['reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'penalty_id': penaltyId,
      'penalty_name': penaltyName,
      'points_deducted': pointsDeducted,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  PenaltyRecord copyWith({
    int? id,
    int? userId,
    int? penaltyId,
    String? penaltyName,
    int? pointsDeducted,
    String? reason,
    DateTime? createdAt,
  }) {
    return PenaltyRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      penaltyId: penaltyId ?? this.penaltyId,
      penaltyName: penaltyName ?? this.penaltyName,
      pointsDeducted: pointsDeducted ?? this.pointsDeducted,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
