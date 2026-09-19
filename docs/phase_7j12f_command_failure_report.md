# Phase 7J12F：命令确认与错误状态保留

## 2026-09-19 双平台云构建补记

实现提交`e49f048a9a733fa27cfb8562081bb55661a0e7d6`的[push 35440707665](https://github.com/Z-YO-YI/YYMusic/actions/runs/35440707665)和[PR 35440709263](https://github.com/Z-YO-YI/YYMusic/actions/runs/35440709263)均completed/success，源码门禁、Android Debug及Windows native build三个必需job均成功。下文“待推送/待构建”为最初提交时记录，不再代表此实现SHA的当前构建状态。

push日志逐项核验：Linux普通Flutter2330通过、226项固定宿主Golden跳过，Windows另行226项Golden通过；Windows原生窗口/关闭握手3项通过。168 Node、614文件格式零修改、严格分析零问题（14.0秒）；24项参考归档、6项音频包许可及2份原生源指纹、生成物/Drift无差异门禁均成功。Android实际生成Debug APK且v2签名验证通过，51项原生音频依赖/3份完整许可、48项包内设计资产验证通过。普通push/PR没有触发Draft Release，也没有上传Android下载附件。

[Windows Debug归档](https://github.com/Z-YO-YI/YYMusic/actions/runs/35440707665/artifacts/10583364279)已上传，artifactId=10583364279，67934502字节，GitHub digest=`853670f2c1e7f26b305fefaab3406b98a23b38668203dc4b2b73df7c4552f337`，检查时未过期；65文件开发包许可及排除旧后端验证通过。本次只读取GitHub元数据与日志，没有下载或本机运行该包，不把服务器digest当作已完成本地哈希复验，也不称为安装器或正式版。

普通两条CI的音频POC均skipped；另外同一e49f048的[Android原生回归35441460890](https://github.com/Z-YO-YI/YYMusic/actions/runs/35441460890)已completed/success。原WAV/content两项6秒通过，content缺失源被拒绝并在同一引擎恢复；独立序列一项31秒通过，sourceCommit精确匹配，observedIndices/observedCycles=[0,1,2]、progressMs=[303,103,115]，appendAccepted/pruneAccepted/retainAccepted/disposed=true、completedAtIndex=2、acousticGapMeasured=false。未选择HTTPS/Windows或发布模式，产物列表为空，没有Release；模拟器启动时短暂adb未连接重试随后恢复，未放宽测试。本次为真实Android插件/模拟器事件与时钟证据，不是听感、真机后台或Windows播放证明。新根控制器设备验证按[7J13计划](phase_7j13_root_native_validation_plan.md)逐批实施，不重复引擎级探针。

Windows本机成功播放仍未验收；新的自动映射索引对照见[J12E补记](phase_7j12e_windows_audio_comparison.md)，不是本Debug包的新运行。Draft PR #136保持未合并，Phase7及Phase8–11仍未关闭。

此验收补记只改六份文档，无运行时代码/测试/工作流改动；提交前168项Node再次通过（29.99秒、无跳过），614文件格式零修改，严格分析零问题（9.5秒）。本次没有重跑本地2556项Flutter或本机原生构建，完整回归和双平台构建属于上文精确e49f048。后续文档提交的CI单独跟踪，不借该实现SHA冒充新文档SHA已完成构建。

## 基线、范围与风险

2026-09-19，Z-YO-YI/YYMusic，codex/native-repeat-window，基线d6230e207ffd0b415be0e00457a50d114b510b44。开始前fetch并确认本地/远程一致、工作区干净；继续Draft PR #136，不切分支、不重做J11循环/随机或J12C/D加载错误修复。基线的[push 35438366637](https://github.com/Z-YO-YI/YYMusic/actions/runs/35438366637)与[PR 35438368898](https://github.com/Z-YO-YI/YYMusic/actions/runs/35438368898)均success，仅作为基线证据。

目标是在Phase7最终回归中关闭另一个可复现的软件缺口：非加载命令等待期间的异步错误不能返回成功，音量/倍速更新不能把既有播放错误当作已恢复。范围只有JustAudioEngine、两份既有测试及阶段文档；不修改UI、原生插件、依赖、Golden、设计参考或系统设置。风险是误拒绝失败状态下仍有效的偏好更新、阻断明确重试、或stop先发布错误的idle成功态。出口为失败回归先复现、全量验证、提交推送与对应SHA双平台CI。

## 复现、决定与实现

先增加16项行为回归，未改生产代码时运行：原有57项通过、新增16项全部失败。六类命令在后端等待期间收到错误后仍成功返回；音量/倍速会把error覆盖为playing、ready或idle。真实锁定just_audio的方法通道同样复现旧式Windows错误被偏好更新清除，以及seek错误未传播给调用方，不只是Fake后端推测。

ADR146保留现有串行、关闭和明确重试语义：

- `_command`在后端完成后复核本次新错误，通过既有安全DomainFailure路径拒绝确认；命令队列失败后仍可继续处理。
- 音量/倍速执行时保留原错误对象，可以成功更新偏好而不声称播放恢复；等待期间若出现新的错误，仍必须拒绝。比较对象身份而非错误码，避免同码新错误被漏掉。
- stop在发布idle之前检查等待期间的新错误，不再无条件清除它；之后用户明确重试stop成功仍可回到idle。
- play/pause/seek和显式load的原有重试行为保留；不添加自动播放、第二播放器或新的错误重试循环。根收到失败的play确认时不记录播放历史，明确重试仍正常工作。

本批不会让确认已经返回后的迟到错误逆向改变已完成Future；该类错误仍通过现有状态流传播。也没有修改实际音频输出路径，不能据此声称Windows无声原因已修复。

## 验证

| 检查 | 本次结果 |
|---|---|
| 新增回归 | 16项均先失败后通过，未降低断言 |
| 两份引擎/根/真实方法通道专项 | 73项全部通过 |
| 完整Flutter测试 | 2556项通过，117秒，包含Windows宿主Golden及既有循环/随机回归 |
| Node门禁 | 168项通过，49.03秒，0失败/跳过 |
| 格式 | 614个Dart文件，0修改 |
| 严格静态分析 | 0问题，24.5秒 |
| 设计和原生范围 | 未改App.tsx、NEW_ICON_SPRITE、POLISH_CSS、226张Golden、依赖或原生代码；参考指纹由既有Node门禁验证 |

新增覆盖为六类命令等待错误6项、音量/倍速保留已加载/加载失败4项、保留旧错误时再来新错误2项、根play与历史1项、真实插件单源/序列偏好2项、真实seek错误1项。成功后端命令不等于真正出声，协议回归不能充作真机验收。

## 同步、云构建与下一步

本报告提交时新SHA尚未生成，Android/Windows新构建尚待推送触发现有GitHub Actions，不能使用d6230e2或e84bda7的成功记录替代。构建结果按本批精确SHA补充到PR，不自动合并、发布或改写历史；不在本机执行原生构建。

Windows实际播放仍以[J12D失败记录](phase_7j12d_load_failure_report.md)及[J12E路径对照](phase_7j12e_windows_audio_comparison.md)为准。用户确认其他应用可正常出声，不能要求其先修复电脑；本轮不重复原探针、服务重启、输出切换或其他系统变更。后续继续最小兼容性对照；生产无缝入口、声学/资源/生命周期、标准化与Phase8–11仍未验收，不增加未经证明的完成百分比。
