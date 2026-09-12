# Phase 7G3：正在播放侧栏入口

2026-09-13，基线ea2f3a9，fetch/ff-only pull成功、工作区干净；分支codex/inspector-playback-navigation，Draft base codex/shell-fullscreen-navigation。前置双CI仍运行。

四项设计指纹与历史一致，复核App.tsx的NEW_ICON_SPRITE/POLISH_CSS与HTML2407/2413侧栏按钮。按设计转代码技能沿用完整本地导出与现有组件（无在线node），不新增图标/布局。先ADR096，给YYNowPlayingInspector增加受控全屏/歌词回调，AdaptiveRoot侧栏借已有全屏意图、openLyrics、路由与尺寸身份，复用Shell通用导航许可。全屏播放沿G2请求原生会话；歌词沿已有独立/lyrics及平台自动沉浸策略，不新建会话。无曲目时歌词入口禁用，播放页可打开空态。

验证两平台真实按钮、返回及根播放不变，路由切换/隐藏/卸载/内联遮罩撤销旧回调，完整回归/严格分析/格式/生成/Android预检。精确审查两按钮启用态Golden差异；保留未实现设置与队列摘要边界。本阶段非Phase7整体/实机/发行完成。
