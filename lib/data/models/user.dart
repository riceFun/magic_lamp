/// 用户模型
class User {
  final int? id;
  final String name;
  final String? avatar;
  final String role; // 'admin' 或 'child'
  final int totalPoints;
  final String? password;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    this.id,
    required this.name,
    this.avatar,
    this.role = 'child',
    this.totalPoints = 0,
    this.password,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 是否是管理员
  // bool get isAdmin => role == 'admin';

  /// 是否是儿童用户
  bool get isChild => role == 'child';

  /// 从数据库Map创建User对象
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      avatar: map['avatar'] as String?,
      role: map['role'] as String? ?? 'child',
      totalPoints: map['total_points'] as int? ?? 0,
      password: map['password'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'avatar': avatar,
      'role': role,
      'total_points': totalPoints,
      'password': password,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分属性
  User copyWith({
    int? id,
    String? name,
    String? avatar,
    String? role,
    int? totalPoints,
    String? password,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      totalPoints: totalPoints ?? this.totalPoints,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, role: $role, totalPoints: $totalPoints}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
