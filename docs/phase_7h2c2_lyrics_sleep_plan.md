# Phase 7H2C2：歌词页睡眠设置入口

2026-09-13；基线61585ef，fetch/ff-only pull后干净，分支codex/lyrics-sleep-settings，Draft base codex/player-sleep-settings。前置源码CI通过、Android/Windows构建仍运行，无失败待修。

先ADR102再实现：基础HTML2469歌词header使用i-more，最终资产遵循App.tsx NEW_ICON_SPRITE和POLISH_CSS；读取设计转代码技能，无线上节点，复用已审计导出和既有YYButton/睡眠面板。LyricsScreen可选onOpenSettings走原有代数/可见性/路由保护。AppRouter复用唯一modal，为两个入口显式绑定expected owner路径，旧入口不能借另一页面权限；不增播放器/Timer/WebView或复制弹层。

真实App测试手机/平板/Windows：重复打开、五选项与同一根、返回只关设置、页面互转不误关新页面、旧动作、歌词覆盖/恢复后的seek权限、空队列、键盘与卸载。审核歌词header窄屏130%字号及新增生产弹层Golden；全量回归、格式/严格分析/生成迁移、Android预检、敏感扫描后commit/push/Draft。仅歌词入口，不扩展底栏/Inspector或未实现设备选项，不称Phase7整体完成。

审核中发现新增设置使390px全屏手机元信息不可见，按ADR102增加不足500px的翻译第二行，稳定header容器结构；保留原始标签与触控尺寸。新增窄屏元信息宽度、翻译点击、键盘恢复防退化测试后复验。
