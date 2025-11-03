import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/reward_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/exchange_provider.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';

/// 商城页面 - 积分兑换奖励
class ShopPage extends StatefulWidget {
  ShopPage({super.key});

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
        title: Text('商城'),
        actions: [
          // 显示当前积分
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.currentUser;
              if (user == null) return SizedBox.shrink();

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.spacingSmall,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: AppTheme.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        size: 20,
                        color: AppTheme.accentYellow,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${user.totalPoints}',
                        style: TextStyle(
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
              // 热门商品
              if (rewardProvider.hotRewards.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingLarge),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: AppTheme.accentOrange,
                          size: 24,
                        ),
                        SizedBox(width: AppTheme.spacingSmall),
                        Text(
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
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLarge,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
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
                SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spacingLarge),
                ),
              ],

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
              SliverToBoxAdapter(
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
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: AppTheme.spacingMedium),
            ],
            Row(
              children: [
                Text(
                  '词汇代号：',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    reward.wordCode,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingMedium),
            Row(
              children: [
                Icon(
                  Icons.monetization_on,
                  size: 24,
                  color: AppTheme.accentYellow,
                ),
                SizedBox(width: AppTheme.spacingSmall),
                Text(
                  '${reward.points} 积分',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            if (!canAfford) ...[
              SizedBox(height: AppTheme.spacingSmall),
              Text(
                '积分不足，还需 ${reward.points - (user?.totalPoints ?? 0)} 积分',
                style: TextStyle(
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
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: canAfford
                ? () async {
                    Navigator.of(context).pop();
                    await _performExchange(context, reward, user!.id!);
                  }
                : null,
            child: Text('兑换'),
          ),
        ],
      ),
    );
  }

  /// 执行兑换操作
  Future<void> _performExchange(BuildContext context, reward, int userId) async {
    final exchangeProvider = context.read<ExchangeProvider>();
    final userProvider = context.read<UserProvider>();

    // 显示加载提示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(AppTheme.spacingLarge),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppTheme.spacingMedium),
              Text('兑换中...'),
            ],
          ),
        ),
      ),
    );

    // 执行兑换
    final exchangeId = await exchangeProvider.exchangeReward(
      userId: userId,
      rewardId: reward.id!,
    );

    // 关闭加载对话框
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (exchangeId != null) {
      // 刷新用户积分
      await userProvider.refreshCurrentUser();

      // 显示成功对话框
      if (context.mounted) {
        _showExchangeSuccessDialog(context, reward);
      }
    } else {
      // 显示失败消息
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exchangeProvider.errorMessage ?? '兑换失败'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  /// 显示兑换成功对话框
  void _showExchangeSuccessDialog(BuildContext context, reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.celebration,
              color: AppTheme.accentYellow,
              size: 28,
            ),
            SizedBox(width: AppTheme.spacingSmall),
            Text('兑换成功！'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '恭喜你兑换了',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            Text(
              reward.name,
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingMedium),
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school,
                        color: AppTheme.accentGreen,
                        size: 20,
                      ),
                      SizedBox(width: AppTheme.spacingSmall),
                      Text(
                        '学习新词汇',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    reward.wordCode,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeXLarge,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  if (reward.description != null) ...{
                    SizedBox(height: 4),
                    Text(
                      reward.description!,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textSecondaryColor,
                        height: 1.5,
                      ),
                    ),
                  },
                ],
              ),
            ),
            SizedBox(height: AppTheme.spacingMedium),
            Text(
              '请找家长领取奖励哦！',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textHintColor,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('好的'),
          ),
        ],
      ),
    );
  }
}
