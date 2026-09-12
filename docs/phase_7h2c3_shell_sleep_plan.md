# Phase 7H2C3：既有宽底栏睡眠设置绑定

2026-09-13；基线81a93c4，fetch/ff-only pull且干净，分支codex/shell-sleep-settings，Draft base codex/lyrics-sleep-settings。前置双CI运行中，无失败待修。

先ADR103再共享API与生产绑定。按设计转代码技能复用本地导出：HTML2436底栏i-device，App.tsx NEW_ICON_SPRITE/POLISH_CSS优先；无线上Figma节点，不声称线上读取。YYDesktopPlayerBar已有onOpenSettings及宽度>=1200的原始按钮，此批只接既有按钮，不改Phone mini及窄栏布局。窄栏继续通过元信息进入播放页设置；不称所有布局都有直接设置按钮。

AdaptiveRoot→ShellPlayer→既有_navigationAction接原根modal；所有生产主页面、专辑/歌手、歌单、系统歌单、队列frame传入捕获当前GoRouterState.uri的动作。modal拥有者升级完整Uri，既有player/lyrics AppRoute入口保持包装与测试；同路径不同参数必须关闭旧弹层，旧入口不能跨目标借权。禁止新播放器、Timer、数据库或WebView。

真实App测试宽底栏点击、重复打开、共享定时、Esc/返回/焦点；主路由/详情参数切换、同帧旧动作、覆盖/菜单/尺寸/卸载撤销。审核宽栏启用状态及新增生产弹层Golden；完整验证、生成迁移、Android预检、敏感扫描、commit/push/Draft。Inspector和窄栏直接入口后续处理，Phase7整体及8–11未完成。
