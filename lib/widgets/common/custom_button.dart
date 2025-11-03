import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// 自定义按钮组件
/// 设计理念：可爱风格，适合儿童
class CustomButton extends StatelessWidget {
  /// 按钮文字
  final String text;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 按钮类型
  final ButtonType type;

  /// 按钮大小
  final ButtonSize size;

  /// 是否加载中
  final bool isLoading;

  /// 图标
  final IconData? icon;

  /// 是否禁用
  final bool disabled;

  /// 宽度（null 表示自适应）
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.disabled = false,
    this.width,
  });

  /// 主要按钮（快捷构造）
  factory CustomButton.primary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: ButtonType.primary,
      size: size,
      isLoading: isLoading,
      icon: icon,
      width: width,
    );
  }

  /// 次要按钮（快捷构造）
  factory CustomButton.secondary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: ButtonType.secondary,
      size: size,
      isLoading: isLoading,
      icon: icon,
      width: width,
    );
  }

  /// 成功按钮（快捷构造）
  factory CustomButton.success({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: ButtonType.success,
      size: size,
      isLoading: isLoading,
      icon: icon,
      width: width,
    );
  }

  /// 警告按钮（快捷构造）
  factory CustomButton.warning({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: ButtonType.warning,
      size: size,
      isLoading: isLoading,
      icon: icon,
      width: width,
    );
  }

  /// 文本按钮（快捷构造）
  factory CustomButton.text({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    IconData? icon,
    double? width,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      type: ButtonType.text,
      size: size,
      icon: icon,
      width: width,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 根据类型获取颜色
    final buttonColor = _getButtonColor();
    final textColor = _getTextColor();

    // 根据大小获取尺寸
    final padding = _getPadding();
    final fontSize = _getFontSize();

    // 是否可点击
    final isEnabled = !disabled && !isLoading && onPressed != null;

    return SizedBox(
      width: width,
      child: Material(
        color: type == ButtonType.text ? Colors.transparent : buttonColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        elevation: type == ButtonType.text ? 0 : 2,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            padding: padding,
            decoration: type == ButtonType.text
                ? null
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: type == ButtonType.secondary
                        ? Border.all(color: AppTheme.primaryColor, width: 1.5)
                        : null,
                  ),
            child: Row(
              mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: fontSize,
                    height: fontSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                else if (icon != null)
                  Icon(
                    icon,
                    size: fontSize * 1.2,
                    color: textColor,
                  ),
                if ((isLoading || icon != null) && text.isNotEmpty)
                  const SizedBox(width: AppTheme.spacingSmall),
                if (text.isNotEmpty)
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 获取按钮颜色
  Color _getButtonColor() {
    if (disabled) return AppTheme.dividerColor;

    switch (type) {
      case ButtonType.primary:
        return AppTheme.primaryColor;
      case ButtonType.secondary:
        return Colors.white;
      case ButtonType.success:
        return AppTheme.accentGreen;
      case ButtonType.warning:
        return AppTheme.accentOrange;
      case ButtonType.text:
        return Colors.transparent;
    }
  }

  /// 获取文字颜色
  Color _getTextColor() {
    if (disabled) return AppTheme.textHintColor;

    switch (type) {
      case ButtonType.primary:
      case ButtonType.success:
      case ButtonType.warning:
        return Colors.white;
      case ButtonType.secondary:
      case ButtonType.text:
        return AppTheme.primaryColor;
    }
  }

  /// 获取内边距
  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: AppTheme.spacingSmall,
        );
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLarge,
          vertical: AppTheme.spacingMedium,
        );
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXLarge,
          vertical: AppTheme.spacingLarge,
        );
    }
  }

  /// 获取字体大小
  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return AppTheme.fontSizeSmall;
      case ButtonSize.medium:
        return AppTheme.fontSizeMedium;
      case ButtonSize.large:
        return AppTheme.fontSizeLarge;
    }
  }
}

/// 按钮类型
enum ButtonType {
  /// 主要按钮（蓝色）
  primary,

  /// 次要按钮（白色带边框）
  secondary,

  /// 成功按钮（绿色）
  success,

  /// 警告按钮（橙色）
  warning,

  /// 文本按钮（无背景）
  text,
}

/// 按钮大小
enum ButtonSize {
  /// 小号
  small,

  /// 中号
  medium,

  /// 大号
  large,
}
