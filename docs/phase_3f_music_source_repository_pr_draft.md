# PR 草稿：Drift-backed MusicSourceRepository

Head：`feat/music-source-repository-drift`；Base：`feat/lyrics-repository-drift@607267b`。[Draft PR #14](https://github.com/Z-YO-YI/YYMusic/pull/14)保持待审核；不自动合并、不改写历史。

## 变更

- 新增MusicSourceConfig严格JSON/row mapper与Drift-backed `MusicSourceRepository`全合同。
- 公开Map按key排序，URL/枚举/延迟/UTC时间返回前验证；异常统一脱敏。
- sourceType/builtIn稳定身份与内置删除保护；自定义来源删除保留用户TrackRef。
- 数据库只保存credentialRef，代码不导入SensitiveCredential、安全存储或网络。
- 不修改v1 Schema/快照，不新增依赖、原生包、权限或AppBootstrap接线。

## 测试

- 8项真实SQLite Repository测试已通过。
- 完整189项Flutter/32 Golden和strict analyze 0问题已通过。
- lockfile严格复现；125文件format零改动、Node29、ZIP24、生成代码/v1快照零差异已通过。
- 实现提交`22d68f2`的push运行33503815038、PR运行33503837936与手动运行33504877925均为三job success，Android/Windows Debug均通过。
- 私有草稿Release三资产已下载复核；APK为183604101字节，SHA-256/API digest为`db2946d4b416971b2fbb89cc754ba77cdf0c03f36aff3f84b2ad425a281c24a2`，metadata身份一致、48份资产匹配且v2单签名有效。

## 影响与未验收项

影响限于data/repositories、测试与文档。AppBootstrap、DependencyGraph、UI、Shell、播放、依赖和v1 Schema不变。

SecureCredentialGateway、REST Adapter、连接测试/认证/搜索/Stream、Dev Fixture、Controller、本机Windows与Android真机均未验收。
