import 'package:flutter/foundation.dart';
import '../data/models/task_template.dart';
import '../data/repositories/task_template_repository.dart';

/// 任务模板提供者
class TaskTemplateProvider with ChangeNotifier {
  final TaskTemplateRepository _repository = TaskTemplateRepository();

  // 状态
  bool _isLoading = false;
  String? _errorMessage;
  List<TaskTemplate> _templates = [];
  String _selectedCategory = 'all';

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TaskTemplate> get templates => _templates;
  String get selectedCategory => _selectedCategory;

  /// 获取过滤后的模板列表
  List<TaskTemplate> get filteredTemplates {
    if (_selectedCategory == 'all') {
      return _templates;
    }
    return _templates.where((t) => t.category == _selectedCategory).toList();
  }

  /// 加载所有模板
  Future<void> loadTemplates() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _templates = await _repository.getAllTemplates();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 按分类加载模板
  Future<void> loadTemplatesByCategory(String category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (category == 'all') {
        _templates = await _repository.getAllTemplates();
      } else {
        _templates = await _repository.getTemplatesByCategory(category);
      }
      _selectedCategory = category;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 设置选中的分类
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// 创建模板
  Future<int> createTemplate(TaskTemplate template) async {
    try {
      final id = await _repository.createTemplate(template);
      await loadTemplates();
      return id;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 更新模板
  Future<void> updateTemplate(TaskTemplate template) async {
    try {
      await _repository.updateTemplate(template);
      await loadTemplates();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 删除模板
  Future<void> deleteTemplate(int id) async {
    try {
      await _repository.deleteTemplate(id);
      await loadTemplates();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 搜索模板
  Future<List<TaskTemplate>> searchTemplates(String keyword) async {
    try {
      return await _repository.searchTemplates(keyword);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 获取模板统计
  Future<Map<String, int>> getTemplateCountByCategory() async {
    try {
      return await _repository.getTemplateCountByCategory();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 清除错误消息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
