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

/// 积分详情页面 - 显示积分数值和历史记录
class PointsDetailPage extends StatefulWidget {
  const PointsDetailPage({super.key});

  @override
  State<PointsDetailPage> createState() => _PointsDetailPageState();
}

class _PointsDetailPageState extends State<PointsDetailPage> {
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

  /// 按日期分组记录
  Map<String, List<PointRecord>> _groupRecordsByDate(List<PointRecord> records) {
    final Map<String, List<PointRecord>> grouped = {};

    for (var record in records) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.createdAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(record);
    }

    return grouped;
  }

  /// 计算ListView的总item数量
  int _calculateItemCount(Map<String, List<PointRecord>> groupedRecords) {
    // 2个固定项（积分卡片 + 标题） + 每组的日期标题 + 所有记录
    int count = 2;
    groupedRecords.forEach((date, records) {
      count += 1; // 日期标题
      count += records.length; // 该日期的所有记录
    });
    return count;
  }

  /// 构建分组后的记录项
  Widget _buildGroupedRecordItem(Map<String, List<PointRecord>> groupedRecords, int relativeIndex) {
    int currentIndex = 0;

    // 按日期倒序排列（最新的在前面）
    final sortedDates = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    for (var dateKey in sortedDates) {
      final records = groupedRecords[dateKey]!;

      // 如果是日期标题
      if (currentIndex == relativeIndex) {
        return _DateHeader(dateKey: dateKey);
      }
      currentIndex++;

      // 如果是该日期的某条记录
      if (relativeIndex < currentIndex + records.length) {
        final recordIndex = relativeIndex - currentIndex;
        return _PointRecordCard(record: records[recordIndex]);
      }
      currentIndex += records.length;
    }

    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        automaticallyImplyLeading: false,
        title: Text('积分详情'),
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
            return LoadingWidget.medium(message: '加载记录中...');
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
          final groupedRecords = _groupRecordsByDate(records);

          return RefreshIndicator(
            onRefresh: () async {
              if (user != null) {
                await recordProvider.loadUserRecords(user.id!);
              }
            },
            child: ListView.builder(
              padding: EdgeInsets.all(AppTheme.spacingLarge),
              itemCount: _calculateItemCount(groupedRecords),
              itemBuilder: (context, index) {
                // 第一项：积分信息卡片（包含预支按钮和游戏入口）
                if (index == 0) {
                  return _PointsSummaryCard(user: user);
                }

                // 第二项：标题
                if (index == 1) {
                  if (records.isEmpty) {
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: AppTheme.spacingXLarge),
                      child: EmptyWidget(
                        icon: Icons.history,
                        message: '暂无记录',
                        subtitle: '快去完成任务或兑换商品吧',
                      ),
                    );
                  }
                  return Container(
                    margin: EdgeInsets.only(
                      top: AppTheme.spacingMedium,
                      bottom: AppTheme.spacingSmall,
                    ),
                    child: Text(
                      '积分历史',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  );
                }

                // 后续项：日期分组和历史记录
                return _buildGroupedRecordItem(groupedRecords, index - 2);
              },
            ),
          );
        },
      ),
    );
  }
}

/// 积分汇总卡片
class _PointsSummaryCard extends StatelessWidget {
  final dynamic user;

  const _PointsSummaryCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSmall),
      child: CustomCard(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingXSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：用户名 + 积分
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 用户名
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  // 积分
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        size: 28,
                        color: AppTheme.accentYellow,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${user.totalPoints}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          height: 1,
                        ),
                      ),
                      SizedBox(width: 4),
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          '积分',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeMedium,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: AppTheme.spacingMedium),

              // 第二行：申请预支积分按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push(AppConstants.routeAdvanceApply);
                  },
                  icon: Icon(Icons.account_balance_wallet, size: 20),
                  label: Text(
                    '申请预支积分',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLarge,
                      vertical: AppTheme.spacingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                ),
              ),

              SizedBox(height: AppTheme.spacingMedium),

              // 第三行：积分大富翁游戏入口（777老虎机风格）
              InkWell(
                onTap: () {
                  context.push(AppConstants.routeSlotGame);
                },
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppTheme.spacingMedium),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.accentYellow,
                        AppTheme.accentOrange,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 777 老虎机图标
                      Text(
                        '🎰',
                        style: TextStyle(fontSize: 28),
                      ),
                      SizedBox(width: AppTheme.spacingSmall),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '积分大富翁',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '7️⃣7️⃣7️⃣ 幸运转盘等你来',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeSmall,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: AppTheme.spacingSmall),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 积分记录卡片
class _PointRecordCard extends StatelessWidget {
  final PointRecord record;

  const _PointRecordCard({required this.record});

  /// 获取积分变动图标
  IconData _getIcon() {
    if (record.type == 'earn') {
      if (record.sourceType == 'task') {
        return Icons.task_alt;
      } else if (record.sourceType == 'advance') {
        return Icons.account_balance_wallet;
      } else if (record.sourceType == 'manual') {
        return Icons.add_circle;
      } else {
        return Icons.add;
      }
    } else {
      if (record.sourceType == 'exchange') {
        return Icons.card_giftcard;
      } else if (record.sourceType == 'advance_repay') {
        return Icons.payment;
      } else {
        return Icons.remove;
      }
    }
  }

  /// 获取积分变动颜色
  Color _getColor() {
    return record.type == 'earn'
        ? AppTheme.accentGreen
        : AppTheme.accentRed;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM-dd HH:mm');

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSmall),
      child: CustomCard(
        child: Padding(
          padding: EdgeInsets.all(2),
          child: Row(
            children: [
              // 图标
              Icon(
                _getIcon(),
                color: _getColor(),
                size: 28,
              ),
              SizedBox(width: AppTheme.spacingSmall),

              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.description ?? '无描述',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeNormal,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      dateFormat.format(record.createdAt),
                      style: TextStyle(
                        fontSize:  AppTheme.fontSizeNormal,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // 积分变动
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${record.points >= 0 ? '+' : ''}${record.points}',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeXLarge,
                      fontWeight: FontWeight.bold,
                      color: _getColor(),
                    ),
                  ),
                  Text(
                    '余额: ${record.balance}',
                    style: TextStyle(
                      fontSize:  AppTheme.fontSizeNormal,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 日期分组标题
class _DateHeader extends StatelessWidget {
  final String dateKey;

  const _DateHeader({required this.dateKey});

  /// 获取日期标签
  String _getDateLabel() {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final dayBeforeYesterday = today.subtract(Duration(days: 2));
    final targetDate = DateTime(date.year, date.month, date.day);

    final dateFormat = DateFormat('MM月dd日');
    final dateString = dateFormat.format(date);

    if (targetDate == today) {
      return '今天 $dateString';
    } else if (targetDate == yesterday) {
      return '昨天 $dateString';
    } else if (targetDate == dayBeforeYesterday) {
      return '前天 $dateString';
    } else {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: AppTheme.spacingMedium,
        bottom: AppTheme.spacingSmall,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: AppTheme.spacingSmall),
          Text(
            _getDateLabel(),
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
