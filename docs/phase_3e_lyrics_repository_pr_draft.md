# PR 草稿：Drift-backed LyricsRepository

Head：`feat/lyrics-repository-drift`；Base：`feat/collection-repository-drift@bc49b38`。Draft PR编号待推送后记录；不自动合并、不改写历史。

## 变更

- 新增LyricsDocument严格JSON/row mapper与Drift-backed `LyricsRepository`全合同。
- 以完整TrackRef get/upsert/remove，不要求catalog或来源row存在；删除幂等。
- plain/synchronized时间、双语文字、语言、偏移和缓存时间返回前全部验证；错误脱敏。
- shared/owned数据库生命周期显式，不接AppBootstrap。
- 不修改v1 Schema/快照，不新增依赖、原生包、权限、LRC解析、网络、Controller或UI。

## 测试

- 6项真实SQLite Repository测试已通过。
- 完整181项Flutter/32 Golden和strict analyze 0问题已通过。
- lockfile严格复现；122文件format零改动、Node29、ZIP24、生成代码/v1快照零差异已通过。GitHub Android/Windows待目标提交后记录。

## 影响与未验收项

影响限于data/repositories、测试与文档。AppBootstrap、DependencyGraph、UI、Shell、播放、依赖和v1 Schema不变。

MusicSourceRepository、SecureCredentialGateway实现、Dev Fixture、Controller、LRC/在线获取、自动跟随/Seek、本机Windows与Android真机均未验收。
