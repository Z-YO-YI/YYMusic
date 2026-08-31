# YYMusic

当前交付范围：**Phase 0 — Figma 导出审计、最终视觉合成与架构决策**。没有进入 Phase 1，没有批量创建页面，也没有使用 WebView 实现客户端。

设计依据为 `design_reference/YYMusic_HTML.zip` 中完整的 `src/App.tsx` 和基础 HTML，不能只使用旧 HTML。App 的 `NEW_ICON_SPRITE`、两项账户文字替换、全部 `POLISH_CSS` 均已纳入合成。YYMusic 是产品名，YY Listener 是账户 Fixture。

## 审计入口

- [Phase 0 完成报告](docs/phase_0_report.md)与[阶段计划及出口](docs/phase_0_plan.md)
- [指纹和完整导出清单](docs/figma_export_manifest.md)
- [合成规则及 CSS 层叠差异](docs/design_source_composition.md)
- [HTML → Flutter 功能映射](docs/html_to_flutter_mapping.md)
- [架构决策](docs/architecture_decisions.md)、[依赖候选证据](docs/dependency_decisions.md)、[双平台音频 POC 计划](docs/audio_poc_plan.md)
- [实施状态与下一阶段前置条件](docs/implementation_status.md)

## 可重复验证

只需 Node.js 22 或更高版本，无第三方依赖；这些命令不执行参考 HTML 的脚本，不构建 Flutter：

```powershell
node --check tools/design_audit.mjs
node --check tools/design_audit.test.mjs
node tools/design_audit.mjs --check
node --test tools/design_audit.test.mjs
pwsh -NoProfile -File tools/verify_reference_archive.ps1
```

重新生成派生资产使用 `node tools/design_audit.mjs --write`。输入指纹不匹配时失败，不能直接更新预期哈希掩盖变动。

开发参考：[最终合成 HTML](design_reference/generated/YYMusic_Figma_Composed_Reference.html)。仅用于获准环境中的视觉对照，不是正式客户端或已通过的截图基线；不应将 `design_reference` 声明为 Flutter Release assets。

## Git 与本地原型边界

仓库：[Z-YO-YI/YYMusic](https://github.com/Z-YO-YI/YYMusic)。初始远程无 refs，本地也没有 `.git`，本轮建立 `docs/phase-0-design-audit` 独立分支并 fetch 空远程，没有基于或直接开发 main/master。

本轮仅纳入审计来源、派生资产、工具、文档和 Git 保护配置。任务开始前已有的 `lib/`、`test/`、`pubspec.yaml`、`analysis_options.yaml`、`assets/images/album_atlas.png` 保留原地、不修改、未纳入本阶段 Git 基线。因此克隆此阶段分支得到的是审计基线，不是可运行的 Flutter 应用；本机旧代码仍可能显示为未跟踪文件。

## 历史原型说明：声场画廊 · Sonic Gallery

以下保留任务开始前 README 的内容，属于**未重新验证的旧原型记录**，不是 YYMusic Phase 0 的功能交付声明。原型问题见[现有 Flutter 检查](docs/existing_flutter_audit.md)。旧运行命令不应直接用于覆盖当前目录；先在 Phase 1 确认旧代码迁移/归档方式及 SDK。

按《跨平台音乐 App UI/UX 设计规范与 AI 生成指令》实现的 Flutter 交互原型，目标平台为 Windows、Android 手机和 Android 平板。

### 已实现（旧原型记录）

- `< 600dp` 手机单栏布局：双层悬浮迷你播放器 / Liquid Glass 底部导航、全屏播放器与 Bottom Sheet 队列。
- `600–1023dp` 平板布局：84px 悬浮玻璃侧栏、双栏播放器 / 歌词、横向底部播放器与右侧队列。
- `>= 1024dp` Windows 布局：自定义标题栏、232px 侧栏、最大内容宽度、固定底部播放器与 340px 队列。
- 首页、发现、统一搜索、资料库、本地音乐管理、歌词、队列、服务管理、设备同步和主题设置。
- Light / Dark `ThemeExtension`、4px 间距体系、自定义线性图标和自定义按钮 / 搜索 / 分段 / 进度组件。
- Hover、Pressed、Focused、Selected、Disabled 状态；Windows 常用快捷键。
- 原创 3×2 专辑封面图集，应用内离线裁切使用，不依赖远程图片。

界面没有渐变、紫色、霓虹或 Material 3 默认可见组件。

### 运行（旧原型记录）

当前机器没有安装 Flutter SDK，因此仓库保留纯 Flutter 源码与测试，未生成 Android / Windows runner。安装 Flutter 3.27 或更新版本后，在项目根目录执行：

```powershell
flutter create --platforms=android,windows .
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

Android 可通过 `flutter devices` 查看设备后，使用 `flutter run -d <device-id>` 启动。

### 键盘快捷键（旧原型记录）

- `Space`：播放 / 暂停
- `Ctrl+K`：搜索
- `Ctrl+O`：本地音乐
- `Ctrl+,`：设置
- `Ctrl+L`：资料库
- `Ctrl+Q`：播放队列
- `Esc`：关闭队列或播放器

### 目录（旧原型记录）

- `lib/src/theme.dart`：主题与设计 Token
- `lib/src/icons.dart`：自绘线性图标系统
- `lib/src/components.dart`：可复用 UI 组件
- `lib/src/pages.dart`：业务页面
- `lib/src/shell.dart`：三端响应式壳层
- `assets/images/album_atlas.png`：原创封面图集
- `test/`：Token 与手机 / Windows 冒烟测试
