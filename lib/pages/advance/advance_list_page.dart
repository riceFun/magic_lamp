import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/advance_provider.dart';
import '../../providers/user_provider.dart';
import '../../data/models/point.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';

/// 预支积分列表页面
class AdvanceListPage extends StatefulWidget {
  AdvanceListPage({super.key});

  @override
  State<AdvanceListPage> createState() => _AdvanceListPageState();
}

class _AdvanceListPageState extends State<AdvanceListPage> {
  String _selectedFilter = 'active'; // active, repaid, overdue, all
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdvances();
    });
  }

  Future<void> _loadAdvances() async {
    final user = context.read<UserProvider>().currentUser;
    if (user != null) {
      await context.read<AdvanceProvider>().loadUserAdvances(user.id!);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  /// 显示还款确认对话框
  void _showRepayDialog(Advance advance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.payment,
              color: AppTheme.primaryColor,
              size: 28,
            ),
            SizedBox(width: AppTheme.spacingSmall),
            Text('确认还款'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '确定要还清这笔预支吗？',
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
                    label: '预支本金',
                    value: '${advance.amount} 积分',
                    valueColor: AppTheme.textPrimaryColor,
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  _InfoRow(
                    label: '利息',
                    value: '${advance.interestAmount} 积分',
                    valueColor: AppTheme.accentOrange,
                  ),
                  Divider(height: AppTheme.spacingMedium),
                  _InfoRow(
                    label: '还款总额',
                    value: '${advance.totalAmount} 积分',
                    valueColor: AppTheme.accentRed,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performRepay(advance);
            },
            child: Text('确认还款'),
          ),
        ],
      ),
    );
  }

  /// 执行还款
  Future<void> _performRepay(Advance advance) async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;

    final advanceProvider = context.read<AdvanceProvider>();
    final userProvider = context.read<UserProvider>();

    final success = await advanceProvider.repayAdvance(advance.id!, user.id!);

    if (success) {
      // 刷新用户积分
      await userProvider.refreshCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('还款成功！'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(advanceProvider.errorMessage ?? '还款失败'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  /// 获取过滤后的预支列表
  List<Advance> _getFilteredAdvances(List<Advance> advances) {
    switch (_selectedFilter) {
      case 'active':
        return advances.where((a) => a.isActive).toList();
      case 'repaid':
        return advances.where((a) => a.isRepaid).toList();
      case 'overdue':
        return advances.where((a) => a.isOverdue).toList();
      case 'all':
      default:
        return advances;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final advanceProvider = context.watch<AdvanceProvider>();
    final advances = advanceProvider.advances;
    final isLoading = advanceProvider.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('我的预支'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAdvances,
          ),
        ],
      ),
      body: !_isInitialized
          ? LoadingWidget(message: '加载中...')
          : isLoading
              ? LoadingWidget(message: '加载中...')
              : Column(
                  children: [
                    // 统计卡片
                    FutureBuilder<Map<String, dynamic>>(
                      future: advanceProvider.getAdvanceStats(user?.id ?? 0),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return SizedBox.shrink();
                        }

                        final stats = snapshot.data!;
                        return Container(
                          margin: EdgeInsets.all(AppTheme.spacingLarge),
                          padding: EdgeInsets.all(AppTheme.spacingLarge),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.accentOrange,
                                AppTheme.accentOrange.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatItem(
                                      label: '预支次数',
                                      value: '${stats['totalCount']}',
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  Expanded(
                                    child: _StatItem(
                                      label: '总预支额',
                                      value: '${stats['totalAmount']}',
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  Expanded(
                                    child: _StatItem(
                                      label: '已付利息',
                                      value: '${stats['totalInterest']}',
                                    ),
                                  ),
                                ],
                              ),
                              if (stats['activeCount'] > 0 ||
                                  stats['overdueCount'] > 0) ...[
                                SizedBox(height: AppTheme.spacingMedium),
                                Divider(
                                    color: Colors.white.withValues(alpha: 0.3)),
                                SizedBox(height: AppTheme.spacingMedium),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (stats['activeCount'] > 0) ...[
                                      Icon(
                                        Icons.pending_actions,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '进行中 ${stats['activeCount']}',
                                        style: TextStyle(
                                          fontSize: AppTheme.fontSizeSmall,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                    if (stats['activeCount'] > 0 &&
                                        stats['overdueCount'] > 0)
                                      SizedBox(width: AppTheme.spacingMedium),
                                    if (stats['overdueCount'] > 0) ...[
                                      Icon(
                                        Icons.warning,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '逾期 ${stats['overdueCount']}',
                                        style: TextStyle(
                                          fontSize: AppTheme.fontSizeSmall,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),

                    // 过滤选项
                    Container(
                      height: 50,
                      padding:
                          EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _FilterChip(
                            label: '进行中',
                            isSelected: _selectedFilter == 'active',
                            onTap: () => setState(() => _selectedFilter = 'active'),
                          ),
                          SizedBox(width: AppTheme.spacingSmall),
                          _FilterChip(
                            label: '已还清',
                            isSelected: _selectedFilter == 'repaid',
                            onTap: () => setState(() => _selectedFilter = 'repaid'),
                          ),
                          SizedBox(width: AppTheme.spacingSmall),
                          _FilterChip(
                            label: '已逾期',
                            isSelected: _selectedFilter == 'overdue',
                            onTap: () => setState(() => _selectedFilter = 'overdue'),
                          ),
                          SizedBox(width: AppTheme.spacingSmall),
                          _FilterChip(
                            label: '全部',
                            isSelected: _selectedFilter == 'all',
                            onTap: () => setState(() => _selectedFilter = 'all'),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppTheme.spacingMedium),

                    // 预支列表
                    Expanded(
                      child: _buildAdvanceList(
                          _getFilteredAdvances(advances), user),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAdvanceList(List<Advance> advances, user) {
    if (advances.isEmpty) {
      return EmptyWidget(
        icon: Icons.account_balance_wallet,
        message: '暂无预支记录',
        subtitle: _selectedFilter == 'active' ? '当前没有进行中的预支' : null,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAdvances,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
        itemCount: advances.length,
        itemBuilder: (context, index) {
          final advance = advances[index];
          return _AdvanceCard(
            advance: advance,
            onRepay: () => _showRepayDialog(advance),
          );
        },
      ),
    );
  }
}

/// 统计项
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSizeXLarge,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

/// 过滤选项芯片
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  _FilterChip({
    required this.label,
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
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: isSelected ? AppTheme.cardShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fontSizeMedium,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}

/// 预支卡片
class _AdvanceCard extends StatelessWidget {
  final Advance advance;
  final VoidCallback onRepay;

  _AdvanceCard({
    required this.advance,
    required this.onRepay,
  });

  /// 获取状态颜色
  Color _getStatusColor() {
    if (advance.isOverdue) return AppTheme.accentRed;
    if (advance.isRepaid) return AppTheme.accentGreen;
    return AppTheme.accentOrange;
  }

  /// 获取状态文本
  String _getStatusText() {
    if (advance.isOverdue) return '已逾期';
    if (advance.isRepaid) return '已还清';
    return '进行中';
  }

  /// 获取状态图标
  IconData _getStatusIcon() {
    if (advance.isOverdue) return Icons.warning;
    if (advance.isRepaid) return Icons.check_circle;
    return Icons.pending;
  }

  @override
  Widget build(BuildContext context) {
    final daysRemaining = advance.daysRemaining;
    final isUrgent = daysRemaining <= 3 && !advance.isRepaid;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：状态和日期
            Row(
              children: [
                // 状态标签
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSmall,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(),
                        size: 14,
                        color: _getStatusColor(),
                      ),
                      SizedBox(width: 4),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                // 预支日期
                Text(
                  '${advance.advanceAt.year}-${advance.advanceAt.month.toString().padLeft(2, '0')}-${advance.advanceAt.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppTheme.textHintColor,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppTheme.spacingMedium),

            // 金额信息
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '预支金额',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${advance.amount}',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeXLarge,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '利息',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${advance.interestAmount}',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeXLarge,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '应还总额',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${advance.totalAmount}',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeXLarge,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: AppTheme.spacingMedium),
            Divider(height: 1),
            SizedBox(height: AppTheme.spacingMedium),

            // 底部：还款信息和操作
            if (advance.isRepaid) ...[
              // 已还清
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppTheme.accentGreen,
                  ),
                  SizedBox(width: AppTheme.spacingSmall),
                  Text(
                    '还款日期：${advance.repaidAt?.year}-${advance.repaidAt?.month.toString().padLeft(2, '0')}-${advance.repaidAt?.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // 未还清
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '还款日期',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${advance.dueDate.year}-${advance.dueDate.month.toString().padLeft(2, '0')}-${advance.dueDate.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeMedium,
                            fontWeight: FontWeight.bold,
                            color: isUrgent
                                ? AppTheme.accentRed
                                : AppTheme.textPrimaryColor,
                          ),
                        ),
                        if (!advance.isOverdue) ...[
                          SizedBox(height: 2),
                          Text(
                            daysRemaining > 0
                                ? '剩余 $daysRemaining 天'
                                : '今天到期',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeXSmall,
                              color: isUrgent
                                  ? AppTheme.accentRed
                                  : AppTheme.textHintColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 还款按钮
                  ElevatedButton.icon(
                    onPressed: onRepay,
                    icon: Icon(Icons.payment, size: 18),
                    label: Text('立即还款'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: advance.isOverdue
                          ? AppTheme.accentRed
                          : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              if (isUrgent && !advance.isOverdue) ...[
                SizedBox(height: AppTheme.spacingSmall),
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 14,
                        color: AppTheme.accentRed,
                      ),
                      SizedBox(width: AppTheme.spacingSmall),
                      Text(
                        '即将到期，请及时还款',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeXSmall,
                          color: AppTheme.accentRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (advance.isOverdue) ...[
                SizedBox(height: AppTheme.spacingSmall),
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error,
                        size: 14,
                        color: AppTheme.accentRed,
                      ),
                      SizedBox(width: AppTheme.spacingSmall),
                      Text(
                        '已逾期 ${-daysRemaining} 天，请尽快还款',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeXSmall,
                          color: AppTheme.accentRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
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

  _InfoRow({
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
