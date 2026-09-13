# Phase 7J4：本曲结束的序列尾部边界

## 基线与目的

基线2c3f701，仓库Z-YO-YI/YYMusic。工作区干净，fetch/ff-only pull后建立codex/sequence-continuation-boundary。前轮事件隔离为有效进展；检查根的setContinueAfterTrack及本曲结束睡眠发现，加载完整序列前必须具备“不重启本曲但阻止后续预载进入”的控制。本批按ADR135补真实原生控制，不用仅保存开关代替行为，不缩减后续根接入范围。

## 实现与原生证据

- 可选AudioSequenceEngine新增retainSequenceThrough(expectedCursor)。在现有operation tail内复核loaded、无失败、完整批次identity/entryId/TrackRef和当前索引；过期请求false且无原生副作用。保留当前及之前的cursor，只截掉后续预载，不修改持久化队列、歌曲或来源。
- NativeBackend调用锁定just_audio.removeAudioSourceRange(current+1,length)。读取just_audio_windows0.2.3的player.hpp确认真实RemoveAt范围实现；尾部为空不调用其会拒绝的空范围。正常路径不seek/reload/play/pause，保留当前播放器、位置及playing状态。
- 引擎编辑期间暂缓普通状态投影并记录任何索引偏移；发生切曲（即使随后回切）、异步错误或原生失败时清除loaded/序列身份，发布固定sequence-boundary错误并请求stop。停止是尽力执行，J3插件吞没部分释放错误的限制不变，不承诺物理静音成功。必须fresh load才可重试播放。

## 关键失败测试驱动的修正

初轮模拟引擎测试通过，但真实插件跨层测试在编辑中注入下一曲索引仍返回true。源码证实SequenceState会将索引限制在缩短后的列表范围，公开currentIndex因此可能掩盖原生已切曲。不能删掉测试或把返回true当作边界成功。

改为从playbackEvent.currentIndex投影快照，并监听原始playbackEventStream记录索引修订。尾部调用前后同时复核原始索引与修订；引擎也跟踪编辑期间偏移。真实通道竞态随后通过，并额外覆盖切走又回到原索引。原始事件不暴露插件类型、URL或headers；J3播放器generation隔离继续生效。

## 验证

8项新增引擎测试：本曲时钟/身份不变、旧批次/非当前条目无操作、已排队替换撤销旧边界、切曲及回切均失败、原生与stop错误脱敏/新load恢复、异步错误、关闭排空且无迟到通知。

5项新增真实通道测试：中间曲目仅移除正确尾部且二次空尾部不调用、错误索引无操作/关闭后拒绝、原生失败脱敏、真实切曲与回切跨层安全失败。原有37项保留，总50项序列专项。没有播放实际测试声音，不据通道仿真宣称双平台本曲边界听感已验收。

初次严格分析指出测试导入排序及if大括号两项，已修正，不关闭Lint。最终2430 Flutter测试通过（128秒），161 Node门禁通过（31.03秒）；规范修复后50项序列专项再次通过。严格分析0问题（9.0秒），606 Dart文件格式零修改，所有测试/构建进程退出0。226张Golden未变，无依赖、schema或UI变化。

Android Debug构建通过（30.4秒），48资产逐字节一致、六项音频许可和完整原生声明通过；四个参考SHA256符合审计基线，24解压文件逐字节符合原ZIP。既有Java native-access警告不变。差异和变更文本凭据/私钥扫描在提交前复核，不提交构建产物。父运行34760361648复核时仍in_progress，不记为通过。

## 交付与后续

提交推送并创建base为codex/sequence-event-isolation的Draft，不合并/发布。本地Windows既有Developer Mode/symlink限制不绕过，GitHub正常双平台构建继续；不启用可选音频探针。接下来继续把序列和本曲边界纳入唯一PlaybackController的队列修订、睡眠、自动继续、重复/随机和失效来源规则，随后双平台原生验收。完整主开发指令和上线目标仍未完成。
