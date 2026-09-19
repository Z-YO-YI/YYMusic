# Phase 7J13B：固定种子的根原生随机跨轮与策略变更

## 开始与范围

2026-09-19，Z-YO-YI/YYMusic，codex/native-repeat-window，基线7b28a166bb5a308d2a806a5ccde88f665487cef5，fetch后干净且本地远程一致，沿用Draft PR #136。J13A的push35445546018、PR35445548388及Android原生35445563113均success；A已真实观察q0→q1→q0、进度[302,111,101]ms、历史去重更新、完成无重启1206ms及重开无播放1201ms。A完整结果见[报告](phase_7j13a_root_native_repeat_report.md)，不重新实现或修改已通过的A探针。

本阶段按总指令§20/25/34/38/39、既有[7J13计划](phase_7j13_root_native_validation_plan.md)及生产根/随机窗口/已有测试继续。设计仍引用基础HTML与App.tsx的NEW_ICON_SPRITE/POLISH_CSS合成审计，无UI或资产变更。

目标：三曲固定种子，真实根/插件/文件SQLite自然跨轮；新轮关闭随机后原曲继续、旧预载随机尾部失效，下一曲按应用队列自然播放；最终关闭自动继续且完成不重启。新增独立集成测试、结果合同及单测、宿主工具与Node门禁；修改工作流显式选项与阶段索引。生产代码只有发现可复现缺陷才最小修改。ADR148先于实现。

风险：随机预载与新策略混淆、异步持久化尚未完成、把单曲回退错误标为原生无缝、设备测试输出不足或清理失败仍报告成功。出口：精确观测断言、本地格式/分析/全量回归、精确SHA双平台CI及Android原生执行分别通过。本批不测声学，不修改Windows输出/驱动/服务，不打开生产无缝开关，不发布或合并PR。

## 验证记录

### 实现结果与HTML对应

- 独立`integration_test/root_native_shuffle_poc_test.dart`使用三项自有10秒低幅PCM WAV、文件SQLite、真实JustAudioEngine与生产PlaybackController。Random(42)经既有注入点生成前两次[1,0]选择；断言自然原生q0→q1→q2→q1、索引0/1/2/3、轮次0/0/0/1，根元数据与持久化当前项逐次匹配，应用队列始终q0/q1/q2不重排。
- 新轮q1关闭随机；观察同一原生批次/索引的正进度继续至少100ms，随后原生q1自然completed，根自然以既有单曲路径进入顺序后继q2而非旧随机计划q0。再关闭自动继续，观察q2自然completed与至少1秒无重启。随机关闭后不得再抽签，根状态不得反转为随机；全程不调用seek、skipNext或人工emit。单曲回退不是无缝播放证明。
- `expectedRevokedNextEntry=q0`是固定种子与断言顺序推导的预期旧尾项，不冒称读取了插件内部音频缓存。其余运行指标取自原生/根通知、仓库读取与明确完成的资源清理。只在allTestsPassed（含teardown）后输出独立白名单结果，宿主先要求flutter退出成功，再以完整SHA、唯一记录及完整合同复验。未知字段不输出，重复/旧身份/缺失/失败均拒绝。
- 新增`support/root_native_shuffle_result.dart`、7项合同/种子单测、`tools/verify_root_native_shuffle.dart`与3项Node门禁。`.github/workflows/foundation.yml`新增默认false的include_root_shuffle_poc，要求显式Android诊断且与A、旧序列、HTTPS、Windows Profile互斥；保持所有旧探针/合同/格式命令不变。没有生产代码、设计、依赖、数据库schema或Golden变更。对应HTML队列/随机/继续偏好语义，不涉及视觉调整。

### 执行命令与当前状态

固定种子夹具最初误把Random(42)前两次预期写为[0,1]，本地实际[1,0]使测试失败；据真实种子修正场景预期为q0/q1/q2/q1及退出后q2，不修改生产随机实现。严格分析的3处新测试大括号提示已修正，零问题；不关闭lint或改旧测试。

最终本地验证：79项新旧根/CI/循环随机专项、6项新旧根Node门禁通过；完整Flutter **2573项通过（134秒）**，包含既有226 Windows Golden；完整Node **174项通过（51.13秒，无失败/跳过）**；624个Dart文件格式零修改，严格分析零问题（6秒）。执行`flutter test --no-pub --reporter expanded`、`node --test tools/*.test.mjs`、`dart format --output=none --set-exit-if-changed lib test integration_test tools/verify_root_native_repeat.dart tools/verify_root_native_shuffle.dart`、`flutter analyze --no-pub --fatal-infos`。原生Android测试未包含在这些本地数字中，没有本地原生构建。

推送后按精确新SHA执行（只生成诊断，不发布）：

```powershell
gh workflow run foundation.yml --repo Z-YO-YI/YYMusic --ref codex/native-repeat-window -f run_just_audio_poc=true -f just_audio_poc_platform=android -f build_windows_audio_probe=false -f include_https_audio_poc=false -f include_sequence_audio_poc=false -f include_root_repeat_poc=false -f include_root_shuffle_poc=true
```

### 2026-09-19 原生执行补记

精确源码2856dfa530d7cefbc3e1e48d1e476c2847a94ec2的[Android原生35447685127](https://github.com/Z-YO-YI/YYMusic/actions/runs/35447685127)已success。既有WAV/content两项通过；新增根随机测试1项通过（53秒），宿主完整SHA、唯一成功记录和全字段合同复验通过。观测nativeEntries=q0/q1/q2/q1，nativeIndices=0/1/2/3，nativeCycles=0/0/0/1，原生进度[301,101,104,113]ms；根与持久化顺序均q0/q1/q2/q1/q2。关闭随机后当前原生曲继续111ms，完成后单曲顺序q2进度108ms；最终完成后1205ms未重启。mode变化时随机调用3次，此后停止；同批次、元数据、队列不重排、边界完成、顺序回退、随机保持关闭和资源清理均为true，acousticGapMeasured=false。

同SHA的[push35447630428](https://github.com/Z-YO-YI/YYMusic/actions/runs/35447630428)源码检查、Android Debug与Windows构建均success；[PR35447633899](https://github.com/Z-YO-YI/YYMusic/actions/runs/35447633899)也已最终success。本结果关闭B的模拟器状态/时钟/持久化验收，不代表有声音频输出或Android真机后台。Windows重启后的新失败及下一定位见[C报告](phase_7j13c_windows_prefix_report.md)；声学/资源字节/真机生命周期/标准化、Phase7剩余出口与Phase8–11仍未完成。
