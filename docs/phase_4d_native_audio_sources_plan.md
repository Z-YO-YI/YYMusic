# Phase 4D — Android Content URI 与受控 HTTPS 音频 POC 计划

日期：2026-09-04。开始前已fetch并确认
`feat/native-audio-local-poc@faf13f466e2a26b6aeacbb31a2f4edeebbe22da6`与远端同步、工作树干净，
且该提交的push运行33875872724与PR运行33875876876均成功；从该提交创建
`feat/native-audio-content-network-poc`，不在main/master开发。

## 目标与边界

本批完成主指令Phase4尚未取得原生运行证据的两类来源：Android应用内受控`content://`引用，以及
Windows/Android受控HTTPS测试流。继续复用Phase4A的`AudioEngine`/`PlaybackController`合同和
Phase4B的隔离候选层；生产`main.dart`、Bootstrap、Shell和可见UI不接候选后端。

本批不是来源业务、下载器或媒体库导入：不扫描用户文件，不请求广泛存储权限，不保存网络响应，
不新增download/offline/export API，不提交音频二进制、证书、私钥、Token或真实服务地址。测试音频
仍由确定性代码在运行时生成，所有路径、URI、Header和原始异常均不得进入日志。

## 小批设计

### Android Content URI

- 仅在Android debug source set注册不可导出的应用内POC `ContentProvider`。
- Provider按请求即时生成与Dart夹具格式一致的3秒PCM16/mono/16kHz WAV，并通过只读
  `ParcelFileDescriptor`暴露；不读取用户媒体、不写共享存储、不增加权限。
- Android集成测试以`PlayableSource.contentUri`交给真实candidate engine，覆盖load不自动播放、
  duration、play/position、seek、completed和dispose。
- release/production Manifest不得包含该Provider；Windows任务明确跳过Android专属case而不是伪通过。

### 受控 HTTPS 与失败映射

- Windows/Android测试进程启动loopback HTTPS服务器，按固定路由提供运行时生成WAV、Header校验、
  401、403、404、429、503和延迟响应。
- CI在忽略的`build/native-audio-poc/`目录运行时生成一天有效的loopback证书和私钥，并通过
  `--dart-define-from-file`只注入集成测试构建；仓库和artifact均不保存这些材料。
- candidate增加名称明确的POC创建入口，仅允许集成测试对loopback自签名TLS关闭验证；Windows同时
  使用Phase4C的无头时钟sink。默认创建入口必须继续验证TLS并自动选择真实音频设备。
- 项目自有只读网络探针只发HEAD请求、禁用自动跨站重定向、不持久化body，用类型化结果验证公开
  Header传递及401/403/404/429/5xx/timeout/TLS/offline映射。测试专用loopback证书信任必须通过注入，
  不成为生产默认。
- HTTPS成功case还要交给真实native candidate播放，观察duration、position、seek和completed；
  探针成功不能替代native解码/时钟证据。

## CI 隔离

- 在现有`foundation.yml`新增默认关闭的`run_native_audio_source_poc`布尔输入。
- 只有显式手动选择该输入才运行Windows/Android Phase4D job；标准push/PR行为不变。
- Phase4D模式全局`contents: read`，跳过Android发布job和Windows artifact job；不使用Secret、
  不创建Release、不上传artifact。
- Action继续固定完整SHA；生成TLS材料前验证工具存在，结束时检查运行无artifact/Release。

## 验收与否决

必须同时满足：

1. 当前已跟踪文件和Git差异中不存在证书私钥、真实Token、音频二进制或用户路径。
2. Android debug Provider不可导出、无新增权限、release/production Manifest无Provider。
3. Windows与Android同一目标提交的受控HTTPS native成功case均完成load/play/seek/completed。
4. Android同一目标提交的`content://` native case成功；Windows明确记录not-applicable。
5. 401/403/404/429/5xx/timeout/TLS/offline映射为脱敏`DomainFailureCode`，日志不含URL/Header/原始异常。
6. 完整format、严格analyze、Flutter、Node、ZIP、生成代码/Schema零差异与Android/Windows Debug通过。
7. 专用运行artifact为0、Release为0，生产Bootstrap仍为`UnavailableAudioEngine`。

若自签名绕过影响默认生产路径、Header可能跨站泄露、任一平台native HTTPS失败，或Android
Provider进入release Manifest，本批失败并保持Phase4D打开。通过后仍不代表真实第三方API、实体扬声器、
MediaStore/SAF持久授权、后台、音频焦点、系统媒体会话或许可证闭环完成。

## 计划文件

- `lib/playback/network_playable_source_probe.dart`
- `lib/playback/media_kit_audio_backend.dart`
- `lib/playback/media_kit_audio_engine.dart`
- `android/app/src/debug/AndroidManifest.xml`
- `android/app/src/debug/kotlin/io/github/z_y_o_y_i/yymusic/NativeAudioPocProvider.kt`
- `integration_test/native_audio_sources_poc_test.dart`
- `integration_test/support/controlled_https_audio_server.dart`
- `tools/generate_native_audio_poc_tls.mjs`
- `.github/workflows/foundation.yml`
- 对应单元、结构、CI和报告文档
