import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../config/constants.dart';

/// 数据备份服务
/// 提供数据库的备份、恢复、分享功能
class BackupService {
  /// 获取备份目录路径
  static Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(appDir.path, 'backups'));

    // 如果备份目录不存在，创建它
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }

  /// 获取数据库文件路径
  static Future<String> _getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return path.join(databasesPath, AppConstants.databaseName);
  }

  /// 创建备份
  /// 返回备份文件路径
  static Future<String> createBackup() async {
    try {
      // 获取数据库文件路径
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('数据库文件不存在');
      }

      // 生成备份文件名（带时间戳）
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = 'magic_lamp_backup_$timestamp.db';

      // 获取备份目录
      final backupDir = await _getBackupDirectory();
      final backupPath = path.join(backupDir.path, backupFileName);

      // 复制数据库文件到备份目录
      await dbFile.copy(backupPath);

      return backupPath;
    } catch (e) {
      throw Exception('创建备份失败：$e');
    }
  }

  /// 获取所有备份文件列表
  /// 返回备份文件信息列表（文件名、路径、大小、创建时间）
  static Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      final List<FileSystemEntity> files = backupDir.listSync();

      final backups = <Map<String, dynamic>>[];

      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.db')) {
          final stat = await entity.stat();
          final fileName = path.basename(entity.path);

          backups.add({
            'name': fileName,
            'path': entity.path,
            'size': stat.size,
            'createdAt': stat.modified,
          });
        }
      }

      // 按创建时间倒序排序（最新的在前面）
      backups.sort((a, b) {
        final DateTime aTime = a['createdAt'];
        final DateTime bTime = b['createdAt'];
        return bTime.compareTo(aTime);
      });

      return backups;
    } catch (e) {
      throw Exception('获取备份列表失败：$e');
    }
  }

  /// 从备份恢复数据库
  /// backupPath: 备份文件路径
  static Future<void> restoreFromBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);

      if (!await backupFile.exists()) {
        throw Exception('备份文件不存在');
      }

      // 获取数据库文件路径
      final dbPath = await _getDatabasePath();

      // 复制备份文件到数据库路径（覆盖当前数据库）
      await backupFile.copy(dbPath);
    } catch (e) {
      throw Exception('恢复备份失败：$e');
    }
  }

  /// 分享备份文件
  /// backupPath: 备份文件路径
  static Future<void> shareBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);

      if (!await backupFile.exists()) {
        throw Exception('备份文件不存在');
      }

      // 使用系统分享对话框分享文件
      await Share.shareXFiles(
        [XFile(backupPath)],
        subject: '神灯积分管理 - 数据备份',
        text: '分享神灯积分管理的数据备份文件',
      );
    } catch (e) {
      throw Exception('分享备份失败：$e');
    }
  }

  /// 从文件选择器导入备份
  /// 返回导入的文件路径，如果用户取消选择则返回null
  static Future<String?> importBackup() async {
    try {
      // 打开文件选择器，允许选择所有文件类型（因为.db文件可能不被Android识别为标准类型）
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null; // 用户取消选择
      }

      final pickedFile = result.files.first;

      if (pickedFile.path == null) {
        throw Exception('无法获取文件路径');
      }

      // 将选中的文件复制到备份目录
      final sourceFile = File(pickedFile.path!);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = 'magic_lamp_imported_$timestamp.db';

      final backupDir = await _getBackupDirectory();
      final targetPath = path.join(backupDir.path, backupFileName);

      await sourceFile.copy(targetPath);

      return targetPath;
    } catch (e) {
      throw Exception('导入备份失败：$e');
    }
  }

  /// 删除备份文件
  /// backupPath: 备份文件路径
  static Future<void> deleteBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);

      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    } catch (e) {
      throw Exception('删除备份失败：$e');
    }
  }

  /// 清理旧备份（只保留最近的 maxCount 个备份）
  /// maxCount: 保留的最大备份数量，默认10个
  static Future<int> cleanOldBackups({int maxCount = 10}) async {
    try {
      final backups = await listBackups();

      if (backups.length <= maxCount) {
        return 0; // 不需要清理
      }

      // 删除超出数量的旧备份
      int deletedCount = 0;
      for (int i = maxCount; i < backups.length; i++) {
        final backupPath = backups[i]['path'] as String;
        await deleteBackup(backupPath);
        deletedCount++;
      }

      return deletedCount;
    } catch (e) {
      throw Exception('清理旧备份失败：$e');
    }
  }

  /// 格式化文件大小（字节转为可读格式）
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// 格式化备份文件名（提取时间信息）
  static String formatBackupName(String fileName) {
    // 尝试从文件名中提取时间戳
    // 例如：magic_lamp_backup_20250105_143022.db
    final regex = RegExp(r'(\d{8})_(\d{6})');
    final match = regex.firstMatch(fileName);

    if (match != null) {
      final dateStr = match.group(1)!;
      final timeStr = match.group(2)!;

      final year = dateStr.substring(0, 4);
      final month = dateStr.substring(4, 6);
      final day = dateStr.substring(6, 8);

      final hour = timeStr.substring(0, 2);
      final minute = timeStr.substring(2, 4);
      final second = timeStr.substring(4, 6);

      return '$year-$month-$day $hour:$minute:$second';
    }

    return fileName;
  }
}
