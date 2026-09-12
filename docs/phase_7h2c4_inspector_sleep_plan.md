# Phase 7H2C4：Inspector设置入口与窄栏可达性

2026-09-13；基线4784cba，fetch/ff-only pull且干净，分支codex/inspector-sleep-settings，Draft base codex/shell-sleep-settings。前置双平台CI进行中，无失败待修。先ADR104，再API/绑定与测试。

读取设计转代码技能；无线上节点，沿用已完整审计本地导出，基础HTML2407顶部i-more及2414快捷i-device；App.tsx NEW_ICON_SPRITE/POLISH_CSS优先。YYNowPlayingInspector新增可选onOpenSettings，两个原禁用按钮接同一动作，不改布局/资产。AdaptiveRoot把已有URI闭包传入Inspector，ShellPlayer仍走既有_navigationAction；不新增根、Timer、数据库或WebView。

测试Windows/平板两种入口真实点击、同帧双入口与底栏竞争、根意图、关闭和旧动作、隐藏/布局切换/零面积/导航/菜单/卸载、键盘与小高度滚动。窄Windows、平板竖屏和手机沿用曲目信息→播放页→设置，实际点击证明可达，不擅自挤入新按钮。审核启用后的原截图及新增生产弹层Golden，完整验证后commit/push/Draft。侧栏队列摘要和其他真实播放设置继续后续，不称Phase7整体或上线完成。
