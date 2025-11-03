/// 奖励商品模型
class Reward {
  final int? id;
  final String name;
  final String? description;
  final int points;
  final String wordCode; // 成语或英文词汇
  final String wordType; // 'idiom' 或 'english'
  final String? imageUrl;
  final String category; // 'toy', 'book', 'entertainment', 'privilege'
  final int stock; // -1 表示无限库存
  final bool isHot; // 是否热门
  final bool isSpecial; // 是否特惠
  final String status; // 'active', 'inactive', 'sold_out'
  final DateTime createdAt;
  final DateTime updatedAt;

  Reward({
    this.id,
    required this.name,
    this.description,
    required this.points,
    required this.wordCode,
    required this.wordType,
    this.imageUrl,
    required this.category,
    this.stock = -1,
    this.isHot = false,
    this.isSpecial = false,
    this.status = 'active',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

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
      wordCode: map['word_code'] as String,
      wordType: map['word_type'] as String,
      imageUrl: map['image_url'] as String?,
      category: map['category'] as String,
      stock: map['stock'] as int? ?? -1,
      isHot: (map['is_hot'] as int? ?? 0) == 1,
      isSpecial: (map['is_special'] as int? ?? 0) == 1,
      status: map['status'] as String? ?? 'active',
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
      'word_code': wordCode,
      'word_type': wordType,
      'image_url': imageUrl,
      'category': category,
      'stock': stock,
      'is_hot': isHot ? 1 : 0,
      'is_special': isSpecial ? 1 : 0,
      'status': status,
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
    String? wordCode,
    String? wordType,
    String? imageUrl,
    String? category,
    int? stock,
    bool? isHot,
    bool? isSpecial,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reward(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      points: points ?? this.points,
      wordCode: wordCode ?? this.wordCode,
      wordType: wordType ?? this.wordType,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      isHot: isHot ?? this.isHot,
      isSpecial: isSpecial ?? this.isSpecial,
      status: status ?? this.status,
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
