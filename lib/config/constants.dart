/// 神灯积分管理 - 常量配置
class AppConstants {
  // 私有构造函数，防止实例化
  AppConstants._();

  // ==================== 应用信息 ====================

  /// 应用名称
  static const String appName = '神灯积分管理';

  /// 应用英文名
  static const String appNameEn = 'Magic Lamp';

  /// 应用版本
  static const String appVersion = '1.0.0';

  // ==================== 积分规则 ====================

  /// 初始积分
  static const int initialPoints = 0;

  /// 积分与人民币换算比例（10积分 = 1元）
  static const double pointsToRmb = 0.1;

  /// 每日推荐积分目标（最小值）
  static const int dailyPointsMin = 200;

  /// 每日推荐积分目标（最大值）
  static const int dailyPointsMax = 400;

  /// 预支积分月利率（10%）
  static const double advanceInterestRate = 0.1;

  // ==================== 任务奖励积分建议 ====================

  /// 简单任务积分范围（5-15分钟）
  static const int taskPointsSimpleMin = 10;
  static const int taskPointsSimpleMax = 30;

  /// 中等任务积分范围（15-30分钟）
  static const int taskPointsMediumMin = 30;
  static const int taskPointsMediumMax = 80;

  /// 复杂任务积分范围（30-60分钟）
  static const int taskPointsComplexMin = 80;
  static const int taskPointsComplexMax = 150;

  /// 重要任务积分范围（1小时以上）
  static const int taskPointsImportantMin = 150;
  static const int taskPointsImportantMax = 300;

  /// 连续完成奖励积分范围
  static const int streakBonusMin = 10;
  static const int streakBonusMax = 50;

  // ==================== 商品定价建议 ====================

  /// 小奖励积分范围（约5-20元）
  static const int rewardSmallMin = 50;
  static const int rewardSmallMax = 200;

  /// 中等奖励积分范围（约20-100元）
  static const int rewardMediumMin = 200;
  static const int rewardMediumMax = 1000;

  /// 大奖励积分范围（约100-500元）
  static const int rewardLargeMin = 1000;
  static const int rewardLargeMax = 5000;

  /// 特权奖励积分范围
  static const int rewardPrivilegeMin = 100;
  static const int rewardPrivilegeMax = 500;

  // ==================== 连续完成奖励里程碑 ====================

  /// 连续3天奖励积分
  static const int streak3DaysBonus = 30;

  /// 连续7天奖励积分
  static const int streak7DaysBonus = 100;

  /// 连续30天奖励积分
  static const int streak30DaysBonus = 500;

  // ==================== 数据库 ====================

  /// 数据库名称
  static const String databaseName = 'magic_lamp.db';

  /// 数据库版本
  static const int databaseVersion = 1;

  // ==================== 本地存储 Key ====================

  /// 当前登录用户 ID
  static const String keyCurrentUserId = 'current_user_id';

  /// 是否首次启动
  static const String keyFirstLaunch = 'first_launch';

  /// 自动备份设置
  static const String keyAutoBackup = 'auto_backup';

  /// 上次备份时间
  static const String keyLastBackupTime = 'last_backup_time';

  // ==================== 页面路由 ====================

  /// 启动页
  static const String routeSplash = '/';

  /// 登录页
  static const String routeLogin = '/login';

  /// 主页（含底部导航）
  static const String routeMain = '/main';

  /// 任务详情
  static const String routeTaskDetail = '/task/detail';

  /// 任务创建
  static const String routeTaskCreate = '/task/create';

  /// 商品详情
  static const String routeProductDetail = '/shop/product';

  /// 兑换记录
  static const String routeExchangeHistory = '/shop/exchange-history';

  /// 我的词汇库
  static const String routeMyWords = '/shop/my-words';

  /// 项目管理
  static const String routeProjectManagement = '/settings/projects';

  /// 标签管理
  static const String routeTagManagement = '/settings/tags';

  /// 模板管理
  static const String routeTemplateManagement = '/settings/templates';

  /// 商城管理
  static const String routeShopManagement = '/settings/shop';

  /// 目标设定
  static const String routeGoalManagement = '/settings/goals';

  /// 备份与恢复
  static const String routeBackup = '/settings/backup';

  /// 用户管理
  static const String routeUserManagement = '/settings/users';

  /// 个人资料
  static const String routeProfile = '/settings/profile';

  // ==================== 动画时长 ====================

  /// 短动画时长（毫秒）
  static const int animationDurationShort = 200;

  /// 中等动画时长（毫秒）
  static const int animationDurationMedium = 300;

  /// 长动画时长（毫秒）
  static const int animationDurationLong = 500;

  // ==================== 其他配置 ====================

  /// 页面切换动画时长（毫秒）
  static const int pageTransitionDuration = 300;

  /// 默认分页大小
  static const int defaultPageSize = 20;

  /// 图片缓存最大数量
  static const int maxImageCacheCount = 100;

  /// 成语和英文词汇示例
  static const List<String> idiomExamples = [
    '一帆风顺',
    '心想事成',
    '如虎添翼',
    '锦上添花',
    '书香门第',
    '妙笔生花',
    '马到成功',
    '大展宏图',
    '劳逸结合',
    '心旷神怡',
  ];

  static const List<String> englishWordExamples = [
    'Success',
    'Happy',
    'Bright',
    'Smart',
    'Knowledge',
    'Achievement',
    'Excellent',
    'Outstanding',
    'Relax',
    'Freedom',
  ];
}
