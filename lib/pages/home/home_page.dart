import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/story_provider.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';
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
                  ],
                ),
                actions: [
                  PointsBadge(points: user.totalPoints),
                  SizedBox(width: 10),
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

              // 每日故事卡片
              if (storyProvider.todayStory != null)
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(
                      AppTheme.spacingLarge,
                      AppTheme.spacingLarge,
                      AppTheme.spacingLarge,
                      0,
                    ),
                    child: CustomCard(
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
                        child: Padding(
                          padding: EdgeInsets.all(AppTheme.spacingMedium),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentYellow.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                    ),
                                    child: Text(
                                      '📖',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ),
                                  SizedBox(width: AppTheme.spacingSmall),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '每日故事',
                                              style: TextStyle(
                                                fontSize: AppTheme.fontSizeMedium,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimaryColor,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentYellow,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '+10',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          '点击阅读今日故事',
                                          style: TextStyle(
                                            fontSize: AppTheme.fontSizeSmall,
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: AppTheme.textHintColor,
                                  ),
                                ],
                              ),
                              SizedBox(height: AppTheme.spacingSmall),
                              Container(
                                padding: EdgeInsets.all(AppTheme.spacingSmall),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                ),
                                child: Text(
                                  storyProvider.todayStory!.content,
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSizeSmall,
                                    color: AppTheme.textPrimaryColor,
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
                                context.push(AppConstants.routeTaskTemplateMarketplace);
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
                SliverPadding(
                  padding: EdgeInsets.all(AppTheme.spacingLarge),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = taskProvider.activeTasks[index];
                        return _TaskCard(
                          task: task,
                          userId: user.id!,
                          onTap: () {
                            _showTaskDetail(context, task, user.id!);
                          },
                        );
                      },
                      childCount: taskProvider.activeTasks.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// 显示任务详情对话框
  void _showTaskDetail(BuildContext context, Task task, int userId) async {
    final taskProvider = context.read<TaskProvider>();

    // 检查今天是否已完成
    final isCompleted = await taskProvider.isTaskCompletedToday(task.id!, userId);
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
                      color: isCompleted ? AppTheme.accentGreen : AppTheme.primaryColor,
                    ),
                    SizedBox(width: AppTheme.spacingSmall),
                    Text(
                      isCompleted ? '今日已完成' : '待完成',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: isCompleted ? AppTheme.accentGreen : AppTheme.primaryColor,
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
  Future<void> _completeTask(BuildContext context, Task task, int userId) async {
    // 此方法已被移除，使用密码验证后调用 _actualCompleteTask
  }

  /// 实际执行完成任务操作
  Future<void> _actualCompleteTask(BuildContext context, Task task, int userId) async {
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
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.userId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return FutureBuilder<bool>(
      future: taskProvider.isTaskCompletedToday(task.id!, userId),
      builder: (context, snapshot) {
        final isCompleted = snapshot.data ?? false;

        return Container(
          margin: EdgeInsets.only(bottom: AppTheme.spacingMedium),
          decoration: BoxDecoration(
            color: isCompleted
                ? AppTheme.accentGreen.withValues(alpha: 0.05)
                : AppTheme.accentOrange.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: CustomCard(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingSmall),
                child: Column(
                  children: [
                    // 顶部行：任务信息和编辑按钮
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 任务图标（无背景）
                        if (task.icon != null)
                          Text(
                            task.icon!,
                            style: TextStyle(fontSize: 32),
                          )
                        else
                          Icon(
                            _getTypeIcon(task.type),
                            color: _getTypeColor(task.type),
                            size: 32,
                          ),
                        SizedBox(width: AppTheme.spacingSmall),

                        // 任务标题和类型
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeMedium,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.repeat,
                                    size: 14,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    _getTaskTypeText(task.type),
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeSmall,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                ],
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
                                context.read<TaskProvider>().loadUserTasks(user.id!);
                              }
                            }
                          },
                          child: Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: AppTheme.spacingSmall),

                    // 底部行：积分和完成状态
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 完成状态
                        Row(
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 20,
                              color: isCompleted ? AppTheme.accentGreen : AppTheme.textHintColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              isCompleted ? '已完成' : '待完成',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeSmall,
                                color: isCompleted ? AppTheme.accentGreen : AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        // 积分（大而显眼）
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentYellow.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.monetization_on,
                                size: 18,
                                color: AppTheme.accentYellow,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${task.points}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentYellow,
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
      },
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
