# Phase 4L — HTTPS 原生验证报告

2026-09-05。实现提交 `8c4aa6ef88507326387ef118e49fd451e5345070`，分支
`codex/native-https-validation`；[Draft PR #28](https://github.com/Z-YO-YI/YYMusic/pull/28)
基于 `codex/android-native-source-validation@862f88e`，未合并。
开始前已 fetch/pull；上一批文档提交的 PR 33954532219 / push 33954530363 均已成功。

## 实际新增与修改

- 新增固定上游 HTTPS 夹具的限时/限额内存验证、SHA-256/长度与 Range 检查及3项单元测试。
- 新增 HTTPS 原生 load/非自动播放/position/duration/seek/pause/volume/rate/completed/stop/dispose 测试。
- 组合入口保留 Android 原来的 WAV/content URI，用例数为3；Windows 保留原 WAV，加 HTTPS 共2项。
- Windows Profile 诊断入口、结果白名单、构建元数据、归档/执行工具增加显式 HTTPS 模式。
  默认仍为原一项本地测试；模式、测试数量、1秒/3秒时长、夹具指纹及生命周期分别校验。
- CI 增加默认关闭的 `include_https_audio_poc`，非诊断模式拒绝该输入；standard/native/profile
  并发组隔离，同一模式仍取消旧运行。增加相关 CI/Node 负向门禁与 ADR-040。

主要文件：`integration_test/just_audio_native_https_poc_test.dart`、
`integration_test/just_audio_native_sources_poc_test.dart`、
`integration_test/support/pinned_https_audio_fixture.dart`、Windows probe 入口/结果/两个工具脚本、
`.github/workflows/foundation.yml`、三份单元测试、两份 Node 测试以及文档。
生产 lib、依赖、公共 API、Schema、Android/Windows runner 和权限未改动。

## 夹具边界

[ADR-040](architecture_decisions.md) 记录 AndroidX Media 的固定测试夹具与许可来源。
上游提交 `43e3af79dabb43a69badffbbdfa6d421a1cdb36c`，88,278 字节 PCM16/mono/44100Hz/1秒，
SHA-256 `1b35cc093f3d56732b19ff936c21b5bca8195135d63708f6c6488eba5803ddce`。
实际 HTTPS GET 返回200、Range 0–77返回206及精确 Content-Range；Dart 同一预检函数也已通过。

只在测试内存核验上游响应，不写音频文件，不把预检字节交给本地/字节流音源。
原生引擎直接读取固定 HTTPS URL；没有 Header/代理/TLS 例外或系统 CA 修改。
不提交或打包 WAV/Base64，不实现应用下载、缓存或来源配置。原来的本地3秒 WAV 不变。

## 本地验证

| 验证 | 结果 |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 161 文件0改动 |
| `flutter analyze --no-pub --fatal-infos` | 最终0问题；首次1项 import 排序已修正 |
| `flutter test --no-pub --reporter expanded` | 255/255，含32张 Windows Golden |
| CI 并发配置最后增量的单独测试 | 6/6 |
| `node --test tools/*.test.mjs` | 46/46 |
| 原ZIP/总指令身份 | ZIP24/24；主指令副本 SHA-256 一致 |
| build_runner / Drift make-migrations / 生成文件 Git diff | 成功、零差异 |
| 正式入口 Android Debug | 成功，48资产逐字节通过，v2单签名有效 |
| Android 三用例集成入口 Debug 编译 | 成功，48资产通过；随后恢复正式入口 |
| Dart 实际 HTTPS 指纹与 Range 预检 | 成功，仅内存读取 |
| 变更检查和常见凭据扫描 | 通过，无媒体/凭据/构建产物提交 |

恢复后的本地常规 APK 为230,987,069字节，SHA-256
`38fda801f85cbba7cbf4544bb92ae91b22de7796b4e147ad81c76852cf394c0f`。
生产代码未变，因此与上一批同哈希；不是新业务功能交付包。本机 Windows 无完整 C++ 构建环境，
由 GitHub 编译完整 Profile 包后，在本机真实端点验证，不将编译成功当作播放成功。

## GitHub 与 Windows 原生运行

以下四条运行均核对到上述完整实现 SHA，最终整体结果全部为 `success`：

| 运行 | 结果 |
| --- | --- |
| [标准 push 33955129003](https://github.com/Z-YO-YI/YYMusic/actions/runs/33955129003) | checks、Windows Debug、Android Debug 均成功 |
| [标准 PR 33955146253](https://github.com/Z-YO-YI/YYMusic/actions/runs/33955146253) | checks、Windows Debug、Android Debug 均成功 |
| [Android 原生 33955145543](https://github.com/Z-YO-YI/YYMusic/actions/runs/33955145543) | checks、Android API36 三项原生测试全部成功 |
| [Windows Profile 33955146934](https://github.com/Z-YO-YI/YYMusic/actions/runs/33955146934) | checks、完整 HTTPS 诊断构建成功 |

Android 原生 job `101277541759` 的完整日志经认证 API 读取，仅提取安全指标，不保存到仓库：

| Android 来源 | load | 首次进度 | seek | duration |
| --- | --- | --- | --- | --- |
| 本地 WAV | 793 ms | 46 ms | 11 ms | 3000 ms |
| Debug-only content URI | 26 ms | 171 ms | 7 ms | 3000 ms |
| 固定 HTTPS | 1270 ms | 107 ms | 6 ms | 1000 ms |

三项均报告 completed，日志明确 `+3: All tests passed!`；content 缺失来源失败、同引擎恢复和释放均通过。
HTTPS 夹具 SHA/Range 与实际播放、暂停、seek、停止和释放通过；所有来源 proxy/Header 均 false。
这是真实 Android Media3 后端在 API36 x86_64 模拟器的测试，不等同于手机扬声器听感或设备授权验收。

### Windows 本机真实进程

诊断 artifact `9966228383`，名称
`YYMusic-windows-audio-probe-8c4aa6ef88507326387ef118e49fd451e5345070`，24,760,836 字节，
保留一天，API 过期时间 `2026-09-06T08:32:33Z`。GitHub API digest 与独立下载 SHA-256 均为
`36dbafce60135caeedddf3895ba70a7c29d9a5fdcd5c4f3111ca16e708a44693`。
没有将 GitHub 认证转发至下载存储域；下载 ZIP 不进入版本管理。

`ValidateArchive` 已检查归档路径、链接/重复/体积、拒绝候选库和 SDK DLL 指纹。
`PrepareProfile -IncludeHttps` 核对 Profile 元数据、源码/原生精确提交、AOT 完整包以及 HTTPS 模式，
在两个新目录分别准备64项运行文件。没有混合旧引擎、旧 app.so、旧产物或已有测试结果。
本机两个真实 render endpoint、Audiosrv/AudioEndpointBuilder 运行，随后两次执行同一包：

| 本机运行 | 本地 WAV load / 首进度 / seek | HTTPS load / 首进度 / seek | 用例数 / 退出码 | 进程总耗时 |
| --- | --- | --- | --- | --- |
| `https-run-01` | 298 / 155 / 1 ms | 347 / 94 / 1 ms | 2 / 0 | 3710 ms |
| `https-run-02` | 260 / 157 / 1 ms | 330 / 91 / 1 ms | 2 / 0 | 3371 ms |

两次本地 duration 均3000 ms，HTTPS 均1000 ms；独立预检的夹具 SHA 和 Range 均通过。
两次均验证非自动播放、真实 position 推进、暂停、seek、volume/rate、completed、stop 和 dispose。
执行前后64项运行文件指纹未改变；只有新建的白名单结果和进程记录，原始日志仅留在忽略目录。
这不是主观听感、后台播放或正式应用接线证明。

本地诊断根目录为 `build/windows-audio-probe/https-run-01` 与 `https-run-02`。
归档位于 `build/github-artifacts/phase4l-8c4aa6e/YYMusic-windows-https-probe.zip`。
程序是自动执行两项测试后退出的 Profile 诊断入口，不是供用户听歌的 Windows 应用。

### 产物与发布边界

API 复核标准 push 产物1项（既有14天 Windows Debug），标准 PR 0项，Android 原生0项，
Windows Profile 1项（上述一天诊断包）。另外三个普通/原生构建在专用模式中按设计 skipped，
没有把 skipped 算作跨平台通过。Release 列表总数17，本批实现 SHA、分支和四个 run ID 匹配新增数均0。
没有发布候选应用 APK、提交媒体/原始日志，或扩大 Actions 权限。

最终文档整理期间再次完整运行 Flutter 255/255、Node 46/46、161文件格式零改动与严格 analyze。
这些结果和四条云端运行证明本批原生来源验证完成；本批报告之后的文档提交 CI 须独立核对，
不得把实现提交的运行冒充后续提交已通过。

## HTML 对照和后续

本批无 UI、图标、字体或 Golden 基线变更。App.tsx 的 NEW_ICON_SPRITE、账户文字替换和
POLISH_CSS/基础 HTML 合成指纹保持不变；Phase2 网页截图对照仍欠验收。
本批出口已完成：同一实现提交的 Android 三来源、Windows 两来源实际进程与标准双平台构建通过。
此批仅补网络原生播放，不证明任意 API/认证 Header、设备听感、后台、媒体会话或可用业务应用。
生产仍为 `UnavailableAudioEngine`；下一批先整理当前候选的最终决策与 NOTICE/许可展示，明确能力边界，
再接入共用 PlaybackController/生产生命周期。整体 Phase4 尚未完成，不跳到 Phase5或业务页面。
