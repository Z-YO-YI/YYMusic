# Phase 7H2C2：歌词页睡眠设置入口

2026-09-13；基线61585ef1ff4f03e1b739a6354e9dd19856467b41，fetch/ff-only pull且干净；分支codex/lyrics-sleep-settings，Draft base codex/player-sleep-settings。先[计划](phase_7h2c2_lyrics_sleep_plan.md)/ADR102，再入口、路由和测试。

## 实现与设计

- 歌词页原i-more按钮打开已有SleepSettingsPanel，复用唯一AppRouter modal和PlaybackPresenter；两个页面分别显式传入AppRoute owner，旧歌词入口不能在播放页借权限，反向同样拒绝。离页精确移除旧弹层，不误关新页面或新弹层；页面切换保留根睡眠意图。
- 设置选择、取消和关闭不会伪造音频调用；支持真实五选项、空队列禁用本曲结束、键盘、返回和卸载保护。覆盖时沿用LyricsController停用/清空，旧seek失效；关闭后重新读取并激活，新seek可执行，旧动作不重新获权。
- 使用设计转代码技能复用既有组件和原始图标；没有线上节点，继续本地导出审计，不声称线上Figma上下文读取成功。HTML2469歌词页使用i-more，最终视觉依据App.tsx NEW_ICON_SPRITE/POLISH_CSS。无WebView、模拟设备或新增音频实例。
- 初次视觉审核发现390px全屏手机元信息被按钮挤没；不足500px将翻译控制移至第二行，保留原标签和触控尺寸。稳定Column→headerRow结构，数据清空/恢复时不重建入口；360px全屏测试确认标题宽度至少70px、翻译实际可操作，390px键盘焦点恢复通过。

## 测试与视觉审核

新增17 Widget：三平台五选项/重复打开/页面互转共享定时、两个方向的原始owner拒绝、旧选择与旧关闭不影响新弹层、遮罩/Esc/App返回/系统返回、覆盖后新旧seek、空队列、宽窄键盘焦点/未处理Space、导航与卸载、窄屏元信息和翻译操作。与前批17项合计34项；新增4张真实歌词路由弹层Golden：手机390×900、横屏844×390、暗色平板800×1000、Windows1440×1000，130%字号，实际选择本曲结束并断言根entry-0，全部逐张查看。

19张旧Golden按实际差异审核更新：11张native_lyrics、3张lyrics_favorite、5张fullscreen。17张仅标题栏变化（有窗口标题/恢复横幅时坐标相应下移，恢复态至y176）；两张手机图包含翻译第二行及歌词区域重排，已整图查看，不能概括为仅标题栏像素变化。179张旧图不变，加4图共202张，不放宽像素阈值。短横屏弹层展示滚动后的正文，通过ensureVisible实际点击后续选项。

初次交互测试有两处测试假设问题：停用后原控制器会移除歌词正文，而非保留inactive viewport；Tab后Space可能激活完成，再Esc离开歌词页，不能当作焦点恢复失败。测试改为断言根停用及正文不存在、明确聚焦弹层容器并确认Space后弹层仍在；撤回临时FocusNode改动，保持原焦点恢复机制，宽窄键盘均验收。没有放宽断言或忽略失败。

## 最终验证

- 最终完整Flutter **1880通过，90秒**，包括全部202张严格Golden；新增17 Widget+4 Golden通过。
- Node **147通过**；严格分析 **0问题，15.0秒**，最终 **533文件格式零改动**。
- build_runner **30秒**、Drift迁移通过；生成代码/schema无差异。源ZIP24条目逐字节、源文件指纹及音频许可锁定检查通过。
- 最终Android Debug **34.3秒**，48项打包资产、完整音频许可、v2单签名者通过。APK **232259696 bytes**，SHA256 `30a8440a80513c8b054b67a56c80efb45141ea23df0e31288d6f9aaa38cc2e27`；Java native-access警告保留，不提交包。

## GitHub与边界

前置61585ef的[push34721259771](https://github.com/Z-YO-YI/YYMusic/actions/runs/34721259771)及[PR34721287029](https://github.com/Z-YO-YI/YYMusic/actions/runs/34721287029)均SUCCESS。本批新SHA云端独立验证，精确提交/PR/运行链接在提交后PR记录。不自动合并或发布Release。

主要文件：lyrics_screen.dart、app_router.dart、sleep_settings_route.dart、17 Widget/4 Golden/Node owner门禁、23张新增/审核更新基准和开发文档。仅接歌词入口；底栏/Inspector、其他播放设置、真实导入/后台媒体/发行仍待开发，不称Phase7整体完成。无新增设备安装/出声或本地Windows编译；GitHub构建不等同用户设备验收。
