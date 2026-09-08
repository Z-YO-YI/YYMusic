# Phase 6H3 — 歌单条目原子命令计划

2026-09-08，`Z-YO-YI/YYMusic`，分支 `codex/playlist-entry-commands`，
基于 fetch/pull 后的 `a7dd5d05c4064951b281da7718bb0c48e076405e`。
前置 push 34195449767 / PR 34195529670 的 checks、Android、Windows 全部 success，
Draft PR #47 保持 OPEN。五份指纹和 ZIP 24 项再次逐字节通过。

按主指令 Phase 6 Playlists 增量推进，先记录 ADR-059，再扩展公共合同。

- 新增不可变条目草稿（独立 ID、完整 TrackRef、UTC addedAt），位置由事务内当前列表确定。
- CollectionRepository 增加追加、移除、按条目锚点移动；不以页面过期的整表快照替换存储。
  自定义歌单限定、全局条目 ID 防碰撞、缺失目标/跨歌单引用失败，真正已移除条目再次移除幂等。
- 移动/移除仅改必要位置，不删除再插入全表；正数临时位置满足 SQLite 非负和唯一约束，
  失败整体回滚。真实改变更新父歌单单调时间，保持元数据、重复曲目及失效来源软引用。
- 复用根 PlaylistController 的 busy、固定错误、写入登记和关闭排空；不新建列表订阅或播放器。
- Fake 与真实 SQLite 行为对齐，覆盖并发、顺序、ID/来源隔离、系统保护、触发器回滚、
  无操作时间戳、根关闭/重入/异常及既有 Library 投影。
- 不改 schema、依赖、界面布局/Golden；共享缺失目标文案扩展为歌单或歌曲条目，配套回归更新。
  不在本批提供歌单详情、歌曲选择、拖动或播放全部入口。
  不改任何用户真实歌单；写入验证只使用隔离测试库。
- 全量格式/分析/Flutter/Node、生成代码零差异、参考指纹/许可、Android Debug 预检后审查提交，
  推送 stacked Draft PR，对精确提交核验 GitHub Android/Windows。不得合并或发布。

完整 App.tsx 的 NEW_ICON_SPRITE/POLISH_CSS 与基础 HTML 仍为视觉依据。
既有网页对照安全限制不绕过，构建与 Golden 不代替实机体验、网页对照或上线验收。
