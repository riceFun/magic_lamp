import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// 自定义卡片组件
/// 设计理念：可爱风格，适合儿童
class CustomCard extends StatelessWidget {
  /// 卡片内容
  final Widget child;

  /// 点击回调
  final VoidCallback? onTap;

  /// 内边距
  final EdgeInsets? padding;

  /// 圆角大小
  final double? borderRadius;

  /// 阴影深度
  final double? elevation;

  /// 边框颜色
  final Color? borderColor;

  /// 边框宽度
  final double? borderWidth;

  /// 背景颜色
  final Color? backgroundColor;

  /// 外边距
  final EdgeInsets? margin;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.elevation,
    this.borderColor,
    this.borderWidth,
    this.backgroundColor,
    this.margin,
  });

  /// 获取兑换限制文本
  static String _getExchangeLimitText(String? frequency, int? maxCount) {
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

  /// 带标题的卡片（快捷构造）
  factory CustomCard.withTitle({
    Key? key,
    required String title,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Widget? trailing,
  }) {
    return CustomCard(
      key: key,
      onTap: onTap,
      padding: EdgeInsets.zero,
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: padding ?? const EdgeInsets.all(AppTheme.spacingSmall),
            child: child,
          ),
        ],
      ),
    );
  }

  /// 积分卡片（快捷构造）
  factory CustomCard.points({
    Key? key,
    required int points,
    required String label,
    VoidCallback? onTap,
    Color? color,
    IconData? icon,
  }) {
    return CustomCard(
      key: key,
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: Column(
        children: [
          if (icon != null)
            Icon(
              icon,
              size: 40,
              color: color ?? AppTheme.primaryColor,
            ),
          if (icon != null) const SizedBox(height: AppTheme.spacingSmall),
          Text(
            '$points',
            style: TextStyle(
              fontSize: AppTheme.fontSizeTitle,
              fontWeight: FontWeight.bold,
              color: color ?? AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXSmall),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 商品卡片（快捷构造）
  factory CustomCard.product({
    Key? key,
    required String name,
    required int points,
    required String wordCode,
    String? icon,
    String? imageUrl,
    String? exchangeFrequency,
    int? maxExchangeCount,
    int? minPoints,
    int? maxPoints,
    int? currentUserPoints,
    VoidCallback? onTap,
  }) {
    // 判断是否为积分范围商品
    final isRangeProduct = minPoints != null && maxPoints != null;
    final requiredPoints = isRangeProduct ? minPoints : points;

    // 计算兑换进度
    final userPoints = currentUserPoints ?? 0;
    final canAfford = userPoints >= requiredPoints;
    final progress = requiredPoints > 0 ? (userPoints / requiredPoints).clamp(0.0, 1.0) : 0.0;

    return CustomCard(
      key: key,
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderRadius: AppTheme.radiusLarge,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 商品图片区域
              Container(
                height: 140,
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
                  child: icon != null && icon.isNotEmpty
                      ? Text(
                          icon,
                          style: const TextStyle(fontSize: 72),
                        )
                      : imageUrl != null
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppTheme.radiusLarge),
                              ),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.card_giftcard,
                                    size: 64,
                                    color: AppTheme.primaryColor,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.card_giftcard,
                              size: 64,
                              color: AppTheme.primaryColor,
                            ),
                ),
              ),

              // 商品信息区域
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 商品名称
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // 积分显示
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSmall,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.accentOrange.withValues(alpha: 0.2),
                                AppTheme.accentYellow.withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
                                isRangeProduct
                                    ? '$minPoints-$maxPoints'
                                    : '$points',
                                style: const TextStyle(
                                  fontSize: AppTheme.fontSizeSmall,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // 词汇代号
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSmall,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Text(
                              wordCode,
                              style: const TextStyle(
                                fontSize: AppTheme.fontSizeXSmall,
                                color: AppTheme.accentGreen,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 兑换进度条
                    if (currentUserPoints != null) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                canAfford ? '可兑换' : '不可兑换',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeXSmall,
                                  fontWeight: FontWeight.bold,
                                  color: canAfford
                                      ? AppTheme.accentGreen
                                      : AppTheme.textSecondaryColor,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeXSmall,
                                  fontWeight: FontWeight.bold,
                                  color: canAfford
                                      ? AppTheme.accentGreen
                                      : AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // 进度条
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  canAfford
                                      ? AppTheme.accentGreen
                                      : AppTheme.accentOrange,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // 兑换限制信息
                    if (exchangeFrequency != null || maxExchangeCount != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: AppTheme.textSecondaryColor.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _getExchangeLimitText(exchangeFrequency, maxExchangeCount),
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeXSmall,
                                color: AppTheme.textSecondaryColor.withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // 积分范围角标
          if (isRangeProduct)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentPurple.withValues(alpha: 0.9),
                      AppTheme.primaryColor.withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentPurple.withValues(alpha: 0.3),
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
                      size: 12,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '范围',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.cardColor,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppTheme.radiusMedium,
        ),
        border: borderColor != null
            ? Border.all(
                color: borderColor!,
                width: borderWidth ?? 1,
              )
            : null,
        boxShadow: elevation != null && elevation! > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: elevation! * 4,
                  offset: Offset(0, elevation!),
                ),
              ]
            : AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppTheme.radiusMedium,
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppTheme.spacingMedium),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppTheme.radiusMedium,
        ),
        child: card,
      );
    }

    return card;
  }
}
