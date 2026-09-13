# 项目 CI/CD 说明

本项目使用 **GitHub Actions** 作为唯一 CI/CD 系统（无 GitLab CI / Codemagic / Fastlane）。

## Workflow 一览

| Workflow | 触发器 | 作用 |
|---|---|---|
| `ci.yml` | push 全部分支 / PR / 手动 | 静态检查门禁 + 飞书通知 + 影响范围·影响点·回归范围分析 + 代码评审 + 错误/体积 diff（见下） |
| `build-story-apk-ipa.yml` | **仅手动** | 构建双平台（Android APK + iOS IPA/模拟器），`test`（默认）与 `production` 都是 iOS 签名构建 + TestFlight，上传 GitHub Release + artifact + 飞书通知 |

## ci.yml 的 Job 一览

| Job | 事件 | 门禁? | 说明 |
|---|---|---|---|
| `ci-checks` | push + PR | ✅ | 代码生成校验 + `dart format` + `flutter analyze` + `flutter test --coverage` + codecov（唯一会 fail 的 job） |
| `feishu-push-notify` | push | — | 提交卡片 |
| `push-ai-review` | push + **手动** | — | 两次 LLM 调用（影响范围/影响点/回归范围 + 代码级评审）→ job summary + **一张**飞书卡片 |
| `pr-notify-lark` | PR | — | PR 打开/更新通知 |
| `pr-impact` | PR | — | `tool/pr_impact_analysis.dart` → sticky PR 评论 |
| `pr-impact-ai` | PR | — | 影响报告 + diff → AI 影响范围/影响点/回归范围 → PR 评论 |
| `pr-sonar` | PR | — | SonarQube（默认关闭） |
| `pr-agent` | PR | — | 第三方 PR-Agent（默认关闭） |
| `apk-size-diff` | push + PR | — | arm64 release APK 体积 base/head 对比（默认关闭） |
| `analyzer-diff` | push + PR | — | `flutter analyze` base/head 新增/修复问题数 |

### 开关（Settings → Variables）

按需在仓库 Variables 里设置，未设置时走默认值。约定：`ENABLE_*` 用 `!= 'false'` 判断的，默认**开启**；用 `== 'true'` 判断的，默认**关闭**。

| Variable | 默认 | 作用 |
|---|---|---|
| `ENABLE_BRANCH_AI` | 开启 | `push-ai-review` 的影响/回归分析段 |
| `ENABLE_PUSH_CODE_REVIEW` | 开启 | `push-ai-review` 的代码评审段 |
| `ENABLE_IMPACT` | 开启 | PR 静态影响分析 |
| `ENABLE_IMPACT_AI` | 开启 | PR AI 风险评估 |
| `ENABLE_ANALYZER_DIFF` | 开启 | analyzer 错误 diff |
| `ENABLE_BUNDLE_DIFF` | **关闭** | APK 体积 diff（要跑两次 release 构建，约 20+ 分钟） |
| `ENABLE_SONAR` | **关闭** | SonarQube 扫描 |
| `ENABLE_PR_AGENT` | **关闭** | 第三方 PR-Agent |
| `MINIMAX_MODEL` | `MiniMax-M3` | AI 分析使用的模型 |
| `MINIMAX_BASE_URL` | `https://api.minimaxi.com/anthropic` | MiniMax API 基址 |
| `PUSH_REVIEW_MODEL` | 同 `MINIMAX_MODEL` | 代码级评审模型 |
| `PR_AGENT_MODEL` | `minimax/MiniMax-M3` | PR-Agent 模型 |

### AI 评审用的 Secrets

所有 AI 分析都走 MiniMax，唯一入口是 `MINIMAX_KEY_BLOB`。

