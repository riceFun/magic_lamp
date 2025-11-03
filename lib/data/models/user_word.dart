/// 用户词汇库模型
class UserWord {
  final int? id;
  final int userId;
  final String wordCode; // 成语或英文词汇
  final String wordType; // 'idiom' 或 'english'
  final DateTime learnedAt; // 学习时间
  final String sourceType; // 'exchange' (兑换获得)
  final int sourceId; // 来源记录ID（兑换记录ID）

  UserWord({
    this.id,
    required this.userId,
    required this.wordCode,
    required this.wordType,
    required this.learnedAt,
    required this.sourceType,
    required this.sourceId,
  });

  /// 是否是成语
  bool get isIdiom => wordType == 'idiom';

  /// 是否是英文单词
  bool get isEnglish => wordType == 'english';

  /// 从数据库Map创建UserWord对象
  factory UserWord.fromMap(Map<String, dynamic> map) {
    return UserWord(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      wordCode: map['word_code'] as String,
      wordType: map['word_type'] as String,
      learnedAt: DateTime.parse(map['learned_at'] as String),
      sourceType: map['source_type'] as String,
      sourceId: map['source_id'] as int,
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'word_code': wordCode,
      'word_type': wordType,
      'learned_at': learnedAt.toIso8601String(),
      'source_type': sourceType,
      'source_id': sourceId,
    };
  }

  @override
  String toString() {
    return 'UserWord{id: $id, wordCode: $wordCode, wordType: $wordType}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserWord &&
        other.userId == userId &&
        other.wordCode == wordCode;
  }

  @override
  int get hashCode => userId.hashCode ^ wordCode.hashCode;
}
