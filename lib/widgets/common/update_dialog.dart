import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/update_service.dart';

/// 弹出「检查更新」对话框：检查 → 有新版本 → 下载 → 拉起系统安装器
Future<void> showUpdateDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const UpdateDialog(),
  );
}

enum _Step { checking, upToDate, available, downloading, downloaded, error }

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  _Step _step = _Step.checking;
  UpdateInfo? _info;
  String? _error;
  String? _apkPath;
  bool _needPermission = false;
  double? _progress;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() {
      _step = _Step.checking;
      _error = null;
      _needPermission = false;
      _apkPath = null;
      _progress = null;
    });

    try {
      final info = await UpdateService.checkForUpdate();
      if (!mounted) return;
      setState(() {
        _info = info;
        _step = (info == null || !info.hasUpdate)
            ? _Step.upToDate
            : _Step.available;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is UpdateException ? e.message : '$e';
        _step = _Step.error;
      });
    }
  }

  Future<void> _download() async {
    final info = _info;
    if (info == null) return;

    _cancelToken = CancelToken();
    setState(() {
      _step = _Step.downloading;
      _progress = 0;
      _error = null;
    });

    try {
      final path = await UpdateService.downloadApk(
        info,
        cancelToken: _cancelToken,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _progress = total > 0 ? received / total : null;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _apkPath = path;
        _step = _Step.downloaded;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is DioException && e.type == DioExceptionType.cancel) {
        setState(() => _step = _Step.available);
        return;
      }
      setState(() {
        _error = e is UpdateException ? e.message : '下载失败：$e';
        _step = _Step.error;
      });
    }
  }

  Future<void> _install() async {
    final path = _apkPath;
    if (path == null) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await UpdateService.installApk(path);
      if (!mounted) return;

      if (result == 'permission_needed') {
        setState(() => _needPermission = true);
        return;
      }
      if (result == 'started') {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('请在系统安装界面点击「安装」完成更新'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        return;
      }
      setState(() {
        _error = '无法拉起安装器（$result）';
        _step = _Step.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '拉起安装器失败：$e';
        _step = _Step.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.system_update, color: AppTheme.primaryColor),
          SizedBox(width: AppTheme.spacingSmall),
          Text('应用更新'),
        ],
      ),
      content: SingleChildScrollView(child: _buildContent()),
      actions: _buildActions(),
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case _Step.checking:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: AppTheme.spacingLarge),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: AppTheme.spacingMedium),
              Text(
                '正在检查更新…',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        );

      case _Step.upToDate:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.accentGreen),
                SizedBox(width: AppTheme.spacingSmall),
                Text(
                  '已是最新版本',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingSmall),
            Text(
              '当前版本 v${_info?.currentVersion ?? ''}',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        );

      case _Step.available:
        return _buildReleaseInfo();

      case _Step.downloading:
        final percent = _progress == null
            ? null
            : '${(_progress! * 100).toStringAsFixed(0)}%';
        return Padding(
          padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '正在下载安装包…',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: AppTheme.spacingMedium),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: AppTheme.dividerColor,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              SizedBox(height: AppTheme.spacingSmall),
              Text(
                percent ?? '正在连接…',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        );

      case _Step.downloaded:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download_done, color: AppTheme.accentGreen),
                SizedBox(width: AppTheme.spacingSmall),
                Text(
                  '安装包已下载',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingSmall),
            Text(
              'v${_info?.latestVersion ?? ''}，点击「安装」后系统会提示覆盖安装，原有数据不受影响。',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
            ),
            if (_needPermission) ...[
              SizedBox(height: AppTheme.spacingMedium),
              Container(
                padding: EdgeInsets.all(AppTheme.spacingSmall),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: AppTheme.accentOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '需要先允许「安装未知应用」：在系统设置中为 magic_lamp 打开该权限，然后返回点击「重新安装」。',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppTheme.textPrimaryColor,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        );

      case _Step.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: AppTheme.accentRed),
                SizedBox(width: AppTheme.spacingSmall),
                Text(
                  '检查/下载失败',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingSmall),
            Text(
              _error ?? '未知错误',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildReleaseInfo() {
    final info = _info;
    if (info == null) return const SizedBox.shrink();

    final notes = info.releaseNotes.isEmpty ? '（该版本未填写更新说明）' : info.releaseNotes;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSmall,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.accentRed,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                '新版本',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXSmall,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: Text(
                info.releaseName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
        Text(
          '当前版本 v${info.currentVersion}  →  最新版本 v${info.latestVersion}'
          '${info.apkSizeText.isEmpty ? '' : '（${info.apkSizeText}）'}',
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        SizedBox(height: AppTheme.spacingMedium),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 200),
          padding: EdgeInsets.all(AppTheme.spacingSmall),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Scrollbar(
            thumbVisibility: false,
            child: SingleChildScrollView(
              child: Text(
                notes,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: AppTheme.textPrimaryColor,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: AppTheme.spacingSmall),
        GestureDetector(
          onTap: () => UpdateService.openUrl(info.htmlUrl),
          child: Text(
            '在浏览器中查看此版本',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppTheme.primaryColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    switch (_step) {
      case _Step.checking:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('关闭'),
          ),
        ];

      case _Step.upToDate:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('关闭'),
          ),
        ];

      case _Step.available:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('稍后'),
          ),
          ElevatedButton(
            onPressed: _download,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text('立即更新'),
          ),
        ];

      case _Step.downloading:
        return [
          TextButton(
            onPressed: () => _cancelToken?.cancel(),
            child: Text('取消下载'),
          ),
        ];

      case _Step.downloaded:
        return [
          if (!_needPermission)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('稍后'),
            ),
          if (_needPermission)
            TextButton(
              onPressed: () async {
                await UpdateService.openInstallSettings();
                if (!mounted) return;
                setState(() => _needPermission = false);
              },
              child: Text('去授权'),
            ),
          ElevatedButton(
            onPressed: _install,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
            ),
            child: Text(_needPermission ? '重新安装' : '安装'),
          ),
        ];

      case _Step.error:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('关闭'),
          ),
          ElevatedButton(
            onPressed: _check,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text('重试'),
          ),
        ];
    }
  }
}
