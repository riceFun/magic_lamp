import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/story_provider.dart';
import '../../widgets/common/loading_widget.dart';

/// 故事详情页面
class StoryDetailPage extends StatefulWidget {
  final int storyId;

  const StoryDetailPage({
    super.key,
    required this.storyId,
  });

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        await _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          title: Row(
            children: [
              Icon(Icons.book, size: 24),
              SizedBox(width: AppTheme.spacingSmall),
              Text('故事详情'),
            ],
          ),
        ),
        body: Consumer2<UserProvider, StoryProvider>(
          builder: (context, userProvider, storyProvider, child) {
            final user = userProvider.currentUser;
            final story = storyProvider.stories.firstWhere(
              (s) => s.id == widget.storyId,
              orElse: () => storyProvider.stories.first,
            );

            if (_isProcessing) {
              return LoadingWidget.medium(message: '处理中...');
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 故事标题
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacingLarge),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              ),
                              child: Center(
                                child: Text(
                                  '📖',
                                  style: TextStyle(fontSize: 36),
                                ),
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingMedium),
                            Expanded(
                              child: Text(
                                story.content,
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeLarge,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 故事来源/内容
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacingLarge),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 24,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              '故事内容',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeMedium,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingMedium),
                        Text(
                          story.source,
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeMedium,
                            color: AppTheme.textPrimaryColor,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppTheme.spacingLarge),

                  // 学习提示
                  if (user != null)
                    FutureBuilder<bool>(
                      future: storyProvider.isTodayStoryLearned(user.id!),
                      builder: (context, snapshot) {
                        final isLearned = snapshot.data ?? false;

                        return Container(
                          padding: EdgeInsets.all(AppTheme.spacingMedium),
                          decoration: BoxDecoration(
                            color: isLearned
                                ? AppTheme.accentGreen.withValues(alpha: 0.1)
                                : AppTheme.accentYellow.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            border: Border.all(
                              color: isLearned ? AppTheme.accentGreen : AppTheme.accentYellow,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isLearned ? Icons.check_circle : Icons.info_outline,
                                color: isLearned ? AppTheme.accentGreen : AppTheme.accentYellow,
                                size: 24,
                              ),
                              SizedBox(width: AppTheme.spacingSmall),
                              Expanded(
                                child: Text(
                                  isLearned
                                      ? '您已学习过此故事'
                                      : '阅读完成后点击返回可获得 10 积分奖励',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSizeSmall,
                                    color: isLearned ? AppTheme.accentGreen : AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 处理返回导航
  Future<void> _handleBackNavigation() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final userProvider = context.read<UserProvider>();
    final storyProvider = context.read<StoryProvider>();
    final user = userProvider.currentUser;

    if (user != null) {
      // 检查是否今日故事且未学习
      final isTodayStory = storyProvider.todayStory?.id == widget.storyId;

      if (isTodayStory) {
        final alreadyLearned = await storyProvider.isTodayStoryLearned(user.id!);

        if (!alreadyLearned) {
          // 完成学习并奖励积分
          final success = await storyProvider.completeTodayStory(user.id!, userProvider);

          if (success && mounted) {
            // 刷新用户积分
            await userProvider.refreshCurrentUser();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('恭喜！学习故事获得 10 积分'),
                  backgroundColor: AppTheme.accentGreen,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        }
      }
    }

    setState(() {
      _isProcessing = false;
    });

    // 返回故事列表
    if (mounted) {
      context.pop();
    }
  }
}
