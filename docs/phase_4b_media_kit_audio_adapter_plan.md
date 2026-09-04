# Phase 4B 开始 — media_kit 音频候选适配器与打包 POC

2026-09-04。开始前已 fetch，并确认
`feat/playback-core-contracts@3e52f94ff432b06011271cfde2d66f1caf1e8c99`
与远端同步、工作树干净；从该提交创建`feat/media-kit-audio-poc`，未在
main/master开发。

## 本阶段目标

- 以`media_kit 1.2.6`和`media_kit_libs_audio 1.0.7`作为尚未锁定的候选，新增只在
  playback适配层出现的真实Player封装。
- 把Windows绝对文件、Android `content://`与HTTPS临时流安全映射给候选后端；Header只在
  本次`open`调用中传递，不进入状态、日志、数据库或Fixture。
- 将playing/completed/position/duration/buffer/buffering/volume/rate/error组合回现有
  `AudioEngineState`八阶段，保持`PlaybackController`为唯一应用播放真相。
- 验证load不自动播放、play/pause/stop/seek/volume/rate与幂等释放；用项目自有Fake后端测试
  适配逻辑，不把Fake当成真实音频POC。
- 核对Dart包及Windows/Android native audio依赖的实际锁定版本、许可证文件、Android包体和
  GitHub Windows 2025编译结果。

## 已读取的来源

- Phase 0完整合成审计：基础HTML、完整`src/App.tsx`、`NEW_ICON_SPRITE`和`POLISH_CSS`；
  本批没有可见UI，仍不得回退到旧HTML或WebView。
- 主开发指令Phase 4、依赖规则、禁止下载/离线与固定阶段报告格式。
- `lib/playback`现有AudioEngine/State/PlayableSource/PlaybackController，根DependencyGraph
  和Phase4A测试/ADR。
- media_kit维护者的1.2.6官方安装/API文档：初始化必须先于Player；`open(..., play:false)`、
  文件/URL、HTTP Header、Seek、事件流、0–100音量与异步dispose。
- media_kit_libs_audio 1.0.7官方包页：audio-only聚合包、Android/Windows依赖与MIT包许可；
  native二进制的传递许可证仍以解析后的包内容和构建产物再次审计。

## 准备修改的文件

- `pubspec.yaml`、`pubspec.lock`
- `docs/architecture_decisions.md`、`docs/dependency_decisions.md`、
  `docs/audio_poc_plan.md`、`docs/test_matrix.md`、`docs/implementation_status.md`
- `tools/foundation_architecture.test.mjs`

## 准备新增的文件

- `lib/playback/media_kit_audio_backend.dart`
- `lib/playback/media_kit_audio_engine.dart`
- `test/unit/media_kit_audio_engine_test.dart`
- `docs/phase_4b_media_kit_audio_adapter_report.md`
- `docs/phase_4b_media_kit_audio_adapter_pr_draft.md`

## 风险与明确边界

- 本批只把候选后端放进可测试适配层，不在生产Bootstrap创建Player，也不接Shell/UI、系统
  MediaSession、后台服务、音频焦点、输出设备或历史写入；候选未正式选型。
- 不提交音频二进制、用户路径、content URI、可播放URL、凭据或缓存；不新增下载/离线API。
- Flutter单元测试验证的是适配逻辑，不证明native解码或扬声器输出。GitHub双平台Debug只证明
  打包/链接；Windows与Android真实本地音频、受控HTTPS、Seek时延和状态事件留给下一小批
  POC harness，结果未取得前Phase 4出口保持打开。
- 本机Windows C++仍受远程UAC限制；不得把Windows runner成功写成本机安装/运行成功。

## 本批出口条件

- 精确依赖和lockfile可复现，只有audio native libs，不混入video libs或额外平台权限。
- 适配器的来源、命令、状态、错误脱敏、并发关闭测试通过；插件类型不越过playback层。
- format、严格analyze、完整Flutter/Node/ZIP、生成代码/Drift快照和本机Android Debug通过。
- 实现提交推送后，GitHub push与PR三job均独立复核；Draft PR保持开放。因native二进制
  LICENSE/NOTICE链未闭合，本批明确不触发手动工作流、不创建包含候选库的新APK Release。
- 报告明确区分“候选适配/打包成功”和“真实双平台音频POC尚未完成”。
