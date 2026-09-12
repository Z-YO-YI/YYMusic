# Phase 7G4：底栏元数据与歌词入口许可

2026-09-13，基线3be2863，fetch/ff-only pull且干净；分支codex/shell-metadata-navigation-guard，Draft base codex/inspector-playback-navigation。前置双CI仍运行。

非视觉缺陷审查：手机MiniPlayer及桌面/平板底栏的onOpen/onOpenLyrics仍直接转发导航，未沿用G1–G3交互许可。先以真实路由切换回归验证旧回调能否错误打开页面；再复用_navigationAction保护这些现有入口，不改变空态/按钮展示、不扩张共享API。验证三布局正常打开/返回、新旧回调、跨主导航、独立页覆盖与菜单覆盖/关闭；全部Flutter/Node、格式/分析、生成迁移与Android预检，Golden应全不变。

不声称所有播放传输控件均已审计，也不把本修复当作Phase7整体/实机/发行完成。未改设计资产或视觉，不涉及新的Figma实现；既有完整App.tsx/HTML审计沿用，ZIP继续逐字节核验。
