# Phase 7 出口审计与剩余工作

## Phase7J3替换事件隔离

整批替换改用独立播放器ID和订阅generation，通道测试证实旧索引/错误及旧play失败不污染新批次，见[报告](phase_7j3_event_isolation_report.md)。但锁定插件吞没部分原生释放错误，成功dispose不能证明资源释放；原生生命周期验收仍缺。根队列/睡眠/继续策略尚未切换序列，无缝未启用。

## Phase7J2共用序列引擎

序列能力已从插件边界接至JustAudioEngine，状态携带不含播放地址的批次/entry身份并保护异常索引。见[报告](phase_7j2_sequence_engine_report.md)。PlaybackController尚未使用该协议；自动继续/睡眠/队列修订和旧原生事件隔离、真实听感验证仍须完成，不能将本批算作用户可用无缝播放。

## Phase7J1原生序列边界

新增可选后端序列加载与索引快照，真实插件平台通道测试覆盖边界，见[报告](phase_7j1_native_sequence_report.md)。根仍单曲加载，无缝播放尚未启用；序列索引到队列身份、策略撤销及原生声学验证是下一步，不将本增量算作无缝验收。

## Phase7I2反馈接入

队列失效项诊断现在已接实际QueueScreen：可展开安全原因和确认当前快照，失效引用保留、旧确认不清除新记录；详见[报告](phase_7i2_queue_feedback_report.md)。因此下方7I“可见反馈待接入”为历史阶段限制。全局故障仍停止而非遍历；会话记录不代表跨启动诊断存储。其他Phase7/后续阶段缺口不变。

## 当前更新：H6C后复核与Phase7I

H4剩余时间/恢复/淡出、H5真实输出观察与系统设置、H6自动继续根策略/SQLite/设置UI已分批实现，不能再以原始缺口1–3描述当前代码。但Phase7仍未整体完成：无缝/标准化未实现，真实封面与LRC来源依赖Phase8/9，真机系统栏/手势/多屏/性能证据仍缺。

本次直接检查PlaybackController._advanceInternal发现§20“无法播放项跳过并记录错误”此前未落实：只尝试_nextEntry一次。Phase7I补有界候选遍历及最近20项安全会话诊断，保留失效引用；全局/持久化失败仍终止。具体范围与最终验证见[7I报告](phase_7i_queue_skip_report.md)。诊断列表的可见队列反馈随后接入，不能把根记录接口称为完整错误UI。

## 2026-09-13后续更新（Phase7H3B）

H4补充审计：[能力报告](phase_7h4_capability_audit.md)发现§26的剩余时间、未过期恢复和平滑暂停也尚未完成。五选项与入口已实现不等于完整睡眠验收；session-only是早期增量范围，并非用户放弃恢复要求。下一批改为[H4A剩余时间](phase_7h4a_sleep_remaining_plan.md)→恢复→淡出，再推进输出设备/偏好。本文其他历史完成描述均应受此限制。

下文为最初审计时的历史状态。缺口1已由H2C1–C4补齐播放页/歌词页/底栏/Inspector真实睡眠设置入口；缺口2中的15/30/60分钟及本曲结束已实现并测试，输出设备与其他播放偏好仍未完成；缺口3由[H3A](phase_7h3a_queue_summary_report.md)/[H3B](phase_7h3b_inspector_queue_report.md)补齐真实根摘要及队列页入口，已移除预留文本，不复制模拟下一首元数据。**Phase7仍不标记整体完成**，真实来源、设备QA与Phase8–11未完成。下一步先审计输出设备/无缝/标准化/自动继续的后端支持与真实语义，再分阶段实现，不交付假开关。

## 原始审计记录

2026-09-13。审计基线`7d5385e4004d3f3118bde759828c8a2ce158ffa2`，仓库Z-YO-YI/YYMusic，分支codex/phase7-exit-audit；开始前fetch/ff-only pull且工作区干净。此批只整理证据与下一批计划，不改变应用、平台、依赖、数据库或Golden。

## 结论

**Phase 7 不标记整体完成。** 总指令的五项核心出口已有源码和自动化证据，但不能用这些证据掩盖§18明确要求的播放设置缺失，也不能把Fake平台、Golden或Windows云端Runner当作Android真机与全设备验收。仍停留Phase 7，不因本报告跳到Phase 8或发行。

依据为[用户总指令](../design_reference/YYMusic_Flutter_AI_Development_Master_Instructions_v2_Figma_Optimized.md)的§18、§19、§20及Phase7–11；参照包含NEW_ICON_SPRITE和POLISH_CSS的完整App.tsx与基础HTML合成。此前Phase0指纹与24ZIP条目审计保持有效，本文没有重新宣称完成原始全文审计。

## 核心出口证据

