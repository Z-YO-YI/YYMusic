# Phase 4F — just_audio 双平台原生运行 POC 计划

2026-09-05。开始前已fetch并确认
`feat/just-audio-native-poc@9b5558bd4ec7ae4ed708be7c50395e054d1673d4`与远端同步、工作树干净；
从该提交创建`feat/just-audio-native-run-poc`，不在main/master开发。Phase4E只关闭了候选适配、
单元合同与双平台Debug打包，本批必须取得真实Windows/Android进程中的解码、时钟和控制证据。

## 固定边界

- 生产`DependencyGraph`继续创建`UnavailableAudioEngine`；POC不得接入Shell、UI、数据库或正式入口。
- 只使用`JustAudioEngine`现有项目边界。创建时必须显式关闭`useProxyForRequestHeaders`，不得启动
  just_audio loopback代理、缓存、下载、离线保存或字节流音源。
- 测试音频继续由确定性Dart代码在运行时生成；仓库、artifact和Release不保存WAV或用户媒体。
- POC只在显式手动工作流输入为true时运行，继承全局`contents: read`，不使用Secret、不上传artifact、
  不构建或发布APK/Release。标准push/PR的checks与双平台Debug构建行为保持不变。
- URI、Header、文件路径和原始插件异常不得进入日志、状态、数据库或Fixture。日志只输出平台与计时数值。
- 本批不证明实体扬声器、后台播放、音频焦点、系统媒体会话、真实第三方服务或许可证分发闭环。

## 小批 A：本地 WAV

- 新增默认关闭的`run_just_audio_poc`布尔输入，以及Windows/Android各一个只读原生job。
- 两个平台均在测试进程临时目录生成3秒PCM16/mono/16kHz WAV，以`PlayableSource.localFile`加载。
- 必须覆盖load不自动播放、duration、volume/rate、play与position推进、seek、pause、completed、stop和
  dispose；每个异步等待都设置上限，总测试设置两分钟上限。
- Windows使用真实`just_audio_windows` WinRT MediaPlayer，不添加伪时钟或media_kit无头sink。
  若GitHub runner没有可工作的媒体时钟，必须如实记为平台失败，不能用Fake或仅构建替代。

## 小批 B：无 Header HTTPS 与 Android Content URI

- 在小批A的同一默认关闭只读路径追加两平台无Header HTTPS，以及Android `content://`原生运行。
- HTTPS不得使用透明代理、关闭生产TLS验证或把不可信证书策略注入正式路径。测试夹具必须能被平台原生
  TLS栈正常验证；若不能建立可复核且稳定的受控来源，该case保持未关闭而不是退回HTTP或跳过证书验证。
- Android复用仅存在于debug source set、不可导出且只读的`NativeAudioPocProvider`；Windows明确把
  `content://`记录为not-applicable，不伪造成功。
- Header能力不在本批扩大：Android和Windows均以`supportsRequestHeaders: false`运行，无Header来源才可
  进入插件；带Header输入继续在插件调用前失败关闭。Windows认证Header策略留给独立设计审计。

## CI 与结构门禁

- `windows-debug`和`android-debug`在手动POC模式下必须跳过，避免产生既有Windows artifact或Android
  draft Release；普通push/PR仍运行完整标准三job。
- checkout、Flutter、Java和emulator action继续固定完整SHA。专用job不得声明`contents: write`，不得
  出现`upload-artifact`、`gh release`、APK/AAB构建或Secret引用。
- 单元与Node结构测试锁定默认关闭输入、双平台精确job数、集成测试入口、无代理创建参数、无二进制夹具、
  无生产接线及无下载/缓存API。
- 提交前运行format、严格analyze、完整Flutter测试、Node结构测试、ZIP逐entry校验、生成代码/Schema
  零差异和Android Debug构建。Windows本机构建若仍受Developer Mode/UAC阻断，以GitHub标准构建为证据。

## 阶段出口

Phase4F只有在同一目标提交同时满足以下条件后才可关闭：

1. Windows与Android本地WAV真实native job均通过，并有duration、position、seek、completed计时证据。
2. Windows与Android无Header HTTPS真实native case均通过，Android `content://`真实native case通过。
3. 专用工作流整体成功且artifact为0、Release为0；标准checks、Windows Debug、Android Debug也成功。
4. 生产仍为`UnavailableAudioEngine`，没有代理、TLS绕过、WebView、缓存、下载、音频二进制或新增权限。
5. 依赖与许可证事实无漂移，所有错误和日志保持脱敏。

小批A成功只关闭本地文件运行链，不代表Phase4F关闭。任一平台无法推进真实时钟、TLS来源不可复核、
ContentProvider进入main/profile或POC产生发布产物，均必须保留为明确缺口。

## 预计主要文件

- `integration_test/just_audio_native_local_poc_test.dart`
- `.github/workflows/foundation.yml`
- `test/unit/ci_configuration_test.dart`
- `tools/foundation_architecture.test.mjs`
- `docs/phase_4f_just_audio_native_poc_report.md`
- `docs/phase_4f_just_audio_native_poc_pr_draft.md`

