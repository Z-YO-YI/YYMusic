# Phase 2G — 跨平台弹层原语报告

2026-09-01。开始前已fetch并确认`feat/cross-platform-player-surfaces@6ecbbd8`与远端0/0同步、工作树干净；从该提交创建`feat/cross-platform-overlay-primitives`，未在main/master开发。阶段来源、范围和出口见[计划](phase_2g_overlay_primitives_plan.md)。

## 当前实际进度

Phase0五份源指纹、完整App.tsx、基础HTML、`NEW_ICON_SPRITE`与`POLISH_CSS`仍是唯一设计依据。本批只交付Widgets-only受控弹层原语与跨平台Gallery Fixture；整个Phase2尚未完成，业务Overlay Manager、正式页面、数据库、来源Repository、真实AudioEngine、队列、系统媒体会话及窗口Gateway均未接入。

## 实现

1. `YYContextMenu`接收不可变item描述和`onSelected(id)`，拥有独立菜单项动作、44dp命中、方向键/Tab闭环、Enter/Space与Esc通知；它不决定位置、显隐、右键/长按或业务含义。
2. Context Menu沿用基础HTML的桌面224dp、Phone 244dp、7dp内边距和30 blur；最终App.tsx POLISH将圆角确定为20dp。标题/元信息、分隔线、选中、危险、禁用及加载状态均由受控输入表达。
3. `YYDialog`保持680dp最大宽、30dp圆角、72dp最小头尾和不透明Surface。`YYBottomSheet`是主指令允许的Phone平台适配，只保留顶部30dp圆角并处理底部SafeArea；两者共用闭环焦点、关闭按钮autofocus、Esc通知和销毁后焦点恢复。
4. `YYToast`保持42dp最小高、420dp最大宽、14dp圆角与live region；`visible`完全由调用方控制，Reduce Motion将动画归零，组件不内置2300ms计时或成功逻辑。
5. Android Gallery以内联Phone Sheet展示，Windows以内联Dialog展示；两端共用Context Menu与Toast。所有Fixture动作只更新页面局部文字，不调用路由、平台API、播放、队列、歌单、数据库、网络、文件或持久化。

## 设计与视觉依据

本批重新读取主指令第7/16/31节和Phase2出口、基础HTML的overlay/dialog/context-menu/toast完整CSS与脚本，以及App.tsx最终POLISH。普通Dialog没有套用Glass；只有有界Context Menu使用Liquid Glass。Phone Bottom Sheet明确记录为平台主动适配，不冒充599px基础HTML全屏Dialog的逐像素复制。

新增三张1280×720、DPR1、130%文字组件板：浅珊瑚、深翡翠、浅色自定义白/ReduceGlass。三张均覆盖菜单、Windows Dialog、Android Sheet和Toast并已逐张查看；旧20张基线未更新，全套23张非更新精确比较通过。

## 本地验证结果

| 检查 | 实际结果 |
| --- | --- |
| 格式与严格分析 | 75个Dart文件格式无变更；`flutter analyze --no-pub --fatal-infos --fatal-warnings`为0问题 |
| Flutter完整回归 | 104项通过：Phase2F 95 + 弹层Widget6 + 弹层Golden3 |
| 弹层交互 | 6项定向Widget通过：菜单几何/状态/响应式/键盘；Dialog几何/焦点恢复；Sheet安全区；Toast live region/Reduce Motion及Gallery本地边界 |
| Golden | 新3张逐张查看；旧20张不更新；23张串行非更新精确比较通过 |
| Node/源码门禁 | 28项Node、五份源指纹、44 SVG、52项派生产物及13个归档文件保持完整 |
| ZIP复核 | 24个entry与原始ZIP逐字节一致，包含隐藏文件 |
| 依赖与权限 | 无新Flutter依赖、平台权限、机器环境、媒体或用户数据变更 |

## 云端与限制

实现提交`a56d4aa6ab042c35751f45c17d6067b8dad2f33d`的push[运行33465720644](https://github.com/Z-YO-YI/YYMusic/actions/runs/33465720644)与PR[运行33465784721](https://github.com/Z-YO-YI/YYMusic/actions/runs/33465784721)均成功；两组各自的Source checks、Windows Debug（含23张Golden）和Android Debug三个job均逐项确认success。

手动[运行33466396076](https://github.com/Z-YO-YI/YYMusic/actions/runs/33466396076)同样三个job全部成功，并创建私有[草稿Release](https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-01936e0c98443e18e11d)。Release为draft/prerelease，目标为完整实现commit；仅有`YYMusic-debug.apk`、`SHA256SUMS`、`build-metadata.json`三个白名单资产。三者已独立下载，metadata的repository、commit、run URL、attempt、Flutter3.47.2、Debug临时签名身份与APK字段均一致。

APK为175818389字节，本地SHA-256、SHA256SUMS、metadata及GitHub API digest四方均为`836e97c46aef2ed0036aaec085b8fb6113beeb2fe363749a7dfa3e817f648a88`。本机Build Tools36.0.0再次验证v2为true，v1/v3/v3.1/v4为false；临时下载目录经解析路径边界校验后已清理。

本机Windows C++工具链仍受远程UAC限制，因此不声称本机`flutter build windows`或安装运行成功。GitHub Windows Runner成功也不能替代Windows系统辅助技术/GPU Blur、Android真机TalkBack/IME、右键/长按手势及真实业务弹层验收。APK继续使用临时Debug签名，不是正式发布包。

## 主要文件

- `lib/design_system/yy_context_menu.dart`
- `lib/design_system/yy_dialog.dart`
- `lib/design_system/yy_toast.dart`
- `lib/features/design_gallery/gallery_overlay_primitives.dart`
- `lib/design_system/yy_tokens.dart`
- `lib/design_system/yy_button.dart`
- `test/widget/overlay_primitives_test.dart`
- `test/golden/overlay_primitives_golden_test.dart`及三张新基线
- ADR、架构、视觉、映射、矩阵、状态、README与CHANGELOG

下一批仍需从Phase2独立小范围继续；不得用弹层视觉原语冒充Phase3/4/5的业务编排、Repository、音频、队列或平台集成。
