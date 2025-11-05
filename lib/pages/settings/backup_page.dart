import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/backup_service.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';

/// 数据备份页面
class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _isLoading = true;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _backups = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  /// 加载备份列表
  Future<void> _loadBackups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final backups = await BackupService.listBackups();
      if (mounted) {
        setState(() {
          _backups = backups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 创建新备份
  Future<void> _createBackup() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await BackupService.createBackup();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('备份创建成功'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        _loadBackups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// 导入备份
  Future<void> _importBackup() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final importedPath = await BackupService.importBackup();

      if (importedPath == null) {
        // 用户取消选择
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('备份导入成功'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        _loadBackups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// 恢复备份
  Future<void> _restoreBackup(String backupPath, String backupName) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: AppTheme.accentOrange,
            ),
            SizedBox(width: AppTheme.spacingSmall),
            Text('确认恢复'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '确定要从以下备份恢复数据吗？',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingMedium),
            Container(
              padding: EdgeInsets.all(AppTheme.spacingSmall),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                BackupService.formatBackupName(backupName),
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: AppTheme.textSecondaryColor,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingMedium),
            Text(
              '⚠️ 此操作将覆盖当前所有数据，且无法撤销！请确保已创建当前数据的备份。',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.accentRed,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
            ),
            child: Text('确认恢复'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await BackupService.restoreFromBackup(backupPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('数据恢复成功，请重启应用以生效'),
            backgroundColor: AppTheme.accentGreen,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// 分享备份
  Future<void> _shareBackup(String backupPath) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await BackupService.shareBackup(backupPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// 删除备份
  Future<void> _deleteBackup(String backupPath, String backupName) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除备份"${BackupService.formatBackupName(backupName)}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await BackupService.deleteBackup(backupPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('备份已删除'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        _loadBackups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// 清理旧备份
  Future<void> _cleanOldBackups() async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('清理旧备份'),
        content: Text('将只保留最近的10个备份，删除更早的备份。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final deletedCount = await BackupService.cleanOldBackups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已清理 $deletedCount 个旧备份'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        _loadBackups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.backup, size: 24),
            SizedBox(width: AppTheme.spacingSmall),
            Text('数据备份'),
          ],
        ),
        actions: [
          if (_backups.length > 10)
            IconButton(
              icon: Icon(Icons.cleaning_services),
              onPressed: _isProcessing ? null : _cleanOldBackups,
              tooltip: '清理旧备份',
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isProcessing ? null : _loadBackups,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? LoadingWidget(message: '加载备份列表...')
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: AppTheme.accentRed,
                      ),
                      SizedBox(height: AppTheme.spacingMedium),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: AppTheme.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppTheme.spacingLarge),
                      CustomButton.primary(
                        text: '重试',
                        onPressed: _loadBackups,
                        icon: Icons.refresh,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // 操作按钮区域
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacingLarge),
                      child: Column(
                        children: [
                          // 说明文本
                          Container(
                            padding: EdgeInsets.all(AppTheme.spacingMedium),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(
                                color:
                                    AppTheme.primaryColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                SizedBox(width: AppTheme.spacingSmall),
                                Expanded(
                                  child: Text(
                                    '定期备份数据可以防止数据丢失。您可以将备份分享到微信、QQ等应用保存，或从文件中导入备份。',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeSmall,
                                      color: AppTheme.textPrimaryColor,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingMedium),

                          // 操作按钮
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton.primary(
                                  text: '创建备份',
                                  onPressed:
                                      _isProcessing ? null : _createBackup,
                                  icon: Icons.add_circle_outline,
                                  isLoading: _isProcessing,
                                ),
                              ),
                              SizedBox(width: AppTheme.spacingMedium),
                              Expanded(
                                child: CustomButton.secondary(
                                  text: '导入备份',
                                  onPressed:
                                      _isProcessing ? null : _importBackup,
                                  icon: Icons.file_upload,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 备份列表
                    Expanded(
                      child: _backups.isEmpty
                          ? EmptyWidget(
                              icon: Icons.backup,
                              message: '暂无备份',
                              subtitle: '点击上方按钮创建或导入备份',
                            )
                          : RefreshIndicator(
                              onRefresh: _loadBackups,
                              child: ListView.builder(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingLarge,
                                ),
                                itemCount: _backups.length,
                                itemBuilder: (context, index) {
                                  final backup = _backups[index];
                                  return _BackupItem(
                                    backup: backup,
                                    isProcessing: _isProcessing,
                                    onRestore: () => _restoreBackup(
                                      backup['path'],
                                      backup['name'],
                                    ),
                                    onShare: () =>
                                        _shareBackup(backup['path']),
                                    onDelete: () => _deleteBackup(
                                      backup['path'],
                                      backup['name'],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

/// 备份项组件
class _BackupItem extends StatelessWidget {
  final Map<String, dynamic> backup;
  final bool isProcessing;
  final VoidCallback onRestore;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _BackupItem({
    required this.backup,
    required this.isProcessing,
    required this.onRestore,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = backup['name'] as String;
    final fileSize = backup['size'] as int;
    final createdAt = backup['createdAt'] as DateTime;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 备份信息
            Padding(
              padding: EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文件名（格式化后的时间）
                  Row(
                    children: [
                      Icon(
                        Icons.folder_zip,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      SizedBox(width: AppTheme.spacingSmall),
                      Expanded(
                        child: Text(
                          BackupService.formatBackupName(fileName),
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeMedium,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingSmall),

                  // 文件大小和创建时间
                  Row(
                    children: [
                      Icon(
                        Icons.storage,
                        size: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        BackupService.formatFileSize(fileSize),
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      SizedBox(width: AppTheme.spacingMedium),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm').format(createdAt),
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(height: 1),

            // 操作按钮
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSmall,
                vertical: AppTheme.spacingSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 恢复按钮
                  Expanded(
                    child: TextButton.icon(
                      onPressed: isProcessing ? null : onRestore,
                      icon: Icon(Icons.restore, size: 18),
                      label: Text('恢复'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.accentOrange,
                      ),
                    ),
                  ),

                  // 分享按钮
                  Expanded(
                    child: TextButton.icon(
                      onPressed: isProcessing ? null : onShare,
                      icon: Icon(Icons.share, size: 18),
                      label: Text('分享'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.accentGreen,
                      ),
                    ),
                  ),

                  // 删除按钮
                  Expanded(
                    child: TextButton.icon(
                      onPressed: isProcessing ? null : onDelete,
                      icon: Icon(Icons.delete, size: 18),
                      label: Text('删除'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.accentRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
