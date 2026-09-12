# Phase 7H2C3：既有宽底栏睡眠设置绑定

2026-09-13；基线81a93c4e92d83fdd144a7a29e7617bd239a93ea0，fetch/ff-only pull且干净；分支codex/shell-sleep-settings，Draft base codex/lyrics-sleep-settings。先[计划](phase_7h2c3_shell_sleep_plan.md)/ADR103，再共享API、生产绑定与测试。

## 实现范围

- AdaptiveRoot→ShellPlayer→既有_navigationAction绑定YYDesktopPlayerBar.onOpenSettings，激活已有原i-device按钮；复用根唯一modal/PlaybackPresenter，无新播放器、Timer、数据库或WebView。回调替换也撤销旧代数。
- 全部5处生产AdaptiveRoot工厂（主页面、专辑/歌手、歌单、系统歌单、队列）捕获GoRouterState.uri。modal同时校验路径、完整URI、实例及生命周期，参数变化立即撤销旧操作并准确移除，不误关新页面或新弹层；保留原player/lyrics AppRoute包装。
- 回归发现currentConfiguration.uri在push后不一定代表栈顶。读取本地锁定GoRouter18源码确认公开state.uri契约后修正，原有player→lyrics及同路径不同查询参数均通过。
- **本批只激活既有宽度>=1200底栏按钮**，未改变Phone mini或窄栏的设计可见性；窄栏仍可通过曲目信息进入播放页使用设置。Inspector与窄栏直接入口后续处理，不宣称所有布局具备底栏直达设置。

## 设计与视觉审核

使用设计转代码技能复用原组件/图标；没有线上节点，继续已审计本地导出，不冒称线上Figma上下文成功。HTML2436底栏i-device，最终资产与视觉遵循App.tsx NEW_ICON_SPRITE/POLISH_CSS。基础设计组件文件未改。

新增3张生产弹层Golden：Windows1440×1000浅色、平板1280×900深色、Windows系统队列1440×1000深色，130%字号，真实选择60分钟并断言根投影，全部逐张查看。背景是测试仓库数据/真实错误状态，不代表线上来源或设备验收。

首次严格比较有23张旧图变化，每张恰好100像素，完整差异边界均限于14×14设置图标内部；逐张放大核对为禁用→启用颜色变化后才更新。179张旧图不变，加3张共205，未放宽像素阈值。新增Windows图首次还捕获背景播放行不同动画时点；初始化完成后明确设置Reduce Motion，再生成、逐张查看及严格重复比较通过，最终全量205图通过。

## 验证结果

- 新增22 Widget：双平台宽栏点击/重复打开/根选择，8类页面入口，完整URI不同参数/旧原始owner，导航/往返/覆盖/缩放/零面积/卸载，菜单覆盖恢复，Esc/系统返回/遮罩，键盘原焦点恢复。全量 **1905 Flutter通过，89秒**，含3新Golden及既有播放/歌词入口回归。
- Node **148通过，15.6秒**，含全部5个URI绑定工厂门禁；严格分析 **0问题，10.8秒**。修正大括号/导入顺序与新增测试排版后 **535文件格式零改动**。
- build_runner **23秒**、Drift迁移通过，生成/schema无差异。24个ZIP条目逐字节、原文件指纹及锁定音频许可通过。
- 测试宿主最初把完整根清理推迟至addTearDown，绑定先检查残留分钟/取消Timer而失败；初始化跨真实/Fake区也曾悬挂。最终统一依赖创建/初始化异步区，并在测试体finally用closeGraph协议实际排空，再交回绑定检查。未忽略计时器不变量，未遗弃close Future。
- Android Debug **17.7秒**；48资产、完整音频许可、v2单签名者通过。APK **232262272 bytes**，SHA256 `46916984e1006a41427d4177933774aeb5c1c2d69f67c1520a10eb519167c098`；Java native-access警告保留，包不入库。
- 无新增设备安装/出声、本地Windows编译或发行验收；本批新SHA双平台云端独立验证，不能以本地通过代替。

## GitHub与后续

前置81a93c4的[push34722713534](https://github.com/Z-YO-YI/YYMusic/actions/runs/34722713534)/[PR34722770925](https://github.com/Z-YO-YI/YYMusic/actions/runs/34722770925)均SUCCESS。本批精确提交/PR/新运行记录在提交后Draft信息；不自动合并或发布Release。

主要文件：adaptive_root.dart、app_router.dart、sleep_settings_route.dart、shell_player.dart、Widget/Golden/Node门禁、26张新/审核更新图和开发文档。下一增量Inspector设置入口及窄栏可达性审计；其他真实播放设置和Phase7整体、Phase8–11仍未完成。
