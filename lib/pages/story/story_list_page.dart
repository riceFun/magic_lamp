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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: Text('故事列表'),
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

          return CustomScrollView(
            slivers: [
              // 今日故事卡片
              if (storyProvider.todayStory != null)
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(
                      AppTheme.spacingLarge,
                      AppTheme.spacingLarge,
                      AppTheme.spacingLarge,
                      AppTheme.spacingMedium,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: AppTheme.spacingSmall),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: AppTheme.accentYellow,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '今日故事',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeMedium,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StoryCard(
                          story: storyProvider.todayStory!,
                          isTodayStory: true,
                          isLearned: storyProvider.learnedStoryIds.contains(storyProvider.todayStory!.id),
                          shouldHighlight: false,
                          onTap: () {
                            context.push(
                              '${AppConstants.routeStoryDetail}/${storyProvider.todayStory!.id}',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              // 分隔线
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLarge,
                    vertical: AppTheme.spacingSmall,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.menu_book,
                        color: AppTheme.textSecondaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '全部故事',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 所有故事列表
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spacingLarge,
                  0,
                  AppTheme.spacingLarge,
                  AppTheme.spacingLarge,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final story = storyProvider.stories[index];
                      final isTodayStory = storyProvider.todayStory?.id == story.id;
                      final isLearned = storyProvider.learnedStoryIds.contains(story.id);

                      return _StoryCard(
                        story: story,
                        isTodayStory: isTodayStory,
                        isLearned: isLearned,
                        shouldHighlight: false,
                        onTap: () {
                          context.push(
                            '${AppConstants.routeStoryDetail}/${story.id}',
                          );
                        },
                      );
                    },
                    childCount: storyProvider.stories.length,
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

/// 故事卡片
class _StoryCard extends StatelessWidget {
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
              padding: EdgeInsets.all(2),
              child: Row(
                children: [
                  // 故事图标
                  // Text(
                  //   '📖',
                  //   style: TextStyle(fontSize: 64),
                  // ),
                  // SizedBox(width: AppTheme.spacingSmall),

                  // 故事信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                '#${story.id + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
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
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.check_circle,
                        size: 20,
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
