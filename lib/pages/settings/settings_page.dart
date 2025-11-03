import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// 设置页面 - 个人信息、系统设置
class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              size: 80,
              color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
            ),
            SizedBox(height: AppTheme.spacingLarge),
            Text(
              '设置',
              style: TextStyle(
                fontSize: AppTheme.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            Text(
              '个人信息、用户管理、系统设置、数据备份',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
