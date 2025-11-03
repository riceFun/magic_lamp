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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedAvatar = 'face';
  String _selectedRole = 'child';
  bool _obscurePassword = true;

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userProvider = context.read<UserProvider>();

    final userId = await userProvider.createUser(
      name: _nameController.text.trim(),
      avatar: _selectedAvatar,
      role: _selectedRole,
      password: _passwordController.text.trim().isEmpty
          ? null
          : _passwordController.text.trim(),
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
            child: Form(
              key: _formKey,
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

                  // 选择角色
                  Text(
                    '用户角色',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          icon: Icons.child_care,
                          title: '儿童',
                          description: '获得积分、兑换奖励',
                          color: AppTheme.primaryColor,
                          isSelected: _selectedRole == 'child',
                          onTap: () {
                            setState(() {
                              _selectedRole = 'child';
                            });
                          },
                        ),
                      ),
                      SizedBox(width: AppTheme.spacingMedium),
                      Expanded(
                        child: _RoleCard(
                          icon: Icons.admin_panel_settings,
                          title: '管理员',
                          description: '管理数据、设置规则',
                          color: AppTheme.accentOrange,
                          isSelected: _selectedRole == 'admin',
                          onTap: () {
                            setState(() {
                              _selectedRole = 'admin';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingLarge),

                  // 密码输入（可选）
                  Text(
                    '密码（可选）',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: '留空表示不设置密码',
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
            ),
          );
        },
      ),
    );
  }
}

/// 角色选择卡片
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : AppTheme.cardColor,
          border: Border.all(
            color: isSelected ? color : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? color : AppTheme.textSecondaryColor,
            ),
            SizedBox(height: AppTheme.spacingSmall),
            Text(
              title,
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingXSmall),
            Text(
              description,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
