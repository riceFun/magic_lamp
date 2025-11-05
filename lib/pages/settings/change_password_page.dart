import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/common/custom_button.dart';
import '../../services/password_storage_service.dart';

/// 修改密码页面
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _superPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureSuperPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _superPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 修改密码
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 验证超级密码
    if (_superPasswordController.text != AppConstants.superPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('超级密码错误'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    // 验证两次输入的密码是否一致
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('两次输入的密码不一致'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 保存密码到本地存储
      await PasswordStorageService.setOperationPassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('密码修改成功'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('修改失败：$e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('修改密码'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(AppTheme.spacingLarge),
          children: [
            // 说明文本
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.accentOrange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.accentOrange,
                    size: 20,
                  ),
                  SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: Text(
                      '请先输入超级密码，以验证身份，然后设置新的4位数字操作密码，提示(159****2333)',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textPrimaryColor,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppTheme.spacingLarge),

            // 超级密码
            Text(
              '超级密码 *',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            TextFormField(
              controller: _superPasswordController,
              obscureText: _obscureSuperPassword,
              decoration: InputDecoration(
                hintText: '请输入超级密码',
                prefixIcon: Icon(Icons.admin_panel_settings),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureSuperPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureSuperPassword = !_obscureSuperPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入超级密码';
                }
                return null;
              },
            ),

            SizedBox(height: AppTheme.spacingLarge),

            // 新密码
            Text(
              '新密码 *',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                hintText: '请输入4位数字新密码',
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入新密码';
                }
                if (value.length != 4) {
                  return '密码必须是4位数字';
                }
                return null;
              },
            ),

            SizedBox(height: AppTheme.spacingLarge),

            // 确认密码
            Text(
              '确认密码 *',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                hintText: '请再次输入新密码',
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请再次输入新密码';
                }
                if (value.length != 4) {
                  return '密码必须是4位数字';
                }
                return null;
              },
            ),

            SizedBox(height: AppTheme.spacingLarge * 2),

            // 提交按钮
            CustomButton.primary(
              text: '确认修改',
              onPressed: _isLoading ? null : _changePassword,
              isLoading: _isLoading,
              icon: Icons.check,
              width: double.infinity,
            ),

            SizedBox(height: AppTheme.spacingLarge),
          ],
        ),
      ),
    );
  }
}
