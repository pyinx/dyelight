# 染光 · Dyelight

> 让每张照片重新有光。

染光是一款基于 Flutter 的 iOS / Android 照片上色与修复应用。它采用 **BYOK（Bring Your Own Key，自带密钥）** 模式：你只需配置任意 OpenAI 兼容的图片模型服务，即可用 AI 给老照片上色、修复画质、变换风格；此外还内置了完全本地的拼图工具，最多可将 9 张照片合成为一张适合分享的图片。

应用无需注册账号、没有中转服务器，API Key 加密保存在本机，照片只会发送到你配置的模型服务。界面支持简体中文与 English，跟随系统语言或手动切换。

## 功能特性

### AI 上色与修复

- **全自动模式**：一键完成白平衡校正、动态范围恢复、暗部/高光细节与质感还原。
- **自定义模式**：输入自然语言描述想要的色调，支持语音输入（语音转文字）。
- **36 个内置模板**，覆盖 6 大类：
  - 上色修复：老照片上色、老照片修复、清晰增强、曝光校正
  - 风格滤镜：复古胶片、日系清新、赛博朋克、黑金夜景、电影青橙、莫兰迪、奶油肌、黄昏暖光
  - 艺术风格：水彩画、油画、日漫、3D 卡通、铅笔素描、像素风
  - 风景：日出日落、蓝天白云、山川云海、森林晨雾、湖面倒影、花海、极光、雨后清新
  - 人像：自然美颜、证件照（蓝底/白底）、职业形象照
  - 场景换景：海边、星空、樱花季、深秋、雪景、白天变夜景
- **生成前预处理**：自动校正 EXIF 方向、将长边缩放至不超过 2048px、高质量 JPEG 重编码，并在后台 isolate 中执行，避免阻塞 UI。
- **结果对比**：原图/效果图同步缩放与滑动对比，长按查看原图。
- **继续调整**：可基于当前结果微调，或从原图重新调整。
- **保存到相册**：一键保存生成结果。

### 本地拼图

拼图完全在手机上合成，不调用 AI、不产生模型费用：

- 最多选择 **9 张照片**。
- **智能布局**：根据照片数量与横竖方向自动选择合适布局。
- 12 种布局：单图、左右、上下、三联、一大两小、上大下二、一大四小、四宫格、六宫格、一大六小、八宫格、九宫格。
- 5 种风格：小红书、朋友圈、杂志、瑞士、自定义。
- 自定义选项：画布比例（3:4、1:1、4:5、9:16）、背景色、间距、圆角。
- 支持标题与副标题；长按照片可拖动交换位置。
- 导出 1620px 宽的 PNG 图片。

### 历史记录

- 每次生成结果自动保存到本地，拼图与 AI 上色分别归档。
- 按类型（全部 / 上色 / 拼图）和时间（今天 / 近 7 天 / 近 30 天 / 自定义）筛选。
- 支持重命名、删除、查看大图、继续调整或从原图重来。

### 模型服务设置

- 内置 8 个 OpenAI 兼容服务商预设：OpenAI、Google Gemini、OpenRouter、xAI、硅基流动 SiliconFlow、火山方舟 Volcengine Ark、阿里云百炼 DashScope、智谱 Zhipu，也可填写自定义 Base URL。
- **接口类型自动识别**：无需手动判断服务支持哪种协议，应用会探测并选择：
  - `POST /images/edits`（multipart 图片编辑）
  - `POST /images/generations`（JSON 图片生成）
  - `POST /chat/completions`（多模态对话）
- 从服务端拉取模型列表并按图片模型优先排序，支持搜索或手动输入模型 ID。
- **测试连接**：检查服务可达性、密钥有效性以及模型是否在列表中。
- 高级设置：请求超时、自定义 Headers、Temperature。
- **调试模式**：记录请求与响应（隐藏 API Key、截断图片内容），支持一键复制，应用重启后清空。

## 隐私与数据

| 数据 | 存放位置 |
| --- | --- |
| API Key | 系统安全存储（iOS Keychain / Android Keystore） |
| 应用设置 | 本机 Hive 数据库 |
| 历史记录与图片 | 本机应用文档目录 |

