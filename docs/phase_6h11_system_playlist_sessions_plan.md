# Phase 6H11 — 系统歌单共用会话计划

2026-09-08，仓库Z-YO-YI/YYMusic，分支codex/system-playlist-sessions。
从fetch/pull后的干净2c22cadbcbfab1a6ef3420cd01758a0410ce1535开始；前置Draft PR #55两组常规源码/Android/Windows成功。
再次验证五份设计指纹、ZIP24项、44图标/52产物；完整重读主指令，沿用Phase0对App.tsx/NEW_ICON_SPRITE/POLISH_CSS和HTML的完整审计。

目标：为Phase6的系统歌单原生页面建立一个共用、根注册的只读会话合同，不引入第二份队列或可删除父歌单。
先记录ADR-067，再新增features/playlists/common/system_playlist_controller.dart及会话注册，修改dependency_graph.dart。
新增控制器、分页、生命周期、真实SQLite测试与测试Probe；同步README、测试矩阵、实施状态和阶段报告。

- 固定SystemPlaylistType，构造/open不订阅或读取，显式start幂等；idle/loading/data/empty/error均明确。
- 先订阅类型相关失效再查询；变化风暴合并到单个串行读worker，旧成功和错误不能覆盖新意图。
- 每次整体替换一致窗口，20条递增至200后前后分组，保留完整来源/真实ID/缺失引用/页外当前队列ID。
  导航绑定当前快照和活动状态；不是拼接版本不同的页，也不让旧回调跨组跳页。
- 删空末组时重新读最后有效组；错误保留禁用旧数据，显式刷新重建订阅并重试同一目标窗口。
- 取消/订阅getter重入/数据通知中关闭与刷新都登记真实Future，根关闭先排空会话再释放共享存储；错误只保留安全分类与诊断ID。
- 不新增数据库Schema、依赖、播放/收藏/历史写行为、页面或平台权限，不改Golden。不把只读数据会话称为可用系统歌单页面。

风险：订阅建立前读造成丢刷新；取消未完成就释放SQLite；错误/旧快照被当作可操作数据；大列表累积和末组越界。
出口：上述边界与真实查询/变更通知/根关闭测试通过；完整Flutter/Node/格式/分析/指纹/许可检查、本地Android预检及精确GitHub双平台构建。
清晰提交推送stacked Draft PR，不自动合并/Release；日志和构建产物仅进入忽略目录。
随后继续系统歌单原生页面、根动作和真正开始播放的历史记录，再按主指令推进Local Music/Settings。
