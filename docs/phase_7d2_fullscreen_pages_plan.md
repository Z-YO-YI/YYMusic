# Phase 7D2 — 原生全屏页面与生命周期

2026-09-09；基线ba68cdd已fetch/pull同步，独立分支`codex/fullscreen-page-lifecycle`，Draft PR base=`codex/native-fullscreen-gateways`。前置D1两组CI仍在运行，独立核对，不借用旧构建。

目标：根FullscreenPresenter拥有唯一通道和状态，路由观察器只传当前页面身份/是否弹层；Windows播放/歌词顶部按钮与F切换，Esc先退出原生全屏、再次返回。非输入且无弹层时F可打开播放页并请求全屏。Android进入播放/歌词页面自动请求沉浸，返回离页恢复；切后台/失焦/零尺寸后不自动重新进入，用户可用按钮恢复。播放与歌词之间保留同一原生会话，覆盖队列/弹层恢复。

读取来源：主指令18/19/Phase7、基础HTML两套顶部全屏按钮/键盘/状态同步、App.tsx最终fullscreen/fullscreen-exit SVG与POLISH_CSS、现有YYButton/WindowFrame/路由/平台通道。原ZIP24条目与源审计10项复核通过。使用figma-design-to-code组件复用流程；本地导出无在线节点，不伪造Figma上下文。

修改：YYMusicApp、AppRouter、WindowFrame、PlayerScreen、LyricsScreen、架构/README/状态/矩阵和架构门禁；新增根协调器、导航观察器、共享全屏按钮、Fake与单元/Widget/Golden测试。先记录ADR080再改共享API；不新增依赖、Schema、媒体能力或原生权限。

风险：原生事件/命令响应乱序；切页/生命周期撤销旧意图；失败恢复和重试；系统返回/Esc层级；隐藏标题栏不能重建Navigator/播放器/歌词状态；窄屏130%字号。通知合并到安全microtask，不在build同步通知或发原生请求。

出口：关闭先撤销并排空全屏，再关闭业务图；完整格式/严格分析/Flutter/Node/指纹/生成/迁移/Android包预检通过；逐张查看新增Golden，旧图仅对实际变化定向更新。提交push与Stacked Draft PR，报告精确CI状态，不发布Release或手动音频诊断。Android实际系统栏与多显示器/DPI验收单列。

执行中发现前置D1云端最大化退出几何失败，暂停新增页面行为，在隔离分支修正后取得`e68fffab81a7e787f31d6a24bc6136410d4bc3af`两组源码/Android/Windows SUCCESS及2项真实Runner通过。保留本批代码并仅做QA，成功后安全快进到已验证修正；最终本批基线为e68fffa，Draft PR base改为`codex/fullscreen-maximized-restore`。失败原因/修复证据见[D1报告](phase_7d1_fullscreen_gateways_report.md)，不将ba68cdd记为通过。