| Secret | 说明 |
|---|---|
| `MINIMAX_KEY_BLOB` | **AI 分析唯一入口**。用 `.github/scripts/keyring.sh encode <key>` 生成 blob（不是明文） |
| `FEISHU_APP_WEBHOOK_URL` | 飞书群机器人 webhook（与构建通知复用同一个 Secret 名） |
| `LARK_WEBHOOK` | 可选，PR 文字通知；未设置时回退到 `FEISHU_APP_WEBHOOK_URL` |
| `OPENAI_KEY` | 已不使用（pr-agent 改为从 `MINIMAX_KEY_BLOB` 解码） |
| `LITELLM_BASE_URL` | 已不使用（pr-agent 直接指向 `MINIMAX_BASE_URL`） |
| `SONAR_TOKEN` / `SONAR_HOST_URL` | 仅 `ENABLE_SONAR=true` 时需要 |

未设置 `MINIMAX_KEY_BLOB` 时，AI job 会打印提示并优雅跳过（不会失败）；`pr-agent` 例外——它是显式开启的，缺 key 会直接报错。

> 之前版本支持 `ANTHROPIC_API_KEY` 优先、MiniMax 兜底。现已按要求移除 Anthropic：三条 AI 链路（分支风险评估、代码级评审、PR 风险评估）和 `pr-agent` 全部走 MiniMax。

#### 生成 `MINIMAX_KEY_BLOB` 并写入 Secret

```bash
# 1. 生成 blob（注意别把明文 key 留在 shell 历史里）
read -rs KEY && .github/scripts/keyring.sh encode "$KEY"
# → 复制输出的整串

# 2. 写进 Secret（避免明文进历史）
read -rs BLOB && printf '%s' "$BLOB" | gh secret set MINIMAX_KEY_BLOB -R cestinevv/cestine-ow-app
```

#### AI job 失败时怎么看

三条 AI 链路都不会让构建变红（`pr-agent` 除外），失败信息落在**飞书卡片 / PR 评论 / job summary** 里，完整原因在对应步骤的日志中。常见几种：

| 现象 | 含义 | 处理 |
|---|---|---|
| `MINIMAX_KEY_BLOB 解码失败` + 日志里 `blob 含 base64 以外的字符` | Secret 里存的是**明文 key**，不是 blob | 用下面的命令重新 encode 再写入 Secret |
| 日志里 `blob 长度 N 不是 4 的倍数` | 复制 blob 时被截断 | 重新完整复制一遍 |
| `AI 调用失败` + `HTTP/2 401` | blob 正确但 key 本身无效/过期 | 去 MiniMax 控制台换 key，重新 encode |
| `AI 调用失败` + `HTTP/2 404` | `MINIMAX_BASE_URL` 或模型名不对 | 检查 Variables |
| `AI 调用失败` + `curl: (6) Could not resolve host` | 网络/DNS，通常是临时故障 | 重跑 |

> 曾经这些都表现为一个**没有任何输出的红叉**：`keyring.sh` 解码失败时 stderr 被 `2>/dev/null` 吞掉，而 `API_KEY=$(...)` 没有兜底，在 `bash -e` 下直接把整步打成 `exit 1`。现在解码失败会打印具体原因并优雅跳过，curl 失败会把**状态行 + 响应体 + stderr** 一起写进卡片（密钥已脱敏）。

混淆用的是「固定盐异或 + base64」，盐明文写在 `keyring.sh` 里。它防的是**顺手看到**（翻 Secrets 列表、日志误打印），防不住有意图的人——拿到仓库代码即可还原。真正的边界是仓库和 Secret 的访问权限。**如果 key 曾经以明文出现在聊天、日志或提交里，请先轮换再混淆。**

### 影响范围 / 影响点 / 回归范围

`push-ai-review`（push）和 `pr-impact-ai`（PR）产出同一份四段报告，给的是业务视角而不是 reviewer 视角：

| 段 | 内容 | 条数上限 |
|---|---|---|
| 📍 影响范围 | 波及哪些业务模块，以及触达方式（直接改动 / 传递依赖 / 构建发布） | 5 |
| 🎯 影响点 | 具体到入口 + 可验证的变化 + 文件:符号 | 6 |
| 🧪 回归范围 | P0/P1/P2 回归项（操作步骤 → 预期结果），**必须**附一行「免回归」 | 6 |
| ⚠️ 风险提示 | 回归清单覆盖不到的（构建发布链路、证书有效期、不可逆操作等） | 3 |

