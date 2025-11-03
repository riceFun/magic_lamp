import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/reward_provider.dart';
import '../../data/models/reward.dart';
import '../../widgets/common/custom_button.dart';

/// 商品编辑页面（管理员功能）
class EditRewardPage extends StatefulWidget {
  final int? rewardId;

  EditRewardPage({super.key, this.rewardId});

  @override
  State<EditRewardPage> createState() => _EditRewardPageState();
}

class _EditRewardPageState extends State<EditRewardPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  final _wordCodeController = TextEditingController();
  final _stockController = TextEditingController();

  String _selectedCategory = 'snack';
  String _selectedWordType = 'idiom';
  String _selectedStatus = 'active';
  bool _isHot = false;
  bool _isSpecial = false;
  bool _isUnlimitedStock = false;
  bool _isLoading = false;
  bool _isLoadingData = false;

  Reward? _existingReward;

  @override
  void initState() {
    super.initState();
    if (widget.rewardId != null) {
      _loadReward();
    } else {
      _stockController.text = '10';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    _wordCodeController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  /// 加载商品数据（编辑模式）
  Future<void> _loadReward() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final rewardProvider = context.read<RewardProvider>();
      final reward = await rewardProvider.getRewardById(widget.rewardId!);

      if (reward != null) {
        _existingReward = reward;
        _nameController.text = reward.name;
        _descriptionController.text = reward.description ?? '';
        _pointsController.text = reward.points.toString();
        _wordCodeController.text = reward.wordCode;
        _selectedCategory = reward.category;
        _selectedWordType = reward.wordType;
        _selectedStatus = reward.status;
        _isHot = reward.isHot;
        _isSpecial = reward.isSpecial;

        if (reward.stock == -1) {
          _isUnlimitedStock = true;
          _stockController.text = '0';
        } else {
          _isUnlimitedStock = false;
          _stockController.text = reward.stock.toString();
        }

        setState(() {});
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('商品不存在'),
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
            content: Text('加载商品失败：$e'),
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

  /// 保存商品
  Future<void> _saveReward() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final rewardProvider = context.read<RewardProvider>();

      final reward = Reward(
        id: _existingReward?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        points: int.parse(_pointsController.text),
        wordCode: _wordCodeController.text.trim(),
        wordType: _selectedWordType,
        category: _selectedCategory,
        stock: _isUnlimitedStock ? -1 : int.parse(_stockController.text),
        isHot: _isHot,
        isSpecial: _isSpecial,
        status: _selectedStatus,
        createdAt: _existingReward?.createdAt,
        updatedAt: DateTime.now(),
      );

      bool success;
      if (_existingReward != null) {
        success = await rewardProvider.updateReward(reward);
      } else {
        final id = await rewardProvider.createReward(reward);
        success = id != null;
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_existingReward != null ? '商品更新成功' : '商品创建成功'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(rewardProvider.errorMessage ?? '保存失败'),
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

  /// 获取类型文本
  String _getCategoryText(String category) {
    switch (category) {
      case 'snack':
        return '零食';
      case 'toy':
        return '玩具';
      case 'book':
        return '图书';
      case 'entertainment':
        return '娱乐';
      case 'privilege':
        return '特权';
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
        title: Text(_existingReward != null ? '编辑商品' : '添加商品'),
      ),
      body: _isLoadingData
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(AppTheme.spacingLarge),
                children: [
                  // 商品名称
                  Text(
                    '商品名称 *',
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
                      hintText: '请输入商品名称',
                      prefixIcon: Icon(Icons.card_giftcard),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入商品名称';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 商品描述
                  Text(
                    '商品描述',
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
                      hintText: '请输入商品描述',
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

                  // 积分
                  Text(
                    '所需积分 *',
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
                      hintText: '请输入所需积分',
                      prefixIcon: Icon(Icons.monetization_on),
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
                        return '请输入所需积分';
                      }
                      final points = int.tryParse(value);
                      if (points == null || points <= 0) {
                        return '积分必须大于0';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 词汇代码
                  Text(
                    '词汇代码 *',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  TextFormField(
                    controller: _wordCodeController,
                    decoration: InputDecoration(
                      hintText: '请输入成语或英文词汇',
                      prefixIcon: Icon(Icons.text_fields),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入词汇代码';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 词汇类型
                  Text(
                    '词汇类型 *',
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
                        child: RadioListTile<String>(
                          title: Text('成语'),
                          value: 'idiom',
                          groupValue: _selectedWordType,
                          onChanged: (value) {
                            setState(() {
                              _selectedWordType = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: Text('英文'),
                          value: 'english',
                          groupValue: _selectedWordType,
                          onChanged: (value) {
                            setState(() {
                              _selectedWordType = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 商品类型
                  Text(
                    '商品类型 *',
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
                      'snack',
                      'toy',
                      'book',
                      'entertainment',
                      'privilege',
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
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: _selectedCategory == category
                              ? Colors.white
                              : AppTheme.textPrimaryColor,
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 库存
                  Text(
                    '库存数量',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  CheckboxListTile(
                    title: Text('无限库存'),
                    value: _isUnlimitedStock,
                    onChanged: (value) {
                      setState(() {
                        _isUnlimitedStock = value!;
                        if (_isUnlimitedStock) {
                          _stockController.text = '0';
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (!_isUnlimitedStock) ...[
                    TextFormField(
                      controller: _stockController,
                      decoration: InputDecoration(
                        hintText: '请输入库存数量',
                        prefixIcon: Icon(Icons.inventory),
                        suffixText: '件',
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
                        if (!_isUnlimitedStock) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入库存数量';
                          }
                          final stock = int.tryParse(value);
                          if (stock == null || stock < 0) {
                            return '库存必须大于等于0';
                          }
                        }
                        return null;
                      },
                    ),
                  ],

                  SizedBox(height: AppTheme.spacingLarge),

                  // 商品状态
                  Text(
                    '商品状态 *',
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
                      {'value': 'active', 'label': '上架'},
                      {'value': 'inactive', 'label': '下架'},
                    ].map((status) {
                      return ChoiceChip(
                        label: Text(status['label']!),
                        selected: _selectedStatus == status['value'],
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = status['value']!;
                          });
                        },
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: _selectedStatus == status['value']
                              ? Colors.white
                              : AppTheme.textPrimaryColor,
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 标签设置
                  Text(
                    '商品标签',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  CheckboxListTile(
                    title: Text('热门商品'),
                    subtitle: Text('在热门推荐中显示'),
                    value: _isHot,
                    onChanged: (value) {
                      setState(() {
                        _isHot = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: Text('特惠商品'),
                    subtitle: Text('在特惠区域中显示'),
                    value: _isSpecial,
                    onChanged: (value) {
                      setState(() {
                        _isSpecial = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 保存按钮
                  CustomButton.primary(
                    text: _existingReward != null ? '保存修改' : '创建商品',
                    onPressed: _isLoading ? null : _saveReward,
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
