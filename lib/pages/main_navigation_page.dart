import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'home/home_page.dart';
import 'shop/shop_page.dart';
import 'history/history_page.dart';
import 'statistics/statistics_page.dart';
import 'settings/settings_page.dart';

/// 主导航页面 - 底部导航栏 + PageView
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  /// PageView 控制器
  late PageController _pageController;

  /// 当前页面索引
  int _currentIndex = 0;

  /// 页面列表
  final List<Widget> _pages = [
    HomePage(),
    ShopPage(),
    HistoryPage(),
    StatisticsPage(),
    SettingsPage(),
  ];

  /// 底部导航栏项目
  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: '首页',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.store_outlined),
      activeIcon: Icon(Icons.store),
      label: '商城',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history),
      activeIcon: Icon(Icons.history),
      label: '历史',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart_outlined),
      activeIcon: Icon(Icons.bar_chart),
      label: '统计',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: '设置',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 切换页面
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// 点击底部导航栏
  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.cardColor,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        selectedLabelStyle: const TextStyle(
          fontSize: AppTheme.fontSizeSmall,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: AppTheme.fontSizeSmall,
        ),
        items: _navItems,
        elevation: 8,
      ),
    );
  }
}
