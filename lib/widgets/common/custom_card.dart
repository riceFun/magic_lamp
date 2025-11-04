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
    String? imageUrl,
    String? exchangeFrequency,
    int? maxExchangeCount,
    VoidCallback? onTap,
  }) {
    return CustomCard(
      key: key,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品图片区域
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryLightColor.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.card_giftcard,
                              size: 60,
                              color: AppTheme.primaryColor,
                            );
                          },
                        )
                      : const Icon(
                          Icons.card_giftcard,
                          size: 60,
                          color: AppTheme.primaryColor,
                        ),
                ),
              ],
            ),
          ),
          // 商品信息区域
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 词汇代号
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
                    wordCode,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                // 积分
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      size: 16,
                      color: AppTheme.accentYellow,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$points 积分',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                // 兑换限制信息
                if (exchangeFrequency != null || maxExchangeCount != null) ...[
                  const SizedBox(height: AppTheme.spacingSmall),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getExchangeLimitText(exchangeFrequency, maxExchangeCount),
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeXSmall,
                            color: AppTheme.textSecondaryColor,
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
