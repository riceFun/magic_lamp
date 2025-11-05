import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// 商品卡片组件
class ProductCard extends StatelessWidget {
  final String name;
  final int points;
  final String wordCode;
  final String? icon;
  final String? imageUrl;
  final String? exchangeFrequency;
  final int? maxExchangeCount;
  final int? minPoints;
  final int? maxPoints;
  final int? currentUserPoints;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.name,
    required this.points,
    required this.wordCode,
    this.icon,
    this.imageUrl,
    this.exchangeFrequency,
    this.maxExchangeCount,
    this.minPoints,
    this.maxPoints,
    this.currentUserPoints,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 判断是否为积分范围商品
    final isRangeProduct = minPoints != null && maxPoints != null;
    final requiredPoints = isRangeProduct ? minPoints! : points;

    // 计算兑换进度
    final userPoints = currentUserPoints ?? 0;
    final canAfford = userPoints >= requiredPoints;
    final progress = requiredPoints > 0
        ? (userPoints / requiredPoints).clamp(0.0, 1.0)
        : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 商品图片区域
              Expanded(
                flex: 4,
                child: _buildImageSection(isRangeProduct),
              ),

              // 商品信息区域
              Expanded(
                flex: 6,
                child: _buildInfoSection(
                  isRangeProduct,
                  canAfford,
                  progress,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建图片区域
  Widget _buildImageSection(bool isRangeProduct) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryLightColor.withValues(alpha: 0.3),
                AppTheme.primaryColor.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusLarge),
            ),
          ),
          child: Center(
            child: _buildImageContent(),
          ),
        ),
        // 积分范围角标
        if (isRangeProduct) _buildRangeBadge(),
      ],
    );
  }

  /// 构建图片内容
  Widget _buildImageContent() {
    if (icon != null && icon!.isNotEmpty) {
      return Text(
        icon!,
        style: const TextStyle(fontSize: 64),
      );
    } else if (imageUrl != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.card_giftcard,
              size: 56,
              color: AppTheme.primaryColor,
            );
          },
        ),
      );
    } else {
      return const Icon(
        Icons.card_giftcard,
        size: 56,
        color: AppTheme.primaryColor,
      );
    }
  }

  /// 构建范围积分角标
  Widget _buildRangeBadge() {
    return Positioned(
      top: 6,
      right: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentPurple.withValues(alpha: 0.95),
              AppTheme.primaryColor.withValues(alpha: 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 10,
              color: Colors.white,
            ),
            SizedBox(width: 3),
            Text(
              '范围',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建信息区域
  Widget _buildInfoSection(bool isRangeProduct, bool canAfford, double progress) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 商品名称
          Flexible(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),

          // 积分显示
          _buildPointsBadge(isRangeProduct),

          const SizedBox(height: 8),

          // 兑换进度条
          if (currentUserPoints != null) ...[
            _buildProgressBar(canAfford, progress),
          ],

          // 兑换限制信息
          if (exchangeFrequency != null || maxExchangeCount != null) ...[
            const SizedBox(height: 4),
            _buildExchangeLimit(),
          ],
        ],
      ),
    );
  }

  /// 构建积分徽章
  Widget _buildPointsBadge(bool isRangeProduct) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentOrange.withValues(alpha: 0.2),
            AppTheme.accentYellow.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on,
            size: 14,
            color: AppTheme.accentOrange,
          ),
          const SizedBox(width: 4),
          Text(
            isRangeProduct ? '$minPoints-$maxPoints 积分' : '$points 积分',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentOrange,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建进度条
  Widget _buildProgressBar(bool canAfford, double progress) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // 进度填充
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: canAfford
                        ? [
                            AppTheme.accentGreen.withValues(alpha: 0.8),
                            AppTheme.accentGreen,
                          ]
                        : [
                            AppTheme.accentOrange.withValues(alpha: 0.6),
                            AppTheme.accentOrange.withValues(alpha: 0.8),
                          ],
                  ),
                ),
              ),
            ),
            // 文字叠加层
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      canAfford ? '✓ 可兑换' : '× 积分不足',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: canAfford && progress > 0.3
                            ? Colors.white
                            : AppTheme.textPrimaryColor,
                        shadows: canAfford && progress > 0.3
                            ? [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: progress > 0.7
                            ? Colors.white
                            : AppTheme.textPrimaryColor,
                        shadows: progress > 0.7
                            ? [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建兑换限制信息
  Widget _buildExchangeLimit() {
    final limitText = _getExchangeLimitText(exchangeFrequency, maxExchangeCount);

    return Row(
      children: [
        Icon(
          Icons.info_outline,
          size: 10,
          color: AppTheme.textSecondaryColor.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            limitText,
            style: TextStyle(
              fontSize: 9,
              color: AppTheme.textSecondaryColor.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 获取兑换限制文本
  String _getExchangeLimitText(String? frequency, int? maxCount) {
    final List<String> limits = [];

    if (frequency != null) {
      switch (frequency) {
        case 'daily':
          limits.add('每日可兑换');
          break;
        case 'weekly':
          limits.add('每周可兑换');
          break;
        case 'monthly':
          limits.add('每月可兑换');
          break;
        case 'quarterly':
          limits.add('每季度可兑换');
          break;
        case 'yearly':
          limits.add('每年可兑换');
          break;
      }
    }

    if (maxCount != null) {
      limits.add('最多$maxCount次');
    }

    return limits.isEmpty ? '' : limits.join('・');
  }
}
