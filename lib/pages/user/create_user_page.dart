import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../providers/user_provider.dart';

/// 创建用户页面
class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedAvatar = 'face';
  bool _obscurePassword = true;
  String? _nameError;
  String? _passwordError;

  // 可选的头像列表
  final List<Map<String, dynamic>> _avatarOptions = [
    {'value': 'face', 'icon': Icons.face, 'label': '笑脸1'},
    {'value': 'face_2', 'icon': Icons.face_2, 'label': '笑脸2'},
    {'value': 'person', 'icon': Icons.person, 'label': '人物'},
    {'value': 'account_circle', 'icon': Icons.account_circle, 'label': '头像'},
    {'value': 'child_care', 'icon': Icons.child_care, 'label': '儿童'},
    {'value': 'emoji_people', 'icon': Icons.emoji_people, 'label': '人形'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 创建用户
  Future<void> _createUser() async {
    // 手动验证
    setState(() {
      _nameError = null;
      _passwordError = null;
    });

    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    bool hasError = false;

    if (name.isEmpty) {
      setState(() {
        _nameError = '请输入用户名';
      });
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = '请输入操作密码';
      });
      hasError = true;
    } else if (password.length != 4) {
      setState(() {
        _passwordError = '密码必须是4位数字';
      });
      hasError = true;
    } else if (!RegExp(r'^\d{4}$').hasMatch(password)) {
      setState(() {
        _passwordError = '密码只能包含数字';
      });
      hasError = true;
    }

    if (hasError) {
      return;
    }

    final userProvider = context.read<UserProvider>();

    final userId = await userProvider.createUser(
      name: name,
      avatar: _selectedAvatar,
      role: 'child',
      password: password,
    );

    if (userId != null && mounted) {
      // 创建成功，返回登录页
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('用户创建成功！'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      // 创建失败
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.errorMessage ?? '创建失败'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('创建新用户'),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户名输入
                Text(
                  '用户名',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                SizedBox(height: AppTheme.spacingSmall),
                CustomTextField(
                  controller: _nameController,
                  hintText: '请输入用户名',
                  prefixIcon: Icons.person_outline,
                  errorText: _nameError,
                  onChanged: (value) {
                    if (_nameError != null) {
                      setState(() {
                        _nameError = null;
                      });
                    }
                  },
                ),
                SizedBox(height: AppTheme.spacingLarge),

                  // 选择头像
                  Text(
                    '选择头像',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingMedium),
                  Wrap(
                    spacing: AppTheme.spacingMedium,
                    runSpacing: AppTheme.spacingMedium,
                    children: _avatarOptions.map((avatar) {
                      final isSelected = _selectedAvatar == avatar['value'];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedAvatar = avatar['value'];
                          });
                        },
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withValues(alpha: 0.2)
                                : AppTheme.cardColor,
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.dividerColor,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                avatar['icon'],
                                size: 36,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondaryColor,
                              ),
                              SizedBox(height: 4),
                              Text(
                                avatar['label'],
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeXSmall,
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: AppTheme.spacingLarge),

                // 密码输入（必填）
                Text(
                  '操作密码（必填）',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                SizedBox(height: AppTheme.spacingSmall),
                Text(
                  '用于完成任务、兑换奖励等操作时的验证',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                SizedBox(height: AppTheme.spacingSmall),
                CustomTextField(
                  controller: _passwordController,
                  hintText: '请输入4位数字密码',
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: _obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  onSuffixIconTap: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  obscureText: _obscurePassword,
                  keyboardType: TextInputType.number,
                  errorText: _passwordError,
                  onChanged: (value) {
                    if (_passwordError != null) {
                      setState(() {
                        _passwordError = null;
                      });
                    }
                  },
                ),
                SizedBox(height: AppTheme.spacingXLarge),

                // 创建按钮
                CustomButton.primary(
                  text: '创建用户',
                  icon: Icons.person_add,
                  width: double.infinity,
                  isLoading: userProvider.isLoading,
                  onPressed: userProvider.isLoading ? null : _createUser,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
