import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/exchange_provider.dart';
import '../../providers/user_provider.dart';
import '../../data/models/user_word.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';

/// 我的词汇库页面
class MyWordsPage extends StatefulWidget {
  const MyWordsPage({super.key});

  @override
  State<MyWordsPage> createState() => _MyWordsPageState();
}

class _MyWordsPageState extends State<MyWordsPage>
    with SingleTickerProviderStateMixin {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  late TabController _tabController;
  String _selectedType = 'all'; // 'all', 'idiom', 'english'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _selectedType = 'all';
              break;
            case 1:
              _selectedType = 'idiom';
              break;
            case 2:
              _selectedType = 'english';
              break;
          }
        });
      }
    });
    _loadWords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;

    if (user != null) {
      await context.read<ExchangeProvider>().loadUserWords(user.id!);
    }
  }

  /// 获取筛选后的词汇列表
  List<UserWord> _getFilteredWords(List<UserWord> allWords) {
    if (_selectedType == 'all') {
      return allWords;
    }
    return allWords.where((word) => word.wordType == _selectedType).toList();
  }

  /// 获取来源文本
  String _getSourceText(String sourceType) {
    switch (sourceType) {
      case 'exchange':
        return '商品兑换';
      case 'task':
        return '任务奖励';
      case 'manual':
        return '手动添加';
      default:
        return '其他';
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
          title: Text('我的词汇库'),
        ),
        body: Center(
          child: Text('请先登录'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('我的词汇库'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '全部'),
            Tab(text: '成语'),
            Tab(text: '英文'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadWords,
            tooltip: '刷新',
          ),
        ],
      ),
      body: Consumer<ExchangeProvider>(
        builder: (context, exchangeProvider, child) {
          if (exchangeProvider.isLoading) {
            return LoadingWidget(message: '加载词汇库...');
          }

          final allWords = exchangeProvider.userWords;
          final filteredWords = _getFilteredWords(allWords);

          return Column(
            children: [
              // 统计信息卡片
              FutureBuilder<Map<String, int>>(
                future: exchangeProvider.getWordStats(user.id!),
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
                          AppTheme.accentGreen,
                          AppTheme.accentGreen.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.school,
                          label: '累计学习',
                          value: '${stats['totalCount']}',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        _StatItem(
                          icon: Icons.translate,
                          label: '中文成语',
                          value: '${stats['chineseCount']}',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        _StatItem(
                          icon: Icons.language,
                          label: '英文单词',
                          value: '${stats['englishCount']}',
                        ),
                      ],
                    ),
                  );
                },
              ),

              // 词汇列表
              Expanded(
                child: filteredWords.isEmpty
                    ? EmptyWidget(
                        icon: Icons.school,
                        message: _selectedType == 'all'
                            ? '暂无学习记录'
                            : _selectedType == 'idiom'
                                ? '暂无成语学习记录'
                                : '暂无英文单词学习记录',
                        subtitle: '快去商城兑换商品学习词汇吧',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadWords,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingLarge,
                          ),
                          itemCount: filteredWords.length,
                          itemBuilder: (context, index) {
                            final word = filteredWords[index];
                            return Container(
                              margin: EdgeInsets.only(
                                bottom: AppTheme.spacingMedium,
                              ),
                              child: CustomCard(
                                child: Padding(
                                  padding: EdgeInsets.all(AppTheme.spacingMedium),
                                  child: Row(
                                    children: [
                                      // 类型图标
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: word.wordType == 'idiom'
                                                ? [
                                                    AppTheme.accentOrange,
                                                    AppTheme.accentOrange
                                                        .withValues(alpha: 0.7),
                                                  ]
                                                : [
                                                    AppTheme.primaryColor,
                                                    AppTheme.primaryDarkColor,
                                                  ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusMedium,
                                          ),
                                        ),
                                        child: Icon(
                                          word.wordType == 'idiom'
                                              ? Icons.translate
                                              : Icons.language,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      SizedBox(width: AppTheme.spacingMedium),

                                      // 词汇信息
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    word.wordCode,
                                                    style: TextStyle(
                                                      fontSize:
                                                          AppTheme.fontSizeXLarge,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme
                                                          .textPrimaryColor,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        AppTheme.spacingSmall,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: (word.wordType ==
                                                                'idiom'
                                                            ? AppTheme.accentOrange
                                                            : AppTheme.primaryColor)
                                                        .withValues(alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      AppTheme.radiusSmall,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    word.wordType == 'idiom'
                                                        ? '成语'
                                                        : '英文',
                                                    style: TextStyle(
                                                      fontSize:
                                                          AppTheme.fontSizeXSmall,
                                                      color: word.wordType ==
                                                              'idiom'
                                                          ? AppTheme.accentOrange
                                                          : AppTheme.primaryColor,
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
                                                  Icons.calendar_today,
                                                  size: 14,
                                                  color:
                                                      AppTheme.textSecondaryColor,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  _dateFormat
                                                      .format(word.learnedAt),
                                                  style: TextStyle(
                                                    fontSize:
                                                        AppTheme.fontSizeSmall,
                                                    color: AppTheme
                                                        .textSecondaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  size: 14,
                                                  color: AppTheme.textHintColor,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  '来源：${_getSourceText(word.sourceType)}',
                                                  style: TextStyle(
                                                    fontSize:
                                                        AppTheme.fontSizeSmall,
                                                    color: AppTheme.textHintColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 徽章图标
                                      Icon(
                                        Icons.workspace_premium,
                                        color: AppTheme.accentYellow,
                                        size: 32,
                                      ),
                                    ],
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
