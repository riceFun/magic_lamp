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
  @override
  void initState() {
    super.initState();
    // 加载惩罚项目列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.currentUser?.id;
      if (userId != null) {
        context.read<PenaltyProvider>().loadActivePenalties(userId);
      }
    });
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
          // 添加惩罚按钮
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final result = await context.push(AppConstants.routePenaltyEdit);
              // 返回时刷新列表
              if (result == true && mounted) {
                final userProvider = context.read<UserProvider>();
                final userId = userProvider.currentUser?.id;
                if (userId != null) {
                  context.read<PenaltyProvider>().loadActivePenalties(userId);
                }
              }
            },
            tooltip: '添加惩罚',
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

          final penalties = penaltyProvider.activePenalties;

          return CustomScrollView(
            slivers: [
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
                    '惩罚列表 (${penalties.length})',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ),

              // 惩罚项目列表
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLarge,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final penalty = penalties[index];
                      return _PenaltyCard(
                        penalty: penalty,
                        onTap: () => _showApplyPenaltyDialog(penalty),
                        onLongPress: () => _showDeletePenaltyDialog(penalty),
                      );
                    },
                    childCount: penalties.length,
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

  /// 显示删除惩罚确认对话框
  void _showDeletePenaltyDialog(Penalty penalty) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.accentRed),
            SizedBox(width: AppTheme.spacingSmall),
            Text('删除惩罚'),
          ],
        ),
        content: Text('确定要删除"${penalty.name}"吗？\n此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _deletePenalty(penalty);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 删除惩罚
  Future<void> _deletePenalty(Penalty penalty) async {
    final penaltyProvider = context.read<PenaltyProvider>();
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.currentUser?.id;

    if (userId == null) return;

    final success = await penaltyProvider.deletePenalty(penalty.id!, userId);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('惩罚删除成功'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(penaltyProvider.errorMessage ?? '删除失败'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }
}

/// 惩罚卡片
class _PenaltyCard extends StatelessWidget {
  final Penalty penalty;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PenaltyCard({
    required this.penalty,
    required this.onTap,
    required this.onLongPress,
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
          onLongPress: onLongPress,
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
