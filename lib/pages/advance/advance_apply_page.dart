import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/advance_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/custom_button.dart';

/// 预支申请页面
class AdvanceApplyPage extends StatefulWidget {
  const AdvanceApplyPage({super.key});

  @override
  State<AdvanceApplyPage> createState() => _AdvanceApplyPageState();
}

class _AdvanceApplyPageState extends State<AdvanceApplyPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  int _selectedDays = 7;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// 申请预支
  Future<void> _applyAdvance() async {
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

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = int.parse(_amountController.text);
      final advanceProvider = context.read<AdvanceProvider>();

      final advanceId = await advanceProvider.applyAdvance(
        userId: user.id!,
        amount: amount,
        days: _selectedDays,
      );

      if (advanceId != null) {
        // 刷新用户积分
        await userProvider.refreshCurrentUser();

        if (mounted) {
          // 显示成功对话框
          _showSuccessDialog(amount);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(advanceProvider.errorMessage ?? '申请失败'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('申请失败：$e'),
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

  /// 显示成功对话框
  void _showSuccessDialog(int amount) {
    final interest = AdvanceProvider.calculateInterest(amount, _selectedDays);
    final total = AdvanceProvider.calculateTotalAmount(amount, _selectedDays);
    final dueDate = DateTime.now().add(Duration(days: _selectedDays));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppTheme.accentGreen,
              size: 28,
            ),
            SizedBox(width: AppTheme.spacingSmall),
            Text('申请成功！'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '预支积分已到账',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingMedium),
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    label: '预支金额',
                    value: '$amount 积分',
                    valueColor: AppTheme.primaryColor,
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  _InfoRow(
                    label: '利息',
                    value: '$interest 积分',
                    valueColor: AppTheme.accentOrange,
                  ),
                  Divider(height: AppTheme.spacingMedium),
                  _InfoRow(
                    label: '到期还款',
                    value: '$total 积分',
                    valueColor: AppTheme.accentRed,
                    isBold: true,
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  _InfoRow(
                    label: '还款日期',
                    value:
                        '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
                    valueColor: AppTheme.textSecondaryColor,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppTheme.spacingMedium),
            Container(
              padding: EdgeInsets.all(AppTheme.spacingSmall),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: AppTheme.accentOrange,
                  ),
                  SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: Text(
                      '请按时还款，逾期会影响信用',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关闭对话框
              Navigator.of(context).pop(true); // 返回上一页
            },
            child: Text('我知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final currentPoints = user?.totalPoints ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('预支积分'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            tooltip: '查看预支记录',
            onPressed: () {
              context.push(AppConstants.routeAdvanceList);
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(AppTheme.spacingLarge),
          children: [
            // 当前积分卡片
            Container(
              padding: EdgeInsets.all(AppTheme.spacingLarge),
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
              child: Column(
                children: [
                  Text(
                    '当前积分',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        size: 32,
                        color: AppTheme.accentYellow,
                      ),
                      SizedBox(width: AppTheme.spacingSmall),
                      Text(
                        '$currentPoints',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: AppTheme.spacingLarge),

            // 说明卡片
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.accentOrange,
                        size: 20,
                      ),
                      SizedBox(width: AppTheme.spacingSmall),
                      Text(
                        '预支说明',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  Text(
                    '• 月利率：10%（按天计算）\n'
                    '• 预支金额不超过当前积分的2倍\n'
                    '• 到期需归还本金+利息\n'
                    '• 同时只能有一笔预支\n'
                    '• 逾期会影响信用记录',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.accentOrange,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppTheme.spacingLarge),

            // 预支金额
            Text(
              '预支金额',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                hintText: '请输入预支金额',
                prefixIcon: Icon(Icons.monetization_on),
                suffixText: '积分',
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
                  return '请输入预支金额';
                }
                final amount = int.tryParse(value);
                if (amount == null || amount <= 0) {
                  return '金额必须大于0';
                }
                if (amount > currentPoints * 2) {
                  return '预支金额不能超过当前积分的2倍';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {}); // 更新利息显示
              },
            ),

            SizedBox(height: AppTheme.spacingLarge),

            // 预支期限
            Text(
              '预支期限',
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
                  child: _DurationChip(
                    label: '7天',
                    days: 7,
                    isSelected: _selectedDays == 7,
                    onTap: () => setState(() => _selectedDays = 7),
                  ),
                ),
                SizedBox(width: AppTheme.spacingSmall),
                Expanded(
                  child: _DurationChip(
                    label: '14天',
                    days: 14,
                    isSelected: _selectedDays == 14,
                    onTap: () => setState(() => _selectedDays = 14),
                  ),
                ),
                SizedBox(width: AppTheme.spacingSmall),
                Expanded(
                  child: _DurationChip(
                    label: '30天',
                    days: 30,
                    isSelected: _selectedDays == 30,
                    onTap: () => setState(() => _selectedDays = 30),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppTheme.spacingLarge),

            // 预计还款
            if (_amountController.text.isNotEmpty &&
                int.tryParse(_amountController.text) != null) ...{
              Container(
                padding: EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '预计还款',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingMedium),
                    _InfoRow(
                      label: '预支本金',
                      value: '${_amountController.text} 积分',
                      valueColor: AppTheme.textPrimaryColor,
                    ),
                    SizedBox(height: AppTheme.spacingSmall),
                    _InfoRow(
                      label: '利息（${_selectedDays}天）',
                      value:
                          '${AdvanceProvider.calculateInterest(int.parse(_amountController.text), _selectedDays)} 积分',
                      valueColor: AppTheme.accentOrange,
                    ),
                    Divider(height: AppTheme.spacingMedium),
                    _InfoRow(
                      label: '到期还款总额',
                      value:
                          '${AdvanceProvider.calculateTotalAmount(int.parse(_amountController.text), _selectedDays)} 积分',
                      valueColor: AppTheme.accentRed,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppTheme.spacingLarge),
            },

            // 申请按钮
            CustomButton.primary(
              text: '申请预支',
              onPressed: _isLoading ? null : _applyAdvance,
              isLoading: _isLoading,
              icon: Icons.send,
              width: double.infinity,
            ),

            SizedBox(height: AppTheme.spacingLarge),
          ],
        ),
      ),
    );
  }
}

/// 期限选择芯片
class _DurationChip extends StatelessWidget {
  final String label;
  final int days;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.days,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '利率${(AppConstants.advanceInterestRate * days / 30 * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 信息行
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? AppTheme.fontSizeMedium : AppTheme.fontSizeSmall,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
