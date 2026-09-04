# Phase 4C — Windows/Android 原生本地音频运行 POC 报告

2026-09-04。开始前已fetch并确认
`feat/media-kit-audio-poc@e1c50ca9e2477c4968ebb3526ccac6a6f2c4c223`与远端同步、工作树干净；
从该提交创建`feat/native-audio-local-poc`，未在main/master开发。范围与出口见
[计划](phase_4c_native_local_audio_poc_plan.md)。

## 当前实现

测试在运行时生成3秒、16kHz、PCM16单声道、低幅度方波WAV。固定输出为96,044字节，
SHA-256为`571edd11f9568729867f4a1db7b5f4318e3868024e41253f5c5ca4a09787d51e`。
仓库没有新增音频二进制、用户音乐或真实路径；文件只写入测试进程私有临时目录并在teardown删除。

Windows和Android运行相同的`integration_test/native_local_audio_poc_test.dart`：候选Engine创建后
load且不自动播放，观察duration；设置音量与速率后play并等待position推进；执行seek、pause，再从
接近末尾播放到completed；最后stop回到idle/zero并dispose。日志只输出平台、load/首进度/seek耗时、
duration和completed，不输出临时路径、URI、Header或插件错误。

生产`main.dart`、AppBootstrap、DependencyGraph与Shell均未改变，仍使用
`UnavailableAudioEngine`。本批不把集成测试接入产品，也不创建可下载APK。

## CI隔离

GitHub要求手动作业文件先存在于默认分支，因此本批复用已经注册的`foundation.yml`，增加默认关闭的
布尔输入`run_native_audio_poc`。只有显式传入`true`才运行两个native job；普通push/PR继续运行标准
三job，普通手动发布仍走原有路径。native模式会跳过带写权限的Android发布job，实际运行路径只有
全局`contents: read`的checks与两个native job。

Windows使用`windows-2025`；Android使用`ubuntu-24.04`、API36/default/x86_64/pixel_6与固定NDK，
Android Emulator Runner v2.38.0固定到完整提交
`a421e43855164a8197daf9d8d40fe71c6996bb0d`。两个job只执行测试，不上传artifact、不构建/发布APK、
不调用Release、不读取Secret。

## 本地门禁

| 检查 | 结果 |
| --- | --- |
| 生成器 | RIFF/WAVE/fmt/data、PCM/mono/16kHz/16-bit、96,044字节与固定SHA通过；duration/sample rate/frequency/amplitude非法值被拒绝 |
| Flutter | 149文件format 0变化；严格analyze 0问题；完整221项测试通过，含32张Windows宿主Golden |
| 仓库审计 | 31项Node、24/24 ZIP entry通过；无WebView、媒体二进制、下载API、生产候选接线或工作流写权限 |
| 依赖/生成 | `dart pub get --enforce-lockfile`通过；build_runner与Drift make-migrations后g.dart/v1快照零差异 |
| 本机Android Debug | 构建成功；279,083,994字节，诊断SHA-256 `91bee6ec8cc76c324bf009e011a9dd38658bdbbf3f7e32971489af604caa065e`；48资产逐字节匹配，v2单Debug签名有效 |

本机`flutter pub get`因Windows Developer Mode关闭而无法建立插件符号链接；同一锁文件使用
`dart pub get --enforce-lockfile`已成功复现，Android Debug也成功。由于远程环境无本机Android
模拟器且Windows C++工具链仍受UAC/Developer Mode限制，本机没有伪造原生运行结果。

## 云端状态

实现提交、Draft PR、标准foundation push/PR运行以及专用native POC运行尚待推送后填写。出口要求
同一实现提交的Windows和Android专用job均成功；任一失败时Phase4C保持打开。专用工作流不会产生
Release或可下载APK，许可证未闭合前也不触发普通foundation的手动发布路径。

## 证据边界与下一批

无头Windows runner和Android模拟器中的position/completed只证明候选native初始化、WAV解码、时钟、
状态及控制命令链工作，不证明扬声器可听、音质、实体Android设备、SMTC/MediaSession、音频焦点、
后台、耳机/蓝牙或设备切换。本批只覆盖应用私有本地文件；Android `content://`、持久SAF授权、
受控HTTPS/Header及失败矩阵进入Phase4D。native LICENSE/NOTICE链仍未闭合，因此即使本批双平台通过，
候选也不进入生产组合、不视为可发布。

## 主要文件

- `integration_test/native_local_audio_poc_test.dart`
- `integration_test/support/deterministic_pcm_wav.dart`
- `test/unit/deterministic_pcm_wav_test.dart`
- `.github/workflows/foundation.yml`
- `pubspec.yaml`、`pubspec.lock`
- `tools/foundation_architecture.test.mjs`
