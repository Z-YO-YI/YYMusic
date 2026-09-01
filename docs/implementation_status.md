# 实施状态

更新：2026-09-01。用户要求持续开发并同步Windows，Android APK仍由GitHub构建。当前推进到Phase2I：受控SourceCard、PlaylistCard及跨平台Gallery Fixture已完成本地验证，GitHub双平台构建与本批APK复核待实现提交后执行。这不是完整客户端或整个Phase2已完成。

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
| Phase 2 后续组件及视觉对照 | 更多基础组件及业务页未实现；网页对照和设备性能待验 |
| Phase 3 Domain/数据库/状态 | 未开始；只有边界决策 |
| Phase 4 双平台音频 | 仅 POC 计划；没有真实播放验证 |
| 后续页面、歌词、导入、来源、平台集成 | 未开始 |
| GitHub APK交付 | 9f71d14的运行33469832392完成编译、验签、资源核验及草稿Release三资产下载复核；见phase_2h_state_surfaces_report.md |
| 浏览器参考截图 / Computed Style | 未运行：file: 导航被安全策略阻止 |
| Flutter format/analyze/test | 85文件格式无变更、严格分析0问题、完整121项含29张原生Golden全部通过；见phase_2i_collection_cards_report.md |
| Windows / Android Debug构建 | Phase2I云端运行待实现提交；最近Phase2H的push、PR及手动运行三组均成功，本机Windows C++工具链仍受UAC限制 |

## 保留的验收缺口与后续边界

1. 已执行安全归档：13个旧原型文件移入archive/sonic_gallery，指纹一致，f96197b保存；根lib是新骨架，不再是旧代码。
2. 用户已批准补足工具链；Android命令行工具/API36/NDK已安装，Windows C++安装等待UAC确认。仍需取得双平台Debug构建成功证据，未批量接受所有Android许可。
3. 已解析Riverpod/go_router并提交lockfile；音频后端仍等待Phase 4双平台POC。
4. 已建立实时平台分类、三个Shell和根依赖；Windows Shell现有设计导航与跨平台Gallery，播放器、弹层及状态组件仅存在于明确标注的Fixture，窗口Gateway、业务Overlay Manager、Inspector业务与正式播放器接线仍未实现。业务页面未实现，不把设计预览当成音乐业务交付。
5. 为后续视觉验证准备获准且可访问的预览环境；遵守 Browser 技能边界，不绕过本轮 file: 拒绝。参考 screenshot 与 Flutter Golden 必须分别记录。

## 仓库边界

开发分支：feat/cross-platform-collection-cards，基于已拉取并同步的feat/cross-platform-state-surfaces@dc2758c。未在main/master直接开发；旧原型保留于归档提交。本批只增加Phase2I受控集合卡片、跨平台Gallery Fixture、测试与文档。

此前GitHub连接器404的历史边界见Phase2C报告；用户明确授权后，临时API访问已能读取本仓库运行和PR，不修改账号权限。Phase2I的push/PR/手动运行和新APK尚未发生；最新已完成证据仍是Phase2H的Draft PR #6及phase_2h_state_surfaces_report.md。
