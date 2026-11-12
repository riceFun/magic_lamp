package com.example.magic_lamp

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 应用更新支持：
 * - 读取当前 versionName
 * - 调用系统安装器安装已下载的 APK（FileProvider 授权）
 * - 跳转「安装未知应用」授权页 / 外部链接
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "magic_lamp/updater"
        const val APK_MIME = "application/vnd.android.package-archive"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getVersionName" -> result.success(versionName())

                    "canInstallPackages" -> result.success(canInstallPackages())

                    "openInstallSettings" -> {
                        try {
                            openInstallPermissionSettings()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SETTINGS_FAILED", e.message, null)
                        }
                    }

                    "installApk" -> {
                        val path = call.argument<String>("path")
                        val authority = call.argument<String>("authority")
                        if (path.isNullOrEmpty()) {
                            result.error("BAD_ARGS", "path 不能为空", null)
                        } else {
                            installApk(path, authority, result)
                        }
                    }

                    "openUrl" -> {
                        val url = call.argument<String>("url")
                        if (url.isNullOrEmpty()) {
                            result.error("BAD_ARGS", "url 不能为空", null)
                        } else {
                            try {
                                startActivity(
                                    Intent(Intent.ACTION_VIEW, Uri.parse(url))
                                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                )
                                result.success(null)
                            } catch (e: Exception) {
                                result.error("OPEN_FAILED", e.message, null)
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun versionName(): String {
        return try {
            val info = packageManager.getPackageInfo(packageName, 0)
            info.versionName ?: "0.0.0"
        } catch (e: Exception) {
            "0.0.0"
        }
    }

    private fun canInstallPackages(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    private fun openInstallPermissionSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startActivity(
                Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        }
    }

    /**
     * 拉起系统安装界面。
     * 返回 "started" 表示已拉起；"permission_needed" 表示缺少「安装未知应用」授权。
     */
    private fun installApk(path: String, authority: String?, result: MethodChannel.Result) {
        try {
            val file = File(path)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "安装包不存在：$path", null)
                return
            }

            if (!canInstallPackages()) {
                result.success("permission_needed")
                return
            }

            val providerAuthority = authority ?: "$packageName.fileprovider"
            val uri = FileProvider.getUriForFile(this, providerAuthority, file)

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, APK_MIME)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(intent)
            result.success("started")
        } catch (e: Exception) {
            result.error("INSTALL_FAILED", e.message, null)
        }
    }
}