输出规格写在 `.github/prompts/impact-regression.md`，两个 job 共用同一份；业务模块清单由 `tool/pr_impact_analysis.dart` 的 `_modules` / `_infraModules` 生成并附在静态报告末尾，是唯一来源——改模块归属只改 Dart 文件，不要再往 prompt 里抄。

全部用列表而非 Markdown 表格：飞书 `lark_md` 不渲染表格，竖线会原样显示成乱码。

#### 手动对任意区间补做分析

```bash
# 不传参数 = 分析 HEAD~1..HEAD
gh workflow run "Unified CI Pipeline" -f base=15722e4 -f head=HEAD
```

手动触发只会跑 `push-ai-review`（影响分析和代码评审两段都会跑），其余 job 的 `if` 都限定了 push / pull_request，会自动跳过。并发组单独按 `run_id` 分，不会取消正在跑的 push CI。

### 一张卡片，两段内容

影响分析和代码评审原本是 `branch-ai-review` / `push-code-review` 两个 job，各自 checkout、各自发一张飞书卡片——同一次 push 会在群里刷出两条，得对照着看。现在合并成 `push-ai-review`：共用一次 checkout，两次 LLM 调用，结果拼成一张卡。

两段各自降级，一边失败不影响另一边照常显示：

| 段的状态 | 卡片里显示 | 卡片颜色 |
|---|---|---|
| 正常出结果 | AI 正文（超 2500 字按字符截断，完整版看 job summary） | 🔵 blue |
| 对应 `ENABLE_*` 设为 `false` | `已通过仓库 Variables 关闭。` | 两段都跳过时 ⚪️ grey |
| 本次区间没有该段关心的改动 | `本次区间没有相关改动,已跳过。` | 同上 |
| 调用失败 | 状态行 + 响应体 + stderr（已脱敏） | 任一段失败即 🟠 orange |

两段的「有没有改动」口径不同：影响分析统计全部改动文件（含 `ios/`、`android/`、`.github/`），代码评审只看 `.dart`——只动了 `pbxproj` 的提交没有代码可评。所以卡片上经常出现「影响 N · 源码 0」。

失败与否以步骤输出的 `ok` 标志为准，不靠正文关键字去猜。飞书 webhook 的返回码也会检查：卡片过大或格式不对时飞书会拒收，以前 CI 一路绿灯、只有群里没消息，现在会打一条 `::warning::` 带上 `code`。

### 为什么有自建的 `tool/pr_impact_analysis.dart`

Web 端用 `madge` 生成 JS 模块依赖图，Dart 没有等价工具能理解本项目的分层规则，所以自建了一个：它扫描 `lib/` 的 `import`/`export`，建反向依赖图，输出「改动文件 → 传递依赖者 → 受影响的层与业务模块」。生成代码（`*.g.dart`、`lib/src/l10n/app_localizations_*.dart`）不计入。

非 Dart 改动（`ios/`、`android/`、`.github/`、根配置）不在 import 图里，但会按 `_infraModules` 单独归类输出——它们不影响某个页面，而是影响全部模块的构建与发版，漏掉会让「影响范围」失真。

改动落在共享层（`api`/`repositories`/`data`）时，传递范围会覆盖 19/21 个业务模块。报告此时会加一条「⚠️ 高扇出」提示，告诉 AI **不要**据此要求全量回归，而要按改动的具体函数/字段判断。

本地复现：

```bash
BASE_SHA=$(git rev-parse HEAD~1) HEAD_SHA=$(git rev-parse HEAD) \
  dart run tool/pr_impact_analysis.dart > impact-report.md
```


## 构建参数

`dart-define` 注入（与 APK 流程一致）：

- `ENV` = `development` / `test` / `production`
- `DISTRIBUTION_CHANNEL` = `apk` / `ios`

构建**只能手动触发**（Actions → Build Story APK + IPA → Run workflow，或 `gh workflow run "Build Story APK + IPA" -f environment=test -f build_target=both`）。push 到 main 不再自动构建——一次构建要占 macOS runner 最长 150 分钟，还会自动 bump 构建号推回 main、往 TestFlight 传包，不该由每次 push 顺带发生。

iOS 的构建方式由 `ENVIRONMENT` 决定（`build-story-apk-ipa.yml:56-74`）：

