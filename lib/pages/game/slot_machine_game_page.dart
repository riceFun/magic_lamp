import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../config/theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/slot_game_provider.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';

/// 积分大富翁游戏页面
class SlotMachineGamePage extends StatefulWidget {
  const SlotMachineGamePage({super.key});

  @override
  State<SlotMachineGamePage> createState() => _SlotMachineGamePageState();
}

class _SlotMachineGamePageState extends State<SlotMachineGamePage>
    with TickerProviderStateMixin {
  late AnimationController _slotController1;
  late AnimationController _slotController2;
  late AnimationController _slotController3;
  late AnimationController _pulseController;

  String _displaySlot1 = '7';
  String _displaySlot2 = '7';
  String _displaySlot3 = '7';

  Timer? _spinTimer1;
  Timer? _spinTimer2;
  Timer? _spinTimer3;

  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();

    _slotController1 = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );

    _slotController2 = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );

    _slotController3 = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // 加载今日游戏记录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.currentUser;
      if (user != null) {
        context.read<SlotGameProvider>().loadTodayRecords(user.id!);
      }
    });
  }

  @override
  void dispose() {
    _slotController1.dispose();
    _slotController2.dispose();
    _slotController3.dispose();
    _pulseController.dispose();
    _spinTimer1?.cancel();
    _spinTimer2?.cancel();
    _spinTimer3?.cancel();
    super.dispose();
  }

  /// 开始游戏
  Future<void> _startGame() async {
    final userProvider = context.read<UserProvider>();
    final slotProvider = context.read<SlotGameProvider>();
    final user = userProvider.currentUser;

    if (user == null) return;

    setState(() => _isSpinning = true);

    // 开始转盘动画
    _startSpinning();

    // 调用Provider执行游戏逻辑
    final result = await slotProvider.playGame(user.id!, user.totalPoints);

    if (!result['success']) {
      setState(() => _isSpinning = false);
      _stopSpinning();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
      return;
    }

    // 转盘停止，依次停止三个转盘
    await _stopSpinningWithResult(
      result['result1'],
      result['result2'],
      result['result3'],
    );

    setState(() => _isSpinning = false);

    // 刷新用户积分
    await userProvider.refreshCurrentUser();

    // 显示中奖动画
    if (mounted) {
      await _showPrizeAnimation(
        result['prizeType'],
        result['prizeName'],
        result['reward'],
        result['netProfit'],
      );
    }
  }

  /// 开始转盘转动
  void _startSpinning() {
    _spinTimer1 = Timer.periodic(Duration(milliseconds: 100), (_) {
      setState(() {
        _displaySlot1 = SlotGameProvider.slotItems[
            DateTime.now().millisecondsSinceEpoch %
                SlotGameProvider.slotItems.length];
      });
      _slotController1.forward(from: 0);
    });

    _spinTimer2 = Timer.periodic(Duration(milliseconds: 120), (_) {
      setState(() {
        _displaySlot2 = SlotGameProvider.slotItems[
            (DateTime.now().millisecondsSinceEpoch + 5) %
                SlotGameProvider.slotItems.length];
      });
      _slotController2.forward(from: 0);
    });

    _spinTimer3 = Timer.periodic(Duration(milliseconds: 140), (_) {
      setState(() {
        _displaySlot3 = SlotGameProvider.slotItems[
            (DateTime.now().millisecondsSinceEpoch + 10) %
                SlotGameProvider.slotItems.length];
      });
      _slotController3.forward(from: 0);
    });
  }

  /// 停止转盘（无结果）
  void _stopSpinning() {
    _spinTimer1?.cancel();
    _spinTimer2?.cancel();
    _spinTimer3?.cancel();
  }

  /// 停止转盘并显示结果
  Future<void> _stopSpinningWithResult(
    String result1,
    String result2,
    String result3,
  ) async {
    // 第一个转盘停止
    await Future.delayed(Duration(milliseconds: 800));
    _spinTimer1?.cancel();
    setState(() => _displaySlot1 = result1);

    // 第二个转盘停止
    await Future.delayed(Duration(milliseconds: 600));
    _spinTimer2?.cancel();
    setState(() => _displaySlot2 = result2);

    // 第三个转盘停止
    await Future.delayed(Duration(milliseconds: 600));
    _spinTimer3?.cancel();
    setState(() => _displaySlot3 = result3);

    await Future.delayed(Duration(milliseconds: 500));
  }

  /// 显示中奖动画
  Future<void> _showPrizeAnimation(
    String prizeType,
    String prizeName,
    int reward,
    int netProfit,
  ) async {
    if (prizeType == 'jackpot777' || prizeType == 'diamond') {
      // 全屏特效
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _FullScreenPrizeDialog(
          prizeType: prizeType,
          prizeName: prizeName,
          reward: reward,
          netProfit: netProfit,
        ),
      );
    } else if (prizeType != 'none') {
      // 普通中奖动画
      await showDialog(
        context: context,
        builder: (context) => _NormalPrizeDialog(
          prizeName: prizeName,
          reward: reward,
          netProfit: netProfit,
        ),
      );
    } else {
      // 未中奖
      await showDialog(
        context: context,
        builder: (context) => _NoWinDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: Text('🎰 积分大富翁'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () => _showRulesDialog(),
            tooltip: '游戏规则',
          ),
        ],
      ),
      body: Consumer2<UserProvider, SlotGameProvider>(
        builder: (context, userProvider, slotProvider, child) {
          final user = userProvider.currentUser;

          if (user == null) {
            return Center(child: Text('未登录'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              children: [
                // 积分余额显示
                CustomCard(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingMedium),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: AppTheme.accentYellow,
                          size: 32,
                        ),
                        SizedBox(width: AppTheme.spacingSmall),
                        Text(
                          '当前积分：',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeLarge,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          '${user.totalPoints}',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeXLarge,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: AppTheme.spacingMedium),

                // 剩余次数显示
                _RemainingPlaysCard(
                  remaining: slotProvider.remainingPlays,
                  total: SlotGameProvider.dailyLimit,
                ),

                SizedBox(height: AppTheme.spacingLarge),

                // 转盘区域
                CustomCard(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingLarge),
                    child: Column(
                      children: [
                        // 转盘
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _SlotReel(
                              value: _displaySlot1,
                              controller: _slotController1,
                            ),
                            _SlotReel(
                              value: _displaySlot2,
                              controller: _slotController2,
                            ),
                            _SlotReel(
                              value: _displaySlot3,
                              controller: _slotController3,
                            ),
                          ],
                        ),

                        SizedBox(height: AppTheme.spacingLarge),

                        // 开始按钮
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isSpinning
                                  ? 1.0
                                  : 1.0 + _pulseController.value * 0.05,
                              child: ElevatedButton.icon(
                                onPressed: _isSpinning ||
                                        !slotProvider.canPlay ||
                                        user.totalPoints < 1
                                    ? null
                                    : _startGame,
                                icon: Icon(
                                  _isSpinning ? Icons.casino : Icons.play_arrow,
                                  size: 28,
                                ),
                                label: Text(
                                  _isSpinning ? '转动中...' : '开始游戏 (-1积分)',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSizeLarge,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isSpinning
                                      ? Colors.grey
                                      : AppTheme.accentOrange,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingXLarge,
                                    vertical: AppTheme.spacingLarge,
                                  ),
                                  minimumSize: Size(double.infinity, 60),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusLarge),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: AppTheme.spacingSmall),

                        // 提示文字
                        if (!slotProvider.canPlay)
                          Text(
                            '今日次数已用完',
                            style: TextStyle(
                              color: AppTheme.accentRed,
                              fontSize: AppTheme.fontSizeMedium,
                            ),
                          )
                        else if (user.totalPoints < 1)
                          Text(
                            '积分不足，无法游戏',
                            style: TextStyle(
                              color: AppTheme.accentRed,
                              fontSize: AppTheme.fontSizeMedium,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: AppTheme.spacingLarge),

                // 今日游戏记录
                if (slotProvider.todayRecords.isNotEmpty) ...[
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '今日游戏记录',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingMedium),
                  ...slotProvider.todayRecords.map((record) {
                    return _GameRecordCard(record: record);
                  }).toList(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// 显示游戏规则对话框
  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (context) => _GameRulesDialog(),
    );
  }
}

/// 转盘组件
class _SlotReel extends StatelessWidget {
  final String value;
  final AnimationController controller;

  const _SlotReel({
    required this.value,
    required this.controller,
  });

  /// 根据值返回背景颜色
  Color _getBackgroundColor() {
    switch (value) {
      case '0':
        return Colors.purple;
      case '1':
        return Colors.blue;
      case '2':
        return Colors.green;
      case '3':
        return Colors.teal;
      case '4':
        return Colors.orange;
      case '5':
        return Colors.pink;
      case '6':
        return Colors.indigo;
      case '7':
        return Colors.red; // 7是红色
      case '8':
        return Colors.brown;
      case '9':
        return Colors.deepPurple;
      case '💎':
        return Colors.cyan;
      case '⭐':
        return Colors.amber;
      case '🍀':
        return Colors.lightGreen;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -controller.value * 20),
          child: Container(
            width: 90,
            height: 100,
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // 数字颜色为白色
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 剩余次数卡片
class _RemainingPlaysCard extends StatelessWidget {
  final int remaining;
  final int total;

  const _RemainingPlaysCard({
    required this.remaining,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingMedium),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.confirmation_number,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                SizedBox(width: AppTheme.spacingSmall),
                Text(
                  '今日剩余次数',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            Text(
              '$remaining / $total',
              style: TextStyle(
                fontSize: AppTheme.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: remaining > 0 ? AppTheme.accentGreen : AppTheme.accentRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 游戏记录卡片
class _GameRecordCard extends StatelessWidget {
  final dynamic record;

  const _GameRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final bool isWin = record.reward > 0;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSmall),
      child: CustomCard(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingSmall),
          child: Row(
            children: [
              // 结果显示
              Row(
                children: [
                  _MiniSlot(record.result1),
                  SizedBox(width: 4),
                  _MiniSlot(record.result2),
                  SizedBox(width: 4),
                  _MiniSlot(record.result3),
                ],
              ),

              SizedBox(width: AppTheme.spacingMedium),

              // 结果文字
              Expanded(
                child: Text(
                  record.getPrizeTypeName(),
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 奖励
              Text(
                isWin ? '+${record.reward}' : '-1',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: isWin ? AppTheme.accentGreen : AppTheme.accentRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 迷你转盘显示
class _MiniSlot extends StatelessWidget {
  final String value;

  const _MiniSlot(this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Text(
          value,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

/// 游戏规则对话框
class _GameRulesDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text('🎰'),
          SizedBox(width: 8),
          Text('游戏规则', style: TextStyle(fontSize: AppTheme.fontSizeLarge)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RuleItem(
              emoji: '💰',
              title: '每次消耗',
              description: '1 积分',
            ),
            _RuleItem(
              emoji: '🎯',
              title: '每日限制',
              description: '最多玩 10 次',
            ),
            Divider(),
            Text(
              '中奖规则',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _PrizeRuleItem(symbol: '7️⃣7️⃣7️⃣', name: '超级大奖', reward: '+20', color: Colors.purple),
            _PrizeRuleItem(symbol: '💎💎💎', name: '钻石三连', reward: '+15', color: Colors.blue),
            _PrizeRuleItem(symbol: '⭐⭐⭐', name: '星星三连', reward: '+10', color: Colors.orange),
            _PrizeRuleItem(symbol: '🍀🍀🍀', name: '幸运三连', reward: '+8', color: Colors.green),
            _PrizeRuleItem(symbol: '###', name: '豹子', reward: '+5', color: AppTheme.primaryColor),
            _PrizeRuleItem(symbol: '##_', name: '对子', reward: '+2', color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('知道了'),
        ),
      ],
    );
  }
}

/// 规则项
class _RuleItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;

  const _RuleItem({
    required this.emoji,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 24)),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 中奖规则项
class _PrizeRuleItem extends StatelessWidget {
  final String symbol;
  final String name;
  final String reward;
  final Color color;

  const _PrizeRuleItem({
    required this.symbol,
    required this.name,
    required this.reward,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                symbol,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              reward,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 普通中奖对话框
class _NormalPrizeDialog extends StatefulWidget {
  final String prizeName;
  final int reward;
  final int netProfit;

  const _NormalPrizeDialog({
    required this.prizeName,
    required this.reward,
    required this.netProfit,
  });

  @override
  State<_NormalPrizeDialog> createState() => _NormalPrizeDialogState();
}

class _NormalPrizeDialogState extends State<_NormalPrizeDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // 2秒后自动关闭
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: AlertDialog(
              backgroundColor: AppTheme.accentGreen.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🎉',
                    style: TextStyle(fontSize: 80),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '恭喜中奖！',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.prizeName,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '+${widget.reward} 积分',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '净赚 ${widget.netProfit} 积分',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 未中奖对话框
class _NoWinDialog extends StatefulWidget {
  @override
  State<_NoWinDialog> createState() => _NoWinDialogState();
}

class _NoWinDialogState extends State<_NoWinDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _shakeAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticIn),
    );

    _controller.repeat(reverse: true);

    // 1.5秒后自动关闭
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: AlertDialog(
            backgroundColor: AppTheme.textSecondaryColor.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '😢',
                  style: TextStyle(fontSize: 80),
                ),
                SizedBox(height: 16),
                Text(
                  '很遗憾',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '未中奖',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '再接再厉！',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 全屏特效对话框（777和钻石三连）
class _FullScreenPrizeDialog extends StatefulWidget {
  final String prizeType;
  final String prizeName;
  final int reward;
  final int netProfit;

  const _FullScreenPrizeDialog({
    required this.prizeType,
    required this.prizeName,
    required this.reward,
    required this.netProfit,
  });

  @override
  State<_FullScreenPrizeDialog> createState() => _FullScreenPrizeDialogState();
}

class _FullScreenPrizeDialogState extends State<_FullScreenPrizeDialog>
    with TickerProviderStateMixin {
  late AnimationController _explosionController;
  late AnimationController _textController;
  late Animation<double> _explosionAnimation;
  late Animation<double> _textScaleAnimation;
  late Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();

    _explosionController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _textController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _explosionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _explosionController, curve: Curves.easeOut),
    );

    _textScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.elasticOut),
    );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _explosionController.forward();
    Future.delayed(Duration(milliseconds: 300), () {
      _textController.forward();
    });

    // 3秒后自动关闭
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _explosionController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final is777 = widget.prizeType == 'jackpot777';
    final backgroundColor = is777 ? Colors.purple : Colors.blue;
    final emoji = is777 ? '🎰' : '💎';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              backgroundColor.withValues(alpha: 0.9),
              backgroundColor.withValues(alpha: 0.7),
              Colors.black.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 爆炸粒子效果
            AnimatedBuilder(
              animation: _explosionAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ExplosionPainter(
                    progress: _explosionAnimation.value,
                    color: backgroundColor,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // 文字内容
            Center(
              child: AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textOpacityAnimation.value,
                    child: Transform.scale(
                      scale: _textScaleAnimation.value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            emoji,
                            style: TextStyle(fontSize: 120),
                          ),
                          SizedBox(height: 24),
                          Text(
                            is777 ? '超级大奖！' : '钻石三连！',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.yellow,
                              shadows: [
                                Shadow(
                                  blurRadius: 20,
                                  color: Colors.yellow,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            is777 ? '7️⃣ 7️⃣ 7️⃣' : '💎 💎 💎',
                            style: TextStyle(fontSize: 60),
                          ),
                          SizedBox(height: 32),
                          Text(
                            '+${widget.reward}',
                            style: TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 30,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '积分',
                            style: TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '净赚 ${widget.netProfit} 积分',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.yellow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 爆炸粒子绘制器
class _ExplosionPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ExplosionPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = size.width > size.height ? size.width : size.height;

    // 绘制多个圆形波纹
    for (int i = 0; i < 3; i++) {
      final delay = i * 0.2;
      final waveProgress = (progress - delay).clamp(0.0, 1.0);

      if (waveProgress > 0) {
        final radius = maxRadius * waveProgress;
        final opacity = (1.0 - waveProgress) * 0.3;

        paint.color = color.withValues(alpha: opacity);
        canvas.drawCircle(
          Offset(centerX, centerY),
          radius,
          paint,
        );
      }
    }

    // 绘制星星粒子
    for (int i = 0; i < 20; i++) {
      final angle = (i / 20) * 2 * 3.14159;
      final distance = 100 + (progress * 300);
      final x = centerX + distance * cos(angle);
      final y = centerY + distance * sin(angle);
      final opacity = 1.0 - progress;

      paint.color = Colors.yellow.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), 8 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

double cos(double radians) => (radians * 180 / 3.14159).cos();
double sin(double radians) => (radians * 180 / 3.14159).sin();

extension on double {
  double cos() {
    // 简化的cos实现
    return 1.0 - (this * this) / 2.0;
  }

  double sin() {
    // 简化的sin实现
    return this - (this * this * this) / 6.0;
  }
}
