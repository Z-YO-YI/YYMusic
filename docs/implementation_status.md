# 实施状态

更新：2026-09-04。用户要求持续开发并同步Windows，Android APK仍由GitHub构建。Phase 3已按主指令出口关闭；Phase4A已完成正式播放/来源/媒体会话合同、唯一PlaybackState、持久队列/随机/循环算法与本地及GitHub双平台构建验证。真实Windows+Android音频backend POC尚未执行，不能把Fake测试或编译通过称为播放通过。

| 阶段/能力 | 状态 |
| --- | --- |
| Phase 0 输入身份、源码审计、合成与映射 | 已形成可复核产物，结果见 phase_0_report.md |
| Phase 1 Flutter 工程骨架 | 已实现路由/DI/三个Shell/runner/测试/CI；GitHub Android/Windows Debug已通过，本机Windows仍待UAC，见phase_1_report.md及ci_reference_audit_fix.md |
| Phase 2A Android设计基础 | 已接入主题/字体/44SVG/首批控件及原生预览，见phase_2_android_report.md |
| Phase 2B Android导航与控件 | 手机/平板导航已驱动路由，Slider和七种Artwork占位已加入Gallery；见phase_2b_android_report.md |
| Phase 2C Android输入与选择 | SearchField、SegmentedControl、Toggle及Gallery已实现/测试；见phase_2c_android_report.md |
| Phase 2D Android内容组件 | AlbumCard、TrackTile及Gallery Fixture已实现/测试；见phase_2d_android_report.md |
| Phase 2E Windows导航基础 | 42工具区、240/72侧栏、1440/1024/840布局、跨平台Gallery及Windows Chrome Fixture已实现/测试；见phase_2e_cross_platform_report.md |
| Phase 2F 跨平台播放器表面 | Mini64与Desktop88/76受控组件、Android/Windows Gallery Fixture已实现；真实音频和正式Shell接线不在本阶段，见phase_2f_player_surfaces_report.md |
| Phase 2G 跨平台弹层原语 | ContextMenu/Dialog/BottomSheet/Toast及Android/Windows Gallery Fixture已实现；业务Overlay编排、路由、锚定、计时器和真实动作不在本阶段，见phase_2g_overlay_primitives_report.md |
| Phase 2H 跨平台状态原语 | ThemeSwatch/EmptyState/ErrorBanner/Skeleton及Gallery Fixture已实现；真实异步状态、重试、Repository和假数据均不在本阶段，见phase_2h_state_surfaces_report.md |
| Phase 2I 跨平台集合卡片 | SourceCard/PlaylistCard及Gallery Fixture已实现；来源连接、真实计数、歌单Repository/Create流程和持久化均不在本阶段，见phase_2i_collection_cards_report.md |
| Phase 2J 跨平台队列与歌词原语 | QueueTile/LyricsLine/LyricsPlayerDock及Gallery Fixture已实现；队列算法、Seek、LRC、自动滚动、持久化和正式歌词页均不在本阶段，见phase_2j_queue_lyrics_primitives_report.md |
| Phase 2 后续组合及视觉对照 | 通用组件清单已完成；正式业务页组合、网页对照和设备性能待验 |
| Phase 3A Domain合同 | Track/Collection/Lyrics/Source模型、显式LoadState/错误分类、四类Repository及安全凭据Gateway已实现；无数据库或生产接线，见phase_3a_domain_contracts_report.md |
| Phase 3B Drift Schema/Migration | 17张表、10索引、v1创建/审计/空队列状态、外键/约束、Schema快照和后台文件打开已实现；不接App启动，见phase_3b_database_schema_report.md |
| Phase 3C LibraryRepository | Track/Album/Artist双向映射、事务upsert、分页/watch/可用性及脱敏失败已实现；不接App启动，见phase_3c_library_repository_report.md |
| Phase 3D CollectionRepository | 歌单/条目、收藏、最近20首历史和可重复TrackRef队列已用Drift事务持久化；不接App启动，见phase_3d_collection_repository_report.md |
| Phase 3E LyricsRepository | 完整TrackRef歌词缓存、plain/synchronized双语严格JSON、upsert/remove与脱敏失败已实现；不解析LRC/联网/接App启动，见phase_3e_lyrics_repository_report.md |
| Phase 3F MusicSourceRepository | 公开配置/credentialRef严格JSON、确定watch、稳定身份/内置删除保护与引用保留已实现；不接安全存储/网络/App启动，见phase_3f_music_source_repository_report.md |
| Phase 3G 安全凭据Gateway | Android/Windows安全存储适配器、192位随机引用、规范载荷、碰撞保护、限额和日志脱敏已实现；不接数据库、网络、UI或App启动，见phase_3g_secure_credential_gateway_report.md |
| Phase 3H 数据引导与Dev Fixture | Android/Windows生产空库组合、四Repository/安全Gateway根接线、独立内存HTML Fixture及脱敏Bootstrap状态已实现；默认入口无Fixture，见phase_3h_dev_fixture_bootstrap_report.md |
| Phase 3 后续来源/状态 | 主指令Phase3本地出口已满足；REST Adapter、来源凭据事务与业务Controller按后续阶段分批交付 |
| Phase 4A 播放核心合同 | 完整八阶段Engine/Playback状态、脱敏PlayableSource、唯一Controller、持久队列/随机/循环/自动下一首、MediaSession接口已实现；本地门禁与目标提交GitHub三类三job/草稿APK复核完成，见phase_4a_playback_core_contracts_report.md |
| Phase 4B 双平台音频 POC | 未开始真实后端；本地授权Fixture、受控HTTPS流、双平台Seek/状态/错误及MediaSession实现仍待验 |
| 后续页面、歌词、导入、来源、平台集成 | 未开始 |
| GitHub APK交付 | Phase4A ec508df的唯一手动运行33848236710创建私有草稿Release；190735487字节APK的三资产、metadata、SHA256SUMS、API digest、48份包内资产、Manifest及v2单签名已独立复核 |
| 浏览器参考截图 / Computed Style | 未运行：file: 导航被安全策略阻止 |
| Flutter format/analyze/test | Phase4A 143文件格式通过、严格分析0问题、完整214项含32张原生Golden全部通过；7项播放合同/Controller新测试通过 |
| Windows / Android Debug构建 | Phase4A本机Android Debug通过；ec508df的GitHub push/PR/手动运行均完成Windows/Android Debug，本机Windows C++工具链仍受UAC限制 |

