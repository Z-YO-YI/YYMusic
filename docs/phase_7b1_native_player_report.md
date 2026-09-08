# Phase 7B1 阶段报告 — 原生独立播放页

2026-09-09；仓库 Z-YO-YI/YYMusic；分支 `codex/native-player-route`。
从 fetch/pull 后的干净 `ffb83e6` 创建独立分支；提交前再次 fetch 确认远程基线未变。Draft PR base=`codex/lyrics-synchronization-core`，不修改 main、不自动合并或发布。

## 实际新增与修改

- `lib/features/player/common/player_screen.dart`：原生独立路由、根播放投影、仅页面拥有的手势预览与撤销代次。
- `lib/features/player/{phone,tablet,windows}/*_player_layout.dart`：三个独立布局，不创建播放器或访问仓储。
- `lib/design_system/yy_full_player_content.dart`：受控标题/真实状态、播放/切歌、随机/循环、进度与音量；复用既有 Slider/TransportButton，默认旧控件样式不变。
- `lib/app/app_router.dart`、`adaptive_root.dart`、`features/player/common/shell_player.dart`：底栏曲目信息入口、实际顶层路由活动投影、重复打开去重与统一返回。
- `lib/app/playback_presenter.dart`：Seek 只在 ready/playing/paused/completed 且有时长时可用；可选 isIntentCurrent 传给根串行命令执行前验证。
- 新增 25 项 Widget 测试、8 项 Golden 与 8 张基线；调整既有路由/元数据语义测试，不删旧断言或跳过失败。
- 新增 Node 架构门禁；先写计划与 ADR-076，更新 README、实施状态、测试矩阵，并回填前置 7A 云端报告及 PR #64。

## 行为与来源对应

独立 `/player` 不显示主 Shell；从底栏打开、收起和浏览当前队列均保留唯一根播放器/队列，离页不停止音频。快速双击打开不会叠加两层；直接进入时系统返回统一回首页。活动判断使用 GoRouter 最后匹配叶路由，避免 imperative push 后基础 URI 仍指向下层页面。

播放控制消费真实 Presenter；进度与音量仅拖动时本地预览，松手提交，取消不提交。切歌、覆盖/隐藏、零面积、卸载、跨布局及同类布局内尺寸变化撤销旧回调；排队 Seek 在实际开始前重新授权。已接受普通播放命令不因离页停止。

手机竖屏封面在上、短横屏双栏；Android 当前宽度达到 Tablet 断点后使用平板布局。平板横屏双栏、竖屏居中上下；Windows 始终桌面双栏。短横屏收紧元数据和间距，小尺寸/130% 字体可滚动，未知时长、空队列和错误不伪装正常播放。

封面复用明确“暂无封面”的现有几何兜底，播放 scale 1、暂停 .94，减少动态不缩放；没有读取真实专辑封面。队列按钮打开已有 SystemPlaylistType.queue 浏览，不声称独立 `/queue` 管理已完成。未启用 OS 全屏/F、收藏、完整歌词或高级音频假入口。

使用 figma-design-to-code 技能并遵循本地导出回退：重读完整 506 行 App.tsx 的 NEW_ICON_SPRITE、品牌替换和全部 POLISH_CSS，以及基础 HTML 的播放器结构/immersive 样式和主指令第 18 节。没有在线 Figma 节点，未伪造设计工具结果。复用 44 原始 SVG、YY Token/控件，不用 WebView 或 Material 默认样式。

## 测试命令与结果

- `dart format --output=none --set-exit-if-changed lib test integration_test`：425 文件，零修改。
- `flutter analyze --no-pub --fatal-infos --fatal-warnings`：最终零问题，8.1 秒。
- `flutter test --no-pub --reporter expanded`：最终 1160/1160 通过，56 秒；含 120 张 Windows 宿主 Golden。
- `flutter test --no-pub test/widget/player_screen_test.dart test/golden/native_player_golden_test.dart`：新增 33 项通过。
- `node --test tools/*.test.mjs`：文档更新后 118/118 通过，15.6 秒。
- `dart run build_runner build`、`dart run drift_dev make-migrations`：通过，生成/Schema/锁文件/平台配置与原始资产无漂移。
- `node tools/design_audit.mjs --check`、`verify_reference_archive.ps1`：5 指纹、44 SVG、52 确定产物、24 原 ZIP 文件通过。
- `verify_audio_licenses.ps1 -Mode Source`、`verify_native_audio_notices.ps1 -Mode Source`：六音频 Dart 包/两个原生构建来源与完整原生许可材料通过。
- `flutter build apk --debug --no-pub`：成功，19.2 秒。`verify_android_apk.ps1`：48 原始资产、六包/原生完整许可、私密/参考文件和已拒绝后端排除通过。
- `apksigner verify --verbose`：v2、单签名者通过。APK 为 232,076,137 bytes，SHA-256 `a78f7cfc66010b924369da3e066b422f335979cb52307ac8a4ef1e5f545274c6`；仅保留在忽略的 `build/app/outputs/flutter-apk/app-debug.apk`，不提交安装包。

新增 Widget 包含 12 组 130% 尺寸、真实 pointer 拖动/取消、原生路由进退、延迟 Seek 离页撤销、快速重复打开、缓冲/未知时长/失败重试及 Windows 聚焦 Space 不泄漏至全局快捷键。
8 张新 Golden 覆盖 Phone 浅色/空态、Android 短横屏、Tablet 横竖与 Windows 浅/深/错误，已逐张视觉检查。初轮短横屏控制位于折叠下方，收紧布局后重验；112 张旧基线字节不变，不修改阈值。
开发中发现的重复 push、直接系统返回和测试焦点定位问题均修复并重跑；没有关闭 Lint 或删减旧回归。系统 Java native-access 警告不影响本次成功构建与签名，但不视作未来 JDK 兼容验收。
提交前 22 个变更文本文件敏感模式扫描零命中，30 个候选文件中没有凭据/私钥/环境文件或构建产物；`git diff --check` 通过。8 个二进制候选仅为新增 Golden PNG。

## 限制、同步与下一阶段

本批为 Phase 7 独立播放器的首个可验证增量，不是整个 Phase 7 或上线完成。真实封面、系统沉浸、原生歌词自动跟随/翻译控制及独立队列管理仍需后续增量。
新安装为空库；真实导入/扫描和授权属于 Phase 8，来源/后台系统媒体/设备 QA 与 Release 仍待 Phase 9–11。不用测试歌曲填充生产库，也不按测试数量换算虚假完成百分比。
本批没有本机 Windows 编译、Android 实机安装/出声、性能 Profile 或 Release/AAB 验收。GitHub 必须按推送后的精确 SHA 单独核对 Android/Windows；前置 7A 双组 SUCCESS 仅归前置提交。
普通 Android CI 构建并验证 APK，但未上传 APK artifact；Windows Debug artifact 依赖 Debug CRT，不是通用安装发行包。不发布 Release、不手动触发原生诊断、不自动合并 PR、不提交凭据/环境文件/构建产物。
本批提交、Draft PR 和精确云端状态记录在 GitHub 对应开发分支及 PR；推送和权限检查未成功之前不能声称已同步。下一增量继续按 Phase 7 处理独立页面与真实交互，不跳到整项目生成。
