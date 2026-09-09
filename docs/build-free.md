# 免费双平台构建指南

## 概述

使用 **方案 A（免费）**：GitHub Actions 同时构建 Android APK 和 iOS 模拟器产物，$0 成本。

**产物说明**：
- ✅ **Android APK**：可直接安装到任何 Android 设备（手机/平板）
- ⚠️ **iOS .app**：只能在 macOS 的模拟器中运行，**无法安装到真实 iPhone**

## 使用方法

### 1. 触发构建

1. 打开 GitHub 仓库 → **Actions** 标签页
2. 左侧选择 **"Build APK + iOS (Free)"**
3. 点击右上角 **"Run workflow"** 按钮
4. 填写参数：
   - **选择分支**：输入分支名（如 `main`、`develop`、`feature/xxx`）
   - **目标环境**：选择 `development` / `test` / `production`
5. 点击绿色的 **"Run workflow"** 确认

### 2. 等待构建完成

- Android 构建：约 10-15 分钟
- iOS 构建：约 15-20 分钟
- 两个 job 并行执行，总耗时取较慢的那个

GitHub Actions 免费额度：
- 公开仓库：**无限**
- 私有仓库：每月 2000 分钟（约可构建 60-80 次）

### 3. 下载产物

构建完成后：

1. 滚动到 workflow 运行记录底部
2. **Artifacts** 区域会显示两个文件：
   - `android-{environment}` → APK 文件
   - `ios-{environment}` → iOS 模拟器 .app 的 zip 包

3. 点击下载（需要登录 GitHub）

### 4. 安装使用

#### Android APK

**方法 1：直接安装**
```bash
# 手机开启"未知来源"权限后，直接点击 APK 安装
# 或通过 adb 安装
adb install story_android_test_*.apk
```

**方法 2：分享给测试用户**
- 把 APK 上传到云盘（Google Drive / Dropbox / 国内网盘）
- 发送链接给测试用户
- 用户下载后直接安装

#### iOS 模拟器 .app

**必须在 macOS 上操作**：

```bash
# 1. 解压下载的 zip
unzip story_ios_test_*_simulator.zip

# 2. 打开 Xcode 的模拟器
open -a Simulator

# 3. 拖动 Runner.app 到模拟器窗口
# 或使用命令行安装
xcrun simctl install booted Runner.app

# 4. 在模拟器的主屏幕点击应用图标启动
```

**查看可用模拟器**：
```bash
xcrun simctl list devices available
```

**在特定模拟器安装**：
```bash
# 替换 DEVICE_UUID 为上面命令输出的设备 ID
xcrun simctl install <DEVICE_UUID> Runner.app
```

## 环境变量说明

三个环境对应不同的后端配置（根据你的 `lib/main.dart`）：

- **development**：开发环境，通常指向开发服务器
- **test**：测试环境，用于 QA 测试
- **production**：生产环境，正式数据

构建时通过 `--dart-define=ENV={environment}` 注入，应用启动时读取。

## 限制说明

### Android

- ✅ 产出的是 **debug 签名** APK（免费方案不需要 release keystore）
- ✅ 可以安装到任何 Android 设备
- ⚠️ Google Play 不接受 debug APK，如需上架需要 release 签名（需要生成 keystore）

### iOS

- ❌ **无法安装到真实 iPhone/iPad**
- ✅ 可以在 macOS 模拟器运行（需要 macOS + Xcode）
- ❌ 无法通过 TestFlight 分发
- ❌ 无法上架 App Store

### 升级到真实 iOS 设备支持

需要：
1. 加入 Apple Developer Program（$99/年）
2. 生成分发证书和 Provisioning Profile
3. 配置 GitHub Secrets（7 个）
4. 使用 `build-story-ipa.yml` workflow

详见 `docs/cicd.md`。

## 已知问题与解决方案

### iOS 构建失败：`isUltraConstrained` 报错

**现象**：
```
Swift Compiler Error (Xcode): Value of type 'NWPath' has no member 'isUltraConstrained'
/Users/runner/.pub-cache/hosted/pub.dev/connectivity_plus-7.3.1/...
```

**原因**：`connectivity_plus` 插件的 `PathMonitorConnectivityProvider.swift` 引用了 `path.isUltraConstrained`（iOS 26 新增 API），但 GitHub Actions 的 macOS runner 上的 Xcode SDK 还没有这个成员，编译必定失败。插件还在代码里加了 `#available(iOS 26.0, *)` 检查，但因为成员不存在，availability 检查救不了。

**解决方案**（已在 workflow 中自动应用）：
- 在构建前用 `perl` 精确替换：把 `if #available(iOS 26.0, *), path.isUltraConstrained {` 整行替换为 `if false {`
- 保持 Swift 文件的括号结构完整（不能整行删除，会破坏花括号配对导致 `Extraneous '}' at top level` 错误）
- 该补丁同时覆盖 `connectivity_plus 7.2.x` 和 `7.3.x`，以及 iOS / macOS 两个平台的源文件

对业务的影响：`.satellite` 连接类型永远不会被上报（超低带宽卫星连接场景），对常规功能无影响。

如果 workflow 日志中 "Patch connectivity_plus isUltraConstrained" 步骤没有输出 `✓ Patched:`，说明版本路径变了，需调整匹配模式。

---

## 故障排查

### Android 构建失败

**Gradle 内存不足**：
```
FAILURE: Build failed with an exception.
* What went wrong: Java heap space
```

→ 已在 workflow 里配置 `-Xmx3G`，如仍失败需检查 `android/build.gradle` 的依赖项。

**依赖冲突**：
```
Execution failed for task ':app:checkDebugDuplicateClasses'
```

→ 运行 `flutter pub get` 后检查 `flutter doctor` 输出。

### iOS 构建失败

**Flutter 版本不兼容**：
```
Building for iOS Simulator, but the linked framework was built for iOS
```

→ 已指定 `--simulator`，如仍报错需检查 `ios/Podfile` 配置。

**CocoaPods 依赖错误**：
```
[!] CocoaPods could not find compatible versions for pod "xxx"
```

→ 删除 `ios/Podfile.lock`，重新提交代码触发构建。

### 模拟器安装失败

**错误信息**：
```
Unable to install "Runner"
Domain: IXUserPresentableErrorDomain
Code: 1
```

→ 确保模拟器的 iOS 版本 ≥ 项目的 `ios/Podfile` 指定的最低版本（通常是 iOS 12+）。

**权限问题**：
```
Could not copy the app to the device
```

→ 用 `sudo` 或确保 `~/Library/Developer/CoreSimulator/` 有写权限。

## 成本分析

| 项目 | 费用 |
|---|---|
| GitHub Actions（公开仓库） | $0（无限） |
| GitHub Actions（私有仓库） | $0（2000 分钟/月免费额度） |
| Android 构建 | $0 |
| iOS 模拟器构建 | $0 |
| **总计** | **$0** |

超出免费额度后：
- GitHub Actions：$0.008/分钟（macOS runner）
- 每次构建约 $0.20

## 下一步

### 如需 Android release 签名

生成 keystore：
```bash
keytool -genkey -v -keystore android/story-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias story
```

填入 GitHub Secrets：
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_PROPERTIES`

修改 workflow 的 `flutter build apk --debug` 为 `--release`。

### 如需真实 iPhone 支持

参考 `docs/cicd.md`，需要 Apple Developer Program（$99/年）。