| `ENVIRONMENT` | Android | iOS | 需要签名材料? |
|---|---|---|---|
| `production` | release | **release + 签名 → TestFlight** | ✅ |
| `test`（**表单默认值**） | debug | **release + 签名 → TestFlight** | ✅ |
| `development` | debug | 模拟器（不签名） | — |

注意 `test` 同样是签名的 release 构建并会上传 TestFlight，只是 `--dart-define=ENV=test` 让包连测试后端。表单默认就是 `test`，**点 Run workflow 不改选项就会传 TestFlight**，所以签名材料缺失/过期会让构建直接失败，不是只影响 `production`。

另外：`Bump pubspec build number` 步骤会把新构建号 push 回 main（构建号不能重复，否则 App Store Connect 拒收）。所以**手动构建之后本地记得先 `git pull` 再提交**，否则会撞上非 fast-forward。

这一步排在整个 job 的**最后**，失败只报 warning。它原本夹在 altool 上传和上传产物之间：构建要跑几十分钟，期间 main 往往已经前进，`git push` 被拒 → `exit 1` → 后面的产物、Release、飞书通知、TestFlight 分发**全部跳过**——包传上去了却没进测试组。现在每轮重试都重新 fetch，在 origin/main 最新的 pubspec 上重做那一行（用独立 worktree，不碰构建产物所在的工作区），所以不会把别人同期改的其他行一起回退。真正的构建号来源是 App Store Connect（`resolve_build_number.py` 查 max+1），pubspec 里这个数只是兜底，不值得为它红一次构建。

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
| `IOS_PROVISIONING_PROFILE_BASE64` | `.mobileprovision` 的 base64。workflow 会按 UUID 命名同时装进旧目录 `~/Library/MobileDevice/Provisioning Profiles/` 和 Xcode 16 的新目录 `~/Library/Developer/Xcode/UserData/Provisioning Profiles/` |

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

iOS 项目的 Runner Release 配置（`ios/Runner.xcodeproj/project.pbxproj:709-729`）：`DEVELOPMENT_TEAM = 7T6LG3LXBN`、`CODE_SIGN_IDENTITY = "iPhone Distribution"`、`CODE_SIGN_STYLE = Manual`、`PROVISIONING_PROFILE_SPECIFIER = "cestine-test"`、Bundle ID `com.cestine.officeapp`。

手动签名意味着**本机用 Xcode 打 Release 包也需要装上名为 `cestine-test` 的描述文件**，不能靠 Xcode 自动管理兜底。（文件里另有几处 `CODE_SIGN_STYLE = Automatic`，属于测试 target，不影响 app 的签名。）

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
2. 左侧选中该账号 → **Manage Certificates** → ➕ → **Apple Distribution**（没装 Xcode 时：钥匙串访问 → 证书助理 → 从证书颁发机构请求证书，生成 CSR 后到 developer.apple.com 创建 **iOS Distribution** 或 **Apple Distribution** 证书，两种都可以，项目 Release 配置的 `CODE_SIGN_IDENTITY = "iPhone Distribution"` 两种都能匹配）
3. 打开「钥匙串访问」→ 我的证书 → 找到 `Apple Distribution: ...` → 右键导出
4. 保存为 `story-release.p12`，**设置导出密码**（之后填 secret 用）

```bash
# 先验证导出密码是否正确（输入密码后无报错即通过；报 "Mac verify error" 说明密码不对）
openssl pkcs12 -in story-release.p12 -noout
# 导出密码 → IOS_CERTIFICATE_PASSWORD（粘贴时不要带换行）
# 转 base64 → IOS_CERTIFICATE_P12_BASE64（直接复制到剪贴板）
base64 -i story-release.p12 | tr -d '\n' | pbcopy
```

> CI 报 `MAC verification failed during PKCS12 import (wrong password?)` 时，就是上面两个 secret 不匹配：要么密码填错 / 带了换行，要么 base64 用的是另一个 .p12。

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

