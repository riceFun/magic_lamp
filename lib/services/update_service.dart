import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 应用内更新
///
/// 数据来源：GitHub Releases（`releases/latest`，自动排除 draft 与 prerelease）
/// 安装方式：下载 APK 到应用私有目录，再通过 FileProvider 拉起系统安装器覆盖安装
class UpdateService {
  UpdateService._();

  /// GitHub 仓库
  static const String owner = 'riceFun';
  static const String repo = 'magic_lamp';

  static const String _apiLatest =
      'https://api.github.com/repos/$owner/$repo/releases/latest';
  static const String _releasesPage =
      'https://github.com/$owner/$repo/releases';

  static const MethodChannel _channel = MethodChannel('magic_lamp/updater');

  static String? _cachedVersion;

  /// 当前安装包版本号（取自原生 versionName，与 pubspec 保持一致）
  static Future<String> currentVersion() async {
    if (_cachedVersion != null) return _cachedVersion!;
    try {
      final version =
          await _channel.invokeMethod<String>('getVersionName') ?? '0.0.0';
      _cachedVersion = version;
      return version;
    } on PlatformException {
      return '0.0.0';
    } on MissingPluginException {
      return '0.0.0';
    }
  }

  /// 检查是否有新版本。无 Release 时返回 null；网络异常抛 [UpdateException]。
  static Future<UpdateInfo?> checkForUpdate() async {
    final current = await currentVersion();

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'magic_lamp-updater',
        },
      ),
    );

    Response<dynamic> response;
    try {
      response = await dio.get<dynamic>(_apiLatest);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // 仓库还没有任何正式 Release
        return null;
      }
      throw UpdateException(_describeDioError(e));
    }

    final data = response.data;
    if (data is! Map) {
      throw UpdateException('Release 数据格式异常');
    }

    final tag = (data['tag_name'] as String?)?.trim();
    if (tag == null || tag.isEmpty) {
      throw UpdateException('未获取到版本号');
    }

    final assets = (data['assets'] as List?) ?? const [];
    final apkAsset = assets.cast<Map>().firstWhere(
          (a) => ((a['name'] as String?) ?? '').toLowerCase().endsWith('.apk'),
          orElse: () => const {},
        );
    final apkUrl = apkAsset['browser_download_url'] as String?;

    return UpdateInfo(
      currentVersion: current,
      latestVersion: _normalize(tag),
      tagName: tag,
      releaseName: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : tag,
      releaseNotes: (data['body'] as String?)?.trim() ?? '',
      apkUrl: apkUrl,
      apkSize: (apkAsset['size'] as num?)?.toInt() ?? 0,
      htmlUrl: (data['html_url'] as String?) ?? _releasesPage,
      publishedAt: data['published_at'] as String?,
    );
  }

  /// 下载 APK，返回本地文件路径
  static Future<String> downloadApk(
    UpdateInfo info, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final url = info.apkUrl;
    if (url == null || url.isEmpty) {
      throw UpdateException('该版本未提供 APK 安装包');
    }

    final dir = await _downloadDir();
    final fileName = 'magic_lamp-${info.latestVersion}.apk';
    final target = File(p.join(dir.path, fileName));

    // 已下载完整则直接复用
    if (await target.exists() &&
        info.apkSize > 0 &&
        await target.length() == info.apkSize) {
      return target.path;
    }

    // 清理旧版本残留
    try {
      await for (final entity in dir.list()) {
        if (entity is File &&
            entity.path.endsWith('.apk') &&
            entity.path != target.path) {
          await entity.delete();
        }
      }
    } catch (_) {
      // 清理失败不影响下载
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(minutes: 5),
        headers: const {'User-Agent': 'magic_lamp-updater'},
      ),
    );

    try {
      await dio.download(
        url,
        target.path,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      throw UpdateException(_describeDioError(e));
    }

    if (!await target.exists() || await target.length() < 1024) {
      throw UpdateException('安装包下载不完整，请重试');
    }
    return target.path;
  }

  /// 拉起系统安装器。返回 "started" 或 "permission_needed"
  static Future<String> installApk(String path) async {
    // authority 由原生侧按 ${packageName}.fileprovider 生成，避免 Dart 侧写死包名
    final result = await _channel.invokeMethod<String>('installApk', {
      'path': path,
    });
    return result ?? 'unknown';
  }

  /// 是否已允许「安装未知应用」
  static Future<bool> canInstallPackages() async {
    try {
      return await _channel.invokeMethod<bool>('canInstallPackages') ?? true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true;
    }
  }

  /// 跳转「安装未知应用」授权页
  static Future<void> openInstallSettings() async {
    await _channel.invokeMethod<void>('openInstallSettings');
  }

  /// 用系统浏览器/应用打开链接
  static Future<void> openUrl(String url) async {
    await _channel.invokeMethod<void>('openUrl', {'url': url});
  }

  static String get releasesPageUrl => _releasesPage;

  static Future<Directory> _downloadDir() async {
    Directory? base;
    if (Platform.isAndroid) {
      base = await getExternalStorageDirectory();
    }
    base ??= await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'updates'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _describeDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '网络超时，请检查网络后重试';
      case DioExceptionType.connectionError:
        return '无法连接 GitHub，请检查网络或稍后重试';
      default:
        final code = e.response?.statusCode;
        if (code != null) return '请求失败（HTTP $code）';
        return e.message ?? '网络请求失败';
    }
  }

  /// 去掉前缀 v，只保留数字部分
  static String _normalize(String tag) {
    var v = tag.trim();
    if (v.toLowerCase().startsWith('v')) v = v.substring(1);
    return v;
  }

  /// a > b 返回正数，相等 0，a < b 负数
  static int compareVersion(String a, String b) {
    List<int> parse(String v) {
      final core = _normalize(v).split('+').first;
      return core
          .split('.')
          .map((s) => int.tryParse(RegExp(r'^\d+').stringMatch(s) ?? '') ?? 0)
          .toList();
    }

    final va = parse(a);
    final vb = parse(b);
    final len = va.length > vb.length ? va.length : vb.length;
    for (var i = 0; i < len; i++) {
      final x = i < va.length ? va[i] : 0;
      final y = i < vb.length ? vb[i] : 0;
      if (x != y) return x - y;
    }
    return 0;
  }
}

/// 更新信息
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String tagName;
  final String releaseName;
  final String releaseNotes;
  final String? apkUrl;
  final int apkSize;
  final String htmlUrl;
  final String? publishedAt;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.tagName,
    required this.releaseName,
    required this.releaseNotes,
    required this.apkUrl,
    required this.apkSize,
    required this.htmlUrl,
    this.publishedAt,
  });

  bool get hasUpdate =>
      UpdateService.compareVersion(latestVersion, currentVersion) > 0;

  String get apkSizeText {
    if (apkSize <= 0) return '';
    final mb = apkSize / 1024 / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// 更新流程异常
class UpdateException implements Exception {
  final String message;
  UpdateException(this.message);

  @override
  String toString() => message;
}
