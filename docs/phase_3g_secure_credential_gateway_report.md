# Phase 3G — Android / Windows SecureCredentialGateway 报告

2026-09-01。开始前已fetch并确认`feat/music-source-repository-drift@e0f49c6`与远端同步、工作树干净；从该提交创建`feat/secure-credential-gateway`，未在main/master开发。范围与出口见[计划](phase_3g_secure_credential_gateway_plan.md)。

## 当前实际进度

本批实现Android与Windows的正式`SecureCredentialGateway`，通过可替换`SecureStringStore`隔离`flutter_secure_storage`。AppBootstrap/DependencyGraph仍未构造它们，启动应用不会创建凭据、打开数据库或伪造来源成功。REST Adapter、Dev Fixture和Controller待后续独立批次。

## 存储、编码与失败边界

1. 引用由24个`Random.secure()`字节生成，固定为`cred_` + 32位base64url；保存前检查冲突，最多8次且绝不覆盖旧值。
2. 载荷只含`schemaVersion=1`、kind和按key排序字段；限制64字段、单值16384字符和总载荷65536字节，读取后重走`SensitiveCredential`验证。
3. 同一Gateway内save/read/delete串行交给平台store；删除不存在引用幂等。非法引用在接触插件前拒绝，避免Windows文件key路径或长度攻击。
4. 原始插件异常、key、凭据、载荷和栈不进入公开失败；`SecureCredentialFailure`只保留operation/kind，字符串统一`<redacted>`。
5. Android使用独立namespace、崩溃安全算法迁移且`resetOnError=false`，不在密钥故障时静默永久清空全部凭据；manifest明确`allowBackup=false`。Windows使用新存储路径，不扫描/迁移本项目从未写入的旧格式。

## 本地验证

| 检查 | 当前结果 |
| --- | --- |
| Credential定向 | 10项通过：Android/Windows合同、确定版本JSON/重建、全kind/不可变、冲突不覆盖、非法引用、损坏载荷、平台异常脱敏、并发串行、生成器/尺寸失败 |
| 架构边界 | Node定向/全量通过：只有`platform/secure_credentials`导入插件，无Drift/HTTP/dart:io/日志，AppBootstrap不接线 |
| 全量门禁 | lockfile严格复现；130文件format零改动、严格分析0问题；199项Flutter含32 Golden、29项Node、ZIP24全部通过；代码生成/make-migrations后v1 g.dart/快照零差异 |
| 本机Android Debug | 构建成功，237658550字节，本地诊断SHA-256 `801b783f15c7f235d848f5748fb2a8b1e63694d80176a13769dde629e5874a22`；48份资产匹配、v2单签名有效、合并manifest确认`allowBackup=false` |

## 云端与限制

实现提交`4daf38019b250dddf24296a771efcd5e824dd6e1`已推送；[Draft PR #15](https://github.com/Z-YO-YI/YYMusic/pull/15)以`feat/music-source-repository-drift`为base。push[运行33510086595](https://github.com/Z-YO-YI/YYMusic/actions/runs/33510086595)、PR[运行33510153174](https://github.com/Z-YO-YI/YYMusic/actions/runs/33510153174)和触发前计数为0、触发后计数为1的唯一手动[运行33511421874](https://github.com/Z-YO-YI/YYMusic/actions/runs/33511421874)均为checks/Windows Debug/Android Debug三job success。

[私有草稿Release](https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-15023c88bca130379b81)标签`ci-debug-33511421874-1`，target为完整实现提交，保持draft/prerelease且恰有`YYMusic-debug.apk`、`SHA256SUMS`和`build-metadata.json`三资产。三资产下载到全新临时目录复核：APK为189393711字节，SHA-256、metadata、SHA256SUMS与GitHub API digest均为`2623eab9590f4f333bc7327ee4d4dea49ee5b6f6789219f129b44f1e7108bcdf`；48份资产匹配、无参考/凭据文件、Manifest确认包名/YYMusic/`allowBackup=false`，apksigner确认仅v2且1个Debug signer。临时三文件与目录已删除，Release保留。

本机Windows因远程无法开启Developer Mode/符号链接支持，不声称本机Windows构建成功。定向测试的内存store和云端编译只证明编码/失败合同、wrapper可替换及原生构建兼容，不等于Android KeyStore或Windows Credential Manager的真机save/read/delete/重启/升级验收。GitHub APK仍是临时Debug签名，不是正式Release签名包。

## 主要文件

- `lib/platform/secure_credentials/secure_storage_credential_gateway.dart`
- `lib/platform/secure_credentials/flutter_secure_string_store.dart`
- `lib/platform/secure_credentials/android_secure_credential_gateway.dart`
- `lib/platform/secure_credentials/windows_secure_credential_gateway.dart`
- `test/unit/secure_credential_gateway_test.dart`
- Android manifest、依赖锁、架构边界与阶段文档

下一批应完成Phase3 Dev Fixture/AppBootstrap数据策略，再进入Phase4双平台音频POC；不把REST请求、Source Controller或UI混入本提交。
