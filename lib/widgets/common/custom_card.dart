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
