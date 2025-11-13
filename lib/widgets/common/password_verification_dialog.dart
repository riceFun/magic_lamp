import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/user_provider.dart';

/// 密码验证模式
enum PasswordMode {
  /// 用户操作密码（4位数字）
  user,

  /// 超级密码（2333）
  super_,
}

/// 密码验证对话框
class PasswordVerificationDialog extends StatefulWidget {
  final PasswordMode mode;
  final String? title;
  final String? message;
  final VoidCallback onVerified;

  const PasswordVerificationDialog({
    super.key,
    required this.mode,
    this.title,
    this.message,
    required this.onVerified,
  });

  @override
  State<PasswordVerificationDialog> createState() =>
      _PasswordVerificationDialogState();
}

class _PasswordVerificationDialogState
    extends State<PasswordVerificationDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// 验证密码
  Future<void> _verifyPassword() async {
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      setState(() {
        _errorMessage = '请输入密码';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      bool isValid = false;

      if (widget.mode == PasswordMode.super_) {
        // 验证超级密码
        isValid = password == AppConstants.superPassword;
        if (!isValid) {
          setState(() {
            _errorMessage = '超级密码错误';
            _isVerifying = false;
          });
          return;
        }
      } else {
        // 验证用户操作密码（从当前用户的password字段读取）
        final userProvider = context.read<UserProvider>();
        final currentUser = userProvider.currentUser;

        if (currentUser == null) {
          setState(() {
            _errorMessage = '未登录，请先登录';
            _isVerifying = false;
          });
          return;
        }

        // 从用户对象的password字段验证
        isValid = password == currentUser.password;
        if (!isValid) {
          setState(() {
            _errorMessage = '操作密码错误';
            _isVerifying = false;
          });
          return;
        }
      }

      // 验证成功
      if (mounted) {
        Navigator.of(context).pop();
        widget.onVerified();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '验证失败：$e';
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuperMode = widget.mode == PasswordMode.super_;
    final defaultTitle = isSuperMode ? '超级密码验证' : '身份验证';
    final defaultMessage = isSuperMode
        ? '请输入超级密码以继续此操作'
        : '请输入您的操作密码以继续';

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isSuperMode ? Icons.admin_panel_settings : Icons.lock,
            color: isSuperMode ? AppTheme.accentRed : AppTheme.primaryColor,
          ),
          SizedBox(width: AppTheme.spacingSmall),
          Text(widget.title ?? defaultTitle),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 提示消息
          Text(
            widget.message ?? defaultMessage,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: AppTheme.spacingLarge),

          // 密码输入框
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofocus: true,
            decoration: InputDecoration(
              labelText: isSuperMode ? '超级密码' : '操作密码',
              hintText: isSuperMode ? '请输入超级密码' : '请输入4位操作密码',
              prefixIcon: Icon(Icons.password),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              errorText: _errorMessage,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              if (!isSuperMode) LengthLimitingTextInputFormatter(4),
            ],
            onSubmitted: (_) => _verifyPassword(),
          ),

          // 提示信息
          if (!isSuperMode) ...[
            SizedBox(height: AppTheme.spacingSmall),
            Text(
              '提示：操作密码为4位数字',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textHintColor,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _verifyPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isSuperMode ? AppTheme.accentRed : AppTheme.primaryColor,
          ),
          child: _isVerifying
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text('确认'),
        ),
      ],
    );
  }
}

/// 显示密码验证对话框的便捷方法
Future<void> showPasswordVerificationDialog({
  required BuildContext context,
  required PasswordMode mode,
  String? title,
  String? message,
  required VoidCallback onVerified,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PasswordVerificationDialog(
      mode: mode,
      title: title,
      message: message,
      onVerified: onVerified,
    ),
  );
}
