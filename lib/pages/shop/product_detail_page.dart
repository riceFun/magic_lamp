import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/reward_provider.dart';
import '../../providers/exchange_provider.dart';
import '../../providers/user_provider.dart';
import '../../data/models/reward.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/points/points_badge.dart';

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
  bool? _isExchangeable; // 是否可兑换（考虑所有限制）

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

      // 加载完成后检查可兑换状态
      if (reward != null) {
        _checkExchangeAbility();
      }
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

  /// 检查商品是否可兑换（考虑积分、频率、次数等所有限制）
  Future<void> _checkExchangeAbility() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;

    if (user == null || _reward == null) {
      setState(() {
        _isExchangeable = false;
      });
      return;
    }

    final exchangeProvider = context.read<ExchangeProvider>();
    final requiredPoints = _reward!.minPoints ?? _reward!.points;

    final isExchangeable = await exchangeProvider.canUserExchangeReward(
      userId: user.id!,
      rewardId: _reward!.id!,
      userPoints: user.totalPoints,
      requiredPoints: requiredPoints,
      exchangeFrequency: _reward!.exchangeFrequency,
      maxExchangeCount: _reward!.maxExchangeCount,
    );

    if (mounted) {
      setState(() {
        _isExchangeable = isExchangeable;
      });
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('商品已删除')));
        // 返回到商城页面
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败'), backgroundColor: AppTheme.accentRed),
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
    // 如果正在兑换中，直接返回
    if (_isExchanging) return;

    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请先登录'), backgroundColor: AppTheme.accentRed),
      );
      return;
    }

    if (_reward == null) return;

    // 检查库存
    if (!_reward!.hasStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('该商品已售罄'), backgroundColor: AppTheme.accentRed),
      );
      return;
    }

    // 检查是否可兑换，如果不可兑换则显示具体原因
    if (_isExchangeable == false) {
      final exchangeProvider = context.read<ExchangeProvider>();
      final requiredPoints = _reward!.minPoints ?? _reward!.points;

      // 首先检查积分
      if (user.totalPoints < requiredPoints) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('积分不足，还需 ${requiredPoints - user.totalPoints} 积分'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
        return;
      }

      // 如果积分足够，说明是频率或次数限制的问题
      // 尝试执行兑换来获取具体的错误信息
      final exchangeId = await exchangeProvider.exchangeReward(
        userId: user.id!,
        rewardId: _reward!.id!,
      );

      if (exchangeId == null) {
        // 显示具体的错误信息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exchangeProvider.errorMessage ?? '无法兑换该商品'),
            backgroundColor: AppTheme.accentRed,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

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

        // 重新检查可兑换状态
        await _checkExchangeAbility();

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
            Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 28),
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
          // 显示当前积分
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.currentUser;
              if (user == null) return SizedBox.shrink();
              return PointsBadge(points: user.totalPoints);
            },
          ),
          SizedBox(width: 8),
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
                                  Row(
                                    children: [
                                      // 图标容器（带类型角标）
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  AppTheme.primaryLightColor
                                                      .withValues(alpha: 0.3),
                                                  AppTheme.primaryColor
                                                      .withValues(alpha: 0.15),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusLarge,
                                                  ),
                                              boxShadow: AppTheme.cardShadow,
                                            ),
                                            child: Center(
                                              child: Text(
                                                _reward!.icon != null &&
                                                        _reward!
                                                            .icon!
                                                            .isNotEmpty
                                                    ? _reward!.icon!
                                                    : '🎁', // 默认礼物emoji
                                                style: TextStyle(fontSize: 64),
                                              ),
                                            ),
                                          ),
                                          // 类型角标
                                          Positioned(
                                            top: -6,
                                            right: -6,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppTheme.accentPurple,
                                                    AppTheme.primaryColor,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.2),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    _getCategoryIcon(
                                                      _reward!.category,
                                                    ),
                                                    size: 12,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    _getCategoryText(
                                                      _reward!.category,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _reward!.name,
                                              style: TextStyle(
                                                fontSize:
                                                    AppTheme.fontSizeXLarge,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    AppTheme.textPrimaryColor,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            Row(children: [
                                              Icon(Icons.attach_money, size: AppTheme.fontSizeXLarge, color: AppTheme.accentOrange,),
                                              Text(
                                                '${_reward!.points}',
                                                style: TextStyle(
                                                  fontSize:
                                                  AppTheme.fontSizeXLarge,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.accentOrange,
                                                ),
                                              ),
                                            ],),
                                            Text(
                                              '库存：${_reward!.stock == -1 ? '∞' : '${_reward!.stock}'}',
                                              style: TextStyle(
                                                fontSize:
                                                    AppTheme.fontSizeMedium,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    _reward!.stock == -1 ||
                                                        _reward!.stock > 10
                                                    ? AppTheme.accentGreen
                                                    : _reward!.stock > 0
                                                    ? AppTheme.accentOrange
                                                    : AppTheme.accentRed,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: AppTheme.spacingMedium),
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
                              Text(
                                _reward!.description!,
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeMedium,
                                  color: AppTheme.textPrimaryColor,
                                  height: 1.6,
                                ),
                              ),
                              SizedBox(height: AppTheme.spacingLarge),
                            ],

                            // 用户积分提示
                            Visibility(
                              visible: canAfford == false,
                              child: Container(
                                padding: EdgeInsets.all(AppTheme.spacingMedium),
                                decoration: BoxDecoration(
                                  color: canAfford
                                      ? AppTheme.accentGreen.withValues(
                                          alpha: 0.1,
                                        )
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
                              child: GestureDetector(
                                onTap: () {
                                  context.push(
                                    '${AppConstants.routeRewardEdit}?id=${_reward!.id}',
                                  );
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                    border: Border.all(
                                      color: AppTheme.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '编辑商品',
                                        style: TextStyle(
                                          fontSize: AppTheme.fontSizeMedium,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingMedium),
                            // 兑换按钮
                            Expanded(
                              flex: 3,
                              child: GestureDetector(
                                onTap: _exchangeReward, // 总是可以点击
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient:
                                        (_reward!.hasStock &&
                                            (_isExchangeable ?? false) &&
                                            !_isExchanging)
                                        ? LinearGradient(
                                            colors: [
                                              AppTheme.primaryColor,
                                              AppTheme.primaryDarkColor,
                                            ],
                                          )
                                        : null,
                                    color:
                                        (_reward!.hasStock &&
                                            (_isExchangeable ?? false) &&
                                            !_isExchanging)
                                        ? null
                                        : Colors.grey.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isExchanging)
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      else
                                        Icon(
                                          Icons.redeem,
                                          color:
                                              (_reward!.hasStock &&
                                                  (_isExchangeable ?? false))
                                              ? Colors.white
                                              : AppTheme.textSecondaryColor,
                                          size: 20,
                                        ),
                                      SizedBox(width: 8),
                                      Text(
                                        _reward!.hasStock ? '立即兑换' : '已售罄',
                                        style: TextStyle(
                                          fontSize: AppTheme.fontSizeMedium,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              (_reward!.hasStock &&
                                                  (_isExchangeable ?? false) &&
                                                  !_isExchanging)
                                              ? Colors.white
                                              : AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
