import 'package:flutter/material.dart';

/// 神灯积分管理 - 主题配置
/// 设计理念：活泼、可爱、有趣（适合儿童）
/// 主色：明快的蓝色
class AppTheme {
  // 私有构造函数，防止实例化
  AppTheme._();

  // ==================== 主题色 ====================

  /// 主色 - 明快蓝色
  static const Color primaryColor = Color(0xFF42A5F5); // 浅蓝
  static const Color primaryDarkColor = Color(0xFF2196F3); // 标准蓝
  static const Color primaryLightColor = Color(0xFF90CAF9); // 更浅的蓝

  /// 辅助色 - 用于强调和点缀
  static const Color accentYellow = Color(0xFFFFD54F); // 明亮黄色
  static const Color accentGreen = Color(0xFF66BB6A); // 明亮绿色
  static const Color accentOrange = Color(0xFFFF9800); // 明亮橙色
  static const Color accentRed = Color(0xFFEF5350); // 明亮红色
  static const Color accentPurple = Color(0xFFAB47BC); // 明亮紫色

  /// 背景色
  static const Color backgroundColor = Color(0xFFF5F5F5); // 浅灰背景
  static const Color cardColor = Colors.white; // 卡片背景

  /// 文字颜色
  static const Color textPrimaryColor = Color(0xFF212121); // 主要文字
  static const Color textSecondaryColor = Color(0xFF757575); // 次要文字
  static const Color textHintColor = Color(0xFFBDBDBD); // 提示文字

  /// 分割线颜色
  static const Color dividerColor = Color(0xFFE0E0E0);

  // ==================== 圆角 ====================

  /// 小圆角
  static const double radiusSmall = 8.0;

  /// 中等圆角
  static const double radiusMedium = 12.0;

  /// 大圆角
  static const double radiusLarge = 16.0;

  /// 超大圆角
  static const double radiusXLarge = 24.0;

  // ==================== 间距 ====================

  /// 极小间距
  static const double spacingXSmall = 4.0;

  /// 小间距
  static const double spacingSmall = 8.0;

  /// 中等间距
  static const double spacingMedium = 16.0;

  /// 大间距
  static const double spacingLarge = 24.0;

  /// 超大间距
  static const double spacingXLarge = 32.0;

  // ==================== 字体大小 ====================

  /// 超小字体
  static const double fontSizeXSmall = 10.0;

  /// 小字体
  static const double fontSizeSmall = 12.0;

  /// 正常字体
  static const double fontSizeNormal = 14.0;

  /// 中等字体
  static const double fontSizeMedium = 16.0;

  /// 大字体
  static const double fontSizeLarge = 18.0;

  /// 超大字体
  static const double fontSizeXLarge = 24.0;

  /// 标题字体
  static const double fontSizeTitle = 32.0;

  // ==================== 主题数据 ====================

  /// 亮色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // 配色方案
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentYellow,
        surface: backgroundColor,
        brightness: Brightness.light,
      ),

      // 主色
      primaryColor: primaryColor,

      // 脚手架背景色
      scaffoldBackgroundColor: backgroundColor,

      // 卡片主题
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      // 应用栏主题
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.bold,
        ),
      ),

      // 底部导航栏主题
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        selectedLabelStyle: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: fontSizeSmall,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          elevation: 2,
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // 文本按钮主题
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: accentRed),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingMedium,
        ),
      ),

      // 文本主题
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeTitle,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeMedium,
          color: textPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeNormal,
          color: textPrimaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeSmall,
          color: textSecondaryColor,
        ),
        labelSmall: TextStyle(
          fontSize: fontSizeXSmall,
          color: textHintColor,
        ),
      ),

      // 分割线主题
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),

      // 浮动操作按钮主题
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ==================== 自定义阴影 ====================

  /// 卡片阴影
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// 按钮阴影
  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
