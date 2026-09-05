# Phase 6H1 — 歌单元数据命令基础

2026-09-06，基于fetch/pull后的`3ac653b2f5bf40515a2e7e33f39d499839936d6c`，
分支`codex/playlist-metadata-commands`。前置两组checks/Android/Windows success，五指纹与ZIP24一致。

依主指令Phase6在歌曲/详情动作后推进Playlists。此次只接可独立验证的创建、重命名、删除写入基础，
不一次生成歌单详情/三端弹窗/条目管理/播放全部；界面和入口仍待Phase6H2，现有70张Golden全部不改。
先补ADR-057再改变CollectionRepository和根Graph合同。

- Repository新增原子create-only与rename-existing命令，避免upsert覆盖碰撞ID或复活已删除歌单。
  复用现有事务与Schema，保留savePlaylist用于既有受控引导；不改变历史调用方。
- 名称修剪、1–512字符、禁控制字符；系统歌单元数据不可由编辑命令创建/改名/删除。
  重命名保留createdAt/description/条目，updatedAt不因时钟回拨倒退；改名不存在目标报告notFound，删除仍幂等。
  删除仍只删除歌单及其条目，绝不删除曲目、收藏、历史、队列或任何文件。
- 根PlaylistController借用同一CollectionRepository，不订阅第二份列表，不查询构造期数据；
  稳定随机ID，明确安全结果，单命令busy避免重复点击。已经接受的写入在UI离页/根关闭后排空。
  UI将显式确认删除后才调用；本批只使用测试库，绝不执行用户歌单删除。
- 单元测试覆盖输入、碰撞、系统保护、不存在目标、错误脱敏、重复/重入和根关闭；真实SQLite
  验证创建/重命名/删除、事务不覆盖、元数据/条目保留和删除后的非歌单数据完整。
- 全量格式/analyze/Flutter/Node、生成/Schema/lockfile、指纹/许可和本地Android预检；
  审查后提交推送stacked Draft PR，以当前精确提交触发GitHub Android/Windows，不合并或发布。

涉及Domain命名/Repository、Drift实现、根Controller/Graph、Fake/真实SQL测试、Node和开发文档；
不改平台、播放引擎、路由、HTML参考或设计原语。App.tsx NEW_ICON_SPRITE/POLISH_CSS约束继续保留。
