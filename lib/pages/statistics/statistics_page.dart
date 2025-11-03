import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/exchange_provider.dart';
import '../../providers/advance_provider.dart';
import '../../data/repositories/point_record_repository.dart';
import '../../data/repositories/exchange_repository.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';

/// 统计页面 - 积分统计和图表
class StatisticsPage extends StatefulWidget {
  StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final _repository = PointRecordRepository();
  final _userWordRepository = UserWordRepository();
  bool _isLoading = true;

  // 总体统计
  int _totalEarned = 0;
  int _totalSpent = 0;

  // 今日统计
  int _todayEarned = 0;
  int _todaySpent = 0;
  int _todayCount = 0;

  // 本周统计
  int _weekEarned = 0;
  int _weekSpent = 0;
  int _weekCount = 0;

  // 本月统计
  int _monthEarned = 0;
  int _monthSpent = 0;
  int _monthCount = 0;

  // 任务统计
  Map<String, int> _taskStats = {};

  // 兑换统计
  Map<String, int> _exchangeStats = {};

  // 预支统计
  Map<String, dynamic> _advanceStats = {};

  // 词汇学习统计
  Map<String, int> _wordStats = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  /// 加载统计数据
  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.currentUser;

      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 获取总体统计
      _totalEarned = await _repository.getUserTotalEarned(user.id!);
      _totalSpent = await _repository.getUserTotalSpent(user.id!);

      // 获取今日记录
      final todayRecords = await _repository.getTodayRecords(user.id!);
      _todayCount = todayRecords.length;
      _todayEarned = 0;
      _todaySpent = 0;
      for (var record in todayRecords) {
        if (record.points > 0) {
          _todayEarned += record.points;
        } else {
          _todaySpent += record.points.abs();
        }
      }

      // 获取本周记录
      final weekRecords = await _repository.getThisWeekRecords(user.id!);
      _weekCount = weekRecords.length;
      _weekEarned = 0;
      _weekSpent = 0;
      for (var record in weekRecords) {
        if (record.points > 0) {
          _weekEarned += record.points;
        } else {
          _weekSpent += record.points.abs();
        }
      }

      // 获取本月记录
      final monthRecords = await _repository.getThisMonthRecords(user.id!);
      _monthCount = monthRecords.length;
      _monthEarned = 0;
      _monthSpent = 0;
      for (var record in monthRecords) {
        if (record.points > 0) {
          _monthEarned += record.points;
        } else {
          _monthSpent += record.points.abs();
        }
      }

      // 获取任务统计
      final taskProvider = context.read<TaskProvider>();
      _taskStats = await taskProvider.getTaskStats(user.id!);

      // 获取兑换统计
      final exchangeProvider = context.read<ExchangeProvider>();
      _exchangeStats = await exchangeProvider.getExchangeStats(user.id!);

      // 获取预支统计
      final advanceProvider = context.read<AdvanceProvider>();
      _advanceStats = await advanceProvider.getAdvanceStats(user.id!);

