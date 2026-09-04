# Phase 4D — Android Content URI 与受控 HTTPS 音频 POC 报告

2026-09-04。开始前已fetch并确认
`feat/native-audio-local-poc@faf13f466e2a26b6aeacbb31a2f4edeebbe22da6`与远端同步、工作树干净；
该提交的push运行33875872724与PR运行33875876876均为标准三job成功。从该提交创建
`feat/native-audio-content-network-poc`，先以`3a1813e`锁定计划，未在main/master开发。

## 当前实现

新增项目自有`NetworkPlayableSourceProbe`和`DartIoNetworkHeadTransport`。探针只接受已由
`PlayableSource`验证的无userinfo HTTPS URI，只发HEAD、禁止自动重定向、在操作后强制关闭客户端，
不保存响应body。401/403/404/408/410/429/3xx/5xx以及offline/timeout/TLS/unknown被映射为既有
`DomainFailureCode`；诊断只包含固定ID和sourceId，不保留URL、Query、Header值或原始异常。

Android debug source set新增不可导出、不可授权给外部应用的`NativeAudioPocProvider`。它只读打开应用
cache目录中固定文件名的运行时WAV，不查询MediaStore、不扫描文件、不写共享存储、不增加媒体或存储
权限。main/profile Manifest均不注册该Provider，生产与release源码边界不变。

Windows/Android共用`native_audio_sources_poc_test.dart`：测试进程启动loopback HTTPS服务器，提供
运行时生成的固定WAV和401/403/404/429/503/timeout路由；公开POC Header用于验证瞬时传递。CI运行时
调用OpenSSL生成一天有效的自签名loopback证书，编码到忽略的`build/native-audio-poc/tls-defines.json`
后立即删除原始PEM/key；Flutter只通过`--dart-define-from-file`将其注入专用测试构建。

candidate新增名称明确的`createForControlledHttpsPoc`：仅专用集成测试关闭loopback自签名TLS验证，
Windows同时使用无头时钟sink；默认`MediaKitAudioEngine.create()`继续验证TLS并选择真实音频设备。
成功case仍必须经过真实native candidate的load不自动播放、duration、play/position、seek、completed、
stop/dispose，而不是把HEAD探针冒充音频播放。

## CI 隔离

`foundation.yml`新增默认关闭的`run_native_audio_source_poc`。只有手动显式选中时才运行
`Windows controlled HTTPS audio`与`Android content URI and controlled HTTPS audio`；标准push/PR
行为不变。新路径继承全局`contents: read`，不使用Secret、不上传artifact、不构建/发布APK、不创建
Release。checkout/setup-node/setup-java/flutter/emulator action均固定完整SHA。

## 本地门禁

| 检查 | 结果 |
| --- | --- |
| Flutter | 153文件format 0变化；严格analyze 0问题；完整225项测试通过，含32张Windows宿主Golden |
| 新增单元 | 4项探针测试覆盖2xx、HTTP矩阵、四类transport失败、脱敏、timeout和非网络输入拒绝 |
| 仓库审计 | 31项Node、24/24 ZIP entry通过；无WebView、下载API、媒体二进制、证书/私钥或生产候选接线 |
| TLS生成 | 本机从Git for Windows受控定位OpenSSL；仅生成忽略的defines，原始cert/key立即删除且Git正确忽略 |
| Android Debug | 构建成功，279,083,994字节，SHA-256 `a77f94094676bf6a5ee10dd18c526e707ef59fa11c686e10c048fa2d4b3ab405`；48资产逐字节匹配，v2单Debug签名有效 |
| Manifest | Debug Provider authority固定、`exported=false`、`grantUriPermissions=false`；权限仍仅INTERNET及插件生成的not-exported receiver权限 |

本机没有Android模拟器，Windows C++/Developer Mode仍受远程UAC限制，因此本地没有伪造content URI或
HTTPS native运行结果。实现提交`913f3d75e06a144c25c56175b5c9428d1090f44f`已推送并创建Draft PR #20。
该提交的标准PR运行[33878401743](https://github.com/Z-YO-YI/YYMusic/actions/runs/33878401743)
整体成功，checks、Windows Debug和Android Debug三个job均成功；同提交的较早push运行33878342752
因工作流并发组被该PR运行替代而cancelled，不属于代码失败。

只读专用运行[33878710671](https://github.com/Z-YO-YI/YYMusic/actions/runs/33878710671)整体成功：

| 平台/来源 | load | 首次进度 | seek | completed | 失败矩阵 |
| --- | ---: | ---: | ---: | --- | --- |
| Windows 受控HTTPS | 77 ms | 244 ms | 2 ms | true | true |
| Android 受控HTTPS | 110 ms | 143 ms | 3 ms | true | true |
| Android `content://` | 56 ms | 151 ms | 2 ms | true | 共用同一成功case |

Windows和Android日志均报告`All tests passed!`。该运行仅有`contents: read`，标准构建/发布和Phase4C
job按设计跳过；artifact总数0，目标为该提交或分支的Release总数0。

## 出口与保留缺口

Phase4D出口已由同一实现提交关闭：Windows HTTPS native、Android HTTPS native、Android content URI
native、失败矩阵和零artifact/Release均满足。该结论只证明受控loopback自签名环境中的来源、Header、
解码、时钟和控制链；不证明真实第三方API、跨站重定向、实体扬声器、MediaStore/SAF持久授权、后台/
焦点、SMTC/MediaSession或native许可证闭环。候选仍不接生产、不发布。

## 主要文件

- `lib/playback/network_playable_source_probe.dart`
- `lib/playback/media_kit_audio_backend.dart`
- `lib/playback/media_kit_audio_engine.dart`
- `android/app/src/debug/AndroidManifest.xml`
- `android/app/src/debug/kotlin/io/github/z_y_o_y_i/yymusic/NativeAudioPocProvider.kt`
- `integration_test/native_audio_sources_poc_test.dart`
- `integration_test/support/controlled_https_audio_server.dart`
- `tools/generate_native_audio_poc_tls.mjs`
- `.github/workflows/foundation.yml`
- `test/unit/network_playable_source_probe_test.dart`
- `test/unit/ci_configuration_test.dart`
- `tools/foundation_architecture.test.mjs`
