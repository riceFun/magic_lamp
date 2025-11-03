import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';
import '../../data/models/task.dart';

/// 任务列表页面
class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  @override
  void initState() {
    super.initState();
    // 加载任务列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.currentUser;
      if (user != null) {
        context.read<TaskProvider>().loadUserTasks(user.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('任务列表'),
        actions: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.currentUser;
              if (user != null && user.isAdmin) {
                return IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () async {
                    // 跳转到创建任务页面
                    final result = await context.push(AppConstants.routeTaskCreate);

                    // 如果创建成功，刷新列表
                    if (result == true && user.id != null) {
                      if (context.mounted) {
                        context.read<TaskProvider>().loadUserTasks(user.id!);
                      }
                    }
                  },
                  tooltip: '创建任务',
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer2<TaskProvider, UserProvider>(
        builder: (context, taskProvider, userProvider, child) {
          final user = userProvider.currentUser;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: AppTheme.spacingLarge),
                  Text(
                    '未登录',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          if (taskProvider.isLoading) {
            return LoadingWidget.medium(message: '加载任务中...');
          }

          if (taskProvider.errorMessage != null) {
            return Center(
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
            );
          }

          if (taskProvider.filteredTasks.isEmpty) {
            return EmptyWidget.noTasks();
          }

          return Column(
            children: [
              // 筛选栏
              _FilterBar(
                currentFilter: taskProvider.filterType,
                onFilterChanged: (filter) {
                  taskProvider.setFilterType(filter);
                },
              ),

              // 任务列表
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await taskProvider.loadUserTasks(user.id!);
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(AppTheme.spacingLarge),
                    itemCount: taskProvider.filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = taskProvider.filteredTasks[index];
                      return _TaskCard(
                        task: task,
                        userId: user.id!,
                        onTap: () {
                          _showTaskDetail(context, task, user.id!);
                        },
                      );
                    },
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
              if (task.description != null) ...{
                Text(
                  task.description!,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: AppTheme.textPrimaryColor,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: AppTheme.spacingMedium),
              },

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
                color: AppTheme.primaryColor,
              ),

              // 连续完成天数
              if (streakCount > 0) ...{
                SizedBox(height: AppTheme.spacingSmall),
                _InfoRow(
                  icon: Icons.local_fire_department,
                  label: '连续完成',
                  value: '$streakCount 天',
                  color: AppTheme.accentOrange,
                ),
              },

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

              // 奖励提示
              if (!isCompleted && streakCount >= 0) ...{
                SizedBox(height: AppTheme.spacingMedium),
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppTheme.accentOrange,
                      ),
                      SizedBox(width: AppTheme.spacingSmall),
                      Expanded(
                        child: Text(
                          '连续3天+20%，连续7天+50%',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            color: AppTheme.accentOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              },
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('关闭'),
          ),
          if (!isCompleted)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _completeTask(context, task, userId);
              },
              child: Text('完成任务'),
            ),
        ],
      ),
    );
  }

  /// 完成任务
  Future<void> _completeTask(BuildContext context, Task task, int userId) async {
    final taskProvider = context.read<TaskProvider>();
    final userProvider = context.read<UserProvider>();

    final totalPoints = await taskProvider.completeTask(task.id!, userId);

    if (totalPoints != null) {
      // 刷新用户信息
      await userProvider.refreshCurrentUser();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 任务完成！获得 $totalPoints 积分'),
            backgroundColor: AppTheme.accentGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (taskProvider.errorMessage != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(taskProvider.errorMessage!),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  /// 获取优先级图标
  Widget _getPriorityIcon(String priority) {
    IconData icon;
    Color color;

    switch (priority) {
      case 'urgent':
        icon = Icons.flag;
        color = AppTheme.accentRed;
        break;
      case 'high':
        icon = Icons.flag;
        color = AppTheme.accentOrange;
        break;
      case 'low':
        icon = Icons.flag_outlined;
        color = AppTheme.textHintColor;
        break;
      default:
        icon = Icons.flag_outlined;
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

/// 筛选栏
class _FilterBar extends StatelessWidget {
  final String currentFilter;
  final Function(String) onFilterChanged;

  _FilterBar({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLarge,
        vertical: AppTheme.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: '全部',
              value: 'all',
              isSelected: currentFilter == 'all',
              onTap: () => onFilterChanged('all'),
            ),
            SizedBox(width: AppTheme.spacingSmall),
            _FilterChip(
              label: '一次性',
              value: 'once',
              isSelected: currentFilter == 'once',
              onTap: () => onFilterChanged('once'),
            ),
            SizedBox(width: AppTheme.spacingSmall),
            _FilterChip(
              label: '每日',
              value: 'daily',
              isSelected: currentFilter == 'daily',
              onTap: () => onFilterChanged('daily'),
            ),
            SizedBox(width: AppTheme.spacingSmall),
            _FilterChip(
              label: '每周',
              value: 'weekly',
              isSelected: currentFilter == 'weekly',
              onTap: () => onFilterChanged('weekly'),
            ),
            SizedBox(width: AppTheme.spacingSmall),
            _FilterChip(
              label: '每月',
              value: 'monthly',
              isSelected: currentFilter == 'monthly',
              onTap: () => onFilterChanged('monthly'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 筛选芯片
class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  _FilterChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingSmall,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// 任务卡片
class _TaskCard extends StatelessWidget {
  final Task task;
  final int userId;
  final VoidCallback onTap;

  _TaskCard({
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
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            elevation: 2,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Container(
                padding: EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: isCompleted
                      ? Border.all(color: AppTheme.accentGreen, width: 2)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 优先级标记
                        _getPriorityDot(task.priority),
                        SizedBox(width: AppTheme.spacingSmall),

                        // 标题
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),

                        // 完成状态
                        if (isCompleted)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSmall,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Text(
                              '已完成',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeXSmall,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (task.description != null) ...{
                      SizedBox(height: AppTheme.spacingSmall),
                      Text(
                        task.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    },

                    SizedBox(height: AppTheme.spacingSmall),

                    Row(
                      children: [
                        // 积分
                        Icon(
                          Icons.monetization_on,
                          size: 16,
                          color: AppTheme.accentYellow,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${task.points}',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),

                        SizedBox(width: AppTheme.spacingMedium),

                        // 类型标签
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSmall,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(task.type).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            _getTypeText(task.type),
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeXSmall,
                              color: _getTypeColor(task.type),
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _getPriorityDot(String priority) {
    Color color;
    switch (priority) {
      case 'urgent':
        color = AppTheme.accentRed;
        break;
      case 'high':
        color = AppTheme.accentOrange;
        break;
      case 'low':
        color = AppTheme.textHintColor;
        break;
      default:
        color = AppTheme.primaryColor;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'once':
        return AppTheme.textSecondaryColor;
      case 'daily':
        return AppTheme.primaryColor;
      case 'weekly':
        return AppTheme.accentOrange;
      case 'monthly':
        return AppTheme.accentGreen;
      default:
        return AppTheme.textHintColor;
    }
  }

  String _getTypeText(String type) {
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

/// 信息行
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: AppTheme.spacingSmall),
        Text(
          '$label：',
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
