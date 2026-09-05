# Phase 4G — media_kit 原生分发审计报告（失败关闭）

2026-09-05。开始前已fetch并确认
`feat/just-audio-native-run-poc@4703c52`与远端同步、工作树干净；从该提交创建
`feat/media-kit-license-closure`，未在main/master开发。审计范围与出口条件见
[计划](phase_4g_media_kit_redistribution_plan.md)，完整证据见
[分发清单](phase_4g_media_kit_redistribution_inventory.md)。

## 本批完成内容

- 对lockfile中的四个相关包、包内LICENSE、Android Gradle与Windows CMake记录字节数和SHA-256。
- 固定Android v1.1.8四个JAR及八个SO，确认GitHub release SHA-256、本地JAR与APK三ABI字节一致。
- 固定Windows 2023-09-24归档及DLL，确认归档DLL与Phase4C GitHub Windows Debug bundle逐字节一致。
- 从实际SO/DLL提取并哈希FFmpeg/mpv配置，确认两端都关闭GPL/nonfree并报告LGPLv3+模式。
- 追溯上游tag、commit、依赖版本、构建workflow和历史脚本；明确记录Android helper未固定与Windows
  构建时patch/命令/cache不可恢复，未以最新master代替历史来源。
- 新增`inventory-only`机器清单、确定性审计器和四项反向测试。任何直接改为approved、删除阻断、
  篡改APK→JAR映射或接入生产都会失败。

## 为什么没有生成应用许可证 assets

计划允许在义务完整时建立`assets/legal/media_kit/`。实际审计发现两个平台都缺少可复核的完整来源/
构建链和发行材料；此时复制少量MIT/LGPL文本会制造“已经合规”的假象。因此只在
`docs/legal/media_kit/`保存失败关闭清单，`pubspec.yaml`不打包该目录，机器测试同时拒绝
`assets/legal/media_kit`出现。下载的原生文件和源码clone只留在Git忽略的本地审计目录。

## 本地质量门

| 检查 | 结果 |
| --- | --- |
| 原生证据 | Android 4/4 JAR、8/8 JAR SO、APK 6/6 SO；Windows 7z与DLL强哈希、DLL与Phase4C bundle一致 |
| 审计门禁 | 独立CLI通过；4项正/反向测试通过；全量Node 35/35通过 |
| Flutter | 152文件format零变化；严格analyze 0问题；完整232/232测试通过，含32张Windows宿主Golden |
| 生成/Schema | `build_runner`与`drift_dev make-migrations`成功，g.dart/v1快照零差异 |
| Android Debug | 构建成功，279,085,047字节，SHA-256 `bba16856f7cdbc3c909172cafa75ee07c345067cb50f66dcc6cfe21e9adbf601` |
| APK/参考源 | 48项字体/许可/SVG逐字节匹配；参考/私密文件为0；原ZIP 24/24 entry逐字节通过 |

## 出口结论

Phase4G的“审计并形成可执行结论”已完成，但“解除`media_kit`发布许可证阻断”的条件失败，所以
候选保持不可发布、不可生产接线。Windows最严重：实际DLL配置与最近历史脚本相反，构建时自定义命令和
cache不可恢复，静态组件revision/patch不完整；Android虽大部分依赖可固定，helper仍来自可变main，且
JAR不含任何分发材料。两个平台都没有获批准的逐组件NOTICE、对应源码与重新链接方案。

生产`DependencyGraph`继续创建`UnavailableAudioEngine`；本批没有WebView、下载、离线保存、网络权限、
Secret、用户媒体、发布APK/AAB或正式播放器接线。后续若继续该候选，必须自行从不可变来源重建native
bundle并保留完整patch/构建日志/源码与发行材料；也可继续推进与播放器选型解耦的REST来源适配和业务层，
但不能跨过本门禁发布当前media_kit依赖包。

## 主要文件

- `docs/legal/media_kit/manifest.json`
- `docs/legal/media_kit/README.md`
- `tools/media_kit_redistribution_audit.mjs`
- `tools/media_kit_redistribution_audit.test.mjs`
- `tools/foundation_architecture.test.mjs`
- `docs/phase_4g_media_kit_redistribution_inventory.md`
