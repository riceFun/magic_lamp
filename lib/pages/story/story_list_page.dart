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

      // 滚动到今日故事位置
      if (storyProvider.todayStory != null) {
        _scrollToTodayStory();
      }
    });
  }

  /// 滚动到今日故事
  void _scrollToTodayStory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storyProvider = context.read<StoryProvider>();
      if (storyProvider.todayStory != null && _scrollController.hasClients) {
        final index = storyProvider.todayStory!.id;
        // 计算滚动位置（每个卡片约100高度 + 间距）
        final offset = index * 110.0;
        _scrollController.animateTo(
          offset,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
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

              return _StoryCard(
                story: story,
                isTodayStory: isTodayStory,
                isLearned: isLearned,
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
class _StoryCard extends StatelessWidget {
  final Story story;
  final bool isTodayStory;
  final bool isLearned;
  final VoidCallback onTap;

  const _StoryCard({
    required this.story,
    required this.isTodayStory,
    required this.isLearned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: CustomCard(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            decoration: isTodayStory
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
                      color: isTodayStory
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
                            if (isTodayStory) ...[
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
                                story.content,
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
                          story.source,
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
                  if (isLearned)
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
  }
}
