import 'package:flutter/foundation.dart';
import '../data/models/task.dart';
import '../data/models/point.dart';
import '../data/repositories/task_repository.dart';
import '../data/repositories/point_record_repository.dart';
import '../data/repositories/user_repository.dart';

/// 任务状态管理
class TaskProvider with ChangeNotifier {
  final _taskRepository = TaskRepository();
  final _pointRecordRepository = PointRecordRepository();
  final _userRepository = UserRepository();

  List<Task> _tasks = [];
  List<TaskRecord> _taskRecords = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _filterType = 'all'; // 'all', 'once', 'daily', 'weekly', 'monthly'

  List<Task> get tasks => _tasks;
  List<TaskRecord> get taskRecords => _taskRecords;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filterType => _filterType;

  /// 获取激活的任务
  List<Task> get activeTasks => _tasks.where((task) => task.isActive).toList();

  /// 根据类型过滤任务
  List<Task> get filteredTasks {
    if (_filterType == 'all') {
      return activeTasks;
    }
    return activeTasks.where((task) => task.type == _filterType).toList();
  }

  /// 设置过滤类型
  void setFilterType(String type) {
    _filterType = type;
    notifyListeners();
  }

  /// 加载用户任务
  Future<void> loadUserTasks(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _taskRepository.getUserActiveTasks(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载任务失败：$e';
      _isLoading = false;
      notifyListeners();
      debugPrint('TaskProvider loadUserTasks error: $e');
    }
  }

  /// 加载今日任务
  Future<void> loadTodayTasks(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _taskRepository.getTodayTasks(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载今日任务失败：$e';
      _isLoading = false;
      notifyListeners();
      debugPrint('TaskProvider loadTodayTasks error: $e');
    }
  }

