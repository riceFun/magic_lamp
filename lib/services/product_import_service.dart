import 'dart:convert';
import 'package:flutter/services.dart';
import '../data/models/reward.dart';
import '../data/repositories/reward_repository.dart';

/// 导入结果统计
class ImportResult {
  final int successCount; // 成功导入数量
  final int skippedCount; // 跳过数量（已存在）
  final int failedCount; // 失败数量
  final List<String> errors; // 错误信息列表

  ImportResult({
    required this.successCount,
    required this.skippedCount,
    required this.failedCount,
    required this.errors,
  });

  int get totalProcessed => successCount + skippedCount + failedCount;

  @override
  String toString() {
    return 'ImportResult{总计: $totalProcessed, 成功: $successCount, 跳过: $skippedCount, 失败: $failedCount}';
  }
}

/// 商品导入服务
/// 负责从 assets/products.json 导入商品数据到数据库
class ProductImportService {
  final RewardRepository _rewardRepository = RewardRepository();

  /// 从 assets/products.json 导入商品
  Future<ImportResult> importProducts() async {
    int successCount = 0;
    int skippedCount = 0;
    int failedCount = 0;
    List<String> errors = [];

    try {
      // 1. 读取 JSON 文件
      final String jsonString =
          await rootBundle.loadString('assets/products.json');

      // 2. 解析 JSON 数据
      final List<dynamic> productsJson = json.decode(jsonString);

      // 3. 遍历每个商品
      for (var productJson in productsJson) {
        try {
          final Map<String, dynamic> productMap = productJson;
          final String name = productMap['name'] as String;

          // 4. 检查商品是否已存在（通过名称）
          if (await _isProductExists(name)) {
            skippedCount++;
            continue;
          }

          // 5. 映射并创建 Reward 对象
          final Reward reward = _mapJsonToReward(productMap);

          // 6. 添加到数据库
          await _rewardRepository.createReward(reward);
          successCount++;
        } catch (e) {
          failedCount++;
          errors.add('导入商品失败: ${productJson['name'] ?? 'Unknown'} - $e');
        }
      }
    } catch (e) {
      errors.add('读取或解析 JSON 文件失败: $e');
    }

    return ImportResult(
      successCount: successCount,
      skippedCount: skippedCount,
      failedCount: failedCount,
      errors: errors,
    );
  }

  /// 检查商品是否已存在（通过名称）
  Future<bool> _isProductExists(String name) async {
    final rewards = await _rewardRepository.getAllRewards();
    return rewards.any((reward) => reward.name == name);
  }

  /// 将 JSON 数据映射到 Reward 对象
  Reward _mapJsonToReward(Map<String, dynamic> json) {
    // 解析积分：固定积分 vs 范围积分
    int points = 0;
    int? minPoints;
    int? maxPoints;

    if (json.containsKey('point_type') &&
        json['point_type'] == '范围积分' &&
        json.containsKey('point_range')) {
      // 范围积分：解析 "500-1000" 格式
      final String pointRange = json['point_range'] as String;
      final parts = pointRange.split('-');
      if (parts.length == 2) {
        minPoints = int.tryParse(parts[0].trim());
        maxPoints = int.tryParse(parts[1].trim());
        // points 设置为最小值（用于排序等场景）
        points = minPoints ?? 0;
      }
    } else if (json.containsKey('points')) {
      // 固定积分
      points = json['points'] as int;
    }

    // 映射兑换频率
    final String? exchangeFrequency = _mapPeriodToFrequency(
      json['period'] as String?,
    );

    // 映射兑换次数限制
    final int? maxExchangeCount = _mapLimitToCount(
      json['limit'],
    );

    // 映射分类
    final String category = _mapCategory(
      json['category'] as String?,
      json['type'] as String?,
    );

    // 构建 Reward 对象
    return Reward(
      name: json['name'] as String,
      description: json['description'] as String?,
      points: points,
      minPoints: minPoints,
      maxPoints: maxPoints,
      wordCode: json['wordCode'] as String? ?? json['name'] as String, // 使用商品名称作为默认值
      icon: json['icon'] as String?,
      category: category,
      type: json['type'] as String?,
      stock: -1, // 无限库存
      status: 'active', // 默认激活状态
      exchangeFrequency: exchangeFrequency,
      maxExchangeCount: maxExchangeCount,
      note: json['note'] as String?,
    );
  }

  /// 映射期间到兑换频率
  /// "每日" -> daily, "每周" -> weekly, "每月" -> monthly, "每季度" -> quarterly, "每年" -> yearly
  String? _mapPeriodToFrequency(String? period) {
    if (period == null) return null;

    switch (period) {
      case '每日':
        return 'daily';
      case '每周':
        return 'weekly';
      case '每月':
        return 'monthly';
      case '每季度':
        return 'quarterly';
      case '每年':
        return 'yearly';
      default:
        return null;
    }
  }

  /// 映射限制到兑换次数
  /// "无限次" -> null, 数字 -> 数字
  int? _mapLimitToCount(dynamic limit) {
    if (limit == null) return null;

    if (limit is String) {
      if (limit == '无限次') {
        return null;
      }
      // 尝试解析字符串数字
      return int.tryParse(limit);
    }

    if (limit is int) {
      return limit;
    }

    return null;
  }

  /// 映射分类
  /// 根据 JSON 中的 category 和 type 推断系统分类
  /// 系统分类: snack, toy, book, entertainment, privilege, other
  String _mapCategory(String? category, String? type) {
    // 优先根据 type 判断
    if (type != null) {
      switch (type) {
        case '食物':
          return 'snack';
        case '玩具':
          return 'toy';
        case '书籍':
        case '学习':
          return 'book';
        case '体验':
        case '娱乐':
          return 'entertainment';
        case '服务':
        case '特殊':
          return 'privilege';
      }
    }

    // 根据 category 判断
    if (category != null) {
      if (category.contains('日常')) {
        return 'snack';
      } else if (category.contains('娱乐')) {
        return 'entertainment';
      } else if (category.contains('魔法') || category.contains('特权')) {
        return 'privilege';
      } else if (category.contains('玩具')) {
        return 'toy';
      } else if (category.contains('书籍') || category.contains('学习')) {
        return 'book';
      }
    }

    // 默认分类
    return 'other';
  }

  /// 清空所有商品（危险操作，仅用于测试）
  Future<void> clearAllProducts() async {
    final rewards = await _rewardRepository.getAllRewards();
    for (var reward in rewards) {
      if (reward.id != null) {
        await _rewardRepository.deleteReward(reward.id!);
      }
    }
  }

  /// 重新导入所有商品（清空后重新导入）
  Future<ImportResult> reimportProducts() async {
    await clearAllProducts();
    return await importProducts();
  }
}
