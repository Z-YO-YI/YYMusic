# Phase 4F — just_audio 双平台原生运行 POC 报告（未关闭）

2026-09-05。开始前已fetch并确认
`feat/just-audio-native-poc@9b5558bd4ec7ae4ed708be7c50395e054d1673d4`与远端同步、工作树干净；
从该提交创建`feat/just-audio-native-run-poc`，未在main/master开发。范围与不可降低的验收条件见
[计划](phase_4f_just_audio_native_poc_plan.md)。

## 已实现与修复

新增默认关闭的`run_just_audio_poc`输入，以及Windows/Android各一个只读原生job。两个平台运行同一
`just_audio_native_local_poc_test.dart`：测试进程临时生成3秒PCM16单声道WAV，显式以
`useProxyForRequestHeaders: false`和`supportsRequestHeaders: false`创建候选，覆盖load不自动播放、
duration、volume/rate、play/position、seek、pause、completed、stop与dispose。专用路径继承
`contents: read`，不使用Secret、不上传artifact、不创建Release，也不构建发布APK。

三轮原生运行逐步暴露并修复了两个确定问题：

- Windows元数据是惰性发布，测试改为等待duration事件，而不是把load返回当作duration同步完成。
- `just_audio_windows 0.2.3`在MediaPlayer的position与natural duration都为0时提前报告completed；
  `JustAudioEngine`现在只有在实际播放过后才接受native completed，回归单元测试锁定该行为。
- 同时等待position与duration的Future现在由`Future.wait`共同接管；即使一个条件超时，也不会在释放状态流时
  留下未处理的异步`StateError`。

## 本地质量门

| 检查 | 结果 |
| --- | --- |
| Flutter | Dart format零变化；严格analyze 0问题；完整232项测试通过，含32张Windows宿主Golden |
| 仓库审计 | 31项Node、24/24 ZIP entry通过；无WebView、媒体二进制、下载/缓存API或生产候选接线 |
| Android Debug | 构建成功，279,085,047字节，SHA-256 `bba16856f7cdbc3c909172cafa75ee07c345067cb50f66dcc6cfe21e9adbf601` |
| APK核验 | 48份字体/许可证/SVG资产逐字节匹配；参考/私密文件为0；v2单Android Debug签名有效 |
| Windows本机 | 音频服务均Running但播放端点为0；运行原生测试又在构建前被Developer Mode/plugin symlink要求拒绝，未伪造本机成功 |

实现提交`037db44e778447e0989d75a8d885a508f42088f7f`已推送。
[PR运行33941595645](https://github.com/Z-YO-YI/YYMusic/actions/runs/33941595645)与
[push运行33941592336](https://github.com/Z-YO-YI/YYMusic/actions/runs/33941592336)均整体success；两次都完成
checks、Windows Debug和Android Debug，手动POC job按设计skipped。

## 原生运行证据

[只读专用运行33942090875](https://github.com/Z-YO-YI/YYMusic/actions/runs/33942090875)取得以下结果：

| 平台 | 结果 | load | 首次进度 | seek | duration/completed |
| --- | --- | ---: | ---: | ---: | --- |
| Android API36 x86_64 | 通过 | 596 ms | 68 ms | 9 ms | 3000 ms / true |
| Windows Server 2025 | 失败关闭 | — | — | — | 未运行播放case |

Android日志报告`All tests passed!`，并确认代理与Header能力均为false。Windows预检成功启动
`AudioEndpointBuilder`和`Audiosrv`，两项均为Running，但`Get-PnpDevice -Class AudioEndpoint`
返回可用播放端点数0；job以固定错误`No real Windows playback endpoint is available on this runner.`
停止，没有把无端点的MediaPlayer运行冒充成功。该运行artifact总数0，目标分支/SHA匹配Release总数0。

较早运行也保留为诊断证据：33938888642暴露惰性duration，33940062082暴露0等于0导致的提前
completed；两项修复后，运行33940616187的Windows MediaPlayer完成load并保持ready，但调用play后20秒
position仍不推进。该运行的Android case为708/58/13 ms、duration 3000 ms并完成。服务预检进一步证明
Windows失败条件是托管机无播放端点，不是音频服务未启动。

## 出口结论与下一步

Phase4F没有关闭。小批A只关闭Android本地WAV链；Windows真实端点/时钟证据缺失。按计划，小批B的
无Header HTTPS与Android `content://`没有继续实现，避免在前置双平台条件失败时扩大候选代码。

这不等于证明`just_audio_windows`在有声卡的用户电脑不可用；它说明当前GitHub托管机与当前远程Windows
会话都不能提供验收所需的真实播放端点。取得有端点的Windows runner或本机启用Developer Mode并重跑同一
测试前，备用候选不能被选为正式backend。生产仍创建`UnavailableAudioEngine`，没有代理、TLS绕过、
WebView、缓存、下载、音频二进制或新增权限。

下一独立批次回到已经取得Windows/Android解码与时钟证据的`media_kit`候选，补齐其精确native构建配置、
LGPL/第三方NOTICE、对应源码和可替换策略。发布合规没有关闭前，同样不得接入生产或发布包含候选的APK。

## 主要文件

- `.github/workflows/foundation.yml`
- `integration_test/just_audio_native_local_poc_test.dart`
- `lib/playback/just_audio_engine.dart`
- `test/unit/just_audio_engine_test.dart`
- `test/unit/ci_configuration_test.dart`
- `tools/foundation_architecture.test.mjs`

