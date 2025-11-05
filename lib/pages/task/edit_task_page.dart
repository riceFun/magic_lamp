import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../data/models/task.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/emoji_picker.dart';
import '../../widgets/common/password_verification_dialog.dart';

/// 编辑任务页面
class EditTaskPage extends StatefulWidget {
  final Task task;

  const EditTaskPage({super.key, required this.task});

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _pointsController;

  late String _selectedType;
  late String _selectedPriority;
  String? _selectedIcon;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 初始化控制器并填充当前任务数据
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _pointsController = TextEditingController(text: widget.task.points.toString());
    _selectedType = widget.task.type;
    _selectedPriority = widget.task.priority;
    _selectedIcon = widget.task.icon;
    _startDate = widget.task.startDate;
    _endDate = widget.task.endDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  /// 选择日期
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      locale: Locale('zh', 'CN'),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  /// 更新任务
  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 密码验证
    await showPasswordVerificationDialog(
      context: context,
      mode: PasswordMode.user,
      title: '确认操作',
      message: '请输入操作密码以保存任务',
      onVerified: () {
        _actualUpdateTask();
      },
    );
  }

  /// 实际执行更新任务操作
  Future<void> _actualUpdateTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedTask = Task(
        id: widget.task.id,
        userId: widget.task.userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        points: int.parse(_pointsController.text),
        type: _selectedType,
        priority: _selectedPriority,
        icon: _selectedIcon,
        startDate: _startDate,
        endDate: _endDate,
        status: widget.task.status,
        createdAt: widget.task.createdAt,
        updatedAt: DateTime.now(),
      );

      final taskProvider = context.read<TaskProvider>();
      final success = await taskProvider.updateTask(updatedTask);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('任务更新成功！'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
          Navigator.of(context).pop(true); // 返回true表示更新成功
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(taskProvider.errorMessage ?? '更新失败'),
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

  /// 删除任务
  Future<void> _deleteTask() async {
    // 密码验证
    await showPasswordVerificationDialog(
      context: context,
      mode: PasswordMode.user,
      title: '确认删除',
      message: '请输入操作密码以删除任务',
      onVerified: () {
        _actualDeleteTask();
      },
    );
  }

  /// 实际执行删除任务操作
  Future<void> _actualDeleteTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final taskProvider = context.read<TaskProvider>();
      final success = await taskProvider.deleteTask(widget.task.id!);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('任务已删除'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
          Navigator.of(context).pop(true); // 返回true表示删除成功
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败'),
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
        title: Text('编辑任务'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: AppTheme.accentRed),
            onPressed: _isLoading ? null : _deleteTask,
            tooltip: '删除任务',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(AppTheme.spacingLarge),
          children: [
            // 任务图标
            Text(
              '任务图标',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            InkWell(
              onTap: () async {
                final emoji = await EmojiPicker.show(
                  context,
                  initialEmoji: _selectedIcon,
                );
                if (emoji != null || emoji == null) {
                  setState(() {
                    _selectedIcon = emoji;
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.dividerColor),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Center(
                        child: _selectedIcon != null
                            ? Text(
                                _selectedIcon!,
                                style: TextStyle(fontSize: 36),
                              )
                            : Icon(
                                Icons.add_photo_alternate,
                                size: 32,
                                color: AppTheme.textHintColor,
                              ),
                      ),
                    ),
                    SizedBox(width: AppTheme.spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedIcon != null ? '点击更换图标' : '点击选择图标',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeMedium,
                              color: AppTheme.textPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '选择一个emoji作为任务图标',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeSmall,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppTheme.textHintColor),
                  ],
                ),
              ),
            ),

            SizedBox(height: AppTheme.spacingLarge),

            // 任务标题
            Text(
              '任务标题',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: '请输入任务标题',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入任务标题';
                }
                return null;
              },
            ),

            SizedBox(height: AppTheme.spacingLarge),

            // 任务描述
            Text(
              '任务描述（可选）',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '请输入任务描述',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            SizedBox(height: AppTheme.spacingLarge),

            // 积分
            Text(
              '任务积分',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            TextFormField(
              controller: _pointsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '请输入积分值',
                prefixIcon: Icon(Icons.monetization_on),
                suffixText: '分',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入积分值';
                }
                final points = int.tryParse(value);
                if (points == null || points <= 0) {
                  return '请输入有效的积分值';
                }
                return null;
              },
            ),

            SizedBox(height: AppTheme.spacingLarge),

            // 任务类型
            Text(
              '任务类型',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.repeat),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                DropdownMenuItem(value: 'once', child: Text('一次性任务')),
                DropdownMenuItem(value: 'daily', child: Text('每日任务')),
                DropdownMenuItem(value: 'weekly', child: Text('每周任务')),
                DropdownMenuItem(value: 'monthly', child: Text('每月任务')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),

            SizedBox(height: AppTheme.spacingLarge),

            // 优先级
            Text(
              '优先级',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.flag),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                DropdownMenuItem(value: 'low', child: Text('低优先级')),
                DropdownMenuItem(value: 'normal', child: Text('普通优先级')),
                DropdownMenuItem(value: 'medium', child: Text('中等优先级')),
                DropdownMenuItem(value: 'high', child: Text('高优先级')),
                DropdownMenuItem(value: 'urgent', child: Text('紧急优先级')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
            ),

            SizedBox(height: AppTheme.spacingLarge * 2),

            // 更新按钮
            ElevatedButton(
              onPressed: _isLoading ? null : _updateTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      '更新任务',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
