# Phase 4E — just_audio + Windows WinRT 备用候选适配/打包 POC

2026-09-05。开始前已fetch并确认
`feat/native-audio-content-network-poc@3da2f618ea6de79ece0c885c9bc7a435b509b24f`与远端同步、工作树
干净；该提交的push运行33880462282与PR运行33880464921均整体成功，Phase4D Draft PR #20保持
open/draft。从该提交创建`feat/just-audio-native-poc`，不在main/master开发。

状态：**已关闭**。修复提交`a2b517b3`的标准PR运行33936726367与push运行33936724989均完成
checks、Windows Debug和Android Debug；没有workflow_dispatch或新Release。push按既有策略只保留14天
Windows Debug portable artifact，未生成候选APK Release。

## 背景与决策边界

`media_kit`候选已经通过Windows/Android本地WAV、双平台受控HTTPS及Android `content://`原生POC，
但当前Windows audio package指向已归档的旧libmpv二进制仓库，Android JAR本身也不包含完整第三方
NOTICE。这个事实不构成法律结论，但在可复核的源码、构建配置、许可证文本和分发义务闭环前，不能把
它接入生产或发布。

本批只验证备用候选：`just_audio 0.10.6`加`just_audio_windows 0.2.3`。前者为Android正式实现，
后者使用Windows WinRT MediaPlayer且包声明MIT。所选Windows实现的能力表明确不支持直接请求Header，
因此不能把`just_audio`顶层聚合能力表中的Windows Header标记直接当成本项目结论。

## 本批范围

- 精确解析上述两个版本，不升级Flutter或既有依赖；记录完整lockfile、许可证文件和原生依赖事实。
- 新增项目自有`JustAudioPlayerBackend`边界，只有一个playback文件可导入`package:just_audio`；插件类型
  不进入Domain、Controller、UI、Shell或生产组合。Header能力必须由创建方显式声明，未声明时在插件调用前失败关闭。
- 新增`JustAudioEngine`候选，映射本地文件、Android `content://`、HTTPS、状态、位置、缓冲、时长、
  音量、速率、completed和脱敏错误；`load`不得自动播放。
- 使用可注入Fake backend验证串行命令、三类来源、状态合成、参数边界、异常脱敏与幂等释放。
- 运行Android/Windows Debug构建，核对Manifest权限和新增原生内容；只证明解析/打包，不冒充运行。
- 生产`DependencyGraph`继续创建`UnavailableAudioEngine`；不修改正式Shell、数据库或UI。

## Header与网络约束

- Android候选仅允许经后续native POC确认的平台原生Header路径，不启用透明缓存或下载；本批不预先把能力标记为可用。
- `just_audio_windows`不支持直接Header。本批不得静默丢弃Header，也不得把带凭据URL写入日志。
- 若后续Phase4F评估瞬时loopback relay，必须只绑定loopback、使用不可预测会话能力、支持Range、边读边转发、
  不写磁盘、不缓存、不接受任意目标，并在dispose时关闭全部socket；否则带Header的Windows来源判定不支持。
- 本批不实现relay，不声称Windows认证流可用；无Header HTTPS和本地文件仍可进入后续native POC。

## 验证矩阵

| 门禁 | 通过条件 |
| --- | --- |
| 依赖 | `flutter pub get --enforce-lockfile`可复现；版本与许可证清单精确，现有依赖不漂移 |
| 隔离 | `package:just_audio`只出现在单一backend文件；生产入口和Shell不导入候选 |
| 来源 | Windows绝对路径转file URI；Android content URI原样；HTTPS Header要么显式支持并瞬时转发，要么在插件调用前失败关闭 |
| 状态 | idle/loading/ready/buffering/playing/paused/completed/error由同一snapshot合成 |
| 控制 | play/pause/stop/seek/volume/rate串行；非法值在插件调用前拒绝 |
| 安全 | 原始URL、query、Header、插件异常不进入DomainFailure、日志、Drift或Fixture |
| 生命周期 | dispose等待已接收工作，拒绝新工作，只释放一次 |
| 构建 | Android/Windows Debug通过；无新增存储/媒体权限，无手动候选APK Release；普通push仅允许既有14天Windows Debug审查artifact |

## 失败与出口

版本无法稳定解析、Windows实现不能编译、插件类型越界、Header被静默丢弃、增加下载/离线持久化、
错误泄漏敏感内容或生产入口创建候选，任一发生即否决本批。通过只表示备用适配与打包可行；Phase4F仍须
在Windows/Android native进程运行本地WAV、无Header HTTPS、Android content URI，并单独决定Windows
认证Header策略。正式后端选择还需许可证/分发审计和实体设备生命周期证据。

## 预计主要文件

- `pubspec.yaml`
- `pubspec.lock`
- `lib/playback/just_audio_backend.dart`
- `lib/playback/just_audio_engine.dart`
- `test/unit/just_audio_engine_test.dart`
- `test/unit/ci_configuration_test.dart`
- `tools/foundation_architecture.test.mjs`
- `docs/dependency_decisions.md`
- `docs/architecture_decisions.md`
- `docs/phase_4e_just_audio_candidate_report.md`
- `docs/phase_4e_just_audio_candidate_pr_draft.md`
