# Phase 4B — media_kit 音频候选适配与原生打包报告

2026-09-04。开始前已 fetch，并确认
`feat/playback-core-contracts@3e52f94ff432b06011271cfde2d66f1caf1e8c99`
与远端同步、工作树干净；从该提交创建`feat/media-kit-audio-poc`，未在
main/master开发。范围与出口见[计划](phase_4b_media_kit_audio_adapter_plan.md)。

## 当前实际进度

本批实现Phase 4的候选适配层与native打包验证，不是正式后端选型。项目精确解析
`media_kit 1.2.6`、`media_kit_libs_audio 1.0.7`、Android audio 1.3.8和Windows
audio 1.0.9。只有`lib/playback/media_kit_audio_backend.dart`导入插件；
`MediaKitAudioEngine`只依赖项目自有backend seam与Phase4A的AudioEngine合同。

生产`main.dart`、AppBootstrap和DependencyGraph均未创建候选Player，默认仍为
`UnavailableAudioEngine`。因此本批不会让正式Shell、设计Fixture或开发数据突然变成可播放，
也没有把Fake单元测试或Debug编译写成真实音频输出证据。

## 适配合同

1. native backend在创建Player前调用`MediaKit.ensureInitialized()`，并把Player的playing、
   completed、buffering、position、duration、buffer、volume和rate汇总为插件无关快照。
2. Windows绝对路径转为file URI；Android `content://`与HTTPS URI原样交给Player。Header
   只允许网络来源在当前`open`调用中传递；`open`固定`play: false`。
3. 候选Engine把插件事实组合回idle/loading/buffering/ready/playing/paused/completed/error，
   在项目0–1音量与插件0–100音量之间换算，并保持0.5–2播放速率边界。
4. load、transport、Seek、音量与速率命令串行；dispose先拒绝新操作、等待已接受操作，随后
   取消订阅、释放native backend并关闭状态流，重复调用只执行一次。
5. 插件命令错误和异步错误都丢弃底层文字，仅发布固定`DomainFailureCode`与
   `audio.media-kit.*`诊断ID；运行期URL、Header及原生错误不会进入状态或异常文本。

## 依赖与原生分发审计

本批只加入audio聚合库，没有`media_kit_video`或`media_kit_libs_video`。Android插件构建脚本
从上游`libmpv-android-audio-build v1.1.8`获取四个固定JAR；本机解析结果如下：

| 上游JAR | 字节 | SHA-256 |
| --- | ---: | --- |
| arm64-v8a | 2,983,585 | `0481a64b5e246774da22573d7a4e67f9fb3d89a68630864d8819d3ff3a08bb09` |
| armeabi-v7a | 2,865,617 | `1bba852f5b7f0098c54ab8c3a945866d2b730b9e146b472a6ffaa80fc0dceae9` |
| x86_64 | 3,114,935 | `ddffa0465e2dbb42d52937dae08516dbe07c534d489e9ea995f36a02d31a7106` |
| x86 | 3,040,597 | `824deeee316dfa3085832c6308e2953425bd428ba7eeeefd59bb51101b7ce8b7` |

每个JAR只含对应ABI的`libmpv.so`与`libmediakitandroidhelper.so`，未发现LICENSE或NOTICE。
Windows插件CMake则固定下载`mpv-dev-x86_64-20230924-git-652a1dd.7z`。Dart/Flutter包装包
携带MIT文本，但这不能替代libmpv/FFmpeg及其编译选项、传递许可证、源码/替换方式与第三方
NOTICE核验。因此当前只记录工程事实，不给出法律结论；发布前必须由维护者补齐可审计的
原生分发清单并完成相应审核。

## 本地验证

| 检查 | 当前结果 |
| --- | --- |
| Phase 4B 定向 | 5项Fake backend测试通过：三类来源/open不自动播放、八阶段与transport、Seek/音量/速率、命令/异步错误脱敏、并发幂等释放和非法输入 |
| 全量门禁 | lockfile严格复现；format与严格分析0问题；219项Flutter含32张Windows宿主Golden、30项Node、ZIP 24全部通过；build_runner/make-migrations后g.dart与v1快照零差异 |
| 架构边界 | 插件只在单一playback backend文件导入；生产入口不创建候选；无video库、WebView、下载/离线API、可播放Fixture、额外项目权限或Schema变更 |
| 本机 Android Debug | 构建成功，279,083,792字节，诊断SHA-256 `f3026e694c597b83297405c6587d46dc2906aa422b471838796950f776c59dd8`；48份资产匹配，包名/YYMusic/`allowBackup=false`正确，仅INTERNET及生成的not-exported receiver权限，v2单Debug签名有效 |
| Android native内容 | APK三种Flutter目标ABI均只含libmpv与libmediakitandroidhelper；arm64为6,215,848/386,696字节，armeabi-v7a为5,648,496/286,812字节，x86_64为6,983,648/367,528字节 |

## 云端状态与发布边界

实现提交`b7e0b0f820f1f91f99db89d42cb7241edba4769d`已推送；
[Draft PR #18](https://github.com/Z-YO-YI/YYMusic/pull/18)保持open/draft，head为
`feat/media-kit-audio-poc`，base为`feat/playback-core-contracts@3e52f94`。
[push运行33853006353](https://github.com/Z-YO-YI/YYMusic/actions/runs/33853006353)与
[PR运行33853041607](https://github.com/Z-YO-YI/YYMusic/actions/runs/33853041607)均为三个job
success，分别独立完成checks、Android Debug与Windows Debug。

精确实现SHA只存在上述push与pull_request两次运行，workflow_dispatch为0；GitHub API也确认
没有目标为该SHA或`feat/media-kit-audio-poc`的新Release。GitHub Windows 2025成功补足了
本机受UAC限制而无法执行的Windows编译证据，但只代表依赖解析、链接和打包，不代表Windows
扬声器输出、SMTC、安装或设备切换通过。

本阶段没有触发`workflow_dispatch`，也没有创建包含候选native库的新APK Release。Phase4A的
既有草稿APK只对应旧实现提交，不能作为本批产物。Android/Windows真实文件/content/HTTPS
播放、Seek状态、错误、性能、后台/焦点/系统媒体会话与native许可证闭环仍未验收。

## 主要文件

- `lib/playback/media_kit_audio_backend.dart`
- `lib/playback/media_kit_audio_engine.dart`
- `test/unit/media_kit_audio_engine_test.dart`
- `pubspec.yaml`
- `pubspec.lock`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugins.cmake`
- `tools/foundation_architecture.test.mjs`

下一小批进入Phase4C：先形成许可明确、运行时生成的短音频测试材料与专用POC harness，再在
Windows和Android执行真实文件/content URI、受控HTTPS、Seek/状态/错误矩阵；若native分发
审核仍无法闭合，则用同一合同量化比较`just_audio`加Windows backend，不因本批编译成功就
跳过回退评估。
