/// 故事模型
class Story {
  final int id;
  final String content;
  final String source;

  Story({
    required this.id,
    required this.content,
    required this.source,
  });

  /// 从JSON创建Story对象
  factory Story.fromJson(Map<String, dynamic> json, int index) {
    return Story(
      id: index,
      content: json['content'] as String,
      source: json['source'] as String,
    );
  }

  @override
  String toString() {
    return 'Story{id: $id, content: $content}';
  }
}

/// 故事学习记录模型
class StoryRecord {
  final int? id;
  final int userId;
  final int storyId;
  final DateTime learnedAt;
  final DateTime createdAt;

  StoryRecord({
    this.id,
    required this.userId,
    required this.storyId,
    required this.learnedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从数据库Map创建StoryRecord对象
  factory StoryRecord.fromMap(Map<String, dynamic> map) {
    return StoryRecord(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      storyId: map['story_id'] as int,
      learnedAt: DateTime.parse(map['learned_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'story_id': storyId,
      'learned_at': learnedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'StoryRecord{id: $id, userId: $userId, storyId: $storyId, learnedAt: $learnedAt}';
  }
}
