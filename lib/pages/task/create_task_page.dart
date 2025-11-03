import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../data/models/task.dart';
import '../../data/models/user.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';

/// 创建任务页面（管理员功能）
class CreateTaskPage extends StatefulWidget {
  CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();

  int? _selectedUserId;
  String _selectedType = 'daily';
  String _selectedPriority = 'normal';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  /// 加载用户列表
  Future<void> _loadUsers() async {
    final userProvider = context.read<UserProvider>();
    _users = await userProvider.getAllUsers();

    // 默认选择当前用户（如果不是管理员）
    final currentUser = userProvider.currentUser;
    if (currentUser != null && !currentUser.isAdmin) {
      _selectedUserId = currentUser.id;
    }

    setState(() {});
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

  /// 创建任务
  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请选择任务对象'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final task = Task(
        userId: _selectedUserId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        points: int.parse(_pointsController.text),
        type: _selectedType,
        priority: _selectedPriority,
        startDate: _startDate,
        endDate: _endDate,
        status: 'active',
      );

      final taskProvider = context.read<TaskProvider>();
      final success = await taskProvider.createTask(task);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('任务创建成功！'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
          Navigator.of(context).pop(true); // 返回true表示创建成功
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('任务创建失败'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建失败：$e'),
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
    final currentUser = context.watch<UserProvider>().currentUser;
    final isAdmin = currentUser?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('创建任务'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(AppTheme.spacingLarge),
          children: [
            // 提示信息
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: Text(
                      '建议每日任务200-400积分，培养孩子良好习惯',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppTheme.spacingLarge),

            // 选择用户（仅管理员可见）
            if (isAdmin) ...{
              Text(
                '任务对象',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: AppTheme.spacingSmall),
              DropdownButtonFormField<int>(
                value: _selectedUserId,
                decoration: InputDecoration(
                  hintText: '请选择任务对象',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _users.map((user) {
                  return DropdownMenuItem<int>(
                    value: user.id,
                    child: Row(
                      children: [
                        Text(user.name),
                        if (user.isAdmin) ...{
                          SizedBox(width: AppTheme.spacingSmall),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSmall,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentYellow,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Text(
                              '管理员',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        },
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUserId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '请选择任务对象';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppTheme.spacingLarge),
            },

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
                hintText: '例如：完成数学作业、整理房间',
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
                if (value.trim().length < 2) {
                  return '标题至少2个字符';
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
            CustomTextField.multiline(
              controller: _descriptionController,
              hintText: '详细描述任务要求和完成标准',
              maxLines: 3,
            ),

            SizedBox(height: AppTheme.spacingLarge),

            // 积分奖励
            Text(
              '积分奖励',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            TextFormField(
              controller: _pointsController,
              decoration: InputDecoration(
                hintText: '建议范围：20-100',
                prefixIcon: Icon(Icons.monetization_on),
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
                  return '请输入积分';
                }
                final points = int.tryParse(value);
                if (points == null || points <= 0) {
                  return '积分必须大于0';
                }
                if (points > 1000) {
                  return '单次任务积分不建议超过1000';
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
            Wrap(
              spacing: AppTheme.spacingSmall,
              children: [
                _TypeChip(
                  label: '每日',
                  value: 'daily',
                  description: '每天都可以完成',
                  icon: Icons.today,
                  isSelected: _selectedType == 'daily',
                  onTap: () => setState(() => _selectedType = 'daily'),
                ),
                _TypeChip(
                  label: '每周',
                  value: 'weekly',
                  description: '每周可完成一次',
                  icon: Icons.date_range,
                  isSelected: _selectedType == 'weekly',
                  onTap: () => setState(() => _selectedType = 'weekly'),
                ),
                _TypeChip(
                  label: '每月',
                  value: 'monthly',
                  description: '每月可完成一次',
                  icon: Icons.calendar_month,
                  isSelected: _selectedType == 'monthly',
                  onTap: () => setState(() => _selectedType = 'monthly'),
                ),
                _TypeChip(
                  label: '一次性',
                  value: 'once',
                  description: '只能完成一次',
                  icon: Icons.looks_one,
                  isSelected: _selectedType == 'once',
                  onTap: () => setState(() => _selectedType = 'once'),
                ),
              ],
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
            Wrap(
              spacing: AppTheme.spacingSmall,
              children: [
                _PriorityChip(
                  label: '紧急',
                  value: 'urgent',
                  color: AppTheme.accentRed,
                  isSelected: _selectedPriority == 'urgent',
                  onTap: () => setState(() => _selectedPriority = 'urgent'),
                ),
                _PriorityChip(
                  label: '重要',
                  value: 'high',
                  color: AppTheme.accentOrange,
                  isSelected: _selectedPriority == 'high',
                  onTap: () => setState(() => _selectedPriority = 'high'),
                ),
                _PriorityChip(
                  label: '普通',
                  value: 'normal',
                  color: AppTheme.primaryColor,
                  isSelected: _selectedPriority == 'normal',
                  onTap: () => setState(() => _selectedPriority = 'normal'),
                ),
                _PriorityChip(
                  label: '较低',
                  value: 'low',
                  color: AppTheme.textHintColor,
                  isSelected: _selectedPriority == 'low',
                  onTap: () => setState(() => _selectedPriority = 'low'),
                ),
              ],
            ),

            SizedBox(height: AppTheme.spacingLarge),

            // 日期设置
            Text(
              '有效期（可选）',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: '开始日期',
                    date: _startDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: _DateButton(
                    label: '结束日期',
                    date: _endDate,
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppTheme.spacingXLarge),

            // 创建按钮
            CustomButton.primary(
              text: '创建任务',
              onPressed: _isLoading ? null : _createTask,
              isLoading: _isLoading,
              icon: Icons.add_task,
              width: double.infinity,
            ),

            SizedBox(height: AppTheme.spacingLarge),
          ],
        ),
      ),
    );
  }
}

/// 任务类型选择芯片
class _TypeChip extends StatelessWidget {
  final String label;
  final String value;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  _TypeChip({
    required this.label,
    required this.value,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: AppTheme.spacingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 优先级选择芯片
class _PriorityChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  _PriorityChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: AppTheme.spacingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(
            color: isSelected ? color : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// 日期选择按钮
class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  _DateButton({
    required this.label,
    required this.date,
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
          color: Colors.white,
          border: Border.all(color: AppTheme.dividerColor),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: 4),
                Text(
                  date != null
                      ? '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'
                      : '未设置',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: date != null
                        ? AppTheme.textPrimaryColor
                        : AppTheme.textHintColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
