# Phase 2J — 跨平台队列与歌词原语报告

2026-09-01。开始前已fetch并确认`feat/cross-platform-collection-cards@995016a`与远端0/0同步、工作树干净；从该提交创建`feat/cross-platform-queue-lyrics-primitives`，未在main/master开发。阶段来源、范围和出口见[计划](phase_2j_queue_lyrics_primitives_plan.md)。

## 当前实际进度

Phase0五份源指纹、完整App.tsx、基础HTML、`NEW_ICON_SPRITE`与`POLISH_CSS`仍是唯一设计依据。本批交付主指令通用组件清单最后三个Widgets-only原语与跨平台Gallery Fixture；整个Phase2及正式音乐客户端仍未完成，Queue/Lyrics Domain、音频、LRC、自动跟随、数据库和页面组合均未接入。

## 实现与设计依据

1. `YYQueueTile`保留标准50/7/36和沉浸60/9/42几何、26视觉动作及App.tsx最终10封面圆角；主动作与上移/下移/移除各自拥有44dp命中、键盘和语义边界。
2. `YYLyricsLine`保留future 24%、past 50%、active纯白/1.018缩放和7/6状态点，应用最终780字重、紧字距和6px active ring；Phone与桌面字号分别响应式计算。
3. `YYLyricsPlayerDock`保留82最小高、11/13内边距、50封面、34/44控制、4/12/2歌词Slider和900px两层重排；Phone/低高度使用40/38封面，最终外圆角在所有断点为26。
4. Dock只使用单一纯色Atmosphere；ReduceGlass关闭Blur但保留几何，ReduceMotion取消歌词过渡。所有进度与动作只通知调用方，不订阅播放流或推进时间。
5. Gallery使用确定性Fixture并只修改页面局部标签、选择和预览数值；不调用现有PlaybackController/QueueController。

## 视觉审计

新增三张1280×900、DPR1、130%文字组件板：浅珊瑚、深翡翠、浅色自定义白/ReduceGlass。三张均覆盖Queue当前/普通/禁用/加载和沉浸密度、Lyrics past/active/future/双语及完整Dock，已逐张查看，无裁切、溢出或不可辨动作。

第一次使用长歌词Fixture准确触发328px底部溢出；只缩短测试文案后重新生成，没有缩小正式字体、隐藏内容或放宽Golden。既有29张基线未更新，全套32张非更新精确比较通过。

## 本地验证结果

| 检查 | 实际结果 |
| --- | --- |
| 格式与严格分析 | 91个Dart文件格式无变更；`flutter analyze --no-pub --fatal-infos --fatal-warnings`为0问题 |
| Flutter完整回归 | 131项通过：Phase2I 121 + 队列/歌词Widget7 + Golden3 |
| 交互与响应式 | 动作分离、指针/键盘/语义、禁用/加载、桌面/Phone/低高度、130%、Reduce Motion/Glass、进度预览/提交/取消均通过 |
| Golden | 新3张逐张查看；旧29张不更新；32张非更新精确比较通过 |
| Node/源码门禁 | 28项Node、五份源指纹、44 SVG、52项派生产物及13个归档文件保持完整 |
| ZIP复核 | 24个entry与原始ZIP逐字节一致，包含隐藏文件 |
| 依赖与权限 | 无新Flutter依赖、平台权限、机器环境、媒体或用户数据变更 |

## 云端与限制

实现提交`a20e0fb5fb3558fc2bf43f924ee15f4edf574cdd`的push[运行33475675911](https://github.com/Z-YO-YI/YYMusic/actions/runs/33475675911)与PR[运行33475736751](https://github.com/Z-YO-YI/YYMusic/actions/runs/33475736751)均成功；两组各自的Source checks、Windows Debug（含32张Golden）和Android Debug三个job均逐项确认success。

手动[运行33476650469](https://github.com/Z-YO-YI/YYMusic/actions/runs/33476650469)同样三个job全部成功，并创建私有[草稿Release](https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-94db6b8c22a40fb18b24)。Release为draft/prerelease，标签`ci-debug-33476650469-1`，目标为完整实现commit；仅有`YYMusic-debug.apk`、`SHA256SUMS`、`build-metadata.json`三个白名单资产。三者已独立下载，metadata的repository、commit、run URL、attempt、Flutter3.47.2、Debug临时签名身份与APK字段均一致。

APK为175880481字节，本地SHA-256、SHA256SUMS、metadata及GitHub API digest四方均为`864a557af71841280ed938e80090a07e3bd7764a8e3680a17b6eef81e19af43f`。Build Tools36.0.0验证v2为true，v1/v3/v3.1/v4为false，且只有一个Android Debug signer；APK中的44 SVG与4份字体/许可证逐字节匹配仓库，参考资料及私钥未打包。临时下载目录经解析路径和三文件白名单复核后清理。

本机Windows C++工具链仍受远程UAC限制，因此不声称本机`flutter build windows`或安装运行成功。GitHub Windows Runner成功也不能替代Windows系统辅助技术/GPU或Android真机TalkBack/IME验收。APK继续使用临时Debug签名，不是正式发布包。

## 主要文件

- `lib/design_system/yy_queue_tile.dart`
- `lib/design_system/yy_lyrics_line.dart`
- `lib/design_system/yy_lyrics_player_dock.dart`
- `lib/design_system/yy_slider.dart`
- `lib/features/design_gallery/gallery_queue_lyrics_primitives.dart`
- `test/widget/queue_lyrics_primitives_test.dart`
- `test/golden/queue_lyrics_primitives_golden_test.dart`及三张新基线
- ADR、架构、视觉、映射、矩阵、状态、README与CHANGELOG

下一批必须继续从主指令单独审计后确定，不得用本批Fixture冒充队列/歌词业务、Phase3数据库、Phase4音频或正式页面。Draft PR为[#8](https://github.com/Z-YO-YI/YYMusic/pull/8)，保持待审核且不自动合并。
