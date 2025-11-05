import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/penalty_provider.dart';
import '../../data/models/penalty.dart';
import '../../widgets/common/custom_button.dart';

/// 惩罚编辑页面（管理员功能）
class EditPenaltyPage extends StatefulWidget {
  final int? penaltyId;

  const EditPenaltyPage({super.key, this.penaltyId});

  @override
  State<EditPenaltyPage> createState() => _EditPenaltyPageState();
}

class _EditPenaltyPageState extends State<EditPenaltyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  final _iconController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCategory = 'behavior';
  String _selectedStatus = 'active';
  bool _isLoading = false;
  bool _isLoadingData = false;

  Penalty? _existingPenalty;

  @override
  void initState() {
    super.initState();
    if (widget.penaltyId != null) {
      _loadPenalty();
    } else {
      // 新建时设置默认图标
      _iconController.text = '⚠️';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    _iconController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// 加载惩罚数据（编辑模式）
  Future<void> _loadPenalty() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final penaltyProvider = context.read<PenaltyProvider>();
      final penalty = await penaltyProvider.getPenaltyById(widget.penaltyId!);

      if (penalty != null) {
        _existingPenalty = penalty;
        _nameController.text = penalty.name;
        _descriptionController.text = penalty.description ?? '';
        _pointsController.text = penalty.points.toString();
        _iconController.text = penalty.icon ?? '⚠️';
        _selectedCategory = penalty.category;
        _selectedStatus = penalty.status;
        _noteController.text = penalty.note ?? '';

        setState(() {});
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('惩罚项目不存在'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载惩罚项目失败：$e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  /// 保存惩罚项目
  Future<void> _savePenalty() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final penaltyProvider = context.read<PenaltyProvider>();

      final penalty = Penalty(
        id: _existingPenalty?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        points: int.parse(_pointsController.text),
        icon: _iconController.text.trim().isEmpty ? null : _iconController.text.trim(),
        category: _selectedCategory,
        status: _selectedStatus,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        createdAt: _existingPenalty?.createdAt,
        updatedAt: DateTime.now(),
      );

      bool success;
      if (_existingPenalty != null) {
        success = await penaltyProvider.updatePenalty(penalty);
      } else {
        final id = await penaltyProvider.createPenalty(penalty);
        success = id != null;
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_existingPenalty != null ? '惩罚项目更新成功' : '惩罚项目创建成功'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(penaltyProvider.errorMessage ?? '保存失败'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败：$e'),
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

  /// 获取分类文本
  String _getCategoryText(String category) {
    switch (category) {
      case 'behavior':
        return '行为';
      case 'hygiene':
        return '卫生';
      case 'study':
        return '学习';
      case 'language':
        return '语言';
      case 'other':
      default:
        return '其他';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_existingPenalty != null ? '编辑惩罚' : '添加惩罚'),
      ),
      body: _isLoadingData
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(AppTheme.spacingLarge),
                children: [
                  // 惩罚名称
                  Text(
                    '惩罚名称 *',
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
                      hintText: '请输入惩罚名称',
                      prefixIcon: Icon(Icons.warning_amber),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入惩罚名称';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 惩罚图标
                  Text(
                    '惩罚图标',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  TextFormField(
                    controller: _iconController,
                    decoration: InputDecoration(
                      hintText: '请输入emoji图标（默认⚠️）',
                      prefixIcon: Icon(Icons.emoji_emotions),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 惩罚描述
                  Text(
                    '惩罚描述',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: '请输入惩罚描述',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    maxLines: 3,
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 扣除积分
                  Text(
                    '扣除积分 *',
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
                      hintText: '请输入扣除积分',
                      prefixIcon: Icon(Icons.remove_circle),
                      suffixText: '积分',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
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
                        return '请输入扣除积分';
                      }
                      final points = int.tryParse(value);
                      if (points == null || points <= 0) {
                        return '积分必须大于0';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 惩罚分类
                  Text(
                    '惩罚分类 *',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  Wrap(
                    spacing: AppTheme.spacingSmall,
                    runSpacing: AppTheme.spacingSmall,
                    children: [
                      'behavior',
                      'hygiene',
                      'study',
                      'language',
                      'other'
                    ].map((category) {
                      return ChoiceChip(
                        label: Text(_getCategoryText(category)),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        selectedColor: AppTheme.accentRed,
                        labelStyle: TextStyle(
                          color: _selectedCategory == category
                              ? Colors.white
                              : AppTheme.textPrimaryColor,
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 惩罚状态
                  Text(
                    '惩罚状态 *',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  Wrap(
                    spacing: AppTheme.spacingSmall,
                    runSpacing: AppTheme.spacingSmall,
                    children: [
                      {'value': 'active', 'label': '启用'},
                      {'value': 'inactive', 'label': '停用'},
                    ].map((status) {
                      return ChoiceChip(
                        label: Text(status['label']!),
                        selected: _selectedStatus == status['value'],
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = status['value']!;
                          });
                        },
                        selectedColor: AppTheme.accentOrange,
                        labelStyle: TextStyle(
                          color: _selectedStatus == status['value']
                              ? Colors.white
                              : AppTheme.textPrimaryColor,
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 备注
                  Text(
                    '备注信息',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: '请输入备注信息',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    maxLines: 3,
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 保存按钮
                  CustomButton.primary(
                    text: _existingPenalty != null ? '保存修改' : '创建惩罚',
                    onPressed: _isLoading ? null : _savePenalty,
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