1. 手动触发 `build-story-apk-ipa.yml`（`test` 和 `production` 都会签名上传）
2. CI 构建签名 IPA → `xcrun altool --upload-app`（API Key 认证）上传到 App Store Connect
3. 苹果服务器处理（通常 5-15 分钟）：自动化审查 → 生成 TestFlight 构建
4. CI 轮询到构建变为 `VALID` 后，自动加进 `TESTFLIGHT_GROUPS` 里配置的测试组（见下）
5. 分发成功后，把更旧的构建标为过期，只保留最新 `TESTFLIGHT_KEEP_BUILDS` 个（默认 3，见下）
6. App Store Connect → TestFlight → 该版本状态变为"可测试"
7. 测试用户收到新构建（内部组立即可用，外部组要先过 Beta 审核）

### 自动加入测试组

`altool` 只负责传包，传完构建就停在 TestFlight 里没有分发对象——以前每次都要去 App Store Connect 手动把群组加上。现在由 `Distribute to TestFlight groups` 步骤（`.github/scripts/testflight_distribute.py`）做掉。

配置一个仓库 Variable 即可：

| Variable | 默认 | 作用 |
|---|---|---|
| `TESTFLIGHT_GROUPS` | 空 | 要自动分发的测试组名，逗号分隔。**留空时不分发**，只在日志里列出可用群组 |
| `TESTFLIGHT_WAIT_SECONDS` | `900` | 等构建处理完的上限。超时不会让构建变红，只打 warning |
| `TESTFLIGHT_KEEP_BUILDS` | `3` | 分发成功后把更旧的构建标为**过期**，只保留最新 N 个。填 `0` 关闭（见下） |

不知道群组叫什么就先不配：跑一次构建，日志里的 `::notice::可用群组: ...` 会把名字、内部/外部、是否已开自动分发都列出来，照抄进 Variable 即可。

几个行为上的选择：

- **这一步排在很后面**，不是紧跟上传。构建处理完之前加不进外部组，而上传产物 / 建 Release / 发飞书本来就要跑几分钟——放后面等于白捡一段处理时间，直接从 job 总时长里省下来（timeout 是 150 分钟）。
- **群组名写错会让构建变红**。打错一个字的后果是此后每次构建都静默不分发，正是这个脚本要消灭的那个手动步骤，所以宁可吵。报错里会列出实际可用的名字，并说明 IPA 已经传上去了。
- **超时只是 warning**。包已经传成功了，把整个构建标红会误导人。
- **重复运行安全**。已经在组里的构建会跳过，不会因为 409 把重跑打成失败。
- **Apple 判定 `INVALID` / `FAILED` 会变红**。`altool` 对这种情况是退出 0 的，这个红叉是唯一的信号。