  /// 创建任务
  Future<bool> createTask(Task task) async {
    try {
      final id = await _taskRepository.createTask(task);
      if (id > 0) {
        // 重新加载任务列表
        await loadUserTasks(task.userId);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = '创建任务失败：$e';
      notifyListeners();
      debugPrint('TaskProvider createTask error: $e');
      return false;
    }
  }

  /// 更新任务（实际是归档旧任务并创建新任务）
  /// 这样可以保留历史记录和已完成的积分记录
  Future<bool> updateTask(Task task) async {
    try {
      if (task.id == null) {
        _errorMessage = '任务ID不能为空';
        notifyListeners();
        return false;
      }

      // 1. 将原任务状态设为'replaced'（已替换/归档）
      final originalTask = _tasks.firstWhere((t) => t.id == task.id);
      final archivedTask = originalTask.copyWith(
        status: 'replaced',
        updatedAt: DateTime.now(),
      );

      await _taskRepository.updateTask(archivedTask);

      // 2. 创建新任务（不包含id，让数据库自动生成新id）
      final newTask = Task(
        userId: task.userId,
        title: task.title,
        description: task.description,
        points: task.points,
        type: task.type,
        priority: task.priority,
        startDate: task.startDate,
        endDate: task.endDate,
        repeatType: task.repeatType,
        repeatConfig: task.repeatConfig,
        status: 'active', // 新任务状态为active
        projectId: task.projectId,
        tags: task.tags,
      );

      final newTaskId = await _taskRepository.createTask(newTask);

      if (newTaskId > 0) {
        // 3. 更新原任务的replaced_by_task_id字段
        final updatedArchivedTask = archivedTask.copyWith(
          replacedByTaskId: newTaskId,
          updatedAt: DateTime.now(),
        );
        await _taskRepository.updateTask(updatedArchivedTask);

        // 4. 重新加载任务列表（会自动过滤掉status='replaced'的任务）
        await loadUserTasks(task.userId);

        debugPrint('Task updated: archived task ${task.id}, created new task $newTaskId');
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = '更新任务失败：$e';
      notifyListeners();
      debugPrint('TaskProvider updateTask error: $e');
      return false;
    }
  }

  /// 删除任务
  Future<bool> deleteTask(int taskId) async {
    try {
      final count = await _taskRepository.deleteTask(taskId);
      if (count > 0) {
        _tasks.removeWhere((task) => task.id == taskId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = '删除任务失败：$e';
      notifyListeners();
      debugPrint('TaskProvider deleteTask error: $e');
      return false;
    }
  }

  /// 完成任务
  /// 返回获得的总积分（基础积分 + 奖励积分）
  Future<int?> completeTask(int taskId, int userId, {String? note}) async {
    try {
      // 检查今天是否已完成
      final isCompleted = await _taskRepository.isTaskCompletedToday(taskId, userId);
      if (isCompleted) {
        _errorMessage = '今天已完成该任务';
        notifyListeners();
        return null;
      }

      // 获取任务信息
      final task = await _taskRepository.getTaskById(taskId);
      if (task == null) {
        _errorMessage = '任务不存在';
        notifyListeners();
        return null;
      }

      // 计算连续完成天数
      final streakCount = await _taskRepository.getTaskStreakCount(taskId, userId) + 1;

      // 计算奖励积分（连续完成奖励）
      int bonusPoints = 0;
      if (streakCount >= 7) {
        bonusPoints = (task.points * 0.5).round(); // 连续7天奖励50%
      } else if (streakCount >= 3) {
        bonusPoints = (task.points * 0.2).round(); // 连续3天奖励20%
      }

      final totalPoints = task.points + bonusPoints;

      // 创建完成记录
      final record = TaskRecord(
        taskId: taskId,
        userId: userId,
        completedAt: DateTime.now(),
        pointsEarned: task.points,
        bonusPoints: bonusPoints,
        streakCount: streakCount,
        note: note,
      );

      await _taskRepository.createTaskRecord(record);

      // 增加用户积分
      await _userRepository.addUserPoints(userId, totalPoints);

      // 创建积分记录
      final user = await _userRepository.getUserById(userId);
      if (user != null) {
        final pointRecord = PointRecord(
          userId: userId,
          type: 'earn',
          points: totalPoints,
          balance: user.totalPoints,
          sourceType: 'task',
          sourceId: taskId,
          description: '完成任务：${task.title}${bonusPoints > 0 ? '（连续$streakCount天奖励+$bonusPoints）' : ''}',
        );
        await _pointRecordRepository.createPointRecord(pointRecord);
      }

      // 如果是一次性任务，标记为已完成
      if (task.isOnce) {
        await _taskRepository.updateTaskStatus(taskId, 'completed');
      }

      // 重新加载任务列表
      await loadUserTasks(userId);

      return totalPoints;
    } catch (e) {
      _errorMessage = '完成任务失败：$e';
      notifyListeners();
      debugPrint('TaskProvider completeTask error: $e');
      return null;
    }
  }

  /// 加载任务完成记录
  Future<void> loadTaskRecords(int userId) async {
    try {
      _taskRecords = await _taskRepository.getUserTaskRecords(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载完成记录失败：$e';
      notifyListeners();
      debugPrint('TaskProvider loadTaskRecords error: $e');
    }
  }

  /// 检查任务今天是否已完成
  Future<bool> isTaskCompletedToday(int taskId, int userId) async {
    try {
      return await _taskRepository.isTaskCompletedToday(taskId, userId);
    } catch (e) {
      debugPrint('TaskProvider isTaskCompletedToday error: $e');
      return false;
    }
  }

  /// 获取任务的连续完成天数
  Future<int> getTaskStreakCount(int taskId, int userId) async {
    try {
      return await _taskRepository.getTaskStreakCount(taskId, userId);
    } catch (e) {
      debugPrint('TaskProvider getTaskStreakCount error: $e');
      return 0;
    }
  }

  /// 获取任务统计
  Future<Map<String, int>> getTaskStats(int userId) async {
    try {
      return await _taskRepository.getUserTaskStats(userId);
    } catch (e) {
      debugPrint('TaskProvider getTaskStats error: $e');
      return {
        'totalCount': 0,
        'completedCount': 0,
        'activeCount': 0,
        'totalPoints': 0,
        'maxStreak': 0,
      };
    }
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
