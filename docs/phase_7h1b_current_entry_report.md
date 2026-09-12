# Phase 7H1B：本曲结束睡眠核心

2026-09-13；基线938a896，fetch/ff-only pull且干净后创建codex/sleep-current-entry；Draft base codex/sleep-deadline-core。遵循[计划](phase_7h1b_current_entry_plan.md)与ADR098，非UI增量。

## 行为

- 根同步接口setSleepAtCurrentEntryEnd返回接受/拒绝；只接受当前已加载且ready/playing/buffering/paused的准确queue entry。空库、加载、完成或错误拒绝，不清除之前有效的分钟意图，不自动播放。
- 睡眠投影entryId与deadline互斥，切换模式取消Timer并撤销旧回调。重复歌曲不能以同TrackRef串用意图。
- 完成事件在根生成自动推进前一次性消费为expired；重复单曲/列表和随机模式均不能越过，不多发pause、stop、seek或队列写入。完成通知里取消/改分钟/关闭不恢复已消费的自动推进。
- 暂停/seek/恢复保留，手动换条目、重载、停止、清空或错误撤销；再次显式play仍允许用户重播，一次性睡眠不再次抑制后续完成。
- 根生命周期、历史记录和同一音频引擎保持不变；没有新平台API、依赖、数据库、媒体流订阅、Widget或图标。没有本批新的界面入口，H2下一增量接入。

## 验证

新增24项测试（23本曲结束、1旧分钟回调互斥），47相关测试通过；全量Flutter **1793通过，102秒**，Node **143通过，35.1秒**。严格分析首次指出测试缺少大括号，补齐并再次严格分析**0问题，8.4秒**；最终格式**520文件零改动**，相关47项复验通过。未禁用lint或删除失败用例。

188张原Golden无修改。build_runner **37秒**及Drift迁移通过，无生成文件/Schema Git差异。原ZIP24解压条目、六音频包许可及两原生构建源指纹均通过；App.tsx的NEW_ICON_SPRITE/POLISH_CSS、基础HTML和设计资产未改动。

Android Debug **17.8秒**通过，48资产、完整音频许可及v2单签名者通过；APK **232238506 bytes**，SHA256 `6c1c40c69826414570d79c2bea20b461d49834a54b0cd8cda51b763c3340d330`。Java native-access警告保留，包不提交Git。没有新增设备安装/出声、UI-SQLite验收或本地Windows编译，GitHub双平台按本批提交独立核验。

## GitHub与下一步

H1A的[push34715635205](https://github.com/Z-YO-YI/YYMusic/actions/runs/34715635205)/[PR34715646633](https://github.com/Z-YO-YI/YYMusic/actions/runs/34715646633)在本批开发中核验仍运行，不能声称前置云端已通过。当前新SHA、Draft和Actions状态在提交后的PR交付信息精确记录；不自动合并、修改默认分支或发布Release。

提交前再次核验：上述H1A两组运行均已completed/SUCCESS。这是938a896的前置云端结果，不代表本批新SHA通过。

主要文件：playback_controller.dart、playback_sleep_timer_state.dart、sleep_deadline_actions.dart、两个睡眠单元测试及阶段文档。下一步H2先读Figma设计转代码技能及已审计本地optionsOverlay，按三布局接共享原生睡眠设置；旧弹层回调要验证路由/根快照，显示真实拒绝与失败，不实现假设备列表或假开关。Phase7整体、真实导入/来源/后台/发行仍未完成。
