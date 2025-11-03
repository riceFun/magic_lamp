import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

/// 自定义输入框组件
/// 设计理念：可爱风格，适合儿童
class CustomTextField extends StatelessWidget {
  /// 控制器
  final TextEditingController? controller;

  /// 提示文字
  final String? hintText;

  /// 标签文字
  final String? labelText;

  /// 前缀图标
  final IconData? prefixIcon;

  /// 后缀图标
  final IconData? suffixIcon;

  /// 后缀图标点击回调
  final VoidCallback? onSuffixIconTap;

  /// 是否密码输入
  final bool obscureText;

  /// 键盘类型
  final TextInputType? keyboardType;

  /// 输入格式限制
  final List<TextInputFormatter>? inputFormatters;

  /// 最大行数（1为单行，null为无限制）
  final int? maxLines;

  /// 最小行数
  final int? minLines;

  /// 最大长度
  final int? maxLength;

  /// 是否只读
  final bool readOnly;

  /// 是否启用
  final bool enabled;

  /// 错误提示文字
  final String? errorText;

  /// 输入改变回调
  final ValueChanged<String>? onChanged;

  /// 提交回调
  final ValueChanged<String>? onSubmitted;

  /// 焦点获取回调
  final VoidCallback? onTap;

  /// 填充颜色
  final Color? fillColor;

  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.fillColor,
  });

  /// 搜索框（快捷构造）
  factory CustomTextField.search({
    Key? key,
    TextEditingController? controller,
    String? hintText,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      hintText: hintText ?? '搜索...',
      prefixIcon: Icons.search,
      suffixIcon: controller?.text.isNotEmpty ?? false ? Icons.clear : null,
      onSuffixIconTap: onClear,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: TextInputType.text,
    );
  }

  /// 密码框（快捷构造）
  factory CustomTextField.password({
    Key? key,
    TextEditingController? controller,
    String? hintText,
    String? labelText,
    bool obscureText = true,
    VoidCallback? onToggleVisibility,
    ValueChanged<String>? onChanged,
    String? errorText,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      hintText: hintText ?? '请输入密码',
      labelText: labelText,
      prefixIcon: Icons.lock_outline,
      suffixIcon: obscureText ? Icons.visibility_off : Icons.visibility,
      onSuffixIconTap: onToggleVisibility,
      obscureText: obscureText,
      keyboardType: TextInputType.visiblePassword,
      onChanged: onChanged,
      errorText: errorText,
    );
  }

  /// 数字输入框（快捷构造）
  factory CustomTextField.number({
    Key? key,
    TextEditingController? controller,
    String? hintText,
    String? labelText,
    IconData? prefixIcon,
    int? maxLength,
    bool allowDecimal = false,
    ValueChanged<String>? onChanged,
    String? errorText,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      keyboardType: allowDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: [
        if (!allowDecimal) FilteringTextInputFormatter.digitsOnly,
        if (allowDecimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      maxLength: maxLength,
      onChanged: onChanged,
      errorText: errorText,
    );
  }

  /// 多行文本框（快捷构造）
  factory CustomTextField.multiline({
    Key? key,
    TextEditingController? controller,
    String? hintText,
    String? labelText,
    int? maxLines,
    int? minLines,
    int? maxLength,
    ValueChanged<String>? onChanged,
    String? errorText,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      hintText: hintText,
      labelText: labelText,
      maxLines: maxLines,
      minLines: minLines ?? 3,
      maxLength: maxLength,
      onChanged: onChanged,
      errorText: errorText,
      keyboardType: TextInputType.multiline,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      readOnly: readOnly,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      style: const TextStyle(
        fontSize: AppTheme.fontSizeMedium,
        color: AppTheme.textPrimaryColor,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        errorText: errorText,
        filled: true,
        fillColor: fillColor ??
            (enabled ? AppTheme.cardColor : AppTheme.backgroundColor),

        // 前缀图标
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: enabled
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryColor,
              )
            : null,

        // 后缀图标
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(
                  suffixIcon,
                  color: enabled
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor,
                ),
                onPressed: enabled ? onSuffixIconTap : null,
              )
            : null,

        // 边框样式
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: const BorderSide(color: AppTheme.accentRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: const BorderSide(color: AppTheme.accentRed, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),

        // 内边距
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: AppTheme.spacingMedium,
        ),

        // 计数器样式
        counterStyle: const TextStyle(
          fontSize: AppTheme.fontSizeSmall,
          color: AppTheme.textSecondaryColor,
        ),
      ),
    );
  }
}
