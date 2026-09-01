# PR 草稿：Android / Windows SecureCredentialGateway

Head：`feat/secure-credential-gateway`；Base：`feat/music-source-repository-drift@e0f49c6`。Draft PR编号待推送后记录；不自动合并、不改写历史。

## 变更

- 新增Android/Windows正式SecureCredentialGateway与可注入SecureStringStore，插件隔离于platform边界。
- 192-bit安全随机引用、冲突不覆盖、确定版本JSON、尺寸限制、串行访问与幂等删除。
- 新增只含operation/kind的脱敏失败；平台异常、引用和凭据均不进入错误字符串。
- 锁定`flutter_secure_storage 10.3.1`及Windows 4.2.2解析；Android独立namespace、崩溃安全迁移、不静默reset，manifest禁止备份。
- 不改v1 Schema，不接AppBootstrap、REST、Fixture、Controller、UI、播放或生物识别。

## 测试

- 10项Credential Gateway定向测试已通过。
- 完整199项Flutter/32 Golden和strict analyze 0问题已通过。
- lockfile严格复现；130文件format零改动、Node29、ZIP24、生成代码/v1快照零差异已通过。
- 本机Android Debug已构建/验签/验资产，合并manifest确认`allowBackup=false`；GitHub Android/Windows待目标提交后记录。

## 影响与未验收项

影响限于platform安全凭据实现、合同失败类型、Android备份设置、依赖、测试与文档。Domain凭据模型、Drift v1、UI、Shell、播放和启动图不变。

AppBootstrap/Dev Fixture、凭据与来源事务协调、REST Adapter/Auth、真机KeyStore/Credential Manager重启/升级、本机Windows和Android真机均未验收。
