import 'package:flutter/foundation.dart';
import '../data/models/point.dart';
import '../data/repositories/point_record_repository.dart';

/// 积分记录状态管理
class PointRecordProvider extends ChangeNotifier {
  final PointRecordRepository _repository = PointRecordRepository();

  /// 积分记录列表
  List<PointRecord> _records = [];

  /// 加载状态
  bool _isLoading = false;

  /// 错误信息
  String? _errorMessage;

  /// 当前筛选类型 ('all', 'earn', 'spend')
  String _filterType = 'all';

  // Getters
  List<PointRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filterType => _filterType;

  /// 获取收入记录
  List<PointRecord> get earnRecords =>
      _records.where((r) => r.isEarn).toList();

  /// 获取支出记录
  List<PointRecord> get spendRecords =>
      _records.where((r) => r.isSpend).toList();

  /// 加载用户的所有积分记录
  Future<void> loadUserRecords(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _records = await _repository.getUserPointRecords(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '加载积分记录失败: $e';
      debugPrint('PointRecordProvider loadUserRecords error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 设置筛选类型
  void setFilterType(String type) {
    _filterType = type;
    notifyListeners();
  }

  /// 获取筛选后的记录
  List<PointRecord> getFilteredRecords() {
    switch (_filterType) {
      case 'earn':
        return earnRecords;
      case 'spend':
        return spendRecords;
      default:
        return _records;
    }
  }

  /// 获取用户统计数据
  Future<Map<String, int>> getUserStatistics(int userId) async {
    try {
      final totalEarned = await _repository.getUserTotalEarned(userId);
      final totalSpent = await _repository.getUserTotalSpent(userId);
      final recordCount = await _repository.getUserRecordCount(userId);

      return {
        'totalEarned': totalEarned,
        'totalSpent': totalSpent,
        'recordCount': recordCount,
      };
    } catch (e) {
      debugPrint('PointRecordProvider getUserStatistics error: $e');
      return {
        'totalEarned': 0,
        'totalSpent': 0,
        'recordCount': 0,
      };
    }
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