      // 获取词汇学习统计
      _wordStats = await _userWordRepository.getUserWordStats(user.id!);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载统计数据失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('统计'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.currentUser;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: AppTheme.spacingLarge),
                  Text(
                    '未登录',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          if (_isLoading) {
            return LoadingWidget.medium(message: '加载统计数据...');
          }

          return RefreshIndicator(
            onRefresh: _loadStatistics,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(AppTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 总体统计卡片
                  Container(
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
                    padding: EdgeInsets.all(AppTheme.spacingLarge),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              '总体统计',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingLarge),
                        Row(
                          children: [
                            Expanded(
                              child: _StatisticItem(
                                label: '总收入',
                                value: '$_totalEarned',
                                icon: Icons.arrow_upward,
                                iconColor: AppTheme.accentGreen,
                                isLight: true,
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingMedium),
                            Expanded(
                              child: _StatisticItem(
                                label: '总支出',
                                value: '$_totalSpent',
                                icon: Icons.arrow_downward,
                                iconColor: AppTheme.accentRed,
                                isLight: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingMedium),
                        _StatisticItem(
                          label: '当前余额',
                          value: '${user.totalPoints}',
                          icon: Icons.monetization_on,
                          iconColor: AppTheme.accentYellow,
                          isLight: true,
                        ),
                        SizedBox(height: AppTheme.spacingSmall),
                        Text(
                          '约等于 ${(user.totalPoints * AppConstants.pointsToRmb).toStringAsFixed(2)} 元',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 时间段统计标题
                  Text(
                    '时间段统计',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingMedium),

                  // 今日统计
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.today,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                            SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              '今日统计',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingMedium),
                        Row(
                          children: [
                            Expanded(
                              child: _StatisticItem(
                                label: '收入',
                                value: '$_todayEarned',
                                icon: Icons.add_circle,
                                iconColor: AppTheme.accentGreen,
                                isLight: false,
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingMedium),
                            Expanded(
                              child: _StatisticItem(
                                label: '支出',
                                value: '$_todaySpent',
                                icon: Icons.remove_circle,
                                iconColor: AppTheme.accentRed,
                                isLight: false,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingMedium),
                        _StatisticItem(
                          label: '记录数',
                          value: '$_todayCount',
                          icon: Icons.receipt,
                          iconColor: AppTheme.primaryColor,
                          isLight: false,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppTheme.spacingMedium),

                  // 本周统计
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.date_range,
                              color: AppTheme.accentOrange,
                              size: 24,
                            ),
                            SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              '本周统计',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingMedium),
                        Row(
                          children: [
                            Expanded(
                              child: _StatisticItem(
                                label: '收入',
                                value: '$_weekEarned',
                                icon: Icons.add_circle,
                                iconColor: AppTheme.accentGreen,
                                isLight: false,
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingMedium),
                            Expanded(
                              child: _StatisticItem(
                                label: '支出',
                                value: '$_weekSpent',
                                icon: Icons.remove_circle,
                                iconColor: AppTheme.accentRed,
                                isLight: false,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingMedium),
                        _StatisticItem(
                          label: '记录数',
                          value: '$_weekCount',
                          icon: Icons.receipt,
                          iconColor: AppTheme.accentOrange,
                          isLight: false,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppTheme.spacingMedium),

                  // 本月统计
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: AppTheme.accentGreen,
                              size: 24,
                            ),
                            SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              '本月统计',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingMedium),
                        Row(
                          children: [
                            Expanded(
                              child: _StatisticItem(
                                label: '收入',
                                value: '$_monthEarned',
                                icon: Icons.add_circle,
                                iconColor: AppTheme.accentGreen,
                                isLight: false,
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingMedium),
                            Expanded(
                              child: _StatisticItem(
                                label: '支出',
                                value: '$_monthSpent',
                                icon: Icons.remove_circle,
                                iconColor: AppTheme.accentRed,
                                isLight: false,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingMedium),
                        _StatisticItem(
                          label: '记录数',
                          value: '$_monthCount',
                          icon: Icons.receipt,
                          iconColor: AppTheme.accentGreen,
                          isLight: false,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 活动统计标题
                  Text(
                    '活动统计',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingMedium),

                  // 任务统计
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.task_alt,
                              color: AppTheme.accentGreen,
                              size: 24,
                            ),
                            SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              '任务统计',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingMedium),
                        Row(
                          children: [
                            Expanded(
                              child: _CompactStatItem(
                                label: '总任务数',
                                value: '${_taskStats['totalCount'] ?? 0}',
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Expanded(
                              child: _CompactStatItem(
                                label: '已完成',
                                value: '${_taskStats['completedCount'] ?? 0}',
                                color: AppTheme.accentGreen,
                              ),
                            ),
                            Expanded(
                              child: _CompactStatItem(
                                label: '进行中',
                                value: '${_taskStats['activeCount'] ?? 0}',
                                color: AppTheme.accentOrange,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingSmall),
                        Row(
                          children: [
                            Expanded(
                              child: _CompactStatItem(
                                label: '总积分',
                                value: '${_taskStats['totalPoints'] ?? 0}',
                                color: AppTheme.accentYellow,
                              ),
                            ),
                            Expanded(
                              child: _CompactStatItem(
                                label: '连续天数',
                                value: '${_taskStats['maxStreak'] ?? 0}',
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Expanded(
                              child: Container(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppTheme.spacingMedium),

                  // 兑换统计
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.card_giftcard,
                              color: AppTheme.accentYellow,
                              size: 24,
                            ),
                            SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              '兑换统计',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingMedium),
                        Row(
                          children: [
                            Expanded(
                              child: _CompactStatItem(
                                label: '兑换次数',
                                value: '${_exchangeStats['totalCount'] ?? 0}',
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Expanded(
                              child: _CompactStatItem(
                                label: '消费积分',
                                value: '${_exchangeStats['totalPoints'] ?? 0}',
                                color: AppTheme.accentRed,
                              ),
                            ),
                            Expanded(
                              child: _CompactStatItem(
                                label: '奖励数',
                                value: '${_exchangeStats['rewardCount'] ?? 0}',
                                color: AppTheme.accentYellow,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppTheme.spacingMedium),

                  // 预支统计
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: AppTheme.accentOrange,
                              size: 24,
                            ),
                            SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              '预支统计',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingMedium),
                        Row(
                          children: [
                            Expanded(
                              child: _CompactStatItem(
                                label: '预支次数',
                                value: '${_advanceStats['totalCount'] ?? 0}',
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Expanded(
                              child: _CompactStatItem(
                                label: '预支总额',
                                value: '${_advanceStats['totalAmount'] ?? 0}',
                                color: AppTheme.accentOrange,
                              ),
                            ),
                            Expanded(
                              child: _CompactStatItem(
                                label: '已付利息',
                                value: '${_advanceStats['totalInterest'] ?? 0}',
                                color: AppTheme.accentRed,
                              ),
                            ),
                          ],
                        ),
                        if (_advanceStats['activeCount'] != null && _advanceStats['activeCount'] > 0) ...[
                          SizedBox(height: AppTheme.spacingSmall),
                          Container(
                            padding: EdgeInsets.all(AppTheme.spacingSmall),
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withValues(alpha: 0.1),
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
                                Text(
                                  '当前有 ${_advanceStats['activeCount']} 笔预支进行中',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSizeSmall,
                                    color: AppTheme.accentOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: AppTheme.spacingMedium),

                  // 词汇学习统计
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.school,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                            SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              '词汇学习',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingMedium),
                        Row(
                          children: [
                            Expanded(
                              child: _CompactStatItem(
                                label: '已学词汇',
                                value: '${_wordStats['totalCount'] ?? 0}',
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Expanded(
                              child: _CompactStatItem(
                                label: '成语',
                                value: '${_wordStats['chineseCount'] ?? 0}',
                                color: AppTheme.accentGreen,
                              ),
                            ),
                            Expanded(
                              child: _CompactStatItem(
                                label: '英文',
                                value: '${_wordStats['englishCount'] ?? 0}',
                                color: AppTheme.accentOrange,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingSmall),
                        Container(
                          padding: EdgeInsets.all(AppTheme.spacingSmall),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                              SizedBox(width: AppTheme.spacingSmall),
                              Expanded(
                                child: Text(
                                  '每次兑换奖励都会学习一个新词汇',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSizeSmall,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

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
                          Icons.info_outline,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        SizedBox(width: AppTheme.spacingSmall),
                        Expanded(
                          child: Text(
                            '下拉刷新数据，或点击右上角刷新按钮',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeSmall,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 统计项组件
class _StatisticItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isLight; // 是否是浅色背景（白色文字）

  _StatisticItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isLight ? Colors.white : AppTheme.textPrimaryColor;
    final secondaryColor = isLight
        ? Colors.white.withValues(alpha: 0.8)
        : AppTheme.textSecondaryColor;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withValues(alpha: 0.2)
            : iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isLight ? Colors.white : iconColor,
            size: 28,
          ),
          SizedBox(height: AppTheme.spacingSmall),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTheme.fontSizeXLarge,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 紧凑统计项组件
class _CompactStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  _CompactStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fontSizeXSmall,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}
