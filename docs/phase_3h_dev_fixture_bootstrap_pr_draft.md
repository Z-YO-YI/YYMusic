# PR 草稿：生产数据引导与显式 Dev Fixture

Head：`feat/dev-fixture-bootstrap`；Base：`feat/secure-credential-gateway@9fcbd00`。创建为 Draft，不自动合并、不改写历史。

## 变更

- 新增拥有单一数据库、四类正式 Repository 和平台安全 Gateway 的 `AppDataServices` 生产组合边界。
- AppBootstrap 在 Android/Windows 异步初始化空白生产数据作用域，显示固定加载/失败状态，并处理正常、失败及晚到完成的资源释放。
- 新增独立 `main_dev.dart` 和内存 Dev Fixture；四首审计曲目、歌单、队列与双语歌词均经正式 Repository 写入。
- Fixture 来源使用 `.invalid` 保留域且始终 disabled；不含凭据、路径、媒体 URI、网络请求、可播放 URL、收藏/历史或 fake connected。
- 默认入口与 UI/Shell 禁止引用 Fixture/Drift/data 实现；不改 v1 Schema、依赖、权限或现有可见页面。

## 测试

- 8 项 Phase 3H 新测试通过；定向组合含既有 Graph 回归共 11 项通过。
- 完整 207 项 Flutter/32 Golden、strict analyze 0 问题、137 文件 format 零变化已通过。
- lockfile 严格复现；Node 29、ZIP 24、build_runner/Drift v1 生成零差异已通过。
- 本机 Android 默认生产入口 Debug 已构建；238,963,881 字节 APK 的 48 资产、Manifest 和 v2 单 Debug 签名复核通过。
- GitHub push/PR/唯一手动运行与草稿 Release：实现提交推送后补充，不使用旧 Phase 3G 证据。

## 影响与未验收项

影响限于 app 数据组合/生命周期、显式开发 Fixture、测试与文档。生产首次启动现在会在应用支持目录打开空白数据库并构造平台安全 Gateway，但不会读取或写入秘密，也不会生成演示曲库。

REST Adapter、来源凭据替换事务、Controller、正式业务页面、AudioEngine、真机 KeyStore/Credential Manager、本机 Windows 构建和安装运行均未验收。
