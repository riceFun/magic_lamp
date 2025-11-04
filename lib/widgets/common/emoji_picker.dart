import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Emoji分类数据
class EmojiCategory {
  final String name;
  final List<String> emojis;
  final IconData icon;

  const EmojiCategory({
    required this.name,
    required this.emojis,
    required this.icon,
  });
}

/// 预定义的Emoji分类
class EmojiData {
  static final List<EmojiCategory> categories = [
    EmojiCategory(
      name: '学习',
      icon: Icons.school,
      emojis: [
        '📚', '📖', '📝', '✏️', '📓', '📔', '📕', '📗', '📘', '📙',
        '🎓', '🖊️', '✒️', '📐', '📏', '🧮', '🔬', '🔭', '📊', '📈',
      ],
    ),
    EmojiCategory(
      name: '工作',
      icon: Icons.work,
      emojis: [
        '💼', '💻', '⌨️', '🖥️', '📱', '☎️', '📞', '📟', '📠', '🗂️',
        '📁', '📂', '🗃️', '📋', '📌', '📍', '✅', '📧', '💡', '🎯',
      ],
    ),
    EmojiCategory(
      name: '运动',
      icon: Icons.fitness_center,
      emojis: [
        '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏉', '🎱', '🏓', '🏸',
        '🏒', '🏑', '🥍', '🏏', '⛳', '🏹', '🎣', '🥊', '🥋', '🎽',
        '🏃', '🚴', '🏋️', '🤸', '🧘', '⛷️', '🏂', '🏊', '🤾', '🏇',
        '🪢',
      ],
    ),
    EmojiCategory(
      name: '健康',
      icon: Icons.favorite,
      emojis: [
        '❤️', '💚', '💙', '💛', '🧡', '💜', '🤍', '🖤', '💖', '💝',
        '🏥', '💊', '💉', '🩺', '🩹', '🌡️', '😊', '😌', '🧘', '🌿',
        '🥗', '🥑', '🥦', '🥬', '🥒', '🍎', '🍊', '🍋', '🍇', '🍓',
      ],
    ),
    EmojiCategory(
      name: '阅读',
      icon: Icons.book,
      emojis: [
        '📚', '📖', '📕', '📗', '📘', '📙', '📓', '📔', '📃', '📄',
        '📰', '🗞️', '🔖', '🏷️', '📑', '🧾', '📜', '📋', '📊', '📈',
      ],
    ),
    EmojiCategory(
      name: '艺术',
      icon: Icons.palette,
      emojis: [
        '🎨', '🖌️', '🖍️', '🎭', '🎬', '🎤', '🎧', '🎼', '🎹', '🥁',
        '🎷', '🎺', '🎸', '🎻', '🎮', '🃏', '🎰', '📷', '📸', '📹',
      ],
    ),
    EmojiCategory(
      name: '生活',
      icon: Icons.home,
      emojis: [
        '🏠', '🏡', '🏘️', '🏚️', '🏗️', '🏭', '🏢', '🏬', '🏣', '🏤',
        '🛏️', '🛋️', '🪑', '🚪', '🪟', '🧹', '🧺', '🧻', '🧼', '🧽',
        '🍽️', '🍴', '🥄', '🔪', '🏺', '🕯️', '💡', '🔦', '🏮', '🔌',
      ],
    ),
    EmojiCategory(
      name: '食物',
      icon: Icons.restaurant,
      emojis: [
        '🍔', '🍕', '🌭', '🥪', '🌮', '🌯', '🥙', '🥗', '🍿', '🧈',
        '🍎', '🍌', '🍊', '🍋', '🍉', '🍇', '🍓', '🫐', '🍒', '🍑',
        '🍕', '🍔', '🍟', '🥓', '🍗', '🍖', '🦴', '🌭', '🍝', '🍜',
      ],
    ),
    EmojiCategory(
      name: '交通',
      icon: Icons.directions_car,
      emojis: [
        '🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑', '🚒', '🚐',
        '🚚', '🚛', '🚜', '🛻', '🦯', '🦽', '🦼', '🛴', '🚲', '🛵',
        '🏍️', '🛺', '🚨', '🚔', '🚍', '🚘', '🚖', '🚡', '🚠', '🚟',
      ],
    ),
    EmojiCategory(
      name: '自然',
      icon: Icons.wb_sunny,
      emojis: [
        '🌸', '🌺', '🌻', '🌷', '🌹', '🥀', '💐', '🌼', '🌱', '🌿',
        '☘️', '🍀', '🍃', '🍂', '🍁', '🌾', '🌲', '🌳', '🌴', '🌵',
        '☀️', '🌤️', '⛅', '🌥️', '☁️', '🌦️', '🌧️', '⛈️', '🌩️', '🌨️',
      ],
    ),
    EmojiCategory(
      name: '表情',
      icon: Icons.emoji_emotions,
      emojis: [
        '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃',
        '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😙',
        '😋', '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔',
      ],
    ),
    EmojiCategory(
      name: '其他',
      icon: Icons.more_horiz,
      emojis: [
        '⭐', '🌟', '✨', '⚡', '🔥', '💫', '🎁', '🎈', '🎀', '🎊',
        '🎉', '🎯', '🎲', '🔮', '🧿', '🪬', '📿', '🔔', '🔕', '🎵',
      ],
    ),
  ];

