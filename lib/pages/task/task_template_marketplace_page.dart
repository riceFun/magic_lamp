import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/task_template_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../data/models/task_template.dart';
import '../../data/models/task.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';

/// 任务模板超市页面
class TaskTemplateMarketplacePage extends StatefulWidget {
  const TaskTemplateMarketplacePage({super.key});

  @override
  State<TaskTemplateMarketplacePage> createState() =>
      _TaskTemplateMarketplacePageState();
}

class _TaskTemplateMarketplacePageState
    extends State<TaskTemplateMarketplacePage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  bool _isSelectionMode = false;
  Set<int> _selectedTemplateIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskTemplateProvider>().loadTemplates();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 切换选择模式
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTemplateIds.clear();
      }
    });
  }

  /// 全选/取消全选
  void _toggleSelectAll(List<TaskTemplate> templates) {
    setState(() {
      if (_selectedTemplateIds.length == templates.length) {
        // 已全选，取消全选
        _selectedTemplateIds.clear();
      } else {
        // 全选
        _selectedTemplateIds = templates.map((t) => t.id!).toSet();
      }
    });
  }

  /// 切换单个模板的选中状态
  void _toggleTemplateSelection(int templateId) {
    setState(() {
      if (_selectedTemplateIds.contains(templateId)) {
        _selectedTemplateIds.remove(templateId);
      } else {
        _selectedTemplateIds.add(templateId);
      }
    });
  }

  /// 批量添加任务
  Future<void> _batchAddTasks(BuildContext context, List<TaskTemplate> templates) async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('未登录，无法创建任务'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    final taskProvider = context.read<TaskProvider>();
    int successCount = 0;
    int failCount = 0;

    for (final template in templates) {
      if (_selectedTemplateIds.contains(template.id)) {
        final task = Task(
          userId: user.id!,
          title: template.title,
          description: template.description,
          points: template.points,
          type: template.type,
          priority: template.priority,
          status: 'active',
        );

        final success = await taskProvider.createTask(task);
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      }
    }

    // 刷新任务列表
    await taskProvider.loadUserTasks(user.id!);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 成功添加 $successCount 个任务${failCount > 0 ? '，失败 $failCount 个' : ''}'),
          backgroundColor: failCount > 0 ? AppTheme.accentOrange : AppTheme.accentGreen,
          duration: Duration(seconds: 3),
        ),
      );

      // 退出选择模式
      setState(() {
        _isSelectionMode = false;
        _selectedTemplateIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.store, size: 24),
            SizedBox(width: AppTheme.spacingSmall),
            Text(_isSelectionMode ? '选择任务模板' : '任务超市'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.checklist),
            onPressed: _toggleSelectionMode,
            tooltip: _isSelectionMode ? '退出选择' : '多选模式',
          ),
        ],
      ),
      bottomNavigationBar: _isSelectionMode
          ? Consumer<TaskTemplateProvider>(
              builder: (context, provider, child) {
                final isAllSelected = _selectedTemplateIds.length == provider.filteredTemplates.length &&
                    provider.filteredTemplates.isNotEmpty;

                return Container(
                  padding: EdgeInsets.all(AppTheme.spacingMedium),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _toggleSelectAll(provider.filteredTemplates),
                            icon: Icon(
                              isAllSelected ? Icons.check_box : Icons.check_box_outline_blank,
                            ),
                            label: Text(isAllSelected ? '取消全选' : '全选'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
                              side: BorderSide(color: AppTheme.primaryColor),
                              foregroundColor: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingMedium),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectedTemplateIds.isEmpty
                                ? null
                                : () async {
                                    await _batchAddTasks(context, provider.filteredTemplates);
                                  },
                            icon: Icon(Icons.done_all),
                            label: Text('确定添加 (${_selectedTemplateIds.length})'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
                              disabledBackgroundColor: AppTheme.textHintColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : null,
      body: Consumer<TaskTemplateProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return LoadingWidget.medium(message: '加载模板中...');
          }

          if (provider.errorMessage != null) {
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
                    provider.errorMessage!,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 分类筛选
              Container(
                height: 60,
                padding: EdgeInsets.symmetric(vertical: AppTheme.spacingSmall),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLarge,
                  ),
                  children: [
                    _CategoryChip(
                      label: '全部',
                      value: 'all',
                      icon: Icons.apps,
                      isSelected: _selectedCategory == 'all',
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'all';
                        });
                        provider.setSelectedCategory('all');
                      },
                    ),
                    _CategoryChip(
                      label: '学习',
                      value: 'study',
                      icon: Icons.school,
                      isSelected: _selectedCategory == 'study',
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'study';
                        });
                        provider.setSelectedCategory('study');
                      },
                    ),
                    _CategoryChip(
                      label: '阅读',
                      value: 'reading',
                      icon: Icons.book,
                      isSelected: _selectedCategory == 'reading',
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'reading';
                        });
                        provider.setSelectedCategory('reading');
                      },
                    ),
                    _CategoryChip(
                      label: '健康',
                      value: 'health',
                      icon: Icons.favorite,
                      isSelected: _selectedCategory == 'health',
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'health';
                        });
                        provider.setSelectedCategory('health');
                      },
                    ),
                    _CategoryChip(
                      label: '运动',
                      value: 'exercise',
                      icon: Icons.fitness_center,
                      isSelected: _selectedCategory == 'exercise',
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'exercise';
                        });
                        provider.setSelectedCategory('exercise');
                      },
                    ),
                    _CategoryChip(
                      label: '家务',
                      value: 'housework',
                      icon: Icons.home,
                      isSelected: _selectedCategory == 'housework',
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'housework';
                        });
                        provider.setSelectedCategory('housework');
                      },
                    ),
                    _CategoryChip(
                      label: '才艺',
                      value: 'art',
                      icon: Icons.palette,
                      isSelected: _selectedCategory == 'art',
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'art';
                        });
                        provider.setSelectedCategory('art');
                      },
                    ),
                    _CategoryChip(
                      label: '生活',
                      value: 'life',
                      icon: Icons.self_improvement,
                      isSelected: _selectedCategory == 'life',
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'life';
                        });
                        provider.setSelectedCategory('life');
                      },
                    ),
                    _CategoryChip(
                      label: '其他',
                      value: 'other',
                      icon: Icons.more_horiz,
                      isSelected: _selectedCategory == 'other',
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'other';
                        });
                        provider.setSelectedCategory('other');
                      },
                    ),
                  ],
                ),
              ),

              Divider(height: 1),

              // 模板列表
              Expanded(
                child: provider.filteredTemplates.isEmpty
                    ? EmptyWidget(
                        icon: Icons.inventory_2_outlined,
                        message: '暂无模板',
                        subtitle: '该分类下还没有任务模板',
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadTemplates(),
                        child: ListView.builder(
                          padding: EdgeInsets.all(AppTheme.spacingLarge),
                          itemCount: provider.filteredTemplates.length,
                          itemBuilder: (context, index) {
                            final template = provider.filteredTemplates[index];
                            final isSelected = _selectedTemplateIds.contains(template.id);
                            return _TemplateCard(
                              template: template,
                              isSelectionMode: _isSelectionMode,
                              isSelected: isSelected,
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleTemplateSelection(template.id!);
                                } else {
                                  _showTemplateDetail(context, template);
                                }
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

  /// 显示模板详情
  void _showTemplateDetail(BuildContext context, TaskTemplate template) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            // 显示模板自己的图标，如果没有则使用分类图标
            template.icon != null && template.icon!.isNotEmpty
                ? Text(
                    template.icon!,
                    style: TextStyle(fontSize: 24),
                  )
                : _getCategoryIcon(template.category),
            SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: Text(
                template.title,
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
              if (template.description != null &&
                  template.description!.isNotEmpty) ...{
                Text(
                  template.description!,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: AppTheme.textPrimaryColor,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: AppTheme.spacingMedium),
              },

              // 积分
              Row(
                children: [
                  Icon(
                    Icons.monetization_on,
                    size: 24,
                    color: AppTheme.accentYellow,
                  ),
                  SizedBox(width: AppTheme.spacingSmall),
                  Text(
                    '${template.points} 积分',
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
                value: _getTaskTypeText(template.type),
              ),

              SizedBox(height: AppTheme.spacingSmall),

              // 优先级
              _InfoRow(
                icon: Icons.flag,
                label: '优先级',
                value: _getPriorityText(template.priority),
              ),

              SizedBox(height: AppTheme.spacingSmall),

              // 分类
              if (template.category != null)
                _InfoRow(
                  icon: Icons.category,
                  label: '分类',
                  value: _getCategoryText(template.category),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              // 获取当前用户
              final userProvider = context.read<UserProvider>();
              final user = userProvider.currentUser;

              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('未登录，无法创建任务'),
                    backgroundColor: AppTheme.accentRed,
                  ),
                );
                return;
              }

              // 根据模板创建任务
              final task = Task(
                userId: user.id!,
                title: template.title,
                description: template.description,
                points: template.points,
                type: template.type,
                priority: template.priority,
                status: 'active',
              );

              // 创建任务
              final taskProvider = context.read<TaskProvider>();
              final success = await taskProvider.createTask(task);

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ 任务"${template.title}"已添加！'),
                    backgroundColor: AppTheme.accentGreen,
                    duration: Duration(seconds: 2),
                  ),
                );

                // 刷新任务列表
                await taskProvider.loadUserTasks(user.id!);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('任务添加失败，请重试'),
                    backgroundColor: AppTheme.accentRed,
                  ),
                );
              }
            },
            child: Text('使用模板'),
          ),
        ],
      ),
    );
  }

  /// 获取分类图标
  Widget _getCategoryIcon(String? category) {
    IconData icon;
    Color color;

    switch (category) {
      case 'study':
        icon = Icons.school;
        color = AppTheme.primaryColor;
        break;
      case 'reading':
        icon = Icons.book;
        color = AppTheme.accentOrange;
        break;
      case 'health':
        icon = Icons.favorite;
        color = AppTheme.accentRed;
        break;
      case 'exercise':
        icon = Icons.fitness_center;
        color = AppTheme.accentGreen;
        break;
      case 'housework':
        icon = Icons.home;
        color = AppTheme.primaryColor;
        break;
      case 'art':
        icon = Icons.palette;
        color = Colors.purple;
        break;
      case 'life':
        icon = Icons.self_improvement;
        color = Colors.teal;
        break;
      default:
        icon = Icons.task;
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

  /// 获取优先级文本
  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return '高';
      case 'medium':
        return '中';
      case 'low':
        return '低';
      default:
        return '中';
    }
  }

  /// 获取分类文本
  String _getCategoryText(String? category) {
    switch (category) {
      case 'study':
        return '学习';
      case 'reading':
        return '阅读';
      case 'health':
        return '健康';
      case 'exercise':
        return '运动';
      case 'housework':
        return '家务';
      case 'art':
        return '才艺';
      case 'life':
        return '生活';
      case 'other':
        return '其他';
      default:
        return '未分类';
    }
  }
}

