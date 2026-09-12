# Phase 7E4 阶段报告 — 原生队列拖拽排序

2026-09-12；GitHub `Z-YO-YI/YYMusic`；分支 `codex/queue-drag-sorting`；基线 `32edb5be72e2c7999a92009046063f7c6aacf3be`，开始前 fetch/pull，提交前再次 fetch 验证与 `origin/codex/native-queue-route` 0/0。[计划](phase_7e4_queue_drag_plan.md)和 ADR084 先于实现；Stacked Draft PR base=`codex/native-queue-route`。

## 实际交付

- Android 手机/平板长按条目拖动；Windows 原始 `drag` SVG 手柄鼠标拖动。复用 Flutter widgets 层惰性 SliverReorderableList 的拖动间隙与边缘自动滚动、YYSurface 浮层及 YYQueueTile，保留上下移和无障碍排序替代，没有 Material 默认外观或 WebView。
- QueueDragSession 固定根队列、当前有界只读组、源索引和可撤销权限。按照当前 SDK `onReorderItem` 已归一化的目标索引生成原根 `beforeEntryId`；当前组末尾锚定下一条未加载根条目，不误移至整个队列尾部。重复 TrackRef 保留独立条目身份、addedAt 和当前播放；缺失/未解析项仍可排序。
- 数据对象、根快照和交互版本组成列表身份。刷新、同值替换、尺寸变化、页面隐藏/卸载及零面积取消原生拖动，动画结束后的旧回调和旧语义操作不能改新内容。PointerCancel、无移动和越界不提交。仅根编辑准入检查 busy，自身 busy 通知不撤销已接受写入。
- 修复原生列表更新后 Windows 连续上下移丢失键盘焦点。页面按条目/动作拥有有界 FocusNode，通过 YYQueueTile 新增可选参数接入；只在原焦点未转向其他控件且页面仍可交互时恢复，组外节点与页面关闭均释放，不引入全局焦点状态。
- 排序仍走唯一 QueueController / PlaybackController 串行持久化和既有安全失败反馈，未创建第二份队列、播放器、数据库，也没有 Schema、依赖或原生通道改动。

使用 figma-design-to-code 技能复用了既有 Token、原始图标和组件。输入是本地完整 Figma Make 导出，没有在线 node URL，未虚构线上读取。ZIP、App.tsx、基础 HTML 和主指令四源指纹再次一致；设计检查继续覆盖 NEW_ICON_SPRITE 与 POLISH_CSS，不只读取旧 HTML。ZIP 全 24 个条目与审计导出逐字节一致。

## 验证与修正

- 新增 **8 单元、16 Widget、3 Golden 和 1 Node**。目标队列测试 **41/41** 通过，涵盖三端实际触摸/鼠标、八类生命周期与取消、旧语义回调、缺失项、200 条之后的分页锚点、自动滚动、当前播放保持、连续 Enter 排序。
- 两个既有真实 SQLite 页面用例升级为实际长按拖动正在播放的重复条目；验证落库顺序、根投影重新绑定，随后继续验证 SQL 回滚、安全错误、显式重试、移除、清空及保留音乐记录。音频为 Fake，不计设备出声。
- 完整 `flutter test --no-pub --reporter expanded` **1413/1413 通过**（71 秒）；Node **128/128 通过**（最终重跑约 15.7 秒）。严格分析零问题（8.6 秒），**469 Dart 文件**最终格式零变更；build_runner 成功（14 秒）、Drift 迁移成功，生成文件与 Schema 零漂移。
- **161 Golden** 全部通过。新增手机/平板/Windows 拖动中三张；仅十张受新增手柄/操作文案影响的旧队列图精确更新，其他 **148 张旧基线字节不变**。十三张变更图逐张查看，130% 字体、明暗主题、窄手机、横屏与确认层均检查；未放宽阈值。手机短横屏仍通过内容滚动访问，不把内容在首屏之外误报为不可操作。
- 开发中的失败均保留并修正：自身 busy 误撤销许可、Windows 测试 ValueKey 类型、拖动浮层尺寸导致的落点预期、连续排序焦点丢失。真实指针测试使用明确越过目标条目的坐标，纯模型另验精确归一化索引。正在播放用例最初在拖放动画后、真实写入尚 busy 时断言；改为先等待落下动画，再排空其回调启动的持久化任务，最终确认 busy=false。SQLite 上移同样明确越过首项后通过。未删除失败用例或绕过生产权限。
- 源 ZIP、六个锁定音频包许可、完整原生法律材料通过。原始资产、锁文件、Schema、生成代码和平台目录未改，诊断日志和构建包只留在忽略的 build 目录。

## 构建与 GitHub

本地 Android Debug **19.0 秒成功**，仅作预检；48 个原始资产、六包许可与完整原生法律材料一致；APK v2 签名通过、单签名者。232,169,202 bytes；SHA256 `4f3aca7e855a1c443128038f74e21b1442728a99ca90adb10168a7d3149288bb`。构建与签名工具仍输出 Java native-access 警告，未掩盖为无警告。没有本批本机 Windows 编译/真机安装/出声验收。

前置 E3 精确 `32edb5b` 的 [push34684110805](https://github.com/Z-YO-YI/YYMusic/actions/runs/34684110805) / [PR34684113148](https://github.com/Z-YO-YI/YYMusic/actions/runs/34684113148) 均 SUCCESS，已经回填 [PR #73](https://github.com/Z-YO-YI/YYMusic/pull/73) 和 E3 报告。日志确认 Windows 158 Golden、2 Runner、65 文件正式入口 Debug 包；Android 48 资产、许可与签名通过。手动原生音频诊断未运行。

本批审查后提交、push 并建立 Stacked Draft PR，精确新 SHA 及 push/PR 云端结果记录在该 PR；Android 和 Windows 由 GitHub 常规 CI 独立构建，不借用 E3 成功或本地预检包作为 E4 云端通过。未合并、改默认分支、发布 Release、触发手动诊断、使用付费服务或提交凭据/用户媒体/环境及签名文件/构建产物。

主要文件：`lib/features/queue/common/queue_drag_session.dart`、`queue_reorder_sliver.dart`、QueuePageController/Screen/Sections、`lib/design_system/yy_queue_tile.dart`；单元、指针/SQLite Widget 与 Golden 测试、`tools/queue_page.test.mjs`；README、ADR、计划、报告、状态和矩阵。

## 未完成范围

这是 Phase 7E4，不是完整 Phase 7 或上线。下一增量继续添加到队列/下一首入口；真实封面/收藏等剩余页面能力仍分阶段。Phase 8 导入/扫描/授权、Phase 9 来源、Phase 10 后台/系统媒体和 Phase 11 签名/安装/发行尚未完成。新安装仍为空库，Debug 不是日常可用发行版。
