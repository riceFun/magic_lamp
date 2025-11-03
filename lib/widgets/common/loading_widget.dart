import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// 加载中组件
/// 设计理念：可爱风格，适合儿童
class LoadingWidget extends StatelessWidget {
  /// 加载提示文字
  final String? message;

  /// 加载指示器大小
  final double? size;

  /// 加载指示器颜色
  final Color? color;

  /// 是否显示背景
  final bool showBackground;

  const LoadingWidget({
    super.key,
    this.message,
    this.size,
    this.color,
    this.showBackground = false,
  });

  /// 全屏加载（快捷构造）
  factory LoadingWidget.fullScreen({
    Key? key,
    String? message,
  }) {
    return LoadingWidget(
      key: key,
      message: message ?? '加载中...',
      showBackground: true,
      size: 60,
    );
  }

  /// 小型加载（快捷构造）
  factory LoadingWidget.small({
    Key? key,
    Color? color,
  }) {
    return LoadingWidget(
      key: key,
      size: 20,
      color: color,
    );
  }

  /// 中型加载（快捷构造）
  factory LoadingWidget.medium({
    Key? key,
    String? message,
    Color? color,
  }) {
    return LoadingWidget(
      key: key,
      message: message,
      size: 40,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadingIndicator = SizedBox(
      width: size ?? 40,
      height: size ?? 40,
      child: CircularProgressIndicator(
        strokeWidth: (size ?? 40) / 10,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppTheme.primaryColor,
        ),
      ),
    );

    // 如果有消息，显示加载指示器和文字
    final content = message != null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              loadingIndicator,
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          )
        : loadingIndicator;

    // 如果需要显示背景，用 Container 包裹
    if (showBackground) {
      return Container(
        color: Colors.white.withValues(alpha: 0.9),
        child: Center(child: content),
      );
    }

    return Center(child: content);
  }
}
