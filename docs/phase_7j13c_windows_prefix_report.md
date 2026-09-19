# Phase 7J13C：Windows 重启后前缀清理失败定位

## 开始与范围

2026-09-19，Z-YO-YI/YYMusic，codex/native-repeat-window，基线2856dfa530d7cefbc3e1e48d1e476c2847a94ec2；fetch后本地远程一致、工作区干净，沿用Draft PR #136。按总指令§38/39接续Phase7，不重做循环/随机。设计来源沿用基础HTML、App.tsx NEW_ICON_SPRITE/POLISH_CSS完整合成审计，本阶段不改视觉。

用户已自行重启电脑，LastBootUpTimeUtc为2026-09-19 12:43:59。14:10:20 UTC使用未修改的GitHub Profile归档e84bda796c865aa9419d70f0857a6fc2694bc3ff（artifact10581444263，ZIP SHA256 cf8a4da89a8d4b9bc0aa18550e2bda30b10e15c24f56e23ebeea4f83d2610cea）完成重测：23154ms退出1。测试已越过加载、首曲播放、追加与自然cycle0/1/2，失败转为audio.just-audio.sequence-prefix；未再出现该次旧设备占用错误。没有记录成功指标或声学证据，不能称完整播放验收通过。此前10:01:35 UTC加载失败发生在重启前，不再当作当前结果。

已阅读真实序列探针、后端/引擎、方法通道回归、锁定just_audio0.10.6和just_audio_windows0.2.3源码。后端要求删除前缀后原始playbackEvent.currentIndex归零；Windows插件逐项RemoveAt后直接确认，只有原生状态/当前项事件再广播索引。尚无该次原始索引时间线，不能据源码推断直接改为成功，也不能用SequenceState裁剪的索引代替原生事实。

目标：在既有隔离序列探针的前缀操作周围记录有界、白名单原始快照，区分索引未回传与非法切曲。准备新增诊断支持类及单元测试；修改该探针、Node隔离门禁与阶段索引。ADR149先于实现；不改生产、Pub缓存、依赖或成功结果合同，不扩大音频系统授权。

风险：诊断泄露路径/错误、过量日志、取消遗漏，或把诊断输出误当成功。出口：无字符串载荷的强类型投影、有界去重、精确SHA、真实后端单实例、不吞异常；本地格式/分析/全量回归、GitHub精确SHA Windows Profile构建及原样设备运行分别记账。即使诊断收集成功，原测试失败仍必须退出失败。结果指导下一最小修复，不延长超时、伪造索引、跳过清理或改系统音频设置。

## 验证记录

### 精确3e34aa9云端与本机结果

2026-09-19，3e34aa90012f60f8f3efcd64098aade8e3f732fe的push35448905684、PR35448908327、Windows Profile35448934089、Android原生35448936037均success。Android保留WAV/content2项和31秒序列1项通过，三段进度[301,115,100]ms；前缀轨迹rawIndex从2在5ms变0，7ms接受，未暂停播放。Linux2353普通回归与226 Windows宿主Golden分别执行，不把宿主跳过算通过。

Windows artifact10586454064，24729830字节，官方与下载SHA256均5666420b5789985f8f6577b3ff4e19e2ff7840febf4cf0d76348b7f37430a2e2；路径、SDK、源码身份通过，原样Profile在全新隔离目录运行。进程23026ms退出1，单项failed；前缀前rawIndex=2、position=100ms、ready/playing；后续111–911ms期间rawIndex一直2、position增至1012ms。1003ms开始安全停止，1209ms最终failed；没有观察到原始归零。停止后的index=1是退出状态，不是删除成功。原始stderr确认原生concatenatingRemoveRange被调用，无该次设备占用错误。

因此当前直接失败条件是原始索引重排确认缺失，而非电脑无法开始播放。锁定Windows插件删除后没有显式broadcastState，当前媒体对象未变时不能依赖CurrentItemChanged及时通知；选择[J13D最小原生回传修复](phase_7j13d_windows_prefix_fix_report.md)并用同一失败探针复验。实际原生CurrentItemIndex是否正确重排仍以修复后来自WinRT的事件为准，不从Dart列表推算零，不解除超时/非法索引保护。C诊断完成不等于Windows播放验收通过。

新增`integration_test/support/native_sequence_prune_trace.dart`、`test/unit/native_sequence_prune_trace_test.dart`，修改既有序列探针以显式创建同一个真实后端并交给引擎；只在prune窗口订阅原始快照，finally取消并输出独立诊断标记。保留初始样本与最近有界尾部，原始null/负值/增加索引不裁剪；重复100ms桶合并，溢出计数可见。失败仍rethrow，旧成功合同、Profile退出条件和所有生产代码均不变。Node门禁改为检查明确的真实后端/引擎构造，并增加单实例、取消和失败传播检查，没有删除旧门禁。

本地验证：6项新增诊断单测与既有序列/结果专项共61项通过；全量Flutter **2579项通过（105秒）**；完整Node **175项通过（43.90秒，无失败/跳过）**；626个Dart文件格式零修改，严格分析零问题。10个变更文件UTF-8与敏感模式检查通过，`git diff --check`通过。日志仅在忽略的build目录。未在本机编译Windows或Android程序。尚未执行新SHA的原生探针，不能称前缀问题已修复。

下一步推送后使用既有显式`build_windows_audio_probe=true`及`include_sequence_audio_poc=true`构建精确SHA Profile，验证归档SHA/SDK/源码身份后原样运行；依据原始轨迹选择最小修复。Android J13B原生35447685127及push35447630428已经success，独立指标见[B报告](phase_7j13b_root_native_shuffle_report.md)，不替代Windows实测。
