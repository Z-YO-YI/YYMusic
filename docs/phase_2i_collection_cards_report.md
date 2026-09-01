# Phase 2I — 跨平台来源与歌单卡片报告

2026-09-01。开始前已fetch并确认`feat/cross-platform-state-surfaces@dc2758c`与远端0/0同步、工作树干净；从该提交创建`feat/cross-platform-collection-cards`，未在main/master开发。阶段来源、范围和出口见[计划](phase_2i_collection_cards_plan.md)。

## 当前实际进度

Phase0五份源指纹、完整App.tsx、基础HTML、`NEW_ICON_SPRITE`与`POLISH_CSS`仍是唯一设计依据。本批只交付Widgets-only集合卡片与跨平台Gallery Fixture；整个Phase2尚未完成，来源/歌单Domain、Repository、数据库、连接测试、真实曲目、创建流程、队列和持久化均未接入。

## 实现与设计依据

1. `YYSourceCard`保留基础HTML的72最小高、12内边距、42图标、16卡片圆角与6状态点，并应用App.tsx最终`POLISH_CSS`的13图标圆角。
2. 来源名称、元信息、状态标签及positive/warning/error/neutral色调由调用方提供；组件只发出动作，不测试连接、不读取凭据、不启动网络或计时器。
3. `YYPlaylistCard`采用App.tsx最终20卡片圆角和14图标圆角；桌面使用16内边距、44图标和18标题间距，Phone使用13内边距和40图标。
4. collection/create、选中、禁用、加载和焦点均为受控状态；Create虚线边界由纯色CustomPainter绘制，不使用Material默认Card或渐变。
5. Gallery使用确定性Fixture并只更新本页说明或选择，不把HTML的在线状态和歌曲数接入正式Shell。

## 视觉审计

新增三张1280×720、DPR1、130%文字组件板：浅珊瑚、深翡翠、浅色自定义白/ReduceGlass。三张均覆盖来源四种状态、选中/禁用/加载，以及普通/选中/禁用/加载/Create歌单，并已按原始分辨率逐张查看。

最终状态点、长中文、13/14图标圆角、20卡片圆角、Create虚线和低对比强调色均无裁切或溢出；既有26张基线未更新，全套29张非更新精确比较通过。

## 本地验证结果

| 检查 | 实际结果 |
| --- | --- |
| 格式与严格分析 | 85个Dart文件格式无变更；`flutter analyze --no-pub --fatal-infos --fatal-warnings`为0问题 |
| Flutter完整回归 | 121项通过：Phase2H 113 + 集合卡片Widget5 + 集合卡片Golden3 |
| 集合卡片交互 | Source/Playlist几何、指针、键盘、焦点、语义、选中、禁用、加载、Phone 130%和Gallery本地状态均通过 |
| Golden | 新3张逐张查看；旧26张不更新；29张非更新精确比较通过 |
| Node/源码门禁 | 28项Node、五份源指纹、44 SVG、52项派生产物及13个归档文件保持完整 |
| ZIP复核 | 24个entry与原始ZIP逐字节一致，包含隐藏文件 |
| 依赖与权限 | 无新Flutter依赖、平台权限、机器环境、媒体或用户数据变更 |

## 云端与限制

实现提交`c2948e8e574ae1686ac1f087c23b392f551f3a4e`的push[运行33472070037](https://github.com/Z-YO-YI/YYMusic/actions/runs/33472070037)与PR[运行33472095784](https://github.com/Z-YO-YI/YYMusic/actions/runs/33472095784)均成功；两组各自的Source checks、Windows Debug（含29张Golden）和Android Debug三个job均逐项确认success。

手动[运行33472750596](https://github.com/Z-YO-YI/YYMusic/actions/runs/33472750596)同样三个job全部成功，并创建私有[草稿Release](https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-531a214d60bd84b6ee43)。Release为draft/prerelease，目标为完整实现commit；仅有`YYMusic-debug.apk`、`SHA256SUMS`、`build-metadata.json`三个白名单资产。三者已独立下载，metadata的repository、commit、run URL、attempt、Flutter3.47.2、Debug临时签名身份与APK字段均一致。

APK为175843741字节，本地SHA-256、SHA256SUMS、metadata及GitHub API digest四方均为`3035e3b5a031ef283af098514c78ee8264a5d03ed3aa71f335d177da3ad11417`。首次本地验签启动准确暴露当前进程没有Java路径，未把该次记为通过；使用已安装Android Studio JDK的进程级路径后，Build Tools36.0.0验证v2为true，v1/v3/v3.1/v4为false，且只有一个Android Debug signer。两次临时下载目录均经解析路径边界校验后清理。

本机Windows C++工具链仍受远程UAC限制，因此不声称本机`flutter build windows`或安装运行成功。GitHub Windows Runner成功也不能替代Windows系统辅助技术/GPU或Android真机TalkBack/IME验收。APK继续使用临时Debug签名，不是正式发布包。

## 主要文件

- `lib/design_system/yy_source_card.dart`
- `lib/design_system/yy_playlist_card.dart`
- `lib/features/design_gallery/gallery_collection_cards.dart`
- `lib/features/design_gallery/design_gallery_screen.dart`
- `lib/design_system/yy_tokens.dart`
- `test/widget/collection_cards_test.dart`
- `test/golden/collection_cards_golden_test.dart`及三张新基线
- ADR、架构、视觉、映射、矩阵、状态、README与CHANGELOG

下一批仍需从Phase2独立小范围继续；不得用集合卡片Fixture冒充Phase3来源/歌单Repository、Phase4音频或正式业务页面。