## 保留的验收缺口与后续边界

1. 已执行安全归档：13个旧原型文件移入archive/sonic_gallery，指纹一致，f96197b保存；根lib是新骨架，不再是旧代码。
2. 用户已批准补足工具链；Android命令行工具/API36/35、NDK及项目要求的CMake已安装，Windows C++安装等待UAC确认。GitHub Windows2025/Android的Phase3H Debug构建均已成功，但云端成功不等于本机Windows构建或安装验收。未批量接受所有Android许可。
3. Phase4A没有添加音频依赖；`media_kit`与`just_audio`+Windows backend仍须用同一合同完成双平台POC后才能选择。
4. 已建立实时平台分类、三个Shell和根依赖；Windows Shell现有设计导航与跨平台Gallery，播放器、弹层、状态、队列及歌词组件仅存在于明确标注的Fixture，窗口Gateway、业务Overlay Manager、Inspector业务与正式播放器接线仍未实现。业务页面未实现，不把设计预览当成音乐业务交付。
5. 为后续视觉验证准备获准且可访问的预览环境；遵守 Browser 技能边界，不绕过本轮 file: 拒绝。参考 screenshot 与 Flutter Golden 必须分别记录。

## 仓库边界

开发分支：feat/playback-core-contracts，基于已拉取并同步的feat/dev-fixture-bootstrap@e5072a0。未在main/master直接开发；旧原型保留于归档提交。本批只增加播放核心合同/算法、根生命周期、测试与文档，依赖和Drift v1 Schema不变。实现提交ec508df已同步远端，Draft PR #17保持open/draft。

此前GitHub连接器404的历史边界见Phase2C报告；用户明确授权后，临时API访问可读取本仓库运行和PR，不修改账号权限。Phase3H Draft PR #16与APK证据仍有效但只对应`27dd76c`；Phase4A Draft PR #17与新APK证据只对应`ec508df`。
