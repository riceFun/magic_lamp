/// 任务模板模型
class TaskTemplate {
  final int? id;
  final String title;
  final String? description;
  final int points;
  final String type; // 'once', 'daily', 'weekly', 'monthly'
  final String priority; // 'low', 'medium', 'high'
  final String? category; // 任务分类：'study', 'health', 'housework', 'exercise', 'reading', 'other'
  final String? icon; // 任务图标（emoji）
  final DateTime createdAt;

  TaskTemplate({
    this.id,
    required this.title,
    this.description,
    required this.points,
    required this.type,
    this.priority = 'medium',
    this.category,
    this.icon,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从数据库映射创建对象
  factory TaskTemplate.fromMap(Map<String, dynamic> map) {
    return TaskTemplate(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      points: map['points'] as int,
      type: map['type'] as String,
      priority: map['priority'] as String? ?? 'medium',
      category: map['category'] as String?,
      icon: map['icon'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 转换为数据库映射
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points': points,
      'type': type,
      'priority': priority,
      'category': category,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  TaskTemplate copyWith({
    int? id,
    String? title,
    String? description,
    int? points,
    String? type,
    String? priority,
    String? category,
    String? icon,
    DateTime? createdAt,
  }) {
    return TaskTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      points: points ?? this.points,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
