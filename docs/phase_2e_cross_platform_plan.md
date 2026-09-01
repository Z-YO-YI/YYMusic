# Phase 2E 开始 — Windows 导航基础与跨平台 Gallery

日期：2026-09-01。开始前已执行`git fetch --prune origin`，确认`feat/android-content-cards@f5bbf52`与远端0/0同步、工作树干净；从该提交创建独立分支`feat/windows-navigation-foundation`，不在main/master开发。

## 本阶段目标

- 新增原生Flutter `YYWindowsSidebar`与`YYWindowToolbar`，复用现有Theme、Glass、Profile、44个App.tsx SVG和导航语义，不使用WebView、Material默认视觉或近似重画图标。
- 将Windows Shell的骨架导航替换为受控Sidebar；1440/1024使用240dp展开布局，<1024使用72dp紧凑Rail，保留42dp应用工具区、320dp Inspector结构位和88/76dp播放结构位。
- Windows与Android共享同一原生组件Gallery路由，但显示真实平台标签；Windows Gallery增加明确标注的Toolbar/Sidebar Fixture。
- 修正账户Fixture为`YY Listener / 本地账户`，不把账户名当产品品牌，不伪造音乐源在线、窗口操作或播放状态。

## 已读取与校验的来源

- 主指令SHA-256 `5f024c778be878afc6fcdcc2d3051b1aec5d3357b2fd01d2ea23b1a71066cfcf`；ZIP与仓库副本均为74024字节、`d75093d142b88044a32a95d6064373138b3431b767c8f4df48bff4f7896629ee`。
- App.tsx完整审计既有结果及本批相关最终覆盖：Profile 44圆形双Ring、13.5/720名称、10/540副标题、Nav 14圆角与3×18左指示条、Glass 42参考和Sidebar 24圆角。
- 基础HTML的42/240/320/88 Windows Grid、Toolbar、Sidebar、46dp导航、Source状态、Footer、1439/1023响应式规则与导航脚本。
- 当前Theme/Glass/Profile/Navigation、三套Shell、Router、Gallery、Harness、Widget/Golden与架构测试。

## 准备修改

- `lib/design_system/yy_surface.dart`
- `lib/design_system/yy_profile_header.dart`
- `lib/shells/windows_shell.dart`
- `lib/app/app_router.dart`
- `lib/features/design_gallery/design_gallery_screen.dart`
- `test/widget/foundation_app_test.dart`
- `test/widget/android_design_gallery_test.dart`
- ADR、架构、视觉矩阵、状态、README与CHANGELOG

## 准备新增

- `lib/design_system/yy_windows_sidebar.dart`
- `lib/design_system/yy_window_toolbar.dart`
- `lib/design_system/yy_tooltip.dart`
- `lib/features/design_gallery/gallery_windows_chrome.dart`
- `test/widget/windows_chrome_test.dart`
- `test/golden/windows_chrome_golden_test.dart`及经视觉检查的新基线
- `docs/phase_2e_cross_platform_report.md`与PR草稿

## 风险与边界

- Windows本机C++构建仍受UAC限制；本批Widget/Golden在Flutter Windows测试宿主执行，真正Windows Debug构建以GitHub `windows-2025` runner为证据。
- `WindowsWindowGateway`尚未实现。正式Shell保留操作系统原生窗口边框，不显示可点击的假最小化/最大化/关闭；Toolbar控制仅在Gallery Fixture中验证回调。
- Source Repository属于Phase3。正式Shell明确显示“音乐源尚未接入”，不复制HTML演示的在线/两个来源状态或128首计数。
- 本批不实现DesktopPlayer、MiniPlayer、Inspector业务、右键菜单、拖放、窗口插件或正式页面；Android现有Shell不得回退。

## 出口条件

- Windows 1440×900、1024×720、840×640及130%字号无溢出；展开/紧凑Sidebar、Toolbar动作、Hover/Pressed/Focus/Disabled、Enter/Space、语义和独立路由动作有测试。
- Windows Shell使用新Sidebar驱动现有四条路由，跨断点保留根DependencyGraph、路由、滚动与选择状态；Android Shell与Gallery仍通过原回归。
- 新增Windows关键Golden逐张检查，旧基线仅在修复`YY Listener`空格确有影响时记录并审查，不以更新截图掩盖错误。
- format、fatal-infos analyze、全量Flutter/Node、24个ZIP entry与源指纹门禁通过。
- 独立提交推送GitHub，更新Draft PR；GitHub Android/Windows Debug均成功，APK仍只由GitHub手动工作流构建。
