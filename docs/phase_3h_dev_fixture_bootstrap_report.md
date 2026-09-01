# Phase 3H — 生产数据引导与显式 Dev Fixture 报告

2026-09-01。开始前已 fetch，并确认 `feat/secure-credential-gateway@9fcbd00` 与远端同步、工作树干净；从该提交创建 `feat/dev-fixture-bootstrap`，未在 main/master 开发。范围与出口见[计划](phase_3h_dev_fixture_bootstrap_plan.md)。

## 当前实际进度

本批完成 Phase 3 的生产数据组合与开发样本隔离：默认 Android/Windows 入口异步打开应用私有 Drift 数据库，构造四类正式 Repository 和对应平台安全凭据 Gateway，再由单一 `AppDataServices` 作用域交给 `DependencyGraph` 拥有。首次生产启动保持空库，不写演示数据、凭据或假来源状态。

独立 `main_dev.dart` 才会创建临时内存数据库并种入经审计 HTML 的 Fixture。当前业务路由仍是工程骨架，尚未把 Repository 数据组合成 Home/Search/Library/Settings 页面；REST Adapter、Controller 和 Phase 4 播放仍待后续独立批次。

## 生命周期、夹具与失败边界

1. `DatabaseAppDataServices` 共享一个数据库实例，构造 Library/Collection/Lyrics/MusicSource 四类正式实现；初始化失败、Gateway 构造失败和幂等 dispose 都有明确关闭路径。
2. `AppBootstrap` 只依赖工厂与项目合同，不导入 Drift 或安全存储插件。等待和失败文字固定；底层异常、数据库路径、URL 或凭据不会渲染到 UI。
3. 异步工厂在 Widget 卸载后才完成时立即释放返回的数据作用域，防止晚到初始化泄漏；正常根作用域也只释放一次。
4. Dev Fixture 经正式 Repository 写入四首审计曲目、四组专辑/艺人、两个歌单、三项队列和十行双语时间歌词。来源固定为禁用的 `https://fixture.invalid`，无 credentialRef、真实路径、content URI、artwork URI、可播放 URL、收藏、历史或 connected 状态。
5. Seeder 只接受完全空白的临时存储；默认 `main.dart` 无夹具导入。架构门禁同时禁止 UI/Shell 直接访问 data/Drift，并禁止其他生产入口引用 `lib/dev_fixture`。

## 本地验证

| 检查 | 当前结果 |
| --- | --- |
| Phase 3H 定向 | 新增 8 项：双平台生产组合、关闭失败路径、真实 Drift Fixture 往返、非空拒绝、完整 Graph 所有权，以及 Bootstrap loading/success/脱敏失败/晚到释放；与既有 Graph 回归合跑共 11 项通过 |
| 全量门禁 | lockfile 严格复现；137 个 Dart 文件 format 零改动、严格分析 0 问题；207 项 Flutter 含 32 张 Windows 宿主 Golden、29 项 Node、ZIP 24 全部通过；build_runner/make-migrations 后 g.dart 与 v1 快照零差异 |
| 架构边界 | 默认入口无 Fixture；Fixture 仅显式内存入口；Drift executor 仍只在 data 层；UI/Shell 无 data/DB/安全插件访问；无 WebView、网络、播放或生产假数据 |
| 本机 Android Debug | 默认生产入口构建成功，238,963,881 字节，诊断 SHA-256 `267b4265931d467e180751e32dbedd06cd65f3b3738b62c7a7cd9b5f2960dc0d`；48 份资产匹配、包名/YYMusic/`allowBackup=false` 正确，仅 v2 单 Debug 签名有效 |

## 云端与限制

本文件随实现提交前，目标实现 commit、Draft PR、GitHub push/PR/手动工作流和私有草稿 Release 均尚未产生，因此不提前记录成功。提交推送后必须分别核验 Linux checks、Windows 2025 Debug 与 Android Debug，并且只触发一次绑定完整实现 SHA 的手动工作流。

本机 Windows 仍因远程环境无法完成 UAC/Developer Mode 所需的 C++ 工具链配置，不声称本机 Windows 构建或运行成功。云端编译也不等于真实 Android KeyStore/Windows Credential Manager 的保存、重启、升级与设备迁移验收。APK 是临时 Debug 签名，不是正式 Release 包。

## 主要文件

- `lib/app/app_data_services.dart`
- `lib/app/database_app_data_services.dart`
- `lib/app/app_bootstrap.dart`
- `lib/app/dependency_graph.dart`
- `lib/dev_fixture/dev_fixture.dart`
- `lib/dev_fixture/dev_fixture_app_data_services.dart`
- `lib/main_dev.dart`
- `test/unit/dev_fixture_test.dart`
- `test/widget/app_bootstrap_data_test.dart`

GitHub 双平台和 APK 证据完成后，Phase 3 可按主指令出口关闭；下一批进入 Phase 4 Android/Windows 音频 POC，不把 REST、正式页面或来源 Controller 混入播放后端选择。
