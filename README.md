# magic_lamp

神灯积分管理，基于 Flutter 的儿童积分管理与词汇学习 App。

## 开发环境

- Flutter 3.x
- Dart 3.x
- Android Studio 或 Xcode

## 本地运行

```bash
flutter pub get
flutter run
```

## 发布打包

发布前建议先确认版本号和构建号，然后执行清理与依赖安装：

```bash
flutter clean
flutter pub get
```

### Android

生成发布版 APK：

```bash
flutter build apk --release
```

如果需要按架构拆分 APK，减小安装包体积：

```bash
flutter build apk --release --split-per-abi
```

生成发布版 App Bundle，适合上架 Google Play：

```bash
flutter build appbundle --release
```

输出文件位置：

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- 拆分 APK: `build/app/outputs/flutter-apk/`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### iOS

生成 iOS 发布包：

```bash
flutter build ipa --release
```

如果首次打包或签名配置未完成，先打开 Xcode：

```bash
open ios/Runner.xcworkspace
```

在 Xcode 中确认：

- `Signing & Capabilities` 已选择正确的 `Team`
- `Bundle Identifier` 已配置
- 真机调试和发布证书可用

也可以先只构建 iOS 产物：

```bash
flutter build ios --release
```

然后再用 Xcode 归档并导出 IPA。

### 常用检查命令

```bash
flutter analyze
flutter test
```

## 资源文件

- `assets/story.json`
- `assets/products.json`
- `assets/tasks.json`
