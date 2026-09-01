# Phase 3G 开始 — Android / Windows SecureCredentialGateway

日期：2026-09-01。开始前已fetch并确认`feat/music-source-repository-drift@e0f49c6`与远端同步、工作树干净；从该提交创建`feat/secure-credential-gateway`，不在main/master开发。

## 本阶段目标

- 以`flutter_secure_storage 10.3.1`实现`AndroidSecureCredentialGateway`与`WindowsSecureCredentialGateway`，平台插件类型不进入Domain、UI或数据库。
- 使用192-bit `Random.secure()`引用，严格限定`cred_` + 32位base64url；冲突时不覆盖已有秘密。
- 用版本化、字段排序的JSON保存`SensitiveCredentialKind`和字段；拒绝未知版本/字段/类型、损坏JSON、过大数据和非字符串值。
- save/read/delete串行访问底层store，delete保持幂等；所有插件异常转为只含operation/kind的脱敏失败。
- Android使用独立namespace、RSA-OAEP + AES-GCM默认算法、崩溃安全迁移并禁止应用备份；Windows关闭旧存储兼容扫描。

## 依赖证据与边界

- 10.3.1的官方Android模块使用compileSdk36/minSdk23，与当前Flutter 3.47.2/API36一致；11.0.0需compileSdk37，本批不擅自升级。
- Windows锁定解析为`flutter_secure_storage_windows 4.2.2`；其官方说明为AES-GCM文件与Windows Credential Manager密钥组合，仍必须由Windows云端构建证明当前工具链可用。
- Android `allowBackup=false`避免密文与KeyStore密钥在云备份恢复后错配；Android 12+某些厂商的设备迁移例外留给真机验收。
- Dart不保证不可变`String`的可靠归零；本批通过延迟读取、不缓存、不日志、不包含于异常来缩短内存生命，不伪称安全归零。

## 不在本批

- 不接AppBootstrap/DependencyGraph，不写Dev Fixture，不将任何凭据放入Drift、preferences、日志或构建资产。
- 不实现REST Adapter、OAuth/token refresh、连接测试、Source Controller、网络搜索/Stream、UI或生物识别提示。
- 凭据替换/删除与MusicSourceConfig事务的协调留给后续Controller；Repository不猜测外部秘密生命周期。

## 出口条件

- 可注入store覆盖Android/Windows save/read/delete、编解码、全种类、重建、冲突、损坏载荷、超限、并发串行、平台失败脱敏与非法引用。
- lockfile严格复现，全量format/analyze/Flutter/Node/ZIP、生成代码与v1快照零差异；本机Android Debug编译/验签/资产/manifest通过。
- 独立提交、Draft PR、GitHub Android/Windows Debug与唯一一次手动APK均绑定本批实现commit；不用Fake或编译成功冒充真机密钥库验收。
