import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models/story.dart';
import '../data/models/point.dart';
import '../data/repositories/story_repository.dart';
import '../data/repositories/point_record_repository.dart';
import 'user_provider.dart';

/// 故事Provider
class StoryProvider with ChangeNotifier {
  final StoryRepository _storyRepository = StoryRepository();
  final PointRecordRepository _pointRecordRepository = PointRecordRepository();

  List<Story> _stories = [];
  Set<int> _learnedStoryIds = {};
  Story? _todayStory;
  bool _isLoading = false;
  String? _errorMessage;
  int? _scrollToStoryId; // 需要滚动到的故事ID

  List<Story> get stories => _stories;
  Set<int> get learnedStoryIds => _learnedStoryIds;
  Story? get todayStory => _todayStory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get scrollToStoryId => _scrollToStoryId;

  /// 设置需要滚动到的故事ID
  void setScrollToStoryId(int? storyId) {
    _scrollToStoryId = storyId;
    notifyListeners();
  }

  /// 清除滚动标记
  void clearScrollToStoryId() {
    _scrollToStoryId = null;
  }

  /// 加载故事列表
  Future<void> loadStories() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // 从assets加载story.json
      final jsonString = await rootBundle.loadString('assets/story.json');
      final jsonList = json.decode(jsonString) as List;

      _stories = jsonList
          .asMap()
          .entries
          .map((entry) => Story.fromJson(entry.value as Map<String, dynamic>, entry.key))
          .toList();

      // 设置今日故事（基于日期的固定索引）
      _setTodayStory();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = '加载故事失败：$e';
      notifyListeners();
      debugPrint('StoryProvider loadStories error: $e');
    }
  }

  /// 设置今日故事
  void _setTodayStory() {
    if (_stories.isEmpty) return;

    // 根据今天的日期计算索引（确保每天显示不同的故事）
    final now = DateTime.now();
    final daysSinceEpoch = now.difference(DateTime(2024, 1, 1)).inDays;
    final index = daysSinceEpoch % _stories.length;

    _todayStory = _stories[index];
  }

  /// 加载用户已学习的故事
  Future<void> loadLearnedStories(int userId) async {
    try {
      _learnedStoryIds = await _storyRepository.getLearnedStoryIds(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('StoryProvider loadLearnedStories error: $e');
    }
  }

  /// 检查今日故事是否已学习
  Future<bool> isTodayStoryLearned(int userId) async {
    if (_todayStory == null) return false;
    return await _storyRepository.hasLearnedToday(userId, _todayStory!.id);
  }

  /// 完成今日故事学习并奖励积分
  Future<bool> completeTodayStory(int userId, UserProvider userProvider) async {
    if (_todayStory == null) return false;

    try {
      // 检查今天是否已经学习过
      final alreadyLearned = await _storyRepository.hasLearnedToday(userId, _todayStory!.id);
      if (alreadyLearned) {
        debugPrint('Story already learned today');
        return false;
      }

      final now = DateTime.now();

      // 1. 创建学习记录
      final record = StoryRecord(
        userId: userId,
        storyId: _todayStory!.id,
        learnedAt: now,
      );
      await _storyRepository.createStoryRecord(record);

      // 2. 奖励10积分
      const points = 10;
      final pointRecord = PointRecord(
        userId: userId,
        type: 'earn',
        points: points,
        balance: 0, // 将在保存后更新
        sourceType: 'story',
        sourceId: _todayStory!.id,
        description: '学习故事《${_todayStory!.content}》',
        createdAt: now,
      );

      // 先获取当前积分
      final currentPoints = userProvider.currentUser!.totalPoints;
      final newBalance = currentPoints + points;

      // 设置正确的余额
      final updatedPointRecord = PointRecord(
        userId: userId,
        type: 'earn',
        points: points,
        balance: newBalance,
        sourceType: 'story',
        sourceId: _todayStory!.id,
        description: '学习故事《${_todayStory!.content}》',
        createdAt: now,
      );

      await _pointRecordRepository.createPointRecord(updatedPointRecord);

      // 3. 更新用户积分
      await userProvider.addPoints(points);

      // 4. 更新已学习列表
      _learnedStoryIds.add(_todayStory!.id);
      notifyListeners();

      debugPrint('Story learning completed: +$points points');
      return true;
    } catch (e) {
      _errorMessage = '完成学习失败：$e';
      notifyListeners();
      debugPrint('StoryProvider completeTodayStory error: $e');
      return false;
    }
  }

  /// 获取今天学习的故事数量
  Future<int> getTodayLearnCount(int userId) async {
    try {
      return await _storyRepository.getTodayLearnCount(userId);
    } catch (e) {
      debugPrint('StoryProvider getTodayLearnCount error: $e');
      return 0;
    }
  }
}
