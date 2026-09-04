# Phase 3H 开始 — 生产数据引导与显式 Dev Fixture

日期：2026-09-01。开始前已 fetch，并确认 `feat/secure-credential-gateway@9fcbd00` 与远端同步、工作树干净；从该提交创建 `feat/dev-fixture-bootstrap`，不在 main/master 开发。

## 本阶段目标

- 由一个应用级数据作用域共同拥有 `AppDatabase`、四类正式 Drift Repository 与当前平台的 `SecureCredentialGateway`，并把项目自有合同注入根 `DependencyGraph`。
- Android/Windows 默认 `main.dart` 启动时只打开应用私有数据库和平台安全存储 Gateway；新数据库保持空白，不自动写入曲目、来源、凭据或在线状态。
- 提供独立 `main_dev.dart`，只在显式选择该入口时创建内存数据库，并通过正式 Repository 写入经审计 HTML 的确定性示例状态。
- Dev Fixture 使用保留域 `https://fixture.invalid`、禁用来源与 `sourceDisabled` 曲目；不含凭据、用户路径、content URI、可播放 URL、收藏/历史或伪造连通成功。
- 初始化加载/失败使用固定、可访问且日志安全的文字；初始化失败、晚到完成和根作用域销毁都关闭所拥有的数据资源。

## 数据映射与边界

- 映射四首 HTML 示例曲目、四组专辑/艺人、两个明确标注的开发歌单、三项队列和 `A Quiet Orbit` 的十行双语时间歌词；所有写入都经过 Domain 构造与正式 Repository。
- Fixture 只能写入完全空白的临时数据作用域；发现任一曲目、歌单、队列项或来源即失败，不能覆盖用户状态。
- `lib/main.dart` 不导入 `dev_fixture`；生产代码除 `main_dev.dart` 外不得导入夹具目录。UI/Shell 不导入 Drift、SQLite、平台安全存储或 data 实现。
- 内存 Drift executor 仍封装在 `data/database`；Fixture 工厂只调用应用数据组合边界，不直接依赖数据库插件类型。

## 不在本批

- 不实现 REST Adapter、来源连接测试、OAuth/token refresh、凭据替换事务、Controller、搜索或正式业务页面。
- 不接 AudioEngine、真实播放、Seek、队列算法、文件扫描、MediaStore/SAF、Windows 文件授权或系统媒体会话。
- 不修改 Drift v1 Schema/快照，不新增依赖、权限、下载/离线能力、WebView、网络 Fixture 或生产演示曲库。

## 出口条件

- 生产工厂对 Android/Windows 选择正确 Gateway，共享并幂等释放数据库；构造中途失败不泄漏数据库。
- 显式开发入口通过真实内存 Drift 往返全部夹具，且默认入口与生产库无法引用或写入夹具。
- AppBootstrap 的 loading/success/failure/卸载晚到结果均有测试，错误不显示底层异常、路径或秘密。
- Phase 3 主指令出口继续成立：模型/Migration测试通过，Repository可替换 Fake，UI不直接访问数据库。
- lockfile、生成代码/v1快照、format/analyze/Flutter/Node/ZIP、本机 Android Debug 与目标实现提交的 GitHub Android/Windows Debug 全部通过；唯一一次手动 APK 必须绑定本批实现提交。
