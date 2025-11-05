import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/reward_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';
import '../../widgets/points/points_badge.dart';
import '../../widgets/shop/product_card.dart';

/// 商城页面 - 积分兑换奖励
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  String _selectedCategory = 'all'; // 当前选中的分类
  String _sortBy = 'none'; // 排序方式：none, asc, desc
  bool _showAffordableOnly = false; // 是否只显示可兑换的商品

  @override
  void initState() {
    super.initState();
    // 加载奖励商品列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardProvider>().loadAllRewards();
    });
  }

  /// 获取分类图标
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'all':
        return Icons.apps;
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
      default:
        return Icons.card_giftcard;
    }
  }

  /// 获取分类名称
  String _getCategoryName(String category) {
    switch (category) {
      case 'all':
        return '全部';
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
      default:
        return '其他';
    }
  }

  /// 筛选和排序商品
  List _filterAndSortRewards(List rewards, int userPoints) {
    var filteredRewards = rewards.where((reward) {
      // 按分类筛选
      if (_selectedCategory != 'all' && reward.category != _selectedCategory) {
        return false;
      }

      // 按可兑换筛选
      if (_showAffordableOnly) {
        final requiredPoints = reward.minPoints ?? reward.points;
        if (userPoints < requiredPoints) {
          return false;
        }
      }

      return true;
    }).toList();

    // 排序
    if (_sortBy == 'asc') {
      filteredRewards.sort((a, b) {
        final aPoints = a.minPoints ?? a.points;
        final bPoints = b.minPoints ?? b.points;
        return aPoints.compareTo(bPoints);
      });
    } else if (_sortBy == 'desc') {
      filteredRewards.sort((a, b) {
        final aPoints = a.minPoints ?? a.points;
        final bPoints = b.minPoints ?? b.points;
        return bPoints.compareTo(aPoints);
      });
    }

    return filteredRewards;
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

          return Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final currentUserPoints = userProvider.currentUser?.totalPoints ?? 0;

              // 筛选和排序商品
              final displayedRewards = _filterAndSortRewards(
                rewardProvider.activeRewards,
                currentUserPoints,
              );

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
                      _buildCategoryChip('snack'),
                      SizedBox(width: 8),
                      _buildCategoryChip('toy'),
                      SizedBox(width: 8),
                      _buildCategoryChip('book'),
                      SizedBox(width: 8),
                      _buildCategoryChip('entertainment'),
                      SizedBox(width: 8),
                      _buildCategoryChip('privilege'),
                    ],
                  ),
                ),
              ),

              // 标题栏和排序按钮
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.spacingLarge,
                    AppTheme.spacingSmall,
                    AppTheme.spacingLarge,
                    AppTheme.spacingMedium,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_getCategoryName(_selectedCategory)}商品 (${displayedRewards.length})',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 可兑换筛选按钮
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showAffordableOnly = !_showAffordableOnly;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _showAffordableOnly
                                    ? AppTheme.accentGreen.withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _showAffordableOnly
                                      ? AppTheme.accentGreen
                                      : Colors.grey.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _showAffordableOnly
                                        ? Icons.check_circle
                                        : Icons.check_circle_outline,
                                    size: 16,
                                    color: _showAffordableOnly
                                        ? AppTheme.accentGreen
                                        : AppTheme.textSecondaryColor,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '可兑换',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeSmall,
                                      color: _showAffordableOnly
                                          ? AppTheme.accentGreen
                                          : AppTheme.textSecondaryColor,
                                      fontWeight: _showAffordableOnly
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // 排序按钮
                          PopupMenuButton<String>(
                        initialValue: _sortBy,
                        icon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _sortBy == 'asc'
                                  ? Icons.arrow_upward
                                  : _sortBy == 'desc'
                                      ? Icons.arrow_downward
                                      : Icons.sort,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              _sortBy == 'asc'
                                  ? '低→高'
                                  : _sortBy == 'desc'
                                      ? '高→低'
                                      : '排序',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeSmall,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        onSelected: (value) {
                          setState(() {
                            _sortBy = value;
                          });
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'none',
                            child: Row(
                              children: [
                                Icon(Icons.clear, size: 18),
                                SizedBox(width: 8),
                                Text('默认排序'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'asc',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_upward, size: 18),
                                SizedBox(width: 8),
                                Text('积分从低到高'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'desc',
                            child: Row(
                              children: [
                                Icon(Icons.arrow_downward, size: 18),
                                SizedBox(width: 8),
                                Text('积分从高到低'),
                              ],
                            ),
                          ),
                        ],
                      ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 商品网格
              if (displayedRewards.isEmpty)
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
                          '该分类暂无商品',
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
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: AppTheme.spacingMedium,
                      mainAxisSpacing: AppTheme.spacingMedium,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final reward = displayedRewards[index];
                        return ProductCard(
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
                      childCount: displayedRewards.length,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingLarge),
              ),
            ],
          );
            },
          );
        },
      ),
    );
  }

  /// 跳转到商品详情页
  void _showRewardDetail(BuildContext context, reward) {
    context.push('${AppConstants.routeProductDetail}?id=${reward.id}');
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
                    AppTheme.primaryColor,
                    AppTheme.primaryDarkColor,
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
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
