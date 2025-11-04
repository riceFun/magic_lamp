import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/reward_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';
import '../../widgets/points/points_badge.dart';

/// 商城页面 - 积分兑换奖励
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  bool _isManagementMode = false; // 管理模式

  @override
  void initState() {
    super.initState();
    // 加载奖励商品列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardProvider>().loadAllRewards();
    });
  }

  /// 切换管理模式
  void _toggleManagementMode() {
    setState(() {
      _isManagementMode = !_isManagementMode;
    });
  }

  /// 删除商品
  Future<void> _deleteReward(int rewardId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除这个商品吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('删除', style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final rewardProvider = context.read<RewardProvider>();
      final success = await rewardProvider.deleteReward(rewardId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('商品已删除')),
        );
      }
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
            Text('商城'),
          ],
        ),
        actions: [
          // 管理模式切换按钮
          IconButton(
            icon: Icon(
              _isManagementMode ? Icons.visibility : Icons.edit,
              color: _isManagementMode ? AppTheme.accentOrange : null,
            ),
            onPressed: _toggleManagementMode,
            tooltip: _isManagementMode ? '退出管理模式' : '管理模式',
          ),
          // 显示当前积分
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.currentUser;
              if (user == null) return SizedBox.shrink();
              return PointsBadge(points: user.totalPoints);
            },
          ),
        ],
      ),
      body: Consumer<RewardProvider>(
        builder: (context, rewardProvider, child) {
          if (rewardProvider.isLoading) {
            return LoadingWidget.medium(
              message: '加载商品中...',
            );
          }

          if (rewardProvider.errorMessage != null) {
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
                    rewardProvider.errorMessage!,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          if (rewardProvider.activeRewards.isEmpty) {
            return EmptyWidget.noRewards();
          }

          return CustomScrollView(
            slivers: [
              // 所有商品
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingLarge),
                  child: Text(
                    '全部商品',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLarge,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: AppTheme.spacingMedium,
                    mainAxisSpacing: AppTheme.spacingMedium,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final reward = rewardProvider.activeRewards[index];
                      return Stack(
                        children: [
                          CustomCard.product(
                            name: reward.name,
                            points: reward.points,
                            wordCode: reward.wordCode,
                            imageUrl: reward.imageUrl,
                            exchangeFrequency: reward.exchangeFrequency,
                            maxExchangeCount: reward.maxExchangeCount,
                            onTap: () {
                              _showRewardDetail(context, reward);
                            },
                          ),
                          // 管理模式下显示操作按钮
                          if (_isManagementMode)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 编辑按钮
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.edit, size: 18),
                                      color: AppTheme.primaryColor,
                                      padding: EdgeInsets.all(8),
                                      constraints: BoxConstraints(),
                                      onPressed: () {
                                        context.push(
                                          '${AppConstants.routeRewardEdit}?id=${reward.id}',
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  // 删除按钮
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.delete, size: 18),
                                      color: AppTheme.accentRed,
                                      padding: EdgeInsets.all(8),
                                      constraints: BoxConstraints(),
                                      onPressed: () {
                                        _deleteReward(reward.id!);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                    childCount: rewardProvider.activeRewards.length,
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
      floatingActionButton: _isManagementMode
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push(AppConstants.routeRewardEdit);
              },
              icon: Icon(Icons.add),
              label: Text('新建商品'),
              backgroundColor: AppTheme.primaryColor,
            )
          : null,
    );
  }

  /// 跳转到商品详情页
  void _showRewardDetail(BuildContext context, reward) {
    context.push('${AppConstants.routeProductDetail}?id=${reward.id}');
  }
}
