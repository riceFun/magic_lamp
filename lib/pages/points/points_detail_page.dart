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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('积分详情'),
        actions: [
          // 词汇库按钮
          IconButton(
            icon: Icon(Icons.school),
            onPressed: () {
              context.push(AppConstants.routeMyWords);
            },
            tooltip: '词汇库',
          ),
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

          return Column(
            children: [
              // 积分卡片
              Container(
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
                    Row(
                      children: [
                        Icon(
                          Icons.account_circle,
                          size: 50,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        SizedBox(width: AppTheme.spacingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeXLarge,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingLarge),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.3),
                      height: 1,
                    ),
                    SizedBox(height: AppTheme.spacingLarge),
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.monetization_on,
                          size: 48,
                          color: AppTheme.accentYellow,
                        ),
                        SizedBox(width: AppTheme.spacingSmall),
                        Text(
                          '${user.totalPoints}',
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingSmall),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            '积分',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      '约等于 ${(user.totalPoints * AppConstants.pointsToRmb).toStringAsFixed(2)} 元',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingMedium),
                    // 预支积分按钮
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push(AppConstants.routeAdvanceApply);
                      },
                      icon: Icon(
                        Icons.account_balance_wallet,
                        size: 20,
                      ),
                      label: Text(
                        '申请预支积分',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingLarge,
                          vertical: AppTheme.spacingMedium,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),

              // 历史记录列表
              Expanded(
                child: recordProvider.isLoading
                    ? LoadingWidget.medium(
                        message: '加载记录中...',
                      )
                    : recordProvider.errorMessage != null
                        ? Center(
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
                          )
                        : recordProvider.getFilteredRecords().isEmpty
                            ? EmptyWidget(
                                icon: Icons.history,
                                message: '暂无记录',
                                subtitle: '快去完成任务或兑换商品吧',
                              )
                            : Container(
                                color: AppTheme.backgroundColor,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacingLarge,
                                        vertical: AppTheme.spacingMedium,
                                      ),
                                      child: Text(
                                        '积分历史',
                                        style: TextStyle(
                                          fontSize: AppTheme.fontSizeLarge,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: RefreshIndicator(
                                        onRefresh: () async {
                                          final user =
                                              userProvider.currentUser;
                                          if (user != null) {
                                            await recordProvider
                                                .loadUserRecords(user.id!);
                                          }
                                        },
                                        child: ListView.builder(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: AppTheme.spacingLarge,
                                          ),
                                          itemCount: recordProvider
                                              .getFilteredRecords().length,
                                          itemBuilder: (context, index) {
                                            final record = recordProvider
                                                .getFilteredRecords()[index];
                                            return _PointRecordCard(
                                                record: record);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
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
      margin: EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: CustomCard(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingMedium),
          child: Row(
            children: [
              // 图标
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  _getIcon(),
                  color: _getColor(),
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
                      record.description ?? '无描述',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      dateFormat.format(record.createdAt),
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
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
                      fontSize: AppTheme.fontSizeSmall,
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
