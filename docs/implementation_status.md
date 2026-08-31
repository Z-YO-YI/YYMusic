# 实施状态

更新：2026-08-31。用户要求继续Android开发且APK在GitHub构建。当前组件库推进到Phase2C；经明确授权取得首次远程证据后发现Linux隐藏文件校验错误，正在独立修复分支复验。当前云端证据见[CI记录](ci_reference_audit_fix.md)，不是完整客户端或整个Phase2已完成。

| 阶段/能力 | 状态 |
| --- | --- |
| Phase 0 输入身份、源码审计、合成与映射 | 已形成可复核产物，结果见 phase_0_report.md |
| Phase 1 Flutter 工程骨架 | 已实现路由/DI/三个Shell/runner/测试/CI；构建验收未完成，见phase_1_report.md |
| Phase 2A Android设计基础 | 已接入主题/字体/44SVG/首批控件及原生预览，见phase_2_android_report.md |
| Phase 2B Android导航与控件 | 手机/平板导航已驱动路由，Slider和七种Artwork占位已加入Gallery；见phase_2b_android_report.md |
| Phase 2C Android输入与选择 | SearchField、SegmentedControl、Toggle及Gallery已实现/测试；见phase_2c_android_report.md |
| Phase 2 后续组件及视觉对照 | 业务卡片、更多表单/弹层、正式MiniPlayer等未实现；网页对照和设备性能待验 |
| Phase 3 Domain/数据库/状态 | 未开始；只有边界决策 |
| Phase 4 双平台音频 | 仅 POC 计划；没有真实播放验证 |
| 后续页面、歌词、导入、来源、平台集成 | 未开始 |
| GitHub APK交付 | 已补齐Actions验签/产物下载流程；首次cafb942运行校验失败、无产物，修复与复验见ci_reference_audit_fix.md |
| 浏览器参考截图 / Computed Style | 未运行：file: 导航被安全策略阻止 |
| Flutter format/analyze/test | 本批74项含11张原生Golden；当前结果见phase_2c_android_report.md |
| Windows / Android Debug构建 | 本批仅走GitHub构建，首次运行两平台均因校验失败跳过；Phase2B本机APK仅历史证据；本机Windows安装等待UAC确认 |

## 保留的验收缺口与后续边界

1. 已执行安全归档：13个旧原型文件移入archive/sonic_gallery，指纹一致，f96197b保存；根lib是新骨架，不再是旧代码。
2. 用户已批准补足工具链；Android命令行工具/API36/NDK已安装，Windows C++安装等待UAC确认。仍需取得双平台Debug构建成功证据，未批量接受所有Android许可。
3. 已解析Riverpod/go_router并提交lockfile；音频后端仍等待Phase 4双平台POC。
4. 已建立实时平台分类、三个Shell和根依赖；Android按用户最新指示推进Phase2C，Windows出口保留待办。业务页面未实现，不把设计预览当成音乐业务交付。
5. 为后续视觉验证准备获准且可访问的预览环境；遵守 Browser 技能边界，不绕过本轮 file: 拒绝。参考 screenshot 与 Flutter Golden 必须分别记录。

## 仓库边界

开发分支：feat/android-ci-and-form-controls，基于已拉取并同步的feat/android-navigation-controls@2f35cf5。未在main/master直接开发；旧原型保留于归档提交。本批先单独提交GitHub APK流程，再分批继续Phase2组件。

此前GitHub连接器404的历史边界见Phase2C报告；用户明确授权后，临时API访问已能读取本仓库运行和PR，不修改账号权限或读取现有Git凭据。CI修复分支fix/reference-audit-hidden-files基于cafb942，不改动已完成UI；本次修复和远程证据见ci_reference_audit_fix.md。CI交付配置提交7458a28、UI提交cafb942；实时提交与同步状态以最终交付时实际核验为准。
