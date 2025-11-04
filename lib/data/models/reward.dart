/// 奖励商品模型
class Reward {
  final int? id;
  final String name;
  final String? description;
  final int points; // 固定积分（当不使用范围积分时）
  final int? minPoints; // 最小积分（范围积分）
  final int? maxPoints; // 最大积分（范围积分）
  final String wordCode; // 成语或英文词汇
  final String? icon; // emoji 图标
  final String? imageUrl;
  final String category; // 'toy', 'book', 'entertainment', 'privilege'
  final String? type; // 商品类型：'食物', '体验', '服务', '学习', '特殊'
  final int stock; // -1 表示无限库存
  final String status; // 'active', 'inactive', 'sold_out'
  final String? exchangeFrequency; // 兑换频率: 'daily', 'weekly', 'monthly', 'quarterly', 'yearly', null表示无限制
  final int? maxExchangeCount; // 最大兑换次数，null表示无限制
  final String? note; // 备注
  final DateTime createdAt;
  final DateTime updatedAt;

  Reward({
    this.id,
    required this.name,
    this.description,
    required this.points,
    this.minPoints,
    this.maxPoints,
    required this.wordCode,
    this.icon,
    this.imageUrl,
    required this.category,
    this.type,
    this.stock = -1,
    this.status = 'active',
    this.exchangeFrequency,
    this.maxExchangeCount,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 是否使用范围积分
  bool get isRangePoints => minPoints != null && maxPoints != null;

  /// 获取积分显示文本
  String get pointsText {
    if (isRangePoints) {
      return '$minPoints-$maxPoints积分';
    }
    return '$points积分';
  }

  /// 是否有库存
  bool get hasStock => stock == -1 || stock > 0;

  /// 是否已售罄
  bool get isSoldOut => stock == 0;

  /// 是否可兑换
  bool get isAvailable => status == 'active' && hasStock;

  /// 换算成人民币
  double get priceInRmb => points * 0.1;

  /// 从数据库Map创建Reward对象
  factory Reward.fromMap(Map<String, dynamic> map) {
    return Reward(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      points: map['points'] as int,
      minPoints: map['min_points'] as int?,
      maxPoints: map['max_points'] as int?,
      wordCode: map['word_code'] as String,
      icon: map['icon'] as String?,
      imageUrl: map['image_url'] as String?,
      category: map['category'] as String,
      type: map['type'] as String?,
      stock: map['stock'] as int? ?? -1,
      status: map['status'] as String? ?? 'active',
      exchangeFrequency: map['exchange_frequency'] as String?,
      maxExchangeCount: map['max_exchange_count'] as int?,
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
      'min_points': minPoints,
      'max_points': maxPoints,
      'word_code': wordCode,
      'icon': icon,
      'image_url': imageUrl,
      'category': category,
      'type': type,
      'stock': stock,
      'status': status,
      'exchange_frequency': exchangeFrequency,
      'max_exchange_count': maxExchangeCount,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分属性
  Reward copyWith({
    int? id,
    String? name,
    String? description,
    int? points,
    int? minPoints,
    int? maxPoints,
    String? wordCode,
    String? icon,
    String? imageUrl,
    String? category,
    String? type,
    int? stock,
    String? status,
    String? exchangeFrequency,
    int? maxExchangeCount,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reward(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      points: points ?? this.points,
      minPoints: minPoints ?? this.minPoints,
      maxPoints: maxPoints ?? this.maxPoints,
      wordCode: wordCode ?? this.wordCode,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      type: type ?? this.type,
      stock: stock ?? this.stock,
      status: status ?? this.status,
      exchangeFrequency: exchangeFrequency ?? this.exchangeFrequency,
      maxExchangeCount: maxExchangeCount ?? this.maxExchangeCount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Reward{id: $id, name: $name, points: $points, wordCode: $wordCode}';
  }
}

/// 兑换记录模型
class Exchange {
  final int? id;
  final int userId;
  final int rewardId;
  final String rewardName;
  final int pointsSpent;
  final String wordCode;
  final String status; // 'pending', 'completed', 'cancelled'
  final DateTime exchangeAt;
  final DateTime? completedAt;
  final String? note;
  final DateTime createdAt;

  Exchange({
    this.id,
    required this.userId,
    required this.rewardId,
    required this.rewardName,
    required this.pointsSpent,
    required this.wordCode,
    this.status = 'pending',
    required this.exchangeAt,
    this.completedAt,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 是否待处理
  bool get isPending => status == 'pending';

  /// 是否已完成
  bool get isCompleted => status == 'completed';

  /// 是否已取消
  bool get isCancelled => status == 'cancelled';

  /// 从数据库Map创建Exchange对象
  factory Exchange.fromMap(Map<String, dynamic> map) {
    return Exchange(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      rewardId: map['reward_id'] as int,
      rewardName: map['reward_name'] as String,
      pointsSpent: map['points_spent'] as int,
      wordCode: map['word_code'] as String,
      status: map['status'] as String? ?? 'pending',
      exchangeAt: DateTime.parse(map['exchange_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'reward_id': rewardId,
      'reward_name': rewardName,
      'points_spent': pointsSpent,
      'word_code': wordCode,
      'status': status,
      'exchange_at': exchangeAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改部分属性
  Exchange copyWith({
    int? id,
    int? userId,
    int? rewardId,
    String? rewardName,
    int? pointsSpent,
    String? wordCode,
    String? status,
    DateTime? exchangeAt,
    DateTime? completedAt,
    String? note,
    DateTime? createdAt,
  }) {
    return Exchange(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      rewardId: rewardId ?? this.rewardId,
      rewardName: rewardName ?? this.rewardName,
      pointsSpent: pointsSpent ?? this.pointsSpent,
      wordCode: wordCode ?? this.wordCode,
      status: status ?? this.status,
      exchangeAt: exchangeAt ?? this.exchangeAt,
      completedAt: completedAt ?? this.completedAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Exchange{id: $id, rewardName: $rewardName, pointsSpent: $pointsSpent, status: $status}';
  }
}
