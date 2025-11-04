import 'dart:convert';

/// 任务模型
class Task {
  final int? id;
  final int userId;
  final String title;
  final String? description;
  final int points;
  final String type; // 'once', 'daily', 'weekly', 'monthly'
  final String priority; // 'low', 'normal', 'high', 'urgent'
  final DateTime? startDate;
  final DateTime? endDate;
  final String repeatType; // 'none', 'daily', 'weekly', 'monthly', 'custom'
  final Map<String, dynamic>? repeatConfig;
  final String status; // 'active', 'paused', 'completed', 'expired', 'replaced'
  final int? projectId;
  final List<String>? tags;
  final int? replacedByTaskId; // 指向替换此任务的新任务ID
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.points,
    required this.type,
    this.priority = 'normal',
    this.startDate,
    this.endDate,
    this.repeatType = 'none',
    this.repeatConfig,
    this.status = 'active',
    this.projectId,
    this.tags,
    this.replacedByTaskId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 是否是一次性任务
  bool get isOnce => type == 'once';

  /// 是否是重复任务
  bool get isRepeating => repeatType != 'none';

  /// 是否已过期
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// 是否激活
  bool get isActive => status == 'active';

  /// 从数据库Map创建Task对象
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      points: map['points'] as int,
      type: map['type'] as String,
      priority: map['priority'] as String? ?? 'normal',
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : null,
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      repeatType: map['repeat_type'] as String? ?? 'none',
      repeatConfig: map['repeat_config'] != null
          ? jsonDecode(map['repeat_config'] as String)
              as Map<String, dynamic>
          : null,
      status: map['status'] as String? ?? 'active',
      projectId: map['project_id'] as int?,
      tags: map['tags'] != null
          ? (jsonDecode(map['tags'] as String) as List)
              .map((e) => e.toString())
              .toList()
          : null,
      replacedByTaskId: map['replaced_by_task_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'points': points,
      'type': type,
      'priority': priority,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'repeat_type': repeatType,
      'repeat_config': repeatConfig != null ? jsonEncode(repeatConfig) : null,
      'status': status,
      'project_id': projectId,
      'tags': tags != null ? jsonEncode(tags) : null,
      'replaced_by_task_id': replacedByTaskId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分属性
  Task copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    int? points,
    String? type,
    String? priority,
    DateTime? startDate,
    DateTime? endDate,
    String? repeatType,
    Map<String, dynamic>? repeatConfig,
    String? status,
    int? projectId,
    List<String>? tags,
    int? replacedByTaskId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      points: points ?? this.points,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      repeatType: repeatType ?? this.repeatType,
      repeatConfig: repeatConfig ?? this.repeatConfig,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      tags: tags ?? this.tags,
      replacedByTaskId: replacedByTaskId ?? this.replacedByTaskId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Task{id: $id, title: $title, points: $points, type: $type, status: $status}';
  }
}

/// 任务完成记录模型
class TaskRecord {
  final int? id;
  final int taskId;
  final int userId;
  final DateTime completedAt;
  final int pointsEarned;
  final int bonusPoints;
  final int streakCount;
  final String? note;
  final DateTime createdAt;

  TaskRecord({
    this.id,
    required this.taskId,
    required this.userId,
    required this.completedAt,
    required this.pointsEarned,
    this.bonusPoints = 0,
    this.streakCount = 0,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 总积分（基础积分 + 奖励积分）
  int get totalPoints => pointsEarned + bonusPoints;

  /// 从数据库Map创建TaskRecord对象
  factory TaskRecord.fromMap(Map<String, dynamic> map) {
    return TaskRecord(
      id: map['id'] as int?,
      taskId: map['task_id'] as int,
      userId: map['user_id'] as int,
      completedAt: DateTime.parse(map['completed_at'] as String),
      pointsEarned: map['points_earned'] as int,
      bonusPoints: map['bonus_points'] as int? ?? 0,
      streakCount: map['streak_count'] as int? ?? 0,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'task_id': taskId,
      'user_id': userId,
      'completed_at': completedAt.toIso8601String(),
      'points_earned': pointsEarned,
      'bonus_points': bonusPoints,
      'streak_count': streakCount,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TaskRecord{id: $id, taskId: $taskId, pointsEarned: $pointsEarned, bonusPoints: $bonusPoints}';
  }
}
