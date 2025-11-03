import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/user_provider.dart';
import '../../data/models/user.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';
import 'create_user_page.dart';

/// 用户列表页面（管理员功能）
class UserListPage extends StatefulWidget {
  UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  bool _isLoading = true;
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.loadAllUsers();
      _users = userProvider.allUsers;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载用户失败：$e')),
        );
      }
    }
  }

  /// 获取头像图标
  IconData _getAvatarIcon(String? avatar) {
    switch (avatar) {
      case 'face':
        return Icons.face;
      case 'face_2':
        return Icons.face_2;
      case 'person':
        return Icons.person;
      case 'child_care':
        return Icons.child_care;
      case 'emoji_people':
        return Icons.emoji_people;
      default:
        return Icons.account_circle;
    }
  }

  /// 显示删除用户确认对话框
  void _showDeleteDialog(User user) {
    // 不能删除当前登录用户
    final currentUser = context.read<UserProvider>().currentUser;
    if (currentUser?.id == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('不能删除当前登录用户'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除用户'),
        content: Text('确定要删除用户"${user.name}"吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteUser(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 删除用户
  Future<void> _deleteUser(User user) async {
    try {
      final userProvider = context.read<UserProvider>();
      final success = await userProvider.deleteUser(user.id!);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('用户删除成功'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
          _loadUsers();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userProvider.errorMessage ?? '删除失败'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败：$e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('用户管理'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateUserPage(),
                ),
              );
              if (result == true) {
                _loadUsers();
              }
            },
            tooltip: '添加用户',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? LoadingWidget(message: '加载用户列表...')
          : _users.isEmpty
              ? EmptyWidget(
                  icon: Icons.group,
                  message: '暂无用户',
                  subtitle: '点击右上角添加用户',
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: EdgeInsets.all(AppTheme.spacingLarge),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final currentUser =
                          context.watch<UserProvider>().currentUser;
                      final isCurrentUser = currentUser?.id == user.id;

                      return Container(
                        margin: EdgeInsets.only(
                            bottom: AppTheme.spacingMedium),
                        child: CustomCard(
                          child: Row(
                            children: [
                              // 头像
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.primaryColor,
                                      AppTheme.primaryDarkColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                ),
                                child: Icon(
                                  _getAvatarIcon(user.avatar),
                                  size: 35,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: AppTheme.spacingMedium),

                              // 用户信息
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          user.name,
                                          style: TextStyle(
                                            fontSize: AppTheme.fontSizeLarge,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                        ),
                                        if (user.isAdmin) ...[
                                          SizedBox(
                                              width: AppTheme.spacingSmall),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  AppTheme.spacingSmall,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentYellow,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                AppTheme.radiusSmall,
                                              ),
                                            ),
                                            child: Text(
                                              '管理员',
                                              style: TextStyle(
                                                fontSize:
                                                    AppTheme.fontSizeXSmall,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (isCurrentUser) ...[
                                          SizedBox(
                                              width: AppTheme.spacingSmall),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  AppTheme.spacingSmall,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                AppTheme.radiusSmall,
                                              ),
                                            ),
                                            child: Text(
                                              '当前',
                                              style: TextStyle(
                                                fontSize:
                                                    AppTheme.fontSizeXSmall,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.monetization_on,
                                          size: 16,
                                          color: AppTheme.accentYellow,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '${user.totalPoints} 积分',
                                          style: TextStyle(
                                            fontSize:
                                                AppTheme.fontSizeMedium,
                                            color:
                                                AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // 删除按钮
                              if (!isCurrentUser)
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: AppTheme.accentRed,
                                  ),
                                  onPressed: () => _showDeleteDialog(user),
                                  tooltip: '删除用户',
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
