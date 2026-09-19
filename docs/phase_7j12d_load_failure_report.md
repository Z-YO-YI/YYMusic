# Phase 7J12D：加载确认期间的异步失败

## 2026-09-19 最终云端验证与 Windows 实测

实现提交 `e84bda796c865aa9419d70f0857a6fc2694bc3ff` 的四条 GitHub Actions 均已完成且 conclusion=success，未借用父提交结果：

| 运行 | 已验证范围 |
|---|---|
| [push 35435408871](https://github.com/Z-YO-YI/YYMusic/actions/runs/35435408871) | 源码门禁、Android Debug、Windows Debug |
| [PR 35435410749](https://github.com/Z-YO-YI/YYMusic/actions/runs/35435410749) | 源码门禁、Android Debug、Windows Debug；Windows 原生窗口/关闭握手3项通过 |
| [Android 35435442822](https://github.com/Z-YO-YI/YYMusic/actions/runs/35435442822) | 本地WAV/content URI两项及独立原生序列一项通过 |
| [Windows Profile 35435441492](https://github.com/Z-YO-YI/YYMusic/actions/runs/35435441492) | 独立序列Profile包构建、身份/许可/原生清单验证；不包含本机播放成功 |

云端Linux普通Flutter测试2314通过，226个固定Windows宿主Golden跳过；Windows job另行执行226项且全部通过，不能将Linux单独记为2540项全部执行。168项Node门禁、614个Dart文件格式零修改、严格分析零问题、24项ZIP内容与6份音频包许可/2份原生构建源指纹均通过，生成物及Drift迁移无差异。Android包内48项设计资产、51项原生音频坐标/3份完整声明及六包许可通过；Windows Debug包65文件、Profile包64文件通过许可与排除旧后端检查。普通构建不等于安装、出声或正式发布。

Android独立序列31秒通过，sourceCommit精确匹配e84bda7；observedIndices/observedCycles=[0,1,2]、progressMs=[301,112,110]、appendAccepted/pruneAccepted/retainAccepted/disposed=true、completedAtIndex=2、acousticGapMeasured=false。保留本地WAV/content URI两项成功；这是模拟器原生事件/进度证据，不是真机后台或声学无缝验收。该诊断运行无上传产物、无Release。

Windows Profile artifact `10581444263`，24725897字节，SHA256 `cf8a4da89a8d4b9bc0aa18550e2bda30b10e15c24f56e23ebeea4f83d2610cea`；下载归档与GitHub digest一致。使用未修改的完整包，在全新忽略目录`build/native-sequence-e84bda7-20260919`完成AOT/SDK运行库/路径/文件哈希/source=native身份检查，无本地原生构建或Dart替换。

**本机Windows序列测试仍失败，但现在正确报告加载失败。** 两个音频服务运行且有2个活跃输出端点；进程exitCode=1、elapsedMs=2236，结果passed=false、testCount=1、diagnosticId=sequence-poc.failed，source/native均为e84bda7。原生仍报告音频播放设备正在使用中，引擎在loadSequence返回`playbackOpenFailed / audio.just-audio.sequence`；没有再等待旧包的首项25秒进度超时。这仅证明本次真实原生错误已传入应用，不能将失败计作播放通过，也不代替单源加载保护的自动化回归。尚未进入播放/追加/清理/截尾验收，没有成功序列指标。

本次未重启任何服务或电脑，未关闭其他程序、切换输出、修改独占设置或驱动。此前唯一获准的Audiosrv重启已执行且未解决占用，不能重复或扩大授权。原始日志和进程结果仅保留本机忽略目录，不提交端点名称/标识、运行时服务地址或插件原文。后续先由用户安排可中断远程会话的电脑重启或提供音频正常的Windows设备，再使用同一精确提交的包在新目录复测；未经明确决定不自动执行系统变更。

结论：本批代码/自动化/双平台云构建验证完成，Windows成功播放验收仍受阻。生产无缝开关、Phase7完整出口、标准化、声学/资源/生命周期、真实导入/来源和Phase8–11发布验收均未据此关闭，Draft PR #136不自动合并。下文保留实现及本地回归记录。

本次取证补记只更新阶段报告、实施状态、出口审计和测试矩阵四份文档，没有修改应用或测试。提交前168项Node门禁再次通过（30.89秒、无跳过），614个Dart文件格式零修改，严格分析零问题（12.5秒），差异空白检查通过；全量Flutter和双平台原生构建证据属于上述未改变的e84bda7应用源码。文档提交触发的新CI单独跟踪，不用既有构建冒充该文档SHA已通过。

## 目标、范围与风险

基线c2177b0（J12C已推送），沿用Z-YO-YI/YYMusic的codex/native-repeat-window和Draft PR #136，不切分支、不重做循环/随机。J12C云构建期间复核总指令§25/30/39及现有错误链路，发现单源load缺少序列load已有的失败复核。本批只改JustAudioEngine的一处加载提交前置条件、引擎/根/方法通道回归与阶段记录；不改原生、依赖、UI、设计参考或Golden。先记录ADR145，风险是将加载中已知失败误提交为成功，或使显式重试无法恢复。

## 复现与实现

测试先挂起后端open，发出异步错误，再允许原生确认返回成功。两项回归分别检查引擎load和根play必须失败；修复前两者都返回null而非预期DomainFailure，明确复现。首轮测试缺失PlaybackPhase导入导致编译失败，补全后才运行并记录上述断言失败，不将编译错误当作产品缺陷证据。

单源open返回后复核_failure，已有catch将结果统一为playbackOpenFailed/open并撤销_loaded。根因此不会调用play或开始失败曲目的历史；显式重试重新load可恢复。已存在的序列加载语义保留。补充实际锁定just_audio方法通道的单源与序列两种加载期旧式错误测试；这些是自动化协议证据，不是本机成功播放。

## 验证与后续

本批新增4项回归，64项相关专项通过；614个Dart文件格式零修改，严格分析零问题（15.5秒），全量Flutter2540项通过（108秒），168项Node门禁通过（41.66秒、无跳过）。生产改动为一处加载提交前检查，未改原生、依赖、资产、设计参考或226张既有Golden；差异空白检查通过。先前两项失败断言已按同一预期转为通过，没有删除或弱化测试。

实现时c2177b0的Windows Profile流程35434887146已通过云端源码/生成物/分析/全量测试，原生构建尚未结束；随后由新提交的同组运行取代而cancelled，并非新源码构建失败。e84bda7最终云端与设备结果见文首，父提交结果不能替代本批验证。

Windows设备占用未由J12C软件兼容修复；已授权的一次Audiosrv重启已执行，不重复操作。继续核验对应源码的Profile产物与实际失败路径，设备播放成功、声学/资源/生命周期及其余Phase7–11仍未验收。
