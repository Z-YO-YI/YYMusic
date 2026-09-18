# Phase 7J11：原生循环窗口与随机顺序保护

## 接管基线与范围

2026-09-18，仓库Z-YO-YI/YYMusic，当前分支codex/native-repeat-window，基线c64301d3df03146fb0c90ad6d67a57a360aea013。fetch成功；远程未找到当前分支或main/master，默认分支为docs/phase-0-design-audit。原有8个文件的未提交修改完整保留，用户知悉差异后明确授权以它们继续最终验证、提交和推送。未切换分支、未重置、未重做已完成功能。

本批目标是收尾已有循环与随机顺序修复，而非宣告整个Phase7完成。审阅主指令、App.tsx最终图标/POLISH_CSS合成、基础HTML的nextTrack/handleEnded及既有阶段记录、实现和测试。风险集中在重复entry身份、提前生成随机顺序、存储等待中的新用户意图、窗口有界及过期源回退；出口为最终回归通过、文档与源码同步、Draft PR和对应双平台Actions证据。

## 已有实现与对应文件

- `lib/playback/audio_sequence.dart`：entry/cursor增加非负cycle；请求中同轮entry唯一，cycle不可倒退或跳跃。绝对逻辑index仍唯一递增，原生索引可随前缀清理归零。
- `lib/playback/just_audio_engine.dart`：追加、截尾和前缀清理比较cycle身份；活动窗口按(cycle,entryId)检查重复，不阻止下一轮再次播放同一队列项。
- `lib/playback/native_sequence_playback.dart`：RepeatMode.all跨队尾预载，包括单项队列；每轮冻结顺序并随已播窗口清理，保持11项总窗口和两项前瞻。未来随机轮不提前改变当前手动导航；真正采用新轮后同步根顺序，但appliedShuffleOrder引用必须仍匹配，防止迟到存储覆盖显式随机开关重建的顺序。
- `lib/playback/playback_controller.dart`：向原生批次绑定传递轮次顺序和当前随机顺序引用，仍由唯一根持有应用队列。
- 三份既有测试文件：`audio_sequence_engine_test.dart`、`just_audio_sequence_backend_test.dart`、`root_native_sequence_test.dart`，新增共11项；不删除测试或降低断言。
- README、实施状态、测试矩阵、Phase7出口审计和ADR142更新；本文新增。接管后的审查未发现需额外修改运行时代码的回归问题。

## 最终验证

| 检查 | 本次结果 |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 608文件，0修改 |
| `flutter analyze --no-pub --fatal-infos --fatal-warnings` | 0问题，20.5秒 |
| `flutter test --no-pub --reporter expanded` | 2520通过，133秒；日志build/phase7j11_takeover_full.log |
| `node --test tools/*.test.mjs` | 161通过，0失败/跳过，32.22秒 |
| 参考指纹及ZIP | ZIP、主指令、App.tsx、基础HTML、package.json的5个SHA256匹配；24个解压文件逐字节匹配 |
| Golden | 226张已跟踪基线未修改，全量测试包含其回归 |
| 本地Android Debug | 构建成功，42.0秒；48项资产逐字节匹配，6项音频许可及完整原生声明通过 |
| GitHub Android与Windows | 实现提交931956e的push与PR两组运行均success，具体证据如下；非真实音频验收 |

## 云端验收补记（2026-09-18）

实现提交为`931956eb7511d5be5100547a6e10febd7fe4ec0f`；[Draft PR #136](https://github.com/Z-YO-YI/YYMusic/pull/136)基于codex/native-sequence-prefix，未合并。[push运行35324669599](https://github.com/Z-YO-YI/YYMusic/actions/runs/35324669599)与[PR运行35324699642](https://github.com/Z-YO-YI/YYMusic/actions/runs/35324699642)均完成，源码/分析/测试、Windows native build、Android Debug三个必需job均success。

- Android实际生成APK，v2签名验证为true；51项原生音频依赖、3份完整原生许可文本、6项Dart音频许可和48项包内资源核验通过。此push未触发仅workflow_dispatch创建的Draft Release，也没有上传Android下载附件；不得把job名称中的private draft Release误报为已有可下载发布。
- Windows实际构建并核验65文件Debug bundle，音频许可检查通过；[Windows Debug ZIP](https://github.com/Z-YO-YI/YYMusic/actions/runs/35324669599/artifacts/10538794892)已上传，核对时未过期（67,928,928字节）。这是开发包，不是安装器或Release验收。
- 两个可选原生音频POC job均skipped，不计为设备播放通过。本次构建成功不证明新循环序列的原生事件/声学行为。
- 此补记只更新证据和后续计划，不改变931956e的运行时代码；后续文档提交的CI须独立记录，不把上述结果伪称为未知新SHA的验证。

下一可独立验证的批次见[Phase7J12原生序列探针计划](phase_7j12_native_sequence_probe_plan.md)，不重新实现J1–J11。

上一轮专项140项通过日志仍保留；先前2519项全量通过在最后一个竞态修复之前，本次2520项全量是修复后的证据。Android构建仍有Java native-access与SDK XML版本警告，但退出0；没有为消除警告升级SDK或修改工具链。本地Windows构建本批未运行，使用GitHub Actions补齐，不绕过本机symlink限制。diff空白检查及待提交文件凭据模式扫描通过。父阶段c64301d的Actions [34765739481](https://github.com/Z-YO-YI/YYMusic/actions/runs/34765739481)本次核实success，父Draft PR为[#135](https://github.com/Z-YO-YI/YYMusic/pull/135)。本批新PR基于codex/native-sequence-prefix，不合并或发布。

## 设计对应与限制

对应主指令§20/25的随机、列表循环、单曲循环及实际队列语义，基础HTML约2977–2997行提供交互意图；不复制网页消耗模拟队列或从示例catalog填充的实现。App.tsx的NEW_ICON_SPRITE/POLISH_CSS仍是最终视觉源，本批无UI、图标、依赖、数据库Schema或工作流修改，不使用WebView。

本批仅通过显式原生序列入口验证，生产UI的无缝开关尚未开放。单曲循环仍走既有seek/replay；带明确期限的未来项暂不预载，实际到达时重新解析；不宣称完整网络无缝已完成。通道测试不证明真实Android/Windows事件时序、无间隙听感、原生堆字节数或后台生命周期。Debug构建不等于安装后全功能可用或正式上线。

下一步先核验本批双平台Actions，再推进Phase7剩余原生无缝验收与生产设置、未来网络源刷新和标准化；继续保留Phase8真实扫描、Phase9在线来源、Phase10媒体生命周期、Phase11性能/无障碍/签名发布。不得越过未完成出口。没有删除文件、改写历史、自动合并、上传凭据或本地构建产物。