> App Store Connect 自己也有「Enable automatic distribution」开关，零代码，但[只对内部组有效](https://www.developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers)，而且只能在**建组时**勾选——已有的组要改就得重建，重建会让测试员在 TestFlight 里看到「已被移除」。走 API 内外部组通吃，且不动现有群组。

### 只保留最新 N 个构建

每次构建都会在 TestFlight 里留一条记录，攒几十个之后测试员打开 app 看到一长串版本，不知道该装哪个。`TESTFLIGHT_KEEP_BUILDS`（默认 `3`）让分发成功后自动把更旧的构建标为**过期**。

先说清楚这件事的边界，因为它**不可逆**：

- Apple **不提供删除构建**的能力，过期是唯一能让旧包从测试员手里消失的手段。
- 过期后**记录仍然留在**构建列表里（显示为「已过期」），只是装不了了。想让列表本身变短做不到。
- **没有"取消过期"这个操作**。误过期的唯一补救是用新构建号重新传一个包。
- 不配也会过期：Apple 对所有 TestFlight 构建有 **90 天**自动过期。这个开关只是把时间提前。

正因为不可逆，实现上有四道保险：

| 保险 | 挡住的情况 |
|---|---|
| 只在**分发成功之后**才执行 | 等构建超时、加组失败、Apple 判 `INVALID` 时一律不动旧构建——那时候旧包还是测试员唯一能装的 |
| 过期前**重新 GET 校验版本号** | 列表和实际操作之间构建 id 发生漂移时跳过，不会误伤别的构建 |
| **跳过已关联 App Store 版本的构建** | 在审 / 已上架的构建不能动，那是比留几个旧测试包严重得多的事故 |
| **永不碰本次刚上传的那个** | 即使排序异常也不会把刚传的包过期掉 |

另外：版本号排序在本地按整数做，不用 API 的 `sort=-version`——ASC 把 version 当字符串排，`"99"` 会排到 `"123"` 后面（`resolve_build_number.py` 里也是同样的处理）。非纯数字的版本号不参与排序也不会被过期。

任何一个构建过期失败（比如 Apple 返回 409）只会打 warning 并列出原因，不影响其他构建，也不会让整个构建变红——包已经传好分发好了。

填 `0` 完全关闭。脚本层面 `--keep` 默认就是 `0`，workflow 显式传 `3`：不可逆的行为默认不开，得有人明确要求。

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

**构建传上去了但没进测试组**：
- 日志里有 `::notice::可用群组: ...` → `TESTFLIGHT_GROUPS` 没配，照着列出的名字填进仓库 Variable
- 日志里有 `这些群组在 App Store Connect 上不存在` → 名字打错了，报错里有实际可用的名字
- 日志里有 `等了 900s，构建 N 还没处理完` → 苹果处理慢，调大 `TESTFLIGHT_WAIT_SECONDS` 后重跑，或手动加一次

**旧构建变成了"已过期"**：
是 `TESTFLIGHT_KEEP_BUILDS`（默认 3）干的，日志里有 `::notice::已过期旧构建 ...`。
**恢复不了**——Apple 没有"取消过期"，只能用新构建号重传一个包。想保留更多就调大这个
Variable，填 `0` 彻底关闭。注意即使关掉，Apple 自己也会在 90 天后自动过期。

**`::warning::这些旧构建没过期: ...`**：
某个旧构建没能过期，原因在括号里（`已关联 App Store 版本` = 在审/已上架，故意跳过；
`版本号对不上` = id 漂移，保守跳过；其余是 Apple 返回的报错）。不影响本次构建，包已经
传好也分发好了，不用处理。

**`! [rejected] main -> main (fetch first)`**：
构建期间 main 前进了，回写构建号的那次 push 被拒。现在它会自动重试 3 次并且只报
warning，不会再让构建变红、也不会再把后面的分发步骤带下水。看到 `::warning::构建号 N
没能回写` 时无需处理——下次构建的号照样由 App Store Connect 查出，不会撞号。

**构建卡在"Processing"**：
- 等待苹果服务器处理（最多 1 小时）
- 超过 1 小时联系 Apple 支持

**`MAC verification failed during PKCS12 import (wrong password?)`**：
`IOS_CERTIFICATE_PASSWORD` 和 `IOS_CERTIFICATE_P12_BASE64` 不是一对。本机验证：

```bash
openssl pkcs12 -in 你的.p12 -noout        # 无输出=密码正确
base64 -i 你的.p12 | tr -d '\n' | pbcopy   # 重新生成 base64
```

**`No profile for team 'XXX' matching 'YYY' found`**（归档成功、导出失败）：
Xcode 16 起描述文件改从 `~/Library/Developer/Xcode/UserData/Provisioning Profiles/`
读取，旧的 `~/Library/MobileDevice/Provisioning Profiles/` 不再被索引。
workflow 已改为两个目录都装、按 UUID 命名，并从描述文件本身解析
teamID / bundle id / UUID 生成 `ExportOptions.plist`，不再硬编码名字。

**`描述文件内嵌的证书不在 keychain 里`**：
证书和描述文件不是一对。描述文件在创建时就绑定了特定证书，换了新证书必须
去开发者网站用新证书**重新生成**描述文件，然后同时更新
`IOS_CERTIFICATE_P12_BASE64` 和 `IOS_PROVISIONING_PROFILE_BASE64` 两个 secret。
本机查看描述文件绑定的证书：

```bash
security cms -D -i 你的.mobileprovision | \
  plutil -extract DeveloperCertificates.0 raw -o - - | \
  base64 -d | openssl x509 -inform DER -noout -fingerprint -sha1 -subject
```
