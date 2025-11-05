import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/user_provider.dart';
import '../../data/models/user.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/password_verification_dialog.dart';

/// 编辑个人资料页面
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedAvatar = 'account_circle';
  bool _isLoading = false;

  // 可选头像列表
  final List<Map<String, dynamic>> _avatars = [
    {'id': 'account_circle', 'icon': Icons.account_circle, 'name': '默认头像'},
    {'id': 'face', 'icon': Icons.face, 'name': '笑脸'},
    {'id': 'face_2', 'icon': Icons.face_2, 'name': '微笑'},
    {'id': 'person', 'icon': Icons.person, 'name': '人物'},
    {'id': 'child_care', 'icon': Icons.child_care, 'name': '儿童'},
    {'id': 'emoji_people', 'icon': Icons.emoji_people, 'name': '表情'},
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _selectedAvatar = user.avatar ?? 'account_circle';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 保存个人资料
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('未登录'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    // 密码验证
    await showPasswordVerificationDialog(
      context: context,
      mode: PasswordMode.user,
      title: '确认保存',
      message: '请输入操作密码以保存个人资料',
      onVerified: () {
        _actualSaveProfile();
      },
    );
  }

  /// 实际执行保存个人资料操作
  Future<void> _actualSaveProfile() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;

    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 更新用户信息
      final updatedUser = User(
        id: user.id,
        name: _nameController.text.trim(),
        password: user.password,
        role: user.role,
        avatar: _selectedAvatar,
        totalPoints: user.totalPoints,
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
      );

      final success = await userProvider.updateUser(updatedUser);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('个人资料更新成功'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userProvider.errorMessage ?? '更新失败'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失败：$e'),
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

  /// 获取头像图标
  IconData _getAvatarIcon(String avatarId) {
    final avatar = _avatars.firstWhere(
      (a) => a['id'] == avatarId,
      orElse: () => _avatars[0],
    );
    return avatar['icon'] as IconData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('编辑个人资料'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 当前头像预览
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryDarkColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Icon(
                    _getAvatarIcon(_selectedAvatar),
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),

              SizedBox(height: AppTheme.spacingLarge),

              // 用户名
              Text(
                '用户名',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: AppTheme.spacingSmall),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '请输入用户名',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入用户名';
                  }
                  if (value.trim().length < 2) {
                    return '用户名至少2个字符';
                  }
                  return null;
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

              // 头像网格
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppTheme.spacingMedium,
                  mainAxisSpacing: AppTheme.spacingMedium,
                  childAspectRatio: 1,
                ),
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  final avatar = _avatars[index];
                  final isSelected = avatar['id'] == _selectedAvatar;

                  return _AvatarOption(
                    icon: avatar['icon'] as IconData,
                    name: avatar['name'] as String,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedAvatar = avatar['id'] as String;
                      });
                    },
                  );
                },
              ),

              SizedBox(height: AppTheme.spacingXLarge),

              // 保存按钮
              CustomButton.primary(
                text: '保存修改',
                onPressed: _isLoading ? null : _saveProfile,
                isLoading: _isLoading,
                icon: Icons.save,
                width: double.infinity,
              ),

              SizedBox(height: AppTheme.spacingLarge),
            ],
          ),
        ),
      ),
    );
  }
}

/// 头像选项组件
class _AvatarOption extends StatelessWidget {
  final IconData icon;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _AvatarOption({
    required this.icon,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTheme.cardShadow : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : AppTheme.primaryColor,
            ),
            SizedBox(height: AppTheme.spacingSmall),
            Text(
              name,
              style: TextStyle(
                fontSize: AppTheme.fontSizeXSmall,
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
