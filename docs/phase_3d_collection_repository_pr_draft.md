# PR 草稿：Drift-backed CollectionRepository

Head：`feat/collection-repository-drift`；Base：`feat/library-repository-drift@0fd7c0f`。Draft PR编号待推送后记录；不自动合并、不改写历史。

## 变更

- 新增Playlist/Entry、Favorite、History和Queue严格row mapper及Drift-backed `CollectionRepository`全合同。
- 系统歌单身份/唯一性/删除保护，自定义歌单删除只级联entries。
- 歌单entries与可重复TrackRef的队列使用单事务+batch整体替换，watch只发布提交后快照。
- 收藏幂等移顶，历史按TrackRef去重并保留最近20条；不要求catalog Track存在。
- 不修改v1 Schema/快照，不新增依赖、原生包、权限或AppBootstrap接线。

## 测试

- 10项真实SQLite Repository测试已通过。
- 完整175项Flutter/32 Golden和strict analyze 0问题已通过。
- lockfile严格复现；119文件format零改动、Node29、ZIP24、生成代码/v1快照零差异已通过。GitHub Android/Windows待目标提交后记录。

## 影响与未验收项

影响限于data/repositories、测试与文档。AppBootstrap、DependencyGraph、UI、Shell、播放、依赖和v1 Schema不变。

Lyrics/MusicSource Repository、SecureCredentialGateway实现、Dev Fixture、Controller、队列算法、真实来源/本地扫描、本机Windows与Android真机均未验收。
