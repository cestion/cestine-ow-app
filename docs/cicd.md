# 项目 CI/CD 说明

本项目使用 **GitHub Actions** 作为唯一 CI/CD 系统（无 GitLab CI / Codemagic / Fastlane）。

## Workflow 一览

| Workflow | 触发器 | 作用 |
|---|---|---|
| `flutter-ci.yml` | push main / PR → main | 代码生成校验 + 格式 + 静态分析 + 单测 + 覆盖率上传（守门，不构建） |
| `build-story-apk-ipa.yml` | push main / 手动 | 构建双平台（Android APK + iOS IPA/模拟器），production=签名+TestFlight，上传 GitHub Release + artifact + 飞书通知 |

## 构建参数

`dart-define` 注入（与 APK 流程一致）：

- `ENV` = `development` / `test` / `production`
- `DISTRIBUTION_CHANNEL` = `apk` / `ios`

`production` 环境 → release 签名构建；其余环境 → debug / 模拟器构建。

## 需要的 GitHub Secrets

### Android（`build-story-apk.yml` 生产构建必需）

| Secret | 说明 |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i android/story-release.jks \| tr -d '\n'` 的结果 |
| `ANDROID_KEY_PROPERTIES` | `key.properties` 内容（`storeFile=story-release.jks` 缺失会自动补） |

### iOS（`build-story-ipa.yml` 生产构建必需）

#### 签名材料

| Secret | 说明 |
|---|---|
| `IOS_CERTIFICATE_P12_BASE64` | 分发证书 `.p12` 的 base64（含公钥+私钥） |
| `IOS_CERTIFICATE_PASSWORD` | `.p12` 导出密码 |
| `IOS_KEYCHAIN_PASSWORD` | CI 临时 keychain 密码（任意随机串，如 `openssl rand -base64 32`） |
| `IOS_PROVISIONING_PROFILE_BASE64` | `.mobileprovision` 的 base64，导入到 `~/Library/MobileDevice/Provisioning Profiles/` |

#### TestFlight 自动上传（可选）

| Secret | 说明 |
|---|---|
| `IOS_APP_STORE_CONNECT_API_KEY_CONTENT` | App Store Connect API Key（`.p8` 文件内容，纯文本） |
| `IOS_APP_STORE_CONNECT_KEY_ID` | API Key ID（10 位字母数字，如 `AB12CD34EF`） |
| `IOS_APP_STORE_CONNECT_ISSUER_ID` | Issuer ID（UUID 格式，在 App Store Connect → Users and Access → Keys 页面） |

**获取步骤**：
1. App Store Connect → Users and Access → Keys → Generate API Key（权限选 `Developer` 或 `App Manager`）
2. 下载 `.p8` 文件（只能下载一次，保存好），记录 Key ID 和 Issuer ID
3. 把 `.p8` 文件的**完整内容**（包括 `-----BEGIN PRIVATE KEY-----` 和 `-----END PRIVATE KEY-----`）填入 `IOS_APP_STORE_CONNECT_API_KEY_CONTENT`

缺少这三个 secrets 时，workflow 会跳过 TestFlight 上传（warning），但 IPA 仍会上传到 GitHub Release。

iOS 项目已配置 `DEVELOPMENT_TEAM = 7T6LG3LXBN`、`CODE_SIGN_STYLE = Automatic`、Bundle ID `com.cestine.officeapp`（`ios/Runner.xcodeproj/project.pbxproj`）。

> IPA 构建和 TestFlight 都要求：**Apple Developer Program 会员（$99/年）**。
> 免费 Apple ID 无法在 CI 上产出可安装 IPA，也无法使用 TestFlight。

## 付费方案准备清单（从零开始）

从没有 Apple Developer 账号到 CI 出真 IPA，共 7 样东西：

### ① 加入 Apple Developer Program（$99/年，唯一花钱项）

- 网址：<https://developer.apple.com/programs/enroll/>
- 需要：有效 Apple ID + 身份验证
- 个人账号（Individual）即可，无需公司资质
- 审批通常几分钟到几小时（首次可能需人工审核）

### ② 生成 Distribution 证书（.p12）

在本机（已装 Xcode 26.6）：

1. Xcode → Settings → Accounts → ➕ → 登录刚加入开发者计划的 Apple ID
2. 左侧选中该账号 → **Manage Certificates** → ➕ → **Apple Distribution**
3. 打开「钥匙串访问」→ 我的证书 → 找到 `Apple Distribution: ...` → 右键导出
4. 保存为 `story-release.p12`，**设置导出密码**（之后填 secret 用）

```bash
# 导出密码 → IOS_CERTIFICATE_PASSWORD
# 转 base64 → IOS_CERTIFICATE_P12_BASE64
base64 -i story-release.p12 | tr -d '\n'
```

### ③ 创建 Provisioning Profile（.mobileprovision）

网页操作（任何电脑浏览器，无需 Xcode）：

1. <https://developer.apple.com/account> → **Certificates, Identifiers & Profiles**
2. 先确认 **Identifiers** 里有 App ID `com.cestine.officeapp`（没有就 ➕ 创建，Bundle ID 填 `com.cestine.officeapp`）
3. **Profiles** → ➕ → 选 **App Store Connect**（不要选 Ad Hoc / Development）
4. 选 App ID → 选刚生成的 Distribution 证书 → 命名生成
5. 下载 `story.mobileprovision`

```bash
# 转 base64 → IOS_PROVISIONING_PROFILE_BASE64
base64 -i story.mobileprovision | tr -d '\n'
```

### ④ 创建 App Store Connect 的 App 记录

1. <https://appstoreconnect.apple.com> → My Apps → ➕ → **New App**
2. 平台 iOS，Bundle ID 选 `com.cestine.officeapp`（关键，必须和项目一致）
3. 填名称 / 主要语言 / SKU（随意）→ 创建

> 不建这条记录，altool 上传会报 "no App found for bundle ID"。

### ⑤ 生成 App Store Connect API Key（.p8）

1. App Store Connect → Users and Access → **Keys**（页面顶部）→ ➕
2. 名称随意，权限选 **App Manager**（或 Developer）
3. 下载 `.p8`（**只显示一次**，下载后文件名如 `AuthKey_AB12CD34EF.p8`），记录 **Key ID** 和 **Issuer ID**

```bash
# 文件完整内容（含 BEGIN/END PRIVATE KEY）→ IOS_APP_STORE_CONNECT_API_KEY_CONTENT
cat AuthKey_AB12CD34EF.p8
# Key ID（10 位）→ IOS_APP_STORE_CONNECT_KEY_ID
# Issuer ID（UUID）→ IOS_APP_STORE_CONNECT_ISSUER_ID
```

### ⑥ 生成随机 Keychain 密码

```bash
openssl rand -base64 32
# → IOS_KEYCHAIN_PASSWORD（CI 临时 keychain 用，任意随机串即可）
```

### ⑦ 填入 GitHub Secrets

GitHub 仓库 → Settings → Secrets and variables → Actions，共 7 个：

| Secret | 来源 |
|---|---|
| `IOS_CERTIFICATE_P12_BASE64` | ② base64 |
| `IOS_CERTIFICATE_PASSWORD` | ② 导出密码 |
| `IOS_KEYCHAIN_PASSWORD` | ⑥ 随机串 |
| `IOS_PROVISIONING_PROFILE_BASE64` | ③ base64 |
| `IOS_APP_STORE_CONNECT_API_KEY_CONTENT` | ⑤ .p8 全文 |
| `IOS_APP_STORE_CONNECT_KEY_ID` | ⑤ Key ID |
| `IOS_APP_STORE_CONNECT_ISSUER_ID` | ⑤ Issuer ID |

填完即可触发 `build-story-ipa.yml`（production 环境），成功后 IPA 会出现在 TestFlight。

### 其他注意点

- **构建号要递增**：每次上传的 `CFBundleVersion` 不能与 TestFlight 中已有的重复。版本号在 `pubspec.yaml`（如 `1.3.1+111`，`+111` 即构建号），改 Dart 代码时记得顺手 +1
- **加密合规**：`ios/Runner/Info.plist` 建议加 `ITSAppUsesNonExemptEncryption = NO`（仅用 HTTPS/系统加密时），否则上传后可能停在出口合规询问
- **签名冲突排查**：如果 export 报 `no provisioning profile found`，把 `story.mobileprovision` 的 UUID（用 `grep -a UUID -m1 story.mobileprovision` 查看）在 ExportOptions.plist 的 `provisioningProfiles` 里显式映射

## 免费开发者账号的本地测试路径

免费账号（个人 Apple ID）的限制：

- 仅能开发签名（Development），不能 App Store / Ad Hoc / Enterprise
- 只能在**本机 Xcode + 物理 iPhone 连线**的情况下构建和安装（CI runner 上没有你的账号，无法登录）
- 注册的设备最多 3 台，签名 7 天过期（重新配置后可续期）
- 无法产出可分发 IPA

### 步骤

1. 本机安装 Flutter SDK，`flutter doctor` 确认 Xcode 就绪
2. Xcode → Settings → Accounts → 登录个人 Apple ID（免费即可）
3. Xcode 打开 `ios/Runner.xcworkspace`，Runner target → Signing & Capabilities → 勾选 Automatically manage signing，Team 选个人账号（Bundle ID 改成一个新 id，如 `com.cestine.officeapp-dev`，免费账号不允许占用他人命名空间）
4. iPhone 连线并信任，Xcode 里选择该设备
5. 构建：

```bash
# 模拟器（最快验证）
flutter build ios --simulator --dart-define=ENV=test

