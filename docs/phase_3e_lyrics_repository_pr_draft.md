# PR 草稿：Drift-backed LyricsRepository

Head：`feat/lyrics-repository-drift`；Base：`feat/collection-repository-drift@bc49b38`。[Draft PR #13](https://github.com/Z-YO-YI/YYMusic/pull/13)保持待审核；不自动合并、不改写历史。

## 变更

- 新增LyricsDocument严格JSON/row mapper与Drift-backed `LyricsRepository`全合同。
- 以完整TrackRef get/upsert/remove，不要求catalog或来源row存在；删除幂等。
- plain/synchronized时间、双语文字、语言、偏移和缓存时间返回前全部验证；错误脱敏。
- shared/owned数据库生命周期显式，不接AppBootstrap。
- 不修改v1 Schema/快照，不新增依赖、原生包、权限、LRC解析、网络、Controller或UI。

## 测试

- 6项真实SQLite Repository测试已通过。
- 完整181项Flutter/32 Golden和strict analyze 0问题已通过。
- lockfile严格复现；122文件format零改动、Node29、ZIP24、生成代码/v1快照零差异已通过。
- 实现提交`1e45532`的push运行33499761224、PR运行33499787210与手动运行33500756816均为三job success，Android/Windows Debug均通过。
- 私有草稿Release三资产已下载复核；APK为183604101字节，SHA-256/API digest为`fd71936ef590dc18b1e851572c21cbf6d10f157a495298022dec3f2dd384020a`，metadata身份一致、48份资产匹配且v2单签名有效。

## 影响与未验收项

影响限于data/repositories、测试与文档。AppBootstrap、DependencyGraph、UI、Shell、播放、依赖和v1 Schema不变。

MusicSourceRepository、SecureCredentialGateway实现、Dev Fixture、Controller、LRC/在线获取、自动跟随/Seek、本机Windows与Android真机均未验收。