- 无账号、无遥测、无中转服务器。
- 照片仅发送至你自己配置的模型服务地址。
- 拼图功能全程本地处理。
- 唯一的网络请求来自你触发的模型调用、模型列表获取与连接测试。

## 技术栈

| 类别 | 选型 |
| --- | --- |
| 框架 | Flutter（Dart SDK `^3.11.0`），Cupertino 风格 UI |
| 状态管理 | `flutter_riverpod` |
| 网络 | `dio` |
| 本地存储 | `hive_ce`、`flutter_secure_storage` |
| 图像处理 | `image`、`image_picker`、`gal` |
| 语音输入 | `speech_to_text` |
| 权限 | `permission_handler` |
| 国际化 | `flutter_localizations`、`intl`（ARB，zh / en） |
| 其他 | `path_provider`、`path`、`package_info_plus` |

## 项目结构

```text
lib/
├── main.dart                 # 初始化 Hive、依赖注入与启动
├── app.dart                  # CupertinoApp 与底部三栏 Tab
├── core/
│   ├── models.dart           # AppSettings、EditRequest/Result 等模型
│   ├── providers_preset.dart # 内置服务商预设
│   ├── debug_log.dart        # 调试日志
│   ├── network/              # 三种接口适配器、端点探测、错误映射
│   ├── storage/              # 安全存储、设置与历史仓库
│   ├── image/                # 图片预处理与相册保存
│   └── permissions/          # 权限服务
├── features/
│   ├── home/                 # 创作首页、上色工作区、模板
│   ├── collage/              # 拼图布局、渲染与编辑界面
│   ├── result/               # 结果页与对比查看器
│   ├── history/              # 历史列表与筛选
│   └── settings/             # 设置、模型选择、调试日志页
├── state/                    # Riverpod providers 与控制器
├── ui/                       # 通用弹窗
└── l10n/                     # 中英文 ARB 与生成代码
test/                         # 网络、预处理、拼图、持久化、UI 等测试
docs/superpowers/             # 设计文档与实施计划
```

分层约定：UI 只依赖控制器；控制器只依赖 `ImageEditProvider` 接口与仓库；只有网络适配器了解具体协议；只有 `SecureStore` 读写 API Key。

## 快速开始

### 环境要求

- Flutter SDK（设计文档基于 Flutter 3.41，Dart `^3.11.0`）
- Android：minSdk 24 及以上
- iOS：Xcode 与 CocoaPods（仅 macOS 可构建）

### 运行

```bash
flutter pub get
flutter run
```

应用启动后进入「设置」：

1. 选择服务商，或填写自定义 Base URL。
2. 输入 API Key。
3. 点击模型 ID 选择模型（会自动获取模型列表）。
4. 点击「测试连接」确认配置可用。
5. 回到「创作」页开始使用。

### 生成与构建

```bash
# 生成国际化代码（flutter run/build 时也会自动生成）
flutter gen-l10n

# Android
flutter build apk --release

# iOS（需签名配置）
flutter build ios --release
```

如需更新应用图标：

```bash
dart run flutter_launcher_icons
```

## 测试与检查

```bash
flutter analyze
flutter test
```

测试覆盖网络响应解析与错误映射、端点探测、图片预处理、拼图布局与渲染、历史持久化、设置兼容性以及主要 UI 流程。

## 国际化

- 文案位于 `lib/l10n/app_zh.arb` 与 `lib/l10n/app_en.arb`，以英文 ARB 为模板。
- 运行 `flutter gen-l10n` 生成 `app_localizations*.dart`。
- 模板名称与提示词属于双语数据，存放在 `lib/features/home/templates.dart`。

## 设计边界

- 仅支持 OpenAI 兼容协议；ComfyUI、SD WebUI 等适配器不在当前范围内。
- 上色一次处理一张照片；拼图支持最多 9 张照片多选并本地合成。
- 无账号体系、无云端同步，历史全部保存在本机。

## 文档

- [设计文档](docs/superpowers/specs/2026-11-04-ai-photo-recolor-design.md)
- [实施计划](docs/superpowers/plans/2026-11-04-ai-photo-recolor.md)
