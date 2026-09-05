# Phase 4H — 移除被拒绝的 media_kit 活动候选计划

2026-09-05。开始前已确认`feat/media-kit-license-closure@ad1774c95c1760fabb23488f61be9f352fad5674`
与远端同步，且该提交的push运行33944119640和PR运行33944122330均完成checks、Windows Debug、
Android Debug并成功；从该提交创建`refactor/remove-media-kit-candidate`，不在main/master开发。

Phase4G已经证明当前`media_kit_libs_audio`原生发布链无法满足YYMusic的可复核分发门禁。继续让这些
未获批准的SO/DLL进入每个Debug包既增加约89 MB Android体积，也会让后续误发风险持续存在。本阶段只
移除被拒绝候选及其活动POC入口，保留Git历史、Phase4B—4D报告和Phase4G原始证据；不把`just_audio`
提前标记为正式backend，也不声称Phase4双平台出口已关闭。

## 固定边界

- 从`pubspec.yaml`/lockfile/生成的平台注册中移除`media_kit`、`media_kit_libs_audio`及只由它们带入的包。
- 删除活动`lib/`中的media_kit适配器、对应单元/集成测试和已经完成历史使命的四个media_kit专用CI job；
  不删除Git历史，不改写Phase4B—4D运行记录。
- Android debug-only Provider、受控TLS生成器和通用HEAD探针可由后续`just_audio`来源测试复用，不在本批
  因旧调用方移除而连带删除。
- Phase4G manifest转为“历史候选已拒绝且活动依赖为0”的失败关闭状态；仍不创建
  `assets/legal/media_kit`，不把下载的JAR/SO/DLL/7z或源码clone提交仓库。
- 生产`DependencyGraph`继续创建`UnavailableAudioEngine`。不实现下载、缓存、离线保存、WebView、
  新权限、真实第三方源、后台服务、SMTC/MediaSession或可发布Release。

## 小批 A：活动依赖与代码边界

1. 先用引用扫描列出所有media_kit import、类名、测试、workflow输入/job和生成插件注册。
2. 移除直接依赖并由Dart解析器重建lockfile；检查被删除的传递包，不能误删`just_audio`共享依赖。
3. 移除活动适配器/测试/专用job并更新架构测试：`lib/`、`integration_test/`、工作流和生成平台注册都不得
   再引用media_kit。
4. 更新Phase4G审计器，使其验证历史清单仍完整、活动依赖为0、生产仍不可用，并用反向测试拒绝重新引入。

## 小批 B：双平台打包与体积证据

- 本机重建Android Debug，逐ZIP entry确认`libmpv.so`和`libmediakitandroidhelper.so`为0，48项正式
  SVG/字体/许可证资产仍逐字节一致，Manifest无新增权限，v2单Debug签名有效。
- 对比Phase4G的279,085,047字节基线并记录新体积；体积下降只是移除证据，不代表功能完成。
- 目标提交GitHub标准push/PR必须完成checks、Windows Debug和Android Debug。下载push的Windows portable
  artifact并确认`libmpv-2.dll`、media_kit插件DLL及注册引用均为0；PR artifact应为0、匹配Release为0。
- 运行format、严格analyze、完整Flutter/Node/ZIP、build_runner、Drift迁移与生成零差异；测试数量减少必须
  只来自已拒绝media_kit适配器的5项Fake测试，不得静默删除其他回归。

## 出口

1. 活动源码、依赖、lockfile、生成注册和CI中media_kit引用为0，历史报告/manifest保留。
2. Android APK与GitHub Windows bundle均不再携带media_kit原生二进制。
3. `just_audio`依赖、隔离适配器和Phase4F失败证据保持不变；生产仍为Unavailable。
4. 本地门禁与目标提交GitHub三任务通过，无新Release、Secret、WebView、下载/离线API或新增权限。

完成本阶段后，Phase4仍保持未关闭。后续应在有真实播放端点的Windows环境继续`just_audio`原生验收；
在此之前可准备其完整AndroidX/WinRT发行NOTICE清单，但不能进入Phase5或正式生产接线。
