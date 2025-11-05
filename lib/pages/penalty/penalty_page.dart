import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/penalty_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';
import '../../widgets/points/points_badge.dart';
import '../../data/models/penalty.dart';

/// 惩罚页面 - 扣除积分
class PenaltyPage extends StatefulWidget {
  const PenaltyPage({super.key});

  @override
  State<PenaltyPage> createState() => _PenaltyPageState();
}

class _PenaltyPageState extends State<PenaltyPage> {
  String _selectedCategory = 'all'; // 当前选中的分类

  @override
  void initState() {
    super.initState();
    // 加载惩罚项目列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PenaltyProvider>().loadActivePenalties();
    });
  }

  /// 获取分类图标
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'all':
        return Icons.apps;
      case 'behavior':
        return Icons.psychology;
      case 'hygiene':
        return Icons.cleaning_services;
      case 'study':
        return Icons.school;
      case 'language':
        return Icons.record_voice_over;
      default:
        return Icons.warning;
    }
  }

  /// 获取分类名称
  String _getCategoryName(String category) {
    switch (category) {
      case 'all':
        return '全部';
      case 'behavior':
        return '行为';
      case 'hygiene':
        return '卫生';
      case 'study':
        return '学习';
      case 'language':
        return '语言';
      default:
        return '其他';
    }
  }

  /// 筛选惩罚项目
  List<Penalty> _filterPenalties(List<Penalty> penalties) {
    if (_selectedCategory == 'all') {
      return penalties;
    }
    return penalties.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.warning_amber, size: 24),
            SizedBox(width: AppTheme.spacingSmall),
            Text('惩罚扣分'),
          ],
        ),
        actions: [
          // 显示当前积分
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.currentUser;
              if (user == null) return SizedBox.shrink();
              return PointsBadge(points: user.totalPoints);
            },
          ),
          // 管理按钮
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              await context.push(AppConstants.routePenaltyManagement);
              // 返回时刷新列表
              if (mounted) {
                context.read<PenaltyProvider>().loadActivePenalties();
              }
            },
            tooltip: '惩罚管理',
          ),

        ],
      ),
      body: Consumer<PenaltyProvider>(
        builder: (context, penaltyProvider, child) {
          if (penaltyProvider.isLoading) {
            return LoadingWidget.medium(message: '加载惩罚项目中...');
          }

          if (penaltyProvider.errorMessage != null) {
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
                    penaltyProvider.errorMessage!,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          if (penaltyProvider.activePenalties.isEmpty) {
            return EmptyWidget(
              icon: Icons.check_circle,
              message: '暂无惩罚项目',
              subtitle: '点击右上角菜单按钮进行添加',
            );
          }

          final filteredPenalties = _filterPenalties(penaltyProvider.activePenalties);

          return CustomScrollView(
            slivers: [
              // 分类筛选按钮
              SliverToBoxAdapter(
                child: Container(
                  height: 60,
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacingSmall),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
                    children: [
                      _buildCategoryChip('all'),
                      SizedBox(width: 8),
                      _buildCategoryChip('behavior'),
                      SizedBox(width: 8),
                      _buildCategoryChip('hygiene'),
                      SizedBox(width: 8),
                      _buildCategoryChip('study'),
                      SizedBox(width: 8),
                      _buildCategoryChip('language'),
                      SizedBox(width: 8),
                      _buildCategoryChip('other'),
                    ],
                  ),
                ),
              ),

              // 标题栏
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.spacingLarge,
                    AppTheme.spacingSmall,
                    AppTheme.spacingLarge,
                    AppTheme.spacingMedium,
                  ),
                  child: Text(
                    '${_getCategoryName(_selectedCategory)}惩罚 (${filteredPenalties.length})',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ),

              // 惩罚项目列表
              if (filteredPenalties.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: AppTheme.spacingMedium),
                        Text(
                          '该分类暂无惩罚项目',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeMedium,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLarge,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final penalty = filteredPenalties[index];
                        return _PenaltyCard(
                          penalty: penalty,
                          onTap: () => _showApplyPenaltyDialog(penalty),
                        );
                      },
                      childCount: filteredPenalties.length,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingLarge),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 显示执行惩罚对话框
  void _showApplyPenaltyDialog(Penalty penalty) {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请先登录'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Text(
              penalty.icon ?? '⚠️',
              style: TextStyle(fontSize: 28),
            ),
            SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: Text(
                penalty.name,
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
              if (penalty.description != null && penalty.description!.isNotEmpty) ...[
                Text(
                  penalty.description!,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: AppTheme.textSecondaryColor,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: AppTheme.spacingMedium),
              ],

              // 扣除积分提示
              Container(
                padding: EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.remove_circle,
                      color: AppTheme.accentRed,
                      size: 24,
                    ),
                    SizedBox(width: AppTheme.spacingSmall),
                    Expanded(
                      child: Text(
                        '将扣除 ${penalty.points} 积分',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: AppTheme.accentRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppTheme.spacingMedium),

              // 备注输入框
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: '具体原因（可选）',
                  hintText: '例如：在学校说了脏话',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                ),
                maxLines: 2,
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
              await _applyPenalty(penalty, user.id!, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: Text('确认扣分'),
          ),
        ],
      ),
    );
  }

  /// 执行惩罚
  Future<void> _applyPenalty(Penalty penalty, int userId, String reason) async {
    final penaltyProvider = context.read<PenaltyProvider>();
    final userProvider = context.read<UserProvider>();

    final recordId = await penaltyProvider.applyPenalty(
      userId: userId,
      penaltyId: penalty.id!,
      reason: reason.isEmpty ? null : reason,
    );

    if (recordId != null) {
      // 刷新用户积分
      await userProvider.refreshCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已扣除 ${penalty.points} 积分'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(penaltyProvider.errorMessage ?? '执行惩罚失败'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  /// 构建分类筛选按钮
  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.accentRed,
                    AppTheme.accentOrange,
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accentRed : AppTheme.dividerColor,
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentRed.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(category),
              size: 18,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            ),
            SizedBox(width: 6),
            Text(
              _getCategoryName(category),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 惩罚卡片
class _PenaltyCard extends StatelessWidget {
  final Penalty penalty;
  final VoidCallback onTap;

  const _PenaltyCard({
    required this.penalty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            padding: EdgeInsets.all(AppTheme.spacingMedium),
            child: Row(
              children: [
                // 惩罚图标
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.accentRed.withValues(alpha: 0.8),
                        AppTheme.accentOrange.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Center(
                    child: Text(
                      penalty.icon ?? '⚠️',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.spacingMedium),

                // 惩罚信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        penalty.name,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      if (penalty.description != null && penalty.description!.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          penalty.description!,
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            color: AppTheme.textSecondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // 扣除积分
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.remove_circle,
                        size: 18,
                        color: AppTheme.accentRed,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${penalty.points}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
