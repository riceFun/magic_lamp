import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// 空状态组件
/// 设计理念：可爱风格，适合儿童
class EmptyWidget extends StatelessWidget {
  /// 空状态图标
  final IconData? icon;

  /// 空状态提示文字
  final String message;

  /// 子标题文字
  final String? subtitle;

  /// 操作按钮文字
  final String? actionText;

  /// 操作按钮回调
  final VoidCallback? onAction;

  /// 图标大小
  final double? iconSize;

  /// 图标颜色
  final Color? iconColor;

  const EmptyWidget({
    super.key,
    this.icon,
    required this.message,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.iconSize,
    this.iconColor,
  });

  /// 无数据（快捷构造）
  factory EmptyWidget.noData({
    Key? key,
    String? message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return EmptyWidget(
      key: key,
      icon: Icons.inbox_outlined,
      message: message ?? '暂无数据',
      subtitle: '这里空空如也~',
      actionText: actionText,
      onAction: onAction,
    );
  }

  /// 无任务（快捷构造）
  factory EmptyWidget.noTasks({
    Key? key,
    VoidCallback? onAction,
  }) {
    return EmptyWidget(
      key: key,
      icon: Icons.task_alt,
      message: '暂无任务',
      subtitle: '快去添加一些任务吧！',
      actionText: '添加任务',
      onAction: onAction,
      iconColor: AppTheme.accentGreen,
    );
  }

  /// 无奖励商品（快捷构造）
  factory EmptyWidget.noRewards({
    Key? key,
    VoidCallback? onAction,
  }) {
    return EmptyWidget(
      key: key,
      icon: Icons.card_giftcard,
      message: '暂无奖励商品',
      subtitle: '快去添加一些奖励吧！',
      actionText: '添加奖励',
      onAction: onAction,
      iconColor: AppTheme.accentYellow,
    );
  }

  /// 无历史记录（快捷构造）
  factory EmptyWidget.noHistory({
    Key? key,
  }) {
    return EmptyWidget(
      key: key,
      icon: Icons.history,
      message: '暂无历史记录',
      subtitle: '完成任务或兑换奖励后会显示记录',
    );
  }

  /// 搜索无结果（快捷构造）
  factory EmptyWidget.noSearchResults({
    Key? key,
    String? keyword,
  }) {
    return EmptyWidget(
      key: key,
      icon: Icons.search_off,
      message: '未找到相关内容',
      subtitle: keyword != null ? '没有找到与"$keyword"相关的内容' : '换个关键词试试吧',
    );
  }

  /// 网络错误（快捷构造）
  factory EmptyWidget.networkError({
    Key? key,
    VoidCallback? onRetry,
  }) {
    return EmptyWidget(
      key: key,
      icon: Icons.wifi_off,
      message: '网络连接失败',
      subtitle: '请检查网络设置后重试',
      actionText: '重试',
      onAction: onRetry,
      iconColor: AppTheme.accentRed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标
            if (icon != null)
              Icon(
                icon,
                size: iconSize ?? 80,
                color: iconColor ?? AppTheme.textHintColor,
              ),
            if (icon != null) const SizedBox(height: AppTheme.spacingLarge),

            // 主要提示文字
            Text(
              message,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),

            // 副标题文字
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // 操作按钮
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppTheme.spacingLarge),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXLarge,
                    vertical: AppTheme.spacingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Text(
                  actionText!,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
