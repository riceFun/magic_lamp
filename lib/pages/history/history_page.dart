import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/point_record_provider.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';
import '../../data/models/point.dart';

/// 历史记录页面 - 积分收支记录
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    // 加载积分记录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.currentUser;
      if (user != null) {
        context.read<PointRecordProvider>().loadUserRecords(user.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('历史记录'),
        actions: [
          // 兑换记录按钮
          IconButton(
            icon: Icon(Icons.card_giftcard),
            onPressed: () {
              context.push(AppConstants.routeExchangeHistory);
            },
            tooltip: '兑换记录',
          ),
          // 筛选按钮
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              context.read<PointRecordProvider>().setFilterType(value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Text('全部记录'),
              ),
              PopupMenuItem(
                value: 'earn',
                child: Text('收入记录'),
              ),
              PopupMenuItem(
                value: 'spend',
                child: Text('支出记录'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer2<UserProvider, PointRecordProvider>(
        builder: (context, userProvider, recordProvider, child) {
          final user = userProvider.currentUser;

          if (user == null) {
            return Center(
              child: Text(
                '未登录',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            );
          }

          if (recordProvider.isLoading) {
            return LoadingWidget.medium(
              message: '加载记录中...',
            );
          }

          if (recordProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppTheme.accentRed,
                  ),
                  SizedBox(height: AppTheme.spacingMedium),
                  Text(
                    recordProvider.errorMessage!,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          final records = recordProvider.getFilteredRecords();

          if (records.isEmpty) {
            return EmptyWidget.noHistory();
          }

          return Column(
            children: [
              // 统计卡片
              _buildStatisticsCard(user.id!, recordProvider),

              // 记录列表
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(AppTheme.spacingLarge),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return _buildRecordItem(record);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatisticsCard(int userId, PointRecordProvider provider) {
    return FutureBuilder<Map<String, int>>(
      future: provider.getUserStatistics(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        final stats = snapshot.data!;
        final totalEarned = stats['totalEarned'] ?? 0;
        final totalSpent = stats['totalSpent'] ?? 0;
        final recordCount = stats['recordCount'] ?? 0;

        return Container(
          margin: EdgeInsets.all(AppTheme.spacingLarge),
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
                '统计概览',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: AppTheme.spacingLarge),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.arrow_upward,
                      label: '总收入',
                      value: totalEarned.toString(),
                      color: AppTheme.accentGreen,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMedium),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.arrow_downward,
                      label: '总支出',
                      value: totalSpent.toString(),
                      color: AppTheme.accentRed,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMedium),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.receipt,
                      label: '记录数',
                      value: recordCount.toString(),
                      color: AppTheme.accentYellow,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建统计项
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.9),
          size: 24,
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
        SizedBox(height: AppTheme.spacingXSmall),
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

  /// 构建记录项
  Widget _buildRecordItem(PointRecord record) {
    final isEarn = record.isEarn;
    final color = isEarn ? AppTheme.accentGreen : AppTheme.accentRed;
    final icon = isEarn ? Icons.add_circle : Icons.remove_circle;
    final sign = isEarn ? '+' : '-';

    return CustomCard(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: Row(
        children: [
          // 图标
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          SizedBox(width: AppTheme.spacingMedium),

          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSourceTypeLabel(record.sourceType),
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 4),
                if (record.description != null)
                  Text(
                    record.description!,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 4),
                Text(
                  _formatDateTime(record.createdAt),
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeXSmall,
                    color: AppTheme.textHintColor,
                  ),
                ),
              ],
            ),
          ),

          // 积分
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${record.points.abs()}',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '余额: ${record.balance}',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 获取来源类型标签
  String _getSourceTypeLabel(String sourceType) {
    switch (sourceType) {
      case 'task':
        return '完成任务';
      case 'exchange':
        return '兑换奖励';
      case 'advance':
        return '预支积分';
      case 'adjustment':
        return '积分调整';
      case 'bonus':
        return '奖励积分';
      default:
        return sourceType;
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final recordDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (recordDate == today) {
      return '今天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (recordDate == yesterday) {
      return '昨天 ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('MM-dd HH:mm').format(dateTime);
    }
  }
}
