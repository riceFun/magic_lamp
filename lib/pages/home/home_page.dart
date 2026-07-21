import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/story_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/points/points_badge.dart';
import '../../data/models/task.dart';
import 'package:magic_lamp/pages/task/edit_task_page.dart';
import '../../widgets/common/password_verification_dialog.dart';

/// 首页 - 显示激励任务列表
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isTaskPointsAscending = true;

  @override
  void initState() {
    super.initState();
    // 加载任务列表和故事列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.currentUser;
      if (user != null) {
        context.read<TaskProvider>().loadUserTasks(user.id!);
        // 加载故事
        final storyProvider = context.read<StoryProvider>();
        storyProvider.loadStories();
        storyProvider.loadLearnedStories(user.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTemporaryTaskDialog(context),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.bolt),
        label: Text('临时任务'),
      ),
      body: Consumer3<UserProvider, TaskProvider, StoryProvider>(
        builder: (context, userProvider, taskProvider, storyProvider, child) {
          final user = userProvider.currentUser;

          if (user == null) {
            return Center(
              child: Text(
                '未登录',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.primaryColor,
                title: Row(
                  children: [
                    Icon(Icons.home, size: 24),
                    SizedBox(width: AppTheme.spacingSmall),
                    Text(user.name),
                    SizedBox(width: 5),
                    PointsBadge(points: user.totalPoints),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.sort),
                    onPressed: () {
                      setState(() {
                        _isTaskPointsAscending = !_isTaskPointsAscending;
                      });
                    },
                    tooltip: _isTaskPointsAscending ? '按积分从小到大排序' : '按积分从大到小排序',
                  ),
                  IconButton(
                    padding: EdgeInsets.all(0),
                    icon: Icon(Icons.store),
                    onPressed: () {
                      context.push(AppConstants.routeTaskTemplateMarketplace);
                    },
                    tooltip: '添加任务',
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    onPressed: () {
                      context.push(AppConstants.routeTaskCreate);
                    },
                    tooltip: '添加任务',
                  ),
                ],
              ),

              // 每日故事卡片 - 重新设计
              if (storyProvider.todayStory != null)
                SliverToBoxAdapter(
                  child: InkWell(
                    onTap: () {
                      // 直接跳转到今日故事详情
                      if (storyProvider.todayStory != null) {
                        context.push(AppConstants.routeStoryList);
                        context.push(
                          '${AppConstants.routeStoryDetail}/${storyProvider.todayStory!.id}',
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.accentYellow.withValues(alpha: 0.15),
                            AppTheme.accentOrange.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                      padding: EdgeInsets.all(AppTheme.spacingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // 图标 - 更大更突出
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.accentYellow,
                                      AppTheme.accentOrange,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accentYellow.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '📖',
                                    style: TextStyle(fontSize: 32),
                                  ),
                                ),
                              ),
                              SizedBox(width: AppTheme.spacingMedium),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '每日故事',
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSizeLarge,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppTheme.accentGreen,
                                                AppTheme.accentGreen.withValues(
                                                  alpha: 0.8,
                                                ),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.accentGreen
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.stars,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '+10积分',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 20,
                                color: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                          SizedBox(height: AppTheme.spacingMedium),
                          Container(
                            padding: EdgeInsets.all(AppTheme.spacingSmall),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSmall,
                              ),
                              border: Border.all(
                                color: AppTheme.accentYellow.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              storyProvider.todayStory!.content,
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeSmall,
                                color: AppTheme.textPrimaryColor,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 任务列表
              if (taskProvider.isLoading)
                SliverFillRemaining(
                  child: LoadingWidget.medium(message: '加载任务中...'),
                )
              else if (taskProvider.errorMessage != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: AppTheme.accentRed,
                        ),
                        SizedBox(height: AppTheme.spacingMedium),
                        Text(
                          taskProvider.errorMessage!,
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeMedium,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (taskProvider.activeTasks.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 80,
                          color: AppTheme.textHintColor,
                        ),
                        SizedBox(height: AppTheme.spacingLarge),
                        Text(
                          '还没有任务',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingSmall),
                        Text(
                          '添加一些激励任务开始积分之旅吧！',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeMedium,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingLarge),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                context.push(
                                  AppConstants.routeTaskTemplateMarketplace,
                                );
                              },
                              icon: Icon(Icons.store),
                              label: Text('从任务超市选择'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingLarge,
                                  vertical: AppTheme.spacingMedium,
                                ),
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingMedium),
                            OutlinedButton.icon(
                              onPressed: () {
                                context.push(AppConstants.routeTaskCreate);
                              },
                              icon: Icon(Icons.add),
                              label: Text('手动创建任务'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                side: BorderSide(color: AppTheme.primaryColor),
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingLarge,
                                  vertical: AppTheme.spacingMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                _SortedTaskList(
                  tasks: taskProvider.activeTasks,
                  userId: user.id!,
                  sortAscending: _isTaskPointsAscending,
                  onTaskTap: (task) => _showTaskDetail(context, task, user.id!),
                ),
            ],
          );
        },
      ),
    );
  }

  /// 显示快速临时任务弹框
  Future<void> _showTemporaryTaskDialog(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;

    if (user == null || user.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('未登录，无法创建临时任务'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    final input = await showDialog<_TemporaryTaskInput>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const _TemporaryTaskDialog(),
    );

    if (input == null || !context.mounted) {
      return;
    }

    final taskProvider = context.read<TaskProvider>();

    final task = Task(
      userId: user.id!,
      title: input.title,
      description: '首页快速创建的临时任务',
      points: input.points,
      type: 'once',
      priority: 'normal',
      status: 'active',
      icon: '⚡',
    );

    final taskId = await taskProvider.createTaskAndGetId(task);
    if (taskId == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('临时任务创建失败'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    final earnedPoints = await taskProvider.completeTask(taskId, user.id!);
    if (earnedPoints == null) {
      await taskProvider.deleteTask(taskId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('临时任务完成失败'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    await userProvider.refreshCurrentUser();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('临时任务已完成，获得 $earnedPoints 积分'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  /// 显示任务详情对话框
  void _showTaskDetail(BuildContext context, Task task, int userId) async {
    final taskProvider = context.read<TaskProvider>();

    // 检查今天是否已完成
    final isCompleted = await taskProvider.isTaskCompletedToday(
      task.id!,
      userId,
    );
    final streakCount = await taskProvider.getTaskStreakCount(task.id!, userId);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            _getPriorityIcon(task.priority),
            SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(fontSize: AppTheme.fontSizeLarge),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null && task.description!.isNotEmpty) ...[
                Text(
                  task.description!,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: AppTheme.textPrimaryColor,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: AppTheme.spacingMedium),
              ],

              // 积分信息
              Row(
                children: [
                  Icon(
                    Icons.monetization_on,
                    size: 24,
                    color: AppTheme.accentYellow,
                  ),
                  SizedBox(width: AppTheme.spacingSmall),
                  Text(
                    '${task.points} 积分',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppTheme.spacingSmall),

              // 任务类型
              _InfoRow(
                icon: Icons.repeat,
                label: '任务类型',
                value: _getTaskTypeText(task.type),
              ),

              // 连续完成天数
              if (streakCount > 0) ...[
                SizedBox(height: AppTheme.spacingSmall),
                _InfoRow(
                  icon: Icons.local_fire_department,
                  label: '连续完成',
                  value: '$streakCount 天',
                ),
              ],

              // 今日状态
              SizedBox(height: AppTheme.spacingSmall),
              Container(
                padding: EdgeInsets.all(AppTheme.spacingSmall),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.accentGreen.withValues(alpha: 0.1)
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.pending,
                      size: 20,
                      color: isCompleted
                          ? AppTheme.accentGreen
                          : AppTheme.primaryColor,
                    ),
                    SizedBox(width: AppTheme.spacingSmall),
                    Text(
                      isCompleted ? '今日已完成' : '待完成',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: isCompleted
                            ? AppTheme.accentGreen
                            : AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('取消'),
          ),
          if (!isCompleted)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // 密码验证
                await showPasswordVerificationDialog(
                  context: context,
                  mode: PasswordMode.user,
                  title: '确认完成任务',
                  message: '请输入操作密码以完成任务',
                  onVerified: () {
                    _actualCompleteTask(context, task, userId);
                  },
                );
              },
              child: Text('完成任务'),
            ),
        ],
      ),
    );
  }

  /// 完成任务
  Future<void> _completeTask(
    BuildContext context,
    Task task,
    int userId,
  ) async {
    // 此方法已被移除，使用密码验证后调用 _actualCompleteTask
  }

  /// 实际执行完成任务操作
  Future<void> _actualCompleteTask(
    BuildContext context,
    Task task,
    int userId,
  ) async {
    final taskProvider = context.read<TaskProvider>();
    final userProvider = context.read<UserProvider>();

    try {
      await taskProvider.completeTask(task.id!, userId);

      if (!context.mounted) return;

      // 刷新用户积分
      await userProvider.refreshCurrentUser();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('任务完成！获得 ${task.points} 积分'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('完成任务失败: $e'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  /// 获取优先级图标
  Widget _getPriorityIcon(String priority) {
    IconData icon;
    Color color;

    switch (priority) {
      case 'urgent':
        icon = Icons.priority_high;
        color = AppTheme.accentRed;
        break;
      case 'high':
        icon = Icons.priority_high;
        color = AppTheme.accentOrange;
        break;
      case 'medium':
        icon = Icons.remove;
        color = AppTheme.primaryColor;
        break;
      case 'normal':
        icon = Icons.remove;
        color = AppTheme.primaryColor;
        break;
      case 'low':
        icon = Icons.trending_down;
        color = AppTheme.accentGreen;
        break;
      default:
        icon = Icons.remove;
        color = AppTheme.textSecondaryColor;
    }

    return Icon(icon, size: 24, color: color);
  }

  /// 获取任务类型文本
  String _getTaskTypeText(String type) {
    switch (type) {
      case 'once':
        return '一次性';
      case 'daily':
        return '每日';
      case 'weekly':
        return '每周';
      case 'monthly':
        return '每月';
      default:
        return '未知';
    }
  }
}

class _TemporaryTaskInput {
  final String title;
  final int points;

  const _TemporaryTaskInput({required this.title, required this.points});
}

class _TemporaryTaskDialog extends StatefulWidget {
  const _TemporaryTaskDialog();

  @override
  State<_TemporaryTaskDialog> createState() => _TemporaryTaskDialogState();
}

class _TemporaryTaskDialogState extends State<_TemporaryTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _pointsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pointsController.text = '10';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _TemporaryTaskInput(
        title: _titleController.text.trim(),
        points: int.parse(_pointsController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.fromLTRB(
        AppTheme.spacingLarge,
        AppTheme.spacingLarge,
        AppTheme.spacingLarge,
        AppTheme.spacingSmall,
      ),
      contentPadding: EdgeInsets.fromLTRB(
        AppTheme.spacingLarge,
        0,
        AppTheme.spacingLarge,
        AppTheme.spacingMedium,
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        AppTheme.spacingMedium,
        0,
        AppTheme.spacingMedium,
        AppTheme.spacingMedium,
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(Icons.bolt, color: AppTheme.primaryColor),
          ),
          SizedBox(width: AppTheme.spacingSmall),
          Expanded(child: Text('临时任务')),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '输入一个临时任务名称和积分，完成后会直接入账。',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textSecondaryColor,
                height: 1.4,
              ),
            ),
            SizedBox(height: AppTheme.spacingMedium),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '任务名称',
                hintText: '例如：整理书桌',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入任务名称';
                }
                if (value.trim().length < 2) {
                  return '名称至少2个字符';
                }
                return null;
              },
            ),
            SizedBox(height: AppTheme.spacingMedium),
            TextFormField(
              controller: _pointsController,
              decoration: InputDecoration(
                labelText: '积分数量',
                hintText: '请输入积分',
                prefixIcon: Icon(Icons.monetization_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入积分数量';
                }
                final points = int.tryParse(value.trim());
                if (points == null || points <= 0) {
                  return '积分必须大于0';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(onPressed: _submit, child: Text('完成并获得积分')),
      ],
    );
  }
}

/// 排序后的任务列表
class _SortedTaskList extends StatelessWidget {
  final List<Task> tasks;
  final int userId;
  final bool sortAscending;
  final Function(Task) onTaskTap;

  const _SortedTaskList({
    required this.tasks,
    required this.userId,
    required this.sortAscending,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getSortedTasks(taskProvider),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SliverToBoxAdapter(
            child: LoadingWidget.medium(message: '加载任务中...'),
          );
        }

        final sortedTasks = snapshot.data!;

        return SliverPadding(
          padding: EdgeInsets.all(AppTheme.spacingLarge),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final taskData = sortedTasks[index];
              final task = taskData['task'] as Task;
              final isCompleted = taskData['isCompleted'] as bool;

              return _TaskCard(
                task: task,
                userId: userId,
                isCompleted: isCompleted,
                onTap: () => onTaskTap(task),
              );
            }, childCount: sortedTasks.length),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getSortedTasks(
    TaskProvider taskProvider,
  ) async {
    final tasksWithStatus = <Map<String, dynamic>>[];

    for (final task in tasks) {
      final isCompleted = await taskProvider.isTaskCompletedToday(
        task.id!,
        userId,
      );
      tasksWithStatus.add({'task': task, 'isCompleted': isCompleted});
    }

    // 排序：按积分大小升序或降序
    tasksWithStatus.sort((a, b) {
      final aTask = a['task'] as Task;
      final bTask = b['task'] as Task;
      final pointsCompare = sortAscending
          ? aTask.points.compareTo(bTask.points)
          : bTask.points.compareTo(aTask.points);
      if (pointsCompare != 0) return pointsCompare;

      final aCompleted = a['isCompleted'] as bool;
      final bCompleted = b['isCompleted'] as bool;
      if (aCompleted == bCompleted) return 0;
      return aCompleted ? 1 : -1;
    });

    return tasksWithStatus;
  }
}

/// 信息行组件
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondaryColor),
        SizedBox(width: AppTheme.spacingSmall),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// 任务卡片
class _TaskCard extends StatelessWidget {
  final Task task;
  final int userId;
  final bool isCompleted;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.userId,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            padding: EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 任务图标 - 更大更突出
                    Container(
                      width: 64,
                      height: 64,
                      child: Center(
                        child: task.icon != null && task.icon!.isNotEmpty
                            ? Text(task.icon!, style: TextStyle(fontSize: 48))
                            : Icon(
                                _getTypeIcon(task.type),
                                color: Colors.white,
                                size: 48,
                              ),
                      ),
                    ),
                    SizedBox(width: AppTheme.spacingMedium),

                    // 任务信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 任务标题
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),

                          // 任务类型
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(
                                task.type,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.repeat,
                                  size: 12,
                                  color: _getTypeColor(task.type),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _getTaskTypeText(task.type),
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSizeSmall,
                                    color: _getTypeColor(task.type),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 编辑按钮
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditTaskPage(task: task),
                          ),
                        );

                        if (result == true) {
                          final userProvider = context.read<UserProvider>();
                          final user = userProvider.currentUser;
                          if (user != null) {
                            context.read<TaskProvider>().loadUserTasks(
                              user.id!,
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppTheme.spacingMedium),

                // 底部：积分和完成状态
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 积分显示 - 更大更醒目
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFFD700), // 金色
                            Color(0xFFFFA500), // 橙金色
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFFD700).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: 22,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '${task.points}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 完成状态 - 更突出
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? LinearGradient(
                                colors: [
                                  AppTheme.accentGreen,
                                  AppTheme.accentGreen.withValues(alpha: 0.8),
                                ],
                              )
                            : null,
                        color: isCompleted ? null : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: isCompleted
                            ? null
                            : Border.all(
                                color: AppTheme.textHintColor,
                                width: 1.5,
                              ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: isCompleted
                                ? Colors.white
                                : AppTheme.textSecondaryColor,
                          ),
                          SizedBox(width: 6),
                          Text(
                            isCompleted ? '已完成' : '待完成',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeSmall,
                              fontWeight: isCompleted
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCompleted
                                  ? Colors.white
                                  : AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'once':
        return Icons.check_circle_outline;
      case 'daily':
        return Icons.today;
      case 'weekly':
        return Icons.date_range;
      case 'monthly':
        return Icons.calendar_month;
      default:
        return Icons.task;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'once':
        return AppTheme.primaryColor;
      case 'daily':
        return AppTheme.accentGreen;
      case 'weekly':
        return AppTheme.accentOrange;
      case 'monthly':
        return AppTheme.accentRed;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  String _getTaskTypeText(String type) {
    switch (type) {
      case 'once':
        return '一次性';
      case 'daily':
        return '每日';
      case 'weekly':
        return '每周';
      case 'monthly':
        return '每月';
      default:
        return '未知';
    }
  }
}
