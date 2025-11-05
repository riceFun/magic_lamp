import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/penalty_provider.dart';
import '../../data/models/penalty.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';

/// 惩罚管理页面（管理员功能）
class PenaltyManagementPage extends StatefulWidget {
  const PenaltyManagementPage({super.key});

  @override
  State<PenaltyManagementPage> createState() => _PenaltyManagementPageState();
}

class _PenaltyManagementPageState extends State<PenaltyManagementPage> {
  @override
  void initState() {
    super.initState();
    // 延迟到构建完成后再加载，避免在构建期间调用 notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPenalties();
    });
  }

  Future<void> _loadPenalties() async {
    await context.read<PenaltyProvider>().loadAllPenalties();
  }

  /// 显示删除确认对话框
  void _showDeleteDialog(Penalty penalty) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除惩罚'),
        content: Text('确定要删除惩罚"${penalty.name}"吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deletePenalty(penalty);
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
    try {
      final penaltyProvider = context.read<PenaltyProvider>();
      final success = await penaltyProvider.deletePenalty(penalty.id!);

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败：$e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  /// 获取分类图标
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'behavior':
        return Icons.psychology;
      case 'hygiene':
        return Icons.cleaning_services;
      case 'study':
        return Icons.school;
      case 'language':
        return Icons.record_voice_over;
      case 'other':
      default:
        return Icons.warning;
    }
  }

  /// 获取分类文本
  String _getCategoryText(String category) {
    switch (category) {
      case 'behavior':
        return '行为';
      case 'hygiene':
        return '卫生';
      case 'study':
        return '学习';
      case 'language':
        return '语言';
      case 'other':
      default:
        return '其他';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('惩罚管理'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final result = await context.push(AppConstants.routePenaltyEdit);
              if (result == true) {
                _loadPenalties();
              }
            },
            tooltip: '添加惩罚',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPenalties,
            tooltip: '刷新',
          ),
        ],
      ),
      body: Consumer<PenaltyProvider>(
        builder: (context, penaltyProvider, child) {
          if (penaltyProvider.isLoading) {
            return LoadingWidget(message: '加载惩罚列表...');
          }

          final penalties = penaltyProvider.allPenalties;

          if (penalties.isEmpty) {
            return EmptyWidget(
              icon: Icons.warning_amber,
              message: '暂无惩罚项目',
              subtitle: '点击右上角添加惩罚项目',
            );
          }

          return RefreshIndicator(
            onRefresh: _loadPenalties,
            child: ListView.builder(
              padding: EdgeInsets.all(AppTheme.spacingLarge),
              itemCount: penalties.length,
              itemBuilder: (context, index) {
                final penalty = penalties[index];
                return Container(
                  margin: EdgeInsets.only(bottom: AppTheme.spacingMedium),
                  child: CustomCard(
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
                                AppTheme.accentRed,
                                AppTheme.accentRed.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Center(
                            child: penalty.icon != null
                                ? Text(
                                    penalty.icon!,
                                    style: TextStyle(fontSize: 32),
                                  )
                                : Icon(
                                    _getCategoryIcon(penalty.category),
                                    size: 30,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingMedium),

                        // 惩罚信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      penalty.name,
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSizeLarge,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingSmall,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentRed
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSmall,
                                      ),
                                    ),
                                    child: Text(
                                      _getCategoryText(penalty.category),
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSizeXSmall,
                                        color: AppTheme.accentRed,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.remove_circle,
                                    size: 16,
                                    color: AppTheme.accentRed,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${penalty.points} 积分',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeMedium,
                                      color: AppTheme.accentRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: penalty.status == 'active'
                                          ? AppTheme.accentGreen.withValues(alpha: 0.2)
                                          : AppTheme.textHintColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      penalty.status == 'active' ? '启用' : '停用',
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSizeXSmall,
                                        color: penalty.status == 'active'
                                            ? AppTheme.accentGreen
                                            : AppTheme.textHintColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (penalty.description != null &&
                                  penalty.description!.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Text(
                                  penalty.description!,
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSizeSmall,
                                    color: AppTheme.textHintColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // 操作按钮
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: AppTheme.accentOrange,
                              ),
                              onPressed: () async {
                                final result = await context.push(
                                  '${AppConstants.routePenaltyEdit}?id=${penalty.id}',
                                );
                                if (result == true) {
                                  _loadPenalties();
                                }
                              },
                              tooltip: '编辑',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: AppTheme.accentRed,
                              ),
                              onPressed: () => _showDeleteDialog(penalty),
                              tooltip: '删除',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
