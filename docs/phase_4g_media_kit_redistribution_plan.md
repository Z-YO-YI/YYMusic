# Phase 4G — media_kit native 分发与许可证闭环计划

2026-09-05。开始前已fetch并确认
`feat/just-audio-native-run-poc@4703c52`与远端同步、工作树干净；从该提交创建
`feat/media-kit-license-closure`，不在main/master开发。Phase4F因Windows托管机与当前远程会话均无播放端点
而保持未关闭；本批不把该环境缺口改写为`just_audio`功能失败，也不降低其验收条件。

## 目标与固定边界

- 只审计当前lockfile实际解析的`media_kit 1.2.6`、`media_kit_libs_audio 1.0.7`、Android audio
  1.3.8与Windows audio 1.0.9，以及它们真正打包的native产物。
- Android固定追溯`libmpv-android-audio-build v1.1.8`四个JAR；Windows固定追溯
  `libmpv-win32-audio-build 2023-09-24`与`mpv 652a1dd`归档。版本、commit、构建参数和文件哈希必须来自
  包脚本、GitHub release/API、对应构建仓库或实际产物，不能用最新master替代历史构建。
- 生产`DependencyGraph`继续创建`UnavailableAudioEngine`。本批不接Shell/UI、后台服务、SMTC、
  MediaSession、真实第三方来源或正式播放器，也不触发候选APK Release。
- 不提交下载的JAR、DLL、SO、源码归档或用户媒体；只提交必要的许可证/NOTICE文本、来源清单、哈希、
  自动核验脚本和报告。临时下载材料只能留在Git忽略目录。
- 不给出法律意见。若历史二进制无法映射到对应源码/构建配置，或许可证义务不能形成可执行发布方案，
  结论必须是候选仍被阻断，不能以wrapper的MIT许可证代替传递native依赖。

## 小批 A：历史构建溯源

- 从本机Pub缓存记录四个直接相关包的pubspec、LICENSE、Android Gradle与Windows CMake指纹。
- 通过上游固定tag/release/commit读取Android与Windows构建脚本、submodule/依赖版本、patch及编译选项。
- 对实际Android Debug APK中的各ABI`libmpv.so`/`libmediakitandroidhelper.so`和GitHub Windows Debug
  artifact中的`libmpv-2.dll`记录文件名、尺寸、SHA-256；不得只记录下载归档的MD5。
- 建立“产物 → 上游release → 构建commit → mpv/FFmpeg及其他启用组件”可复核链。任何未知项单独列为阻断。

## 小批 B：许可证与发布材料

- 按实际启用组件收集原始许可证文本和版权/NOTICE；禁止复制与本构建无关的整套依赖列表来掩盖未知项。
- 明确区分media_kit wrapper MIT、mpv LGPL/GPL构建模式、FFmpeg配置许可及其他静态/动态依赖。
- 为Android与Windows分别说明动态链接、替换/重新链接、对应源码获取、构建脚本/patch提供和反向工程限制
  处理策略；如果现有打包方式无法满足策略，保持失败关闭。
- 形成机器可读manifest和确定性校验脚本，检查许可证文件字节、来源URL/commit、native哈希覆盖和禁止项。
  许可证材料若进入应用assets，必须同时验证APK/Windows bundle确实包含且与源文件一致。

## CI、测试与出口

- 标准push/PR继续运行checks、Windows Debug与Android Debug；审计不得新增Secret、网络权限、下载/离线API、
  WebView或工作流写权限。审计脚本本地不执行不固定的远程代码。
- 提交前运行format、严格analyze、完整Flutter测试、Node全量审计、ZIP逐entry校验、生成代码/Schema零差异、
  Android Debug构建及签名/资产核验。Windows bundle内容以目标提交的GitHub标准构建artifact复核。
- 只有当两个平台全部native产物都有对应源码与构建配置、实际许可证/NOTICE覆盖完整、发布者可执行的
  LGPL/第三方履约方案可复核、应用包内材料验证通过，才可解除`media_kit`许可证阻断。
- 解除许可证阻断仍不自动完成生产接线：正式backend选择、实体设备可听输出、生命周期和平台媒体能力需按
  后续独立阶段验证。任何未知native组件、不可复现映射或缺失文本都会使Phase4G保持未关闭。

## 预计主要文件

- `docs/phase_4g_media_kit_redistribution_inventory.md`
- `docs/phase_4g_media_kit_redistribution_report.md`
- `docs/phase_4g_media_kit_redistribution_pr_draft.md`
- `docs/legal/media_kit/`（若审计失败，仅保存`inventory-only`阻断清单）
- `assets/legal/media_kit/`（仅在完整义务可关闭时创建；本次不得用不完整材料占位）
- `tools/media_kit_redistribution_audit.mjs`
- `tools/media_kit_redistribution_audit.test.mjs`
- `docs/dependency_decisions.md`
- `docs/architecture_decisions.md`
- `docs/implementation_status.md`