/// 分类筛选按钮
class _CategoryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: AppTheme.spacingSmall),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            ),
            SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

/// 模板卡片
class _TemplateCard extends StatelessWidget {
  final TaskTemplate template;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: CustomCard(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: isSelected
                  ? Border.all(color: AppTheme.primaryColor, width: 2)
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingMedium),
              child: Row(
                children: [
                  // 选择模式下显示复选框
                  if (isSelectionMode) ...{
                    Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textHintColor,
                      size: 28,
                    ),
                    SizedBox(width: AppTheme.spacingMedium),
                  },

                  // 图标
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getTypeColor(template.type).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Center(
                      child: template.icon != null && template.icon!.isNotEmpty
                          ? Text(
                              template.icon!,
                              style: TextStyle(fontSize: 28),
                            )
                          : Icon(
                              _getTypeIcon(template.type),
                              color: _getTypeColor(template.type),
                              size: 28,
                            ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMedium),

                  // 信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.title,
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeMedium,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.monetization_on,
                              size: 16,
                              color: AppTheme.accentYellow,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${template.points} 积分',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeSmall,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingSmall),
                            Icon(
                              Icons.repeat,
                              size: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              _getTaskTypeText(template.type),
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

                  // 箭头（仅非选择模式显示）
                  if (!isSelectionMode)
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.textHintColor,
                      size: 24,
                    ),
                ],
              ),
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
