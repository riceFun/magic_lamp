import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/reward_provider.dart';
import '../../data/models/reward.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';

/// 商品管理页面（管理员功能）
class RewardManagementPage extends StatefulWidget {
  const RewardManagementPage({super.key});

  @override
  State<RewardManagementPage> createState() => _RewardManagementPageState();
}

class _RewardManagementPageState extends State<RewardManagementPage> {
  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    await context.read<RewardProvider>().loadAllRewardsIncludingInactive();
  }

  /// 显示删除确认对话框
  void _showDeleteDialog(Reward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除商品'),
        content: Text('确定要删除商品"${reward.name}"吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteReward(reward);
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

  /// 删除商品
  Future<void> _deleteReward(Reward reward) async {
    try {
      final rewardProvider = context.read<RewardProvider>();
      final success = await rewardProvider.deleteReward(reward.id!);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('商品删除成功'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(rewardProvider.errorMessage ?? '删除失败'),
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

  /// 获取类型图标
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'snack':
        return Icons.fastfood;
      case 'toy':
        return Icons.toys;
      case 'book':
        return Icons.book;
      case 'entertainment':
        return Icons.movie;
      case 'privilege':
        return Icons.star;
      case 'other':
      default:
        return Icons.card_giftcard;
    }
  }

  /// 获取类型文本
  String _getTypeText(String type) {
    switch (type) {
      case 'snack':
        return '零食';
      case 'toy':
        return '玩具';
      case 'book':
        return '图书';
      case 'entertainment':
        return '娱乐';
      case 'privilege':
        return '特权';
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
        title: Text('商品管理'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final result = await context.push(AppConstants.routeRewardEdit);
              if (result == true) {
                _loadRewards();
              }
            },
            tooltip: '添加商品',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRewards,
            tooltip: '刷新',
          ),
        ],
      ),
      body: Consumer<RewardProvider>(
        builder: (context, rewardProvider, child) {
          if (rewardProvider.isLoading) {
            return LoadingWidget(message: '加载商品列表...');
          }

          final rewards = rewardProvider.rewards;

          if (rewards.isEmpty) {
            return EmptyWidget(
              icon: Icons.card_giftcard,
              message: '暂无商品',
              subtitle: '点击右上角添加商品',
            );
          }

          return RefreshIndicator(
            onRefresh: _loadRewards,
            child: ListView.builder(
              padding: EdgeInsets.all(AppTheme.spacingLarge),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final reward = rewards[index];
                return Container(
                  margin: EdgeInsets.only(bottom: AppTheme.spacingMedium),
                  child: CustomCard(
                    child: Row(
                      children: [
                        // 商品图标
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.accentYellow,
                                AppTheme.accentYellow.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Icon(
                            _getTypeIcon(reward.category),
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingMedium),

                        // 商品信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      reward.name,
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
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSmall,
                                      ),
                                    ),
                                    child: Text(
                                      _getTypeText(reward.category),
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSizeXSmall,
                                        color: AppTheme.primaryColor,
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
                                    Icons.monetization_on,
                                    size: 16,
                                    color: AppTheme.accentOrange,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${reward.points} 积分',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeMedium,
                                      color: AppTheme.accentOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (reward.description != null &&
                                  reward.description!.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Text(
                                  reward.description!,
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
                                color: AppTheme.primaryColor,
                              ),
                              onPressed: () async {
                                final result = await context.push(
                                  '${AppConstants.routeRewardEdit}?id=${reward.id}',
                                );
                                if (result == true) {
                                  _loadRewards();
                                }
                              },
                              tooltip: '编辑',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: AppTheme.accentRed,
                              ),
                              onPressed: () => _showDeleteDialog(reward),
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
