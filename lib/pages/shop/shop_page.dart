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
  @override
  void initState() {
    super.initState();
    // 加载奖励商品列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardProvider>().loadAllRewards();
    });
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
          // 添加商品按钮
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: () {
              context.push(AppConstants.routeRewardEdit);
            },
            tooltip: '添加商品',
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
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final currentUserPoints = userProvider.currentUser?.totalPoints ?? 0;

                  return SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLarge,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: AppTheme.spacingMedium,
                        mainAxisSpacing: AppTheme.spacingMedium,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final reward = rewardProvider.activeRewards[index];
                          return CustomCard.product(
                            name: reward.name,
                            points: reward.points,
                            wordCode: reward.wordCode,
                            icon: reward.icon,
                            imageUrl: reward.imageUrl,
                            exchangeFrequency: reward.exchangeFrequency,
                            maxExchangeCount: reward.maxExchangeCount,
                            minPoints: reward.minPoints,
                            maxPoints: reward.maxPoints,
                            currentUserPoints: currentUserPoints,
                            onTap: () {
                              _showRewardDetail(context, reward);
                            },
                          );
                        },
                        childCount: rewardProvider.activeRewards.length,
                      ),
                    ),
                  );
                },
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

  /// 跳转到商品详情页
  void _showRewardDetail(BuildContext context, reward) {
    context.push('${AppConstants.routeProductDetail}?id=${reward.id}');
  }
}