  /// 获取所有emoji的扁平列表
  static List<String> getAllEmojis() {
    return categories.expand((category) => category.emojis).toList();
  }

  /// 根据关键词搜索emoji（简单的拼音映射）
  static Map<String, String> emojiNameMap = {
    '学习': '📚', '书': '📚', '读书': '📖', '写': '📝', '笔': '✏️',
    '工作': '💼', '电脑': '💻', '文件': '📁', '邮件': '📧', '目标': '🎯',
    '运动': '⚽', '跑步': '🏃', '健身': '🏋️', '篮球': '🏀', '足球': '⚽', '跳绳': '🪢',
    '健康': '❤️', '医院': '🏥', '心': '❤️', '水果': '🍎', '蔬菜': '🥗',
    '阅读': '📖', '书本': '📚', '报纸': '📰',
    '艺术': '🎨', '画': '🎨', '音乐': '🎵', '相机': '📷',
    '生活': '🏠', '家': '🏠', '灯': '💡', '扫除': '🧹',
    '食物': '🍔', '吃': '🍽️', '饭': '🍚', '水果': '🍎',
    '交通': '🚗', '车': '🚗', '自行车': '🚲', '飞机': '✈️',
    '自然': '🌸', '花': '🌸', '树': '🌳', '太阳': '☀️', '月亮': '🌙',
    '表情': '😀', '笑': '😊', '开心': '😄', '爱': '😍',
    '星': '⭐', '礼物': '🎁', '气球': '🎈', '庆祝': '🎉',
  };

  /// 根据关键词搜索emoji
  static List<String> searchEmojis(String query) {
    if (query.isEmpty) return getAllEmojis();

    final lowerQuery = query.toLowerCase();
    final results = <String>[];

    // 1. 先检查名称映射
    emojiNameMap.forEach((key, emoji) {
      if (key.contains(lowerQuery) && !results.contains(emoji)) {
        results.add(emoji);
      }
    });

    // 2. 返回结果
    return results.isNotEmpty ? results : getAllEmojis();
  }
}

/// Emoji选择器对话框
class EmojiPicker extends StatefulWidget {
  final String? selectedEmoji;
  final Function(String?) onEmojiSelected;

  const EmojiPicker({
    super.key,
    this.selectedEmoji,
    required this.onEmojiSelected,
  });

  /// 显示emoji选择器
  static Future<String?> show(BuildContext context, {String? initialEmoji}) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: _EmojiPickerDialog(initialEmoji: initialEmoji),
      ),
    );
  }

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker> {
  @override
  Widget build(BuildContext context) {
    return Container(); // Placeholder, 实际使用Dialog
  }
}

/// Emoji选择器对话框内容
class _EmojiPickerDialog extends StatefulWidget {
  final String? initialEmoji;

  const _EmojiPickerDialog({this.initialEmoji});

  @override
  State<_EmojiPickerDialog> createState() => _EmojiPickerDialogState();
}

class _EmojiPickerDialogState extends State<_EmojiPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedEmoji;
  List<String> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.initialEmoji;
    _tabController = TabController(
      length: EmojiData.categories.length,
      vsync: this,
    );
    _searchResults = EmojiData.getAllEmojis();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      _searchResults = EmojiData.searchEmojis(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMedium),
                topRight: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '选择图标',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                if (_selectedEmoji != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMedium,
                      vertical: AppTheme.spacingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      _selectedEmoji!,
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
              ],
            ),
          ),

          // 搜索框
          Padding(
            padding: EdgeInsets.all(AppTheme.spacingMedium),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: '搜索图标（如：学习、运动、书）',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // 分类标签（搜索时隐藏）
          if (!_isSearching)
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondaryColor,
                indicatorColor: AppTheme.primaryColor,
                tabs: EmojiData.categories.map((category) {
                  return Tab(
                    icon: Icon(category.icon, size: 20),
                    text: category.name,
                  );
                }).toList(),
              ),
            ),

          // Emoji网格
          Expanded(
            child: _isSearching
                ? _buildSearchResults()
                : TabBarView(
                    controller: _tabController,
                    children: EmojiData.categories.map((category) {
                      return _buildEmojiGrid(category.emojis);
                    }).toList(),
                  ),
          ),

          // 底部按钮
          Container(
            padding: EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(null);
                    },
                    child: Text('取消'),
                  ),
                ),
                SizedBox(width: AppTheme.spacingMedium),
                if (_selectedEmoji != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedEmoji = null;
                        });
                      },
                      icon: Icon(Icons.clear),
                      label: Text('清除'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentRed,
                        side: BorderSide(color: AppTheme.accentRed),
                      ),
                    ),
                  ),
                SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(_selectedEmoji);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('确定'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textHintColor,
            ),
            SizedBox(height: AppTheme.spacingMedium),
            Text(
              '未找到匹配的图标',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return _buildEmojiGrid(_searchResults);
  }

  Widget _buildEmojiGrid(List<String> emojis) {
    return GridView.builder(
      padding: EdgeInsets.all(AppTheme.spacingMedium),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: AppTheme.spacingSmall,
        crossAxisSpacing: AppTheme.spacingSmall,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        final isSelected = emoji == _selectedEmoji;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedEmoji = emoji;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.2)
                  : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                emoji,
                style: TextStyle(fontSize: 32),
              ),
            ),
          ),
        );
      },
    );
  }
}
