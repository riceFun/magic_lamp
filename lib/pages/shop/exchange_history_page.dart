import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/exchange_provider.dart';
import '../../providers/user_provider.dart';
import '../../data/models/reward.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';

/// 兑换记录页面
class ExchangeHistoryPage extends StatefulWidget {
  const ExchangeHistoryPage({super.key});

  @override
  State<ExchangeHistoryPage> createState() => _ExchangeHistoryPageState();
}

class _ExchangeHistoryPageState extends State<ExchangeHistoryPage> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    // 使用addPostFrameCallback延迟执行，避免在build期间调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExchanges();
    });
  }

  Future<void> _loadExchanges() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;

    if (user != null) {
      await context.read<ExchangeProvider>().loadUserExchanges(user.id!);
    }
  }

  /// 获取状态图标
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  /// 获取状态文本
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '待领取';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      default:
        return '未知';
    }
  }

  /// 获取状态颜色
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.accentOrange;
      case 'completed':
        return AppTheme.accentGreen;
      case 'cancelled':
        return AppTheme.textSecondaryColor;
      default:
        return AppTheme.textHintColor;
    }
  }

  /// 显示兑换详情对话框
  void _showExchangeDetail(Exchange exchange) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('兑换详情'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(
                label: '商品名称',
                value: exchange.rewardName,
              ),
              Divider(height: AppTheme.spacingMedium),
              _DetailRow(
                label: '消耗积分',
                value: '${exchange.pointsSpent} 积分',
                valueColor: AppTheme.accentOrange,
              ),
              Divider(height: AppTheme.spacingMedium),
              _DetailRow(
                label: '学习词汇',
                value: exchange.wordCode,
                valueColor: AppTheme.accentGreen,
              ),
              Divider(height: AppTheme.spacingMedium),
              _DetailRow(
                label: '兑换时间',
                value: _dateFormat.format(exchange.exchangeAt),
              ),
              Divider(height: AppTheme.spacingMedium),
              _DetailRow(
                label: '状态',
                value: _getStatusText(exchange.status),
                valueColor: _getStatusColor(exchange.status),
              ),
              if (exchange.completedAt != null) ...[
                Divider(height: AppTheme.spacingMedium),
                _DetailRow(
                  label: '完成时间',
                  value: _dateFormat.format(exchange.completedAt!),
                ),
              ],
              if (exchange.note != null && exchange.note!.isNotEmpty) ...[
                Divider(height: AppTheme.spacingMedium),
                _DetailRow(
                  label: '备注',
                  value: exchange.note!,
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (exchange.status == 'pending') ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateExchangeStatus(exchange.id!, 'cancelled');
              },
              child: Text(
                '取消兑换',
                style: TextStyle(color: AppTheme.accentRed),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateExchangeStatus(exchange.id!, 'completed');
              },
              child: Text('标记为已完成'),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('关闭'),
            ),
          ],
        ],
      ),
    );
  }

  /// 更新兑换状态
  Future<void> _updateExchangeStatus(int exchangeId, String status) async {
    final exchangeProvider = context.read<ExchangeProvider>();
    final success = await exchangeProvider.updateExchangeStatus(exchangeId, status);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('状态更新成功'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exchangeProvider.errorMessage ?? '状态更新失败'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text('兑换记录'),
        ),
        body: Center(
          child: Text('请先登录'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('兑换记录'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadExchanges,
            tooltip: '刷新',
          ),
        ],
      ),
      body: Consumer<ExchangeProvider>(
        builder: (context, exchangeProvider, child) {
          if (exchangeProvider.isLoading) {
            return LoadingWidget(message: '加载兑换记录...');
          }

          if (exchangeProvider.exchanges.isEmpty) {
            return EmptyWidget(
              icon: Icons.history,
              message: '暂无兑换记录',
              subtitle: '快去商城兑换商品吧',
            );
          }

          return Column(
            children: [
              // 统计信息卡片
              FutureBuilder<Map<String, int>>(
                future: exchangeProvider.getExchangeStats(user.id!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SizedBox.shrink();
                  }

                  final stats = snapshot.data!;
                  return Container(
                    margin: EdgeInsets.all(AppTheme.spacingLarge),
                    padding: EdgeInsets.all(AppTheme.spacingMedium),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.shopping_bag,
                          label: '累计兑换',
                          value: '${stats['totalCount']}',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        _StatItem(
                          icon: Icons.monetization_on,
                          label: '消耗积分',
                          value: '${stats['totalPoints']}',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        _StatItem(
                          icon: Icons.pending_actions,
                          label: '待领取',
                          value: '${stats['pendingCount']}',
                        ),
                      ],
                    ),
                  );
                },
              ),

              // 兑换记录列表
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadExchanges,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLarge,
                    ),
                    itemCount: exchangeProvider.exchanges.length,
                    itemBuilder: (context, index) {
                      final exchange = exchangeProvider.exchanges[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: AppTheme.spacingMedium),
                        child: CustomCard(
                          child: InkWell(
                            onTap: () => _showExchangeDetail(exchange),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            child: Padding(
                              padding: EdgeInsets.all(AppTheme.spacingMedium),
                              child: Row(
                                children: [
                                  // 状态图标
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(exchange.status)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMedium,
                                      ),
                                    ),
                                    child: Icon(
                                      _getStatusIcon(exchange.status),
                                      color: _getStatusColor(exchange.status),
                                      size: 28,
                                    ),
                                  ),
                                  SizedBox(width: AppTheme.spacingMedium),

                                  // 商品信息
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                exchange.rewardName,
                                                style: TextStyle(
                                                  fontSize: AppTheme.fontSizeLarge,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textPrimaryColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: AppTheme.spacingSmall,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(exchange.status)
                                                    .withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(
                                                  AppTheme.radiusSmall,
                                                ),
                                              ),
                                              child: Text(
                                                _getStatusText(exchange.status),
                                                style: TextStyle(
                                                  fontSize: AppTheme.fontSizeXSmall,
                                                  color: _getStatusColor(exchange.status),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.school,
                                              size: 14,
                                              color: AppTheme.accentGreen,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              exchange.wordCode,
                                              style: TextStyle(
                                                fontSize: AppTheme.fontSizeSmall,
                                                color: AppTheme.accentGreen,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: AppTheme.spacingMedium),
                                            Icon(
                                              Icons.monetization_on,
                                              size: 14,
                                              color: AppTheme.accentOrange,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '${exchange.pointsSpent} 积分',
                                              style: TextStyle(
                                                fontSize: AppTheme.fontSizeSmall,
                                                color: AppTheme.accentOrange,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          _dateFormat.format(exchange.exchangeAt),
                                          style: TextStyle(
                                            fontSize: AppTheme.fontSizeSmall,
                                            color: AppTheme.textHintColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 箭头图标
                                  Icon(
                                    Icons.chevron_right,
                                    color: AppTheme.textHintColor,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 统计项组件
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
        SizedBox(height: AppTheme.spacingXSmall),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSizeXLarge,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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

/// 详情行组件
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              color: valueColor ?? AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
