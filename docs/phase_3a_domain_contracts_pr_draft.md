# PR 草稿：Domain models and repository contracts

Head：`feat/domain-model-contracts`；Base：`feat/cross-platform-queue-lyrics-primitives@3c09ed7`；[Draft PR #9](https://github.com/Z-YO-YI/YYMusic/pull/9)。不自动合并、不改写历史。

## 变更

- 新增Track/Collection/Lyrics/Source核心模型、显式LoadState、脱敏失败和分页；稳定TrackRef与QueueEntry分离。
- 新增Library/Collection/Lyrics/MusicSource Repository及SecureCredentialGateway合同和测试Fake。
- 来源配置拒绝明文敏感Header、HTTP/userinfo/query base URL、Header换行和可执行映射；Credential字符串脱敏。
- 不安装数据库依赖、不接UI/Controller/HTTP/文件/平台/播放，不创建生产Fixture。

## 测试

- 108个Dart文件格式无变更，严格分析0问题；完整147项Flutter通过，既有32张Windows精确Golden未更新。
- 16项新Domain/Repository测试覆盖不可变性、UTC、队列重复/顺序、歌词、来源安全、Fake替换和释放。
- 29项Node、五份源指纹/44 SVG/52项派生产物与24个ZIP entry逐字节核验通过。
- 实现提交`8506afc`的push运行33480316280、PR运行33480358335及手动运行33481171269各自三个job全部成功。
- 私有草稿Release三资产已下载复核；APK为175891537字节，SHA-256/API digest为`1500bd28956befbb697cbe160c388d25a1c900e6454b180bed4335aaec05b712`，metadata身份一致、48份资产匹配且v2单签名有效。

## 影响与未验收项

影响范围限于Domain/Repository/Gateway合同、测试Fake、架构门禁与文档；Phase2 UI、PlaybackController、QueueController行为和CI合同不变。

Drift/SQLite、Schema/Migration、正式Repository/安全存储、Dev Fixture、业务Controller、真实搜索/持久化均未验收。本机Windows C++仍受UAC限制。
