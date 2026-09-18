# Phase 7J12：真实原生序列探针计划

## 已完成基线与实际缺口

基线931956e，保留codex/native-repeat-window分支。J11的2520 Flutter、161 Node、本地Android Debug及GitHub push/PR双平台构建已通过，见[J11报告](phase_7j11_repeat_window_report.md)。不重复实现cycle身份、前瞻、前缀清理或随机顺序保护。

当前`integration_test/just_audio_native_local_poc_test.dart`只验证单源WAV；`just_audio_native_sources_poc_test.dart`组合本地/Android来源与HTTPS；`windows_audio_probe.dart`和其结果验证器严格要求既有1或2项测试。现有成功不能证明新序列加载、追加、跨轮切曲或前缀重排在真实插件上工作。不得直接塞入新测试然后放宽旧探针的计数或身份校验。

## 下一批实现范围

1. 新建独立原生序列集成测试，复用运行时生成的低幅度PCM WAV，不提交用户音频或二进制fixture。经JustAudioEngine和真实后端测试，不用模拟平台通道冒充设备。
2. 先验证最小可观测路径：loadSequence不自动播放、一次play后的真实currentIndex推进、同一entry不同cycle投影、append后继续、prune后绝对cursor保持、retain后停止于已保留边界、关闭排空。对等待设上限，监听先于命令；不将人工emit或固定sleep当原生事件证据。
3. 为独立探针建立严格结果验证：精确源码/原生构建SHA、平台、预期测试数量、观察到的轮次/索引/时钟以及安全诊断ID。缺项、跳过、超时或旧产物均失败，不记录路径、URI或凭据。
4. 独立接入显式选择的Android模拟器诊断和Windows Profile探针入口；保留原有单源/HTTPS诊断合同、默认生产入口和普通双平台构建。不启用生产无缝开关。

准备新增：独立sequence集成测试、结果验证与对应单元/工具测试；准备按需修改：显式诊断入口、工作流、阶段报告与ADR。先以最小探针建立真实证据，再扩展根控制器端到端循环；不能一次性重做播放器。

## 验收与风险

- Dart格式、严格分析、全量回归、工具检查、普通双平台构建继续通过，旧探针1/2项测试合同不变。
- Android真实原生插件在模拟器执行、Windows有实际音频端点的机器执行，并保存与目标SHA一致的脱敏结果。云Windows缺端点不能算通过；缺环境时明确未验收，使用已授权的真实设备渠道，不绕过系统设置。
- Windows removeAudioSourceRange后的原始index事件可能延迟；探针必须暴露真实次序/超时，不放松已有生产安全检查来迎合测试。
- 状态事件和播放时钟通过仍不是声学无间隙证明；声学测量、内存字节、后台/焦点生命周期、未来网络源刷新和音量标准化继续保留独立验收。
- 本文件只是下一批实施计划，尚未新增或执行上述序列探针，不能据此标记Phase7整体完成。
