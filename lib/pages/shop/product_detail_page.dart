import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/reward_provider.dart';
import '../../providers/exchange_provider.dart';
import '../../providers/user_provider.dart';
import '../../data/models/reward.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

/// 商品详情页面
class ProductDetailPage extends StatefulWidget {
  final int rewardId;

  const ProductDetailPage({super.key, required this.rewardId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Reward? _reward;
  bool _isLoading = true;
  bool _isExchanging = false;

  @override
  void initState() {
    super.initState();
    _loadReward();
  }

  Future<void> _loadReward() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rewardProvider = context.read<RewardProvider>();
      final reward = await rewardProvider.getRewardById(widget.rewardId);
      setState(() {
        _reward = reward;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载商品失败：$e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  /// 删除商品
  Future<void> _deleteReward() async {
    if (_reward == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除商品 "${_reward!.name}" 吗？此操作不可撤销。'),
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

    if (confirmed != true) return;

    try {
      final rewardProvider = context.read<RewardProvider>();
      final success = await rewardProvider.deleteReward(_reward!.id!);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('商品已删除')),
        );
        // 返回到商城页面
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
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

  /// 兑换商品
  Future<void> _exchangeReward() async {
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

    if (_reward == null) return;

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认兑换'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要兑换 "${_reward!.name}" 吗？'),
            SizedBox(height: AppTheme.spacingMedium),
            Container(
              padding: EdgeInsets.all(AppTheme.spacingSmall),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.monetization_on,
                    color: AppTheme.accentOrange,
                    size: 20,
                  ),
                  SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: Text(
                      '将消耗 ${_reward!.points} 积分',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        color: AppTheme.accentOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('确认兑换'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isExchanging = true;
    });

    try {
      final exchangeProvider = context.read<ExchangeProvider>();
      final exchangeId = await exchangeProvider.exchangeReward(
        userId: user.id!,
        rewardId: _reward!.id!,
      );

      if (exchangeId != null) {
        // 刷新用户积分
        await userProvider.refreshCurrentUser();

        if (mounted) {
          // 显示成功对话框
          _showSuccessDialog();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(exchangeProvider.errorMessage ?? '兑换失败'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('兑换失败：$e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExchanging = false;
        });
      }
    }
  }

  /// 显示兑换成功对话框
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppTheme.accentGreen,
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
              '恭喜你成功兑换 "${_reward!.name}"',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppTheme.textPrimaryColor,
              ),
            ),
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
                      '请到"我的"页面查看兑换记录',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              context.push(AppConstants.routeExchangeHistory);
            },
            child: Text('查看记录'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: Text('知道了'),
          ),
        ],
      ),
    );
  }

  /// 获取类型图标
  IconData _getCategoryIcon(String category) {
    switch (category) {
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
  String _getCategoryText(String category) {
    switch (category) {
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
        title: Text('商品详情'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: _deleteReward,
            tooltip: '删除商品',
          ),
        ],
      ),
      body: _isLoading
          ? LoadingWidget(message: '加载商品信息...')
          : _reward == null
              ? Center(
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
                        '商品不存在',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              : Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final user = userProvider.currentUser;
                    final userPoints = user?.totalPoints ?? 0;
                    final canAfford = userPoints >= _reward!.points;

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(AppTheme.spacingLarge),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 商品图标和名称
                                Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              AppTheme.primaryColor,
                                              AppTheme.primaryDarkColor,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusLarge,
                                          ),
                                          boxShadow: AppTheme.cardShadow,
                                        ),
                                        child: Icon(
                                          _getCategoryIcon(_reward!.category),
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: AppTheme.spacingMedium),
                                      Text(
                                        _reward!.name,
                                        style: TextStyle(
                                          fontSize: AppTheme.fontSizeXLarge,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: AppTheme.spacingXSmall),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppTheme.spacingSmall,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusSmall,
                                          ),
                                        ),
                                        child: Text(
                                          _getCategoryText(_reward!.category),
                                          style: TextStyle(
                                            fontSize: AppTheme.fontSizeSmall,
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: AppTheme.spacingLarge),

                                // 积分信息
                                Container(
                                  padding: EdgeInsets.all(AppTheme.spacingMedium),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                    boxShadow: AppTheme.cardShadow,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          Icon(
                                            Icons.monetization_on,
                                            size: 32,
                                            color: AppTheme.accentOrange,
                                          ),
                                          SizedBox(height: AppTheme.spacingXSmall),
                                          Text(
                                            '${_reward!.points}',
                                            style: TextStyle(
                                              fontSize: AppTheme.fontSizeXLarge,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.accentOrange,
                                            ),
                                          ),
                                          Text(
                                            '所需积分',
                                            style: TextStyle(
                                              fontSize: AppTheme.fontSizeSmall,
                                              color: AppTheme.textSecondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        width: 1,
                                        height: 60,
                                        color: AppTheme.dividerColor,
                                      ),
                                      Column(
                                        children: [
                                          Icon(
                                            Icons.inventory,
                                            size: 32,
                                            color: _reward!.stock == -1 ||
                                                    _reward!.stock > 10
                                                ? AppTheme.accentGreen
                                                : _reward!.stock > 0
                                                    ? AppTheme.accentOrange
                                                    : AppTheme.accentRed,
                                          ),
                                          SizedBox(height: AppTheme.spacingXSmall),
                                          Text(
                                            _reward!.stock == -1
                                                ? '∞'
                                                : '${_reward!.stock}',
                                            style: TextStyle(
                                              fontSize: AppTheme.fontSizeXLarge,
                                              fontWeight: FontWeight.bold,
                                              color: _reward!.stock == -1 ||
                                                      _reward!.stock > 10
                                                  ? AppTheme.accentGreen
                                                  : _reward!.stock > 0
                                                      ? AppTheme.accentOrange
                                                      : AppTheme.accentRed,
                                            ),
                                          ),
                                          Text(
                                            _reward!.stock == -1
                                                ? '无限库存'
                                                : '剩余库存',
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

                                SizedBox(height: AppTheme.spacingLarge),

                                // 商品描述
                                if (_reward!.description != null &&
                                    _reward!.description!.isNotEmpty) ...[
                                  Text(
                                    '商品描述',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeLarge,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  SizedBox(height: AppTheme.spacingSmall),
                                  Container(
                                    padding: EdgeInsets.all(AppTheme.spacingMedium),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMedium,
                                      ),
                                      boxShadow: AppTheme.cardShadow,
                                    ),
                                    child: Text(
                                      _reward!.description!,
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSizeMedium,
                                        color: AppTheme.textPrimaryColor,
                                        height: 1.6,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: AppTheme.spacingLarge),
                                ],

                                // 用户积分提示
                                Container(
                                  padding: EdgeInsets.all(AppTheme.spacingMedium),
                                  decoration: BoxDecoration(
                                    color: canAfford
                                        ? AppTheme.accentGreen.withValues(alpha: 0.1)
                                        : AppTheme.accentRed.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSmall,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        canAfford
                                            ? Icons.check_circle
                                            : Icons.warning,
                                        color: canAfford
                                            ? AppTheme.accentGreen
                                            : AppTheme.accentRed,
                                        size: 20,
                                      ),
                                      SizedBox(width: AppTheme.spacingSmall),
                                      Expanded(
                                        child: Text(
                                          canAfford
                                              ? '你的积分充足，可以兑换此商品'
                                              : '积分不足，还需 ${_reward!.points - userPoints} 积分',
                                          style: TextStyle(
                                            fontSize: AppTheme.fontSizeSmall,
                                            color: canAfford
                                                ? AppTheme.accentGreen
                                                : AppTheme.accentRed,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 底部按钮区域
                        Container(
                          padding: EdgeInsets.all(AppTheme.spacingMedium),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                offset: Offset(0, -2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: Row(
                              children: [
                                // 编辑按钮
                                Expanded(
                                  flex: 2,
                                  child: CustomButton.secondary(
                                    text: '编辑商品',
                                    onPressed: () {
                                      context.push(
                                        '${AppConstants.routeRewardEdit}?id=${_reward!.id}',
                                      );
                                    },
                                    icon: Icons.edit,
                                  ),
                                ),
                                SizedBox(width: AppTheme.spacingMedium),
                                // 兑换按钮
                                Expanded(
                                  flex: 3,
                                  child: CustomButton.primary(
                                    text: _reward!.hasStock ? '立即兑换' : '已售罄',
                                    onPressed: _reward!.hasStock && canAfford && !_isExchanging
                                        ? _exchangeReward
                                        : null,
                                    isLoading: _isExchanging,
                                    icon: Icons.redeem,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