# 真机（USB 连接，Xcode 自动生成开发签名）
flutter build ios --dart-define=ENV=test
```

真机安装：`flutter build ios` 产物在 `build/ios/iphoneos/Runner.app`，用
`xcrun simctl`（模拟器）或 Xcode Devices 面板（真机）安装。

## TestFlight 发布流程

### 前置条件

- Apple Developer Program 账号（$99/年）
- App Store Connect 上已创建对应 Bundle ID 的 App（`com.cestine.officeapp`）
- 已配置好签名 secrets（4 个签名 + 3 个 API Key）

### 自动化流程

1. Push 到 `main` 或手动触发 `build-story-ipa.yml`，选择 `production` 环境
2. CI 构建签名 IPA → `xcrun altool --upload-app`（API Key 认证）上传到 App Store Connect
3. 苹果服务器处理（通常 5-15 分钟）：自动化审查 → 生成 TestFlight 构建
4. App Store Connect → TestFlight → 该版本状态变为"可测试"
5. 邀请测试用户（内部测试最多 100 人，外部测试需要 Beta 审核但无需完整审核）

### TestFlight 测试用户邀请

**内部测试**（团队成员，立即可用）：
- App Store Connect → TestFlight → Internal Testing → 添加测试人员（需要是 App Store Connect 账号的成员）
- 测试人员在 iPhone 上安装 TestFlight app → 接受邀请 → 安装

**外部测试**（真实用户，需要简短 Beta 审核）：
- App Store Connect → TestFlight → External Testing → 创建测试组 → 添加邮箱或公开链接
- 首次提交需要填写测试信息（"What to Test"），苹果审核通过后（通常 24-48 小时）测试用户可下载

### 故障排查

**上传失败**：
- 检查 `IOS_APP_STORE_CONNECT_API_KEY_CONTENT` 是否完整（包含 `-----BEGIN PRIVATE KEY-----`）
- Key ID / Issuer ID 是否匹配
- API Key 权限至少为 `Developer` 或 `App Manager`

**TestFlight 不显示**：
- App Store Connect → Activities 查看处理状态
- 检查 Bundle ID / Version / Build Number 是否与之前版本冲突（`ios/Runner/Info.plist` 的 `CFBundleShortVersionString` 和 `CFBundleVersion`）
- 确保 `Info.plist` 里有 `ITSAppUsesNonExemptEncryption = NO`（或提交合规信息）

**构建卡在"Processing"**：
- 等待苹果服务器处理（最多 1 小时）
- 超过 1 小时联系 Apple 支持
