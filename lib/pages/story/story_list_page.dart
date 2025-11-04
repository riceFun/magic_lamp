import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/story_provider.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../data/models/story.dart';

/// 故事列表页面
class StoryListPage extends StatefulWidget {
  const StoryListPage({super.key});

  @override
  State<StoryListPage> createState() => _StoryListPageState();
}

class _StoryListPageState extends State<StoryListPage> {
  final ScrollController _scrollController = ScrollController();
  int? _highlightStoryId; // 需要高亮的故事ID

  @override
  void initState() {
    super.initState();
    // 加载故事列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final storyProvider = context.read<StoryProvider>();
      final user = userProvider.currentUser;

      if (user != null) {
        storyProvider.loadLearnedStories(user.id!);
      }

      // 检查是否有需要滚动到的故事
      if (storyProvider.scrollToStoryId != null) {
        final targetId = storyProvider.scrollToStoryId!;
        // 先滚动
        _scrollToStory(targetId).then((_) {
          // 滚动完成后再设置高亮
          if (mounted) {
            setState(() {
              _highlightStoryId = targetId;
            });
            // 3秒后清除高亮
            Future.delayed(Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _highlightStoryId = null;
                });
              }
            });
          }
        });
        // 清除滚动标记
        storyProvider.clearScrollToStoryId();
      } else if (storyProvider.todayStory != null) {
        // 如果没有指定滚动位置，默认滚动到今日故事
        _scrollToStory(storyProvider.todayStory!.id);
      }
    });
  }

  /// 滚动到指定故事
  Future<void> _scrollToStory(int storyId) async {
    await Future.delayed(Duration(milliseconds: 100)); // 等待列表渲染
    if (_scrollController.hasClients) {
      final index = storyId;
      // 计算滚动位置（每个卡片约110高度 + 间距）
      final offset = index * 110.0;
      await _scrollController.animateTo(
        offset,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: Row(
          children: [
            Icon(Icons.book, size: 24),
            SizedBox(width: AppTheme.spacingSmall),
            Text('故事列表'),
          ],
        ),
      ),
      body: Consumer2<UserProvider, StoryProvider>(
        builder: (context, userProvider, storyProvider, child) {
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

          if (storyProvider.isLoading) {
            return LoadingWidget.medium(message: '加载故事中...');
          }

          if (storyProvider.errorMessage != null) {
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
                    storyProvider.errorMessage!,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          if (storyProvider.stories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book,
                    size: 80,
                    color: AppTheme.textHintColor,
                  ),
                  SizedBox(height: AppTheme.spacingMedium),
                  Text(
                    '暂无故事',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(AppTheme.spacingLarge),
            itemCount: storyProvider.stories.length,
            itemBuilder: (context, index) {
              final story = storyProvider.stories[index];
              final isTodayStory = storyProvider.todayStory?.id == story.id;
              final isLearned = storyProvider.learnedStoryIds.contains(story.id);
              final shouldHighlight = _highlightStoryId == story.id;

              return _StoryCard(
                story: story,
                isTodayStory: isTodayStory,
                isLearned: isLearned,
                shouldHighlight: shouldHighlight,
                onTap: () {
                  context.push(
                    '${AppConstants.routeStoryDetail}/${story.id}',
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// 故事卡片
class _StoryCard extends StatefulWidget {
  final Story story;
  final bool isTodayStory;
  final bool isLearned;
  final bool shouldHighlight;
  final VoidCallback onTap;

  const _StoryCard({
    required this.story,
    required this.isTodayStory,
    required this.isLearned,
    required this.shouldHighlight,
    required this.onTap,
  });

  @override
  State<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<_StoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: AppTheme.accentYellow.withValues(alpha: 0.3),
      end: Colors.transparent,
    ).animate(_animationController);

    if (widget.shouldHighlight) {
      _startBlinking();
    }
  }

  @override
  void didUpdateWidget(_StoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldHighlight && !oldWidget.shouldHighlight) {
      _startBlinking();
    }
  }

  void _startBlinking() {
    // 闪烁3次
    _animationController.repeat(reverse: true);
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) {
        _animationController.stop();
        _animationController.value = 1.0;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.only(bottom: AppTheme.spacingMedium),
          decoration: BoxDecoration(
            color: widget.shouldHighlight ? _colorAnimation.value : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: CustomCard(
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Container(
                decoration: widget.isTodayStory
                    ? BoxDecoration(
                        border: Border.all(
                          color: AppTheme.accentYellow,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      )
                    : null,
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingMedium),
              child: Row(
                children: [
                  // 故事图标
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.isTodayStory
                          ? AppTheme.accentYellow.withValues(alpha: 0.2)
                          : AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Center(
                      child: Text(
                        '📖',
                        style: TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMedium),

                  // 故事信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // 序号
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${widget.story.id + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            if (widget.isTodayStory) ...[
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentYellow,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '今日',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                widget.story.content,
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeMedium,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.story.source,
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            color: AppTheme.textSecondaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // 学习状态
                  if (widget.isLearned)
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 24,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
        );
      },
    );
  }
}
