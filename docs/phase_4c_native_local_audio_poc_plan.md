# Phase 4C 开始 — Windows/Android 真实本地音频运行 POC

2026-09-04。开始前已 fetch，并确认
`feat/media-kit-audio-poc@e1c50ca9e2477c4968ebb3526ccac6a6f2c4c223`
与远端同步、工作树干净；实现提交和证据提交的push/PR三job均已成功。从该提交创建
`feat/native-audio-local-poc`，未在main/master开发。

## 本阶段目标

- 运行时确定性生成一段短PCM WAV，不提交用户音乐、媒体二进制或路径，并验证RIFF头、长度与
  固定SHA-256。
- 用Flutter官方`integration_test`从真实Windows应用进程与Android模拟器创建
  `MediaKitAudioEngine`，执行load不自动播放、play、position推进、seek、pause、volume、rate、
  completed、stop与dispose。
- 记录平台、load/首个position/seek耗时和观测状态，但日志不得包含临时文件路径、URL、Header
  或插件原始错误。
- 新建只允许手动运行、只读权限的native POC工作流；Windows 2025和Android x86_64使用相同
  测试，不上传APK/Windows包、不创建Release。
- 保持生产`main.dart`、AppBootstrap、DependencyGraph和Shell继续使用
  `UnavailableAudioEngine`；本批结果不自动锁定正式backend。

## 已读取的来源

- 主开发指令Phase 4：Windows与Android POC必须先通过，PlaybackController保持唯一真相，
  不得出现Shell专属播放逻辑。
- Flutter官方integration test说明：`integration_test`来自Flutter SDK；Android/Windows均可用
  `flutter test integration_test/...`在所选设备运行。
- media_kit 1.2.6维护者文档与已解析源码：初始化先于Player，open可禁用自动播放，position、
  duration、completed、buffering、volume和rate均有真实事件流。
- ReactiveCircus Android Emulator Runner v2.38.0官方README；Action固定到完整提交
  `a421e43855164a8197daf9d8d40fe71c6996bb0d`，Android API/ABI/NDK使用显式版本。

## 准备修改/新增的文件

- `pubspec.yaml`、`pubspec.lock`
- `.github/workflows/foundation.yml`（新增显式`run_native_audio_poc`手动模式）
- `integration_test/native_local_audio_poc_test.dart`
- `integration_test/support/deterministic_pcm_wav.dart`
- `test/unit/deterministic_pcm_wav_test.dart`
- `tools/foundation_architecture.test.mjs`
- `docs/architecture_decisions.md`、`docs/audio_poc_plan.md`、`docs/test_matrix.md`、
  `docs/implementation_status.md`
- `docs/phase_4c_native_local_audio_poc_report.md`
- `docs/phase_4c_native_local_audio_poc_pr_draft.md`
- `README.md`、`CHANGELOG.md`

## 风险与边界

- CI模拟器或托管Windows可能没有真实扬声器；position与completed事件只能证明native
  初始化、解码、时钟和控制链实际运行，不证明用户可听输出、音质、焦点或设备切换。
- 本批Android仅播放应用私有临时文件，不冒充MediaStore `content://`或SAF授权通过；content
  URI、受控HTTPS/Header与失败矩阵留给下一小批。
- native LICENSE/NOTICE链仍未闭合；运行测试不等于允许发布。工作流必须`contents: read`，
  不上传产物、不调用`gh release`、不使用Secrets。
- Android模拟器存在宿主KVM/启动波动；明确timeout并保留失败日志，失败时不把Windows结果外推
  到Android，也不改用WebView或浏览器音频绕过。

## 本批出口条件

- WAV生成器确定、边界校验和单元测试通过；仓库没有新增音频二进制。
- 完整本地format/analyze/Flutter/Node/ZIP、lockfile、生成代码和Drift快照继续通过。
- 标准foundation push/PR三job通过。
- 同一实现提交的手动native POC工作流中，Windows真实运行测试与Android x86_64模拟器真实运行
  测试均成功；若任一未成功，本阶段保持打开且不得声称双平台本地音频POC通过。
- 报告明确记录运行号、目标SHA、平台、测量值、无Release和仍未验收的content/HTTPS/扬声器/
  许可证边界。
