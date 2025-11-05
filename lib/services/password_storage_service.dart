import 'package:shared_preferences/shared_preferences.dart';

/// 密码本地存储服务
/// 管理全局操作密码，与用户无关
class PasswordStorageService {
  static const String _operationPasswordKey = 'operation_password';

  /// 获取操作密码
  static Future<String?> getOperationPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_operationPasswordKey);
  }

  /// 设置操作密码
  static Future<void> setOperationPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_operationPasswordKey, password);
  }

  /// 检查是否已设置操作密码
  static Future<bool> hasOperationPassword() async {
    final password = await getOperationPassword();
    return password != null && password.isNotEmpty;
  }

  /// 验证操作密码
  static Future<bool> verifyOperationPassword(String inputPassword) async {
    final savedPassword = await getOperationPassword();
    if (savedPassword == null || savedPassword.isEmpty) {
      return false; // 未设置密码
    }
    return inputPassword == savedPassword;
  }

  /// 清除操作密码（仅用于测试或重置）
  static Future<void> clearOperationPassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_operationPasswordKey);
  }
}
