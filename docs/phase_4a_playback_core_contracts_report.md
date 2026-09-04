# Phase 4A — 播放核心合同与唯一状态源报告

2026-09-04。开始前已 fetch，并确认
`feat/dev-fixture-bootstrap@e5072a04755e51c1242232e439b5963ca8cee737`
与远端同步、工作树干净；从该提交创建
`feat/playback-core-contracts`，未在 main/master 开发。范围与出口见
[计划](phase_4a_playback_core_contracts_plan.md)。

## 当前实际进度

本批完成 Phase 4 的第一段正式核心，不包含真实音频后端。`AudioEngine`不再直接发布应用
`PlaybackState`，而是只发布插件无关的`AudioEngineState`；唯一根级
`PlaybackController`把完整Track、短期来源、引擎事实、持久队列、随机/循环与媒体会话
合成为一份应用状态。三个Shell和Phase2播放器表面均未接入Fake或插件。

Phase4主出口尚未关闭：Windows/Android真实授权音频、受控HTTPS流、Seek、错误和系统媒体
会话仍须在后续POC通过。当前“本机Android构建成功”只证明Dart/runner可编译，不证明设备
扬声器播放、后台、焦点或媒体按键成功。

## 合同、状态与队列边界

1. `PlayableSource`覆盖Windows绝对文件路径、Android `content://`和无userinfo的HTTPS
   临时流；运行期Header允许交给适配器，但locator/Header在字符串输出中无条件脱敏，
   不进入数据库、Fixture或公开状态。
2. Engine与应用状态均覆盖idle/loading/buffering/ready/playing/paused/completed/error；
   `PlaybackState`另含currentTrack、position、buffered、duration、volume、playbackRate、
   shuffle、repeat、queue、outputDevice与安全failure，并验证时间/范围/错误一致性。
3. Controller用一个串行操作尾部协调resolve/load/transport/Seek/队列写入；Seek拒绝负值，
   已知时长时夹紧曲末，未知时长保持null。未知底层异常只映射到固定diagnostic ID。
4. QueueEntry身份独立于TrackRef；替换、末尾添加、下一首插入、移动、删除、清空、指定项、
   上一首/下一首均使用同一QueueSnapshot。删除另一个同曲目entry不中断当前播放；删除当前
   或清空才停止并清除当前Track。
5. 随机顺序按entryId生成一次遍历；repeat off到末尾保持completed，repeat all开始下一轮，
   repeat one只在自然completed时seek到0重播，不拦截手动next。
6. `QueueController`只委托给PlaybackController并返回`playback.state.queue`。AppBootstrap
   初始化时从正式CollectionRepository恢复队列，但不自动resolve/load/play。
7. `MediaSessionGateway`把Android MediaSession与Windows SMTC命令回调到同一Controller，
   并只接收项目Track/PlaybackState；辅助平台更新失败不能中断音频。

## 本地验证

| 检查 | 当前结果 |
| --- | --- |
| Phase 4A 定向 | 新增7项：三种来源/脱敏、八阶段与边界、load/状态/Seek/音量/速率/媒体回调、重复曲目队列、随机/repeat/自动完成、失败脱敏、持久队列恢复；全部通过 |
| 全量门禁 | lockfile严格复现；143个Dart文件format通过、严格分析0问题；214项Flutter含32张Windows宿主Golden、30项Node、ZIP 24全部通过；build_runner/make-migrations后g.dart与v1快照零差异 |
| 架构边界 | QueueController无第二份队列；UI/Shell不导入音频插件或播放层；默认Engine明确不可用；无WebView、下载/离线API、可播放Fixture、依赖/权限或Schema变更 |
| 本机 Android Debug | 默认生产入口构建成功，238,997,827字节，诊断SHA-256 `ea40ebd646300b0f14c1dcef9aef2971d19fba6da515e83b6f88c8e05bd66ab1`；48份资产匹配且无参考/凭据文件，包名/YYMusic/`allowBackup=false`正确，仅v2单Debug签名有效 |

## 云端与限制

实现提交`ec508dffda97262fc16f96a78901a91b058c6dbf`已推送；[Draft PR #17](https://github.com/Z-YO-YI/YYMusic/pull/17)
保持open/draft，head为`feat/playback-core-contracts`，base为`feat/dev-fixture-bootstrap`。
[push运行33845988715](https://github.com/Z-YO-YI/YYMusic/actions/runs/33845988715)、
[PR运行33846020650](https://github.com/Z-YO-YI/YYMusic/actions/runs/33846020650)与该实现提交的唯一
[手动运行33848236710](https://github.com/Z-YO-YI/YYMusic/actions/runs/33848236710)均为三个job
success；未对同一实现提交重复触发手动工作流。

[私有草稿Release](https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-271d9f07baf51fb6bb95)
标签为`ci-debug-33848236710-1`，target为完整实现提交，保持draft/prerelease且恰有
`YYMusic-debug.apk`、`SHA256SUMS`和`build-metadata.json`三项白名单资产。三资产下载到全新
受控临时目录复核：APK为190,735,487字节，SHA-256、metadata、SHA256SUMS与GitHub API
digest均为`3f95cea301d6710ac46a40a5fbfcd0d4561d91f310ca5d04506d5389a1272aa4`；48份资产逐字节
匹配且无参考/归档/凭据文件，Manifest确认包名、YYMusic与`allowBackup=false`，apksigner确认
仅v2且1个临时Android Debug signer。临时三文件与目录已删除，Release保留。

本机Windows仍因远程环境无法完成UAC/Developer Mode所需C++工具链配置，不声称本机Windows
构建或运行成功。GitHub Windows 2025编译也不等于真实音频输出、SMTC、睡眠/唤醒或设备切换
验收。当前APK仍使用临时Debug签名，不是正式Release包。

## 主要文件

- `lib/playback/playable_source.dart`
- `lib/playback/playback_source_resolver.dart`
- `lib/playback/audio_engine.dart`
- `lib/playback/audio_engine_state.dart`
- `lib/playback/playback_state.dart`
- `lib/playback/playback_controller.dart`
- `lib/playback/queue_controller.dart`
- `lib/platform/contracts/media_session_gateway.dart`
- `lib/app/dependency_graph.dart`
- `test/unit/playback_core_test.dart`
- `tools/foundation_architecture.test.mjs`

下一批进入 Phase4B真实backend最小POC与受控测试音频准备；在双平台结果、License/打包和错误
矩阵完成前不把候选插件称为正式实现，也不接正式Shell。
