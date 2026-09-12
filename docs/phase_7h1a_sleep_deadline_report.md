# Phase 7H1A：睡眠截止核心验证

2026-09-13；基线2fb29ec，分支codex/sleep-deadline-core；开始前确认origin为Z-YO-YI/YYMusic，fetch/ff-only pull无新增远程代码，保留本批未提交工作。先[计划](phase_7h1a_sleep_deadline_plan.md)和ADR097，再实现根接口及测试。

## 已实现与边界

- PlaybackController拥有单次Timer、UTC截止意图及off/armed/pausing/expired/failed只读投影。关闭/15/30/60分钟可用；默认无定时器，不写数据库、不跨进程恢复，不创建第二播放器。
- 到期先撤销未执行自动推进，再经已有根命令队列暂停。旧回调、取消/重设/关闭及通知重入均有代数检查；已被引擎接受的pause排空，不自动恢复播放，也不覆盖新设置。
- 提前唤醒/时钟回拨按截止剩余量重设；延迟唤醒立即处理。时间前跳在下次唤醒才观测，OS挂起期间不承诺精确定时。无活动播放直接过期，不清空队列或启动播放；错误安全可观察且不自动重试。
- **竞争修复**：仅撤销已排队的自动推进不够；到期后、暂停执行前的新completed曾触发stop/load/play。先失败复现后，在pausing期间根完成事件入口禁止创建新自动推进。取消不补发已抑制事件。
- 本批无UI或图标变更。用户尚不能通过界面设置；“本曲结束”准确entry协议为H1B，原生入口为H2，不声称全套睡眠设置已完成。

## 验证结果

- 新增23项确定性根/Fake音频测试，完整Flutter **1769通过，102秒**。覆盖三时长、一次性、取消/重设、早晚唤醒/回拨、空库/暂停、加载排队、接受后重设、关闭屏障、到期前后自动推进、重入和失败；失败复现日志保留在忽略的build目录。
- Node **143通过，36.4秒**；**188张原Golden无修改**。519 Dart文件格式零改动，严格分析0问题（22.7秒）。build_runner35秒、Drift迁移通过，生成文件/Schema无Git差异。
- ZIP、App.tsx、基础HTML和总指令四个SHA256与既有审计一致；24解压条目逐字节通过，六音频包许可及两原生构建源指纹通过。App.tsx中的NEW_ICON_SPRITE/POLISH_CSS及原资产均未改动。
- Android Debug **18.2秒**通过；48打包资产、完整音频许可及v2单签名者验证通过。APK **232235651 bytes**，SHA256 `025860fe192a45fdf2fa3c522d58058dba1f8b545cf5e66b830a5312dc89fe49`。Java native-access警告保留；Debug包不入Git。
- 无新增实机安装/出声、UI-SQLite验收或本地Windows构建。GitHub按本批新SHA运行Android/Windows，不能拿前置或本地结果冒充云端成功。

## 同步与下一增量

前置审计2fb29ec的[push34714283243](https://github.com/Z-YO-YI/YYMusic/actions/runs/34714283243)/[PR34714289994](https://github.com/Z-YO-YI/YYMusic/actions/runs/34714289994)，G4的[push34713323813](https://github.com/Z-YO-YI/YYMusic/actions/runs/34713323813)/[PR34713336459](https://github.com/Z-YO-YI/YYMusic/actions/runs/34713336459)本次核验均SUCCESS。本批push后创建Draft，base为codex/phase7-exit-audit，精确提交及运行链接记录于PR交付信息；不自动合并或发布Release。

主要文件：playback_controller.dart、playback_sleep_timer_state.dart、sleep_deadline_actions.dart、fake_audio_engine.dart及playback_sleep_deadline_test.dart。下一步H1B先明确准确条目的本曲结束语义和竞争，再H2原生设置界面；Phase7整体、Phase8真实导入、Phase9来源、Phase10后台媒体及Phase11发行仍未完成。