| 总指令项目 | 源码与可重跑证据 | 审计判断 |
|---|---|---|
| 独立/player、/lyrics、/queue；播放页不嵌完整歌词 | [AppRouter](../lib/app/app_router.dart)、[PlayerScreen](../lib/features/player/common/player_screen.dart)、[LyricsScreen](../lib/features/lyrics/common/lyrics_screen.dart)、[QueueScreen](../lib/features/queue/common/queue_screen.dart)；[播放页测试](../test/widget/player_screen_test.dart)、[歌词页测试](../test/widget/lyrics_screen_test.dart) | 已实现；完整歌词由独立页面承担，不是播放页Tab |
| 三平台布局 | [原生播放Golden](../test/golden/native_player_golden_test.dart)、[原生歌词Golden](../test/golden/native_lyrics_golden_test.dart)、[队列Golden](../test/golden/queue_screen_golden_test.dart)及对应Widget测试 | Flutter布局自动化通过；Phone/Tablet/Windows、横竖和130%字体，不等于实机截图 |
| 同步歌词、跟随、点击Seek、翻译、无歌词 | [歌词视口测试](../test/widget/lyrics_viewport_test.dart)、[歌词页测试](../test/widget/lyrics_screen_test.dart)、[C2报告](phase_7c2_native_lyrics_report.md) | 自动化覆盖当前行/偏移、手动浏览恢复、懒加载、翻译、纯文本和缺失/错误；真实文件LRC读取依赖Phase8，不伪称已接真实歌词源 |
| Windows全屏、Android沉浸；Esc/返回 | [全屏应用测试](../test/widget/fullscreen_app_test.dart)、[Windows原生Runner测试](../integration_test/windows_window_gateway_test.dart)、[D2报告](phase_7d2_fullscreen_pages_report.md) | Fake跨端流程与Windows CI原生恢复/最小化有证据；Android真实系统栏/手势、Windows多屏/DPI仍需设备QA |
| Reduce Motion | [播放页测试](../test/widget/player_screen_test.dart)、[歌词视口测试](../test/widget/lyrics_viewport_test.dart)及对应Golden | 暂停封面缩放和歌词缩放/滚动策略有自动化验证；无人工读屏/性能验收替代 |
| 队列准确编辑与持久化（§20） | [E3报告](phase_7e3_native_queue_report.md)、[队列SQLite页面测试](../test/widget/queue_sqlite_screen_test.dart)、[队列拖动测试](../test/widget/queue_drag_screen_test.dart) | 排序/清空确认/重复条目/失效软引用/失败回滚与分页锚点已有实现；侧栏队列摘要仍是预留内容 |
| 入口和收藏交互 | [G1](phase_7g1_shell_queue_report.md)、[G2](phase_7g2_shell_fullscreen_report.md)、[G3](phase_7g3_inspector_navigation_report.md)、[G4](phase_7g4_metadata_guard_report.md) | 底栏/侧栏入口与旧回调保护已接；不延伸声称所有传输控件均已完成同等审计 |

## 明确缺口，不以占位按钮交付

1. **播放设置没有真实入口闭环。** [SettingsSection](../lib/features/settings/common/settings_sections.dart)只有appearance/about；[Inspector](../lib/design_system/yy_now_playing_inspector.dart)两个“播放设置”仍onPressed:null；[底栏组件](../lib/design_system/yy_player_surface.dart)onOpenSettings没有业务接线。不能把它们跳到外观页当作完成。
2. **源设计的播放选项尚未实现。** 基础HTML2542附近optionsOverlay明确包括输出设备、15/30/60分钟及本曲结束睡眠定时；2391附近播放设置包含无缝、标准化、继续播放。HTML明说设备切换是模拟，Flutter不能照搬“蓝牙耳机”等假设备。当前PlaybackState只有可选outputDevice，未发现睡眠定时控制器或这些偏好的完整行为闭环。下一批按[7H计划](phase_7h_playback_settings_plan.md)从真实业务能力开始。
3. **侧栏队列摘要仍预留。** 文本“队列详情正在开发”指侧栏摘要，不能误说独立/queue未实现；后续应接根只读摘要/导航并移除此过时歧义，不复制可写队列。
4. **真实专辑封面、LRC和新安装音乐库依赖真实来源。** 目前是明确兜底，不冒充真实封面提色；本地扫描/授权/元数据/LRC属于Phase8，第三方来源属于Phase9。本报告不将这些依赖记成当前已完成。
5. **设备与发行不是本地Debug。** Android实际安装/系统栏/分屏/后台/出声、Windows多屏/DPI与真实音频、性能/无障碍及Release/AAB/签名分发仍需独立验收。不得用测试数量计算整体百分比或把生成安装包称为可日常使用/已上线。

## 本次复验

本批仅文档审计，无新增应用功能、测试或截图。重新运行完整Flutter **1746通过（89秒）**、Node **143通过（42.7秒）**，516 Dart文件格式零改动，严格分析0问题（28.4秒）。188张Golden不变，已有代码生成/Schema验证见G4；本批不修改生成输入。30个本地证据链接存在性检查通过。

Android Debug复验21.5秒通过，48资产/完整音频许可/v2单签名者通过；APK232227826 bytes，SHA256 `8ce83df142656cf2d7ba3800177aefa345194f7b664676380c66bb3a6ad30d37`，与G4源代码构建相同，保留Java警告。没有本地Windows构建或新的设备验证。

核验时基线7d5385e的[push34713323813](https://github.com/Z-YO-YI/YYMusic/actions/runs/34713323813)和[PR34713336459](https://github.com/Z-YO-YI/YYMusic/actions/runs/34713336459)仍运行；不能据此宣布最新云端通过。审计提交的新Actions也按新SHA独立核对，不拿前置CI冒充本批云端成功。

## 下一步执行顺序

先落实7H真实播放设置核心及测试，再接原生对话框/三端入口，随后核对侧栏摘要、整体验收清单。原生设备选择、无缝与标准化要先确认后端支持和真实行为，不以仅保存开关替代效果；阻碍及平台边界写入报告。保留Phase8–11任务，不提前宣布出口或自动合并/发布。
