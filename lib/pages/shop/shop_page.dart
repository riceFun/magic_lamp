import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/reward_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';

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
        title: const Text('商城'),
        actions: [
          // 显示当前积分
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.currentUser;
              if (user == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.spacingSmall,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: AppTheme.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        size: 20,
                        color: AppTheme.accentYellow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${user.totalPoints}',
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
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
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppTheme.accentRed,
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  Text(
                    rewardProvider.errorMessage!,
                    style: const TextStyle(
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
              // 热门商品
              if (rewardProvider.hotRewards.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLarge),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: AppTheme.accentOrange,
                          size: 24,
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        const Text(
                          '热门商品',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLarge,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: AppTheme.spacingMedium,
                      mainAxisSpacing: AppTheme.spacingMedium,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final reward = rewardProvider.hotRewards[index];
                        return CustomCard.product(
                          name: reward.name,
                          points: reward.points,
                          wordCode: reward.wordCode,
                          imageUrl: reward.imageUrl,
                          isHot: reward.isHot,
                          isSpecial: reward.isSpecial,
                          onTap: () {
                            _showRewardDetail(context, reward);
                          },
                        );
                      },
                      childCount: rewardProvider.hotRewards.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spacingLarge),
                ),
              ],

              // 所有商品
              const SliverToBoxAdapter(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLarge,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
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
                        imageUrl: reward.imageUrl,
                        isHot: reward.isHot,
                        isSpecial: reward.isSpecial,
                        onTap: () {
                          _showRewardDetail(context, reward);
                        },
                      );
                    },
                    childCount: rewardProvider.activeRewards.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingLarge),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 显示奖励详情对话框
  void _showRewardDetail(BuildContext context, reward) {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;
    final canAfford = user != null && user.totalPoints >= reward.points;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reward.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reward.description != null) ...[
              Text(
                reward.description!,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
            ],
            Row(
              children: [
                const Text(
                  '词汇代号：',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    reward.wordCode,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Row(
              children: [
                Icon(
                  Icons.monetization_on,
                  size: 24,
                  color: AppTheme.accentYellow,
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Text(
                  '${reward.points} 积分',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            if (!canAfford) ...[
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                '积分不足，还需 ${reward.points - (user?.totalPoints ?? 0)} 积分',
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: AppTheme.accentRed,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: canAfford
                ? () {
                    Navigator.of(context).pop();
                    // TODO: 实现兑换功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('兑换功能开发中...')),
                    );
                  }
                : null,
            child: const Text('兑换'),
          ),
        ],
      ),
    );
  }
}
