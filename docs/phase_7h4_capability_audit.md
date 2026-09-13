# Phase 7H4：剩余播放能力审计

后续状态：H4A倒计时、H4B分钟恢复及[H4C生产根淡出](phase_7h4c2b2_root_fade_report.md)已实现，真实设备听感仍待验收。[H5A](phase_7h5a_audio_output_contract_report.md)现开始输出设备契约，尚无原生/UI绑定。下文是原始审计记录，其“未实现”睡眠条目不代表最新代码状态；输出设备、无缝、标准化与继续策略缺口仍保留。

2026-09-13，基线6d1bb500ec1b6a49a222ae73f8206488b80787ce，仓库Z-YO-YI/YYMusic。fetch/ff-only pull且干净，独立分支codex/playback-capability-audit，Draft base codex/inspector-queue-access。本批只审计、修正验收记录及制定下一批协议，不改变应用行为、依赖或数据库。

## 用户要求与真实实现的差距

依据[总指令§26及Phase7–11](../design_reference/YYMusic_Flutter_AI_Development_Master_Instructions_v2_Figma_Optimized.md)、基础HTML2391–2395/2541–2558与包含NEW_ICON_SPRITE/POLISH_CSS的[App.tsx](../design_reference/figma_export/src/App.tsx)。原始指纹和解压条目继续沿用审计基线，没有把本文当作重新全文审计。

| 能力 | 本项目当前证据 | 验收状态与下一步 |
|---|---|---|
| 睡眠五选项与单根到期 | [截止动作](../lib/playback/sleep_deadline_actions.dart)、[状态](../lib/playback/playback_sleep_timer_state.dart)、[面板](../lib/features/player/common/sleep_settings_panel.dart)；分钟绝对UTC截止、本曲结束先于自动推进 | 已有核心与入口，但不等于§26整体完成 |
| 显示剩余时间 | 面板_status显示原设置分钟数，未用deadline减当前时间，未定期刷新 | 未实现；H4A补根时钟派生值、到期夹零、可见刷新与辅助功能播报策略 |
| 恢复未过期定时 | 状态标注session-only；根初始化只恢复队列，关闭取消Timer；面板明确只在本次启动有效 | 未实现；H4B持久化UTC意图与受保护恢复，不跨重启自动播放，不恢复已过期定时 |
| 到期平滑暂停 | _sleepWoke直接调用_engine.pause，无增益过渡 | 未实现；H4C可撤销淡出，不能改坏用户音量/取消后突然恢复播放 |
| 当前输出设备、系统设置入口 | [AudioEngine](../lib/playback/audio_engine.dart)/[AudioEngineState](../lib/playback/audio_engine_state.dart)没有设备事实/命令；PlaybackState.outputDevice仅可选模型，生产无填充 | 未实现；真实Android/Windows路由Gateway，未知状态明确显示；切换仅在后端支持时开放 |
| 无缝播放 | [后端open](../lib/playback/just_audio_backend.dart)只调用单个AudioSource.uri；根完成后再解析/load下一条 | 未接入应用；插件playlist能力不能证明当前串行load无缝，需要准确队列投影和真实音频边界验收 |
| 音量标准化 | 无响度元数据/分析/增益策略；setVolume是用户音量，不能充当标准化 | 未实现；先定义跨源目标、削波保护与真实平台处理，不能只存开关 |
| 播放结束后继续 | [根完成处理](../lib/playback/playback_controller.dart)已有自动推进与重复/随机，缺用户策略开关 | 部分行为已具备；新增根策略后须覆盖关闭自动推进但保留手动下一首、睡眠优先及旧完成事件 |

## 锁定依赖检查，不以“成功返回”代替音效

以[pubspec.lock](../pubspec.lock)和.dart_tool/package_config.json定位已安装的just_audio0.10.6、just_audio_windows0.2.3、platform_interface4.6.0，读取其缓存源码及README；不是对最新版本的推荐，也未升级依赖。

- just_audio.dart的setAudioSources具备播放列表接口，但本项目seam未调用；setWebSinkId方法明确仅Web，不能作为Android/Windows设备切换。
- AndroidLoudnessEnhancer文档及实现仅为目标dB增益，不提供跨曲目测量。当前NativeJustAudioPlayerBackend没有创建AudioPipeline音效链。
- just_audio_windows0.2.3 README声明playlist/gapless支持；player.hpp有concatenating实现。但audioEffectSetEnabled、androidLoudnessEnhancerSetTargetGain等分支直接返回空Map成功，没有执行音效处理。**不得据这些返回值宣称Windows标准化生效。** 这不推断系统永远不能实现，只说明所选插件调用不足以验收。
- [生产工厂](../lib/app/production_audio.dart)当前已选JustAudioEngine（ADR044），不是仍未选型；不被旧POC注释误导。当前关闭代理与请求头支持的约束保持不变。
- 尝试读取对应版本的在线API页被浏览工具安全检查拒绝，未把网页当作已访问证据；上述结论依据本机锁定版本的一手源码。未运行新增设备诊断。

## 下一执行顺序

遵循ADR107，先[H4A剩余时间计划](phase_7h4a_sleep_remaining_plan.md)，之后H4B恢复和H4C淡出；再真实设备状态/设置入口以及自动继续策略，无缝/标准化独立原生验证。Phase10设备生命周期与系统媒体验收仍保留，不提前声称完成。现有session-only行为不能被误写为用户授权移除恢复需求。

本批不新增可点击功能，不提交测试Token/构建包，不自动合并或发布。验证结果与精确提交/PR/云端运行记录在本阶段报告及Draft。
