# Phase 0 依赖候选与证据

核验日期：2026-08-31。仅查询维护者发布的pub.dev页面与平台官方资料，不使用社区推荐作为平台支持证据。下表版本是**查询快照，不是安装决定/版本锁**；Phase 1选择Flutter SDK后重新解析当前兼容稳定版本并提交lockfile。本轮pubspec未改、未安装依赖、未声称插件双平台已验证。

## 12类候选

| 类别 / 候选及来源 | Windows / Android | 维护快照 / License | 原生配置与测试能力 | 选择理由 / 回退 |
| --- | --- | --- | --- | --- |
| 状态：[flutter_riverpod](https://pub.dev/packages/flutter_riverpod) | 均支持 | 3.4.2，33天前发布；MIT | 无业务原生配置；Provider override/Fake，Controller单测 | 暂定，根作用域持有唯一状态；回退自有Controller+Listenable，不改变Domain接口 |
| 路由：[go_router](https://pub.dev/packages/go_router) | 均支持 | 18.0.0，6天前；BSD-3-Clause | route stack/返回/重定向Widget测试 | 暂定，player/lyrics独立；回退Flutter Router API，UI不依赖插件route类型 |
| 数据库：[drift](https://pub.dev/packages/drift) | 均支持 | 2.34.3，34天前；MIT | SQLite原生库与代码生成需SDK解析；内存DB/Migration/事务测试 | 暂定，关系/队列/搜索一致性；回退自有Repository下的SQLite实现 |
| HTTP：[dio](https://pub.dev/packages/dio) | 均支持 | 5.11.0，36天前；MIT | Android网络配置；adapter Fake、取消/超时/脱敏测试 | 暂定，拦截/取消/映射；回退自有HttpGateway实现。不暴露其下载API |
| 安全存储：[flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) | 均支持 | 11.0.0，24天前；BSD-3-Clause | Windows文档要求C++ ATL；Android加密/备份迁移按所选版本配置；真机save/read/delete/升级测试 | 暂定，DB仅credentialRef；回退平台自有安全存储Gateway，失败不可降级明文 |
| 音频A：[media_kit](https://pub.dev/packages/media_kit) | 原生双平台 | 1.2.6，8个月前；Dart层MIT | 初始化/对应audio native libs、content URI/HTTPS/header探测、播放状态流；原生二进制及传递许可另审 | 优先POC同一核心；未过POC不锁定。回退音频B |
| 音频B：[just_audio](https://pub.dev/packages/just_audio) | Android支持；Windows需额外backend | 0.10.6，2个月前；页面标Apache-2.0/MIT | 官方列just_audio_media_kit/just_audio_windows等Windows实现；逐backend验证，不能只看顶层平台标签 | 与A同套合同测试比较；backend未核验不进入正式架构 |
| 后台播放：[audio_service](https://pub.dev/packages/audio_service) + [audio_session](https://pub.dev/packages/audio_session) | Android支持；不宣称Windows支持 | 0.18.19 /0.2.4，均2个月前；均MIT | service/notification/media session/audio focus；后台/耳机/蓝牙/打断真机测试 | Android候选，Windows走独立SMTC Gateway；回退原生MediaSession服务。不能把音频引擎与系统媒体会话混为一物 |
| 文件选择：[file_selector](https://pub.dev/packages/file_selector) | 双平台选文件；目录能力按功能表区分 | 1.1.0，9个月前；flutter.dev，BSD-3-Clause | Windows file/folder；Android长期媒体授权另接MediaStore/SAF，不假设path持久有效；拒绝/撤销测试 | Windows暂定；Android使用平台Gateway；回退原生选择器 |
| 拖放：[desktop_drop](https://pub.dev/packages/desktop_drop) | Windows支持；Android标preview，不依赖其完成移动端导入 | 0.8.2，4天前；Apache-2.0 | C++插件、批次/目录扫描取消、混合类型集成测试 | 仅Windows候选；回退Win32 DropGateway或文件选择器 |
| 窗口：[window_manager](https://pub.dev/packages/window_manager) | Windows支持；Android不适用 | 0.5.2，57天前；MIT；上游有迁移nativeapi提示 | 初始化/无边框/拖动/最小化/全屏恢复、多显示器可见性测试 | 暂候选，迁移风险需评审；回退自有Win32 Gateway，Android System UI独立 |
| Metadata：[audio_metadata_reader](https://pub.dev/packages/audio_metadata_reader) | 均列支持，纯Dart | 1.7.1，24天前；MIT；unverified uploader | File API不等于Android content URI授权；隔离解析/损坏文件/编码/封面大图测试 | 候选而非已选；回退平台Metadata Gateway；只读用户音频，不调用写标签功能 |
| 图片缓存：[cached_network_image](https://pub.dev/packages/cached_network_image) | 均支持 | 4.0.0，2天前；MIT | 用flutter_cache_manager落盘；限尺寸/过期/错误/凭据URL测试，自定义YY占位 | 仅Artwork候选，不用于在线音频；回退Flutter ImageProvider+受控内存缓存；最新major需兼容验证 |

“活跃发布”不等于可靠性担保；未全量审查issue/backlog、native binaries或传递依赖，也未完成License分发审查。所有第三方类型仅在data/platform/playback实现内部，UI只消费自有接口/ViewModel。

## 关键证据结论

- just_audio在Windows须额外backend，不能拿Android播放成功证明双平台成功。[官方Windows说明](https://pub.dev/packages/just_audio#windows)
- audio_service系统媒体控制支持不等于Windows SMTC支持；Windows走自有平台实现。原生API边界参考 [Microsoft SMTC](https://learn.microsoft.com/en-us/uwp/api/windows.media.systemmediatransportcontrols)。
- Android本地媒体访问参考 [共享媒体存储官方文档](https://developer.android.com/training/data-storage/shared/media)，后台播放参考 [Android官方背景媒体指导](https://developer.android.com/media/platform/mediaplayer/background)。实际权限/target SDK/前台服务要求在Phase 1与Phase 10再次核验，不照搬HTML或插件视频样例中的多余权限。
- media_kit网页示例包含视频/存储广泛权限；YYMusic只按音频与实际来源需求申请权限，不因示例代码就申请视频或写外部存储。

## 决策门槛

可以现在锁定：一个仓库/三套Shell/一套Domain、数据与播放状态；自有Gateway隔离；SQLite关系模型方向；无WebView/无下载/无明文凭据。

不能现在锁定：音频backend、native lib打包策略、SDK/target SDK具体版本、字体和Golden容差。双平台音频POC计划见audio_poc_plan.md；POC在Phase 4实际执行，Phase 0只制定方案。

## Phase 1 解析结果（2026-08-31，覆盖上面的阶段快照状态）

本机已有Flutter 3.47.2 stable / Dart3.13.2；未升级SDK。实际pub解析并提交lockfile：flutter_riverpod3.4.2、go_router18.0.0；开发依赖flutter_lints6.0.0与[yaml3.1.4](https://pub.dev/packages/yaml)（MIT，维护者tools.dart.dev，仅解析CI测试配置）。没有安装数据库/音频/窗口等其余候选。

选用Riverpod的ProviderScope集中管理和替换依赖，不将其类型暴露给Shell/Controller；go_router使用StatefulShellRoute和独立根路由，包在AppRouter中。[Riverpod Providers](https://riverpod.dev/docs/concepts2/providers)、[go_router配置](https://pub.dev/documentation/go_router/latest/topics/Configuration-topic.html)。

pub提示9个传递包存在不兼容约束的新版本，当前解析成功，不执行major强制升级或忽略SDK约束。go_router传递引入material_ui/cupertino_ui；客户端只使用WidgetsApp及自有文本控件，不代表默认Material视觉已获许可。依赖已通过本机分析/测试不等于原生双平台构建通过。

## Phase 2A Android 解析结果

新增直接依赖 [flutter_svg2.3.0](https://pub.dev/packages/flutter_svg)（flutter.dev发布、MIT、支持Android/Windows），锁文件记录实际版本与包哈希；用于原始本地SVG，不使用网络构造器或默认Material图标。对应组件用真实44个SVG解码/渲染测试验证，Android Debug实际构建通过；Windows原生验收仍待完成。

新增传递包：http1.6.0、path_parsing1.1.0、petitparser7.0.2、vector_graphics1.2.3、vector_graphics_codec1.1.13、vector_graphics_compiler1.3.0、xml7.0.1。http为SVG包的传递依赖，本批UI无网络请求，不新增生产网络/媒体权限。没有升级已有Riverpod/go_router或安装音频/数据库包。

Inter/Noto Sans SC以Google Fonts固定提交原文件进入应用assets，OFL许可/哈希/体积详见design_assets.md；不是新增运行时字体服务依赖。UI隔离包的原则延续：flutter_svg只出现在YYIcon，业务UI使用自有组件；Riverpod/go_router仍只出现在app。

## Phase 3A 依赖结果

Domain模型、Repository合同、SecureCredentialGateway和测试Fake只使用Dart/Flutter SDK已有类型，没有修改pubspec或lockfile。Drift仍是Phase3数据库候选而不是已安装决定；版本、生成器、SQLite原生库和双平台构建证据将在独立Schema/Migration批次按当时官方资料重新核验。当前不得用Fake或接口存在冒充数据库已完成。

## Phase 3B 数据库选择（2026-09-01）

| 包 | 选择 | 双平台/维护/License | 使用边界与回退 |
| --- | --- | --- | --- |
| `drift` | `^2.34.3` | 官方pub.dev当前稳定版；Android/Windows；MIT | 只在`data/database`，生成row不进入Domain/UI；若build hook或迁移证据失败则本批停止，不退回只支持Android的sqflite |
| `sqlite3` | `^3.5.2` | 官方当前稳定版；Android/Windows预编译库；MIT；默认二进制有SHA-256与SLSA3说明 | 直接依赖以锁定原生引擎合同；使用默认SQLite，不启用SQLCipher/Multiple Ciphers或外部下载功能 |
| `path_provider` / `path` | `^2.1.6` / `^1.9.1` | Flutter官方插件支持Android SDK24+与Windows10+；BSD-3-Clause / Dart基础包 | 仅默认数据库路径；测试注入内存executor，不调用平台目录。失败时允许调用方注入自有数据库路径 |
| `drift_dev` / `build_runner` | `^2.34.5` / `^2.16.0` | 官方生成/迁移工具；MIT / BSD-3-Clause；仅开发依赖 | 生成代码和schema快照提交并受测试保护；业务运行时不得调用生成器 |

官方Drift原生平台文档说明2.32起`NativeDatabase`在Android/Windows无需`sqlite3_flutter_libs`等额外原生包，SQLite由`sqlite3` build hooks随应用打包；因此不选`drift_flutter`及旧原生库组合，避免重复或过时二进制。默认文件通过`getApplicationSupportDirectory()`定位，使用`NativeDatabase.createInBackground`避免SQLite I/O阻塞UI isolate；应用本批不接线，不会在启动时创建数据库。

依赖来源：[Drift](https://pub.dev/packages/drift)、[原生平台说明](https://drift.simonbinder.eu/platforms/vm/)、[SQLite build hooks](https://pub.dev/documentation/sqlite3/latest/topics/hook-topic.html)、[path_provider](https://pub.dev/packages/path_provider)、[迁移测试](https://drift.simonbinder.eu/migrations/tests/)。本批不新增网络、媒体、存储权限；SQLite文件属于应用私有支持目录，敏感凭据仍只允许SecureCredentialGateway保存。

## Phase 3C Repository映射依赖结果

`crypto` 3.0.7在Phase3B lockfile中已是pub.dev传递依赖；本批因生产mapper需要SHA-256派生可复现artist ID，将同一已锁版本声明为直接依赖。它是纯Dart、BSD-3-Clause，不新增Android/Windows插件、原生二进制、权限或运行时网络。来源：[crypto](https://pub.dev/packages/crypto)。

Drift使用边界不变：事务、batch、watch和limit/offset只存在`data/repositories`，Domain/UI不导入。实现依据[transactions](https://drift.simonbinder.eu/dart_api/transactions/)、[writes](https://drift.simonbinder.eu/dart_api/writes/)、[streams](https://drift.simonbinder.eu/dart_api/streams/)和[selects](https://drift.simonbinder.eu/dart_api/selects/)；`drift_dev`继续仅属dev_dependencies，生产Repository不导入其Schema验证扩展。

## Phase 3D CollectionRepository依赖结果

本批只复用已锁定的Drift/Dart SDK，`pubspec.yaml`和`pubspec.lock`不变；不增加原生插件、网络包、权限或安全存储实现。Playlist/Queue整体替换与Favorite/History组合写入继续使用Drift事务语义；Queue watch通过`readsFrom`显式声明两张表，不引入额外stream组合库。

## Phase 3E LyricsRepository依赖结果

本批只复用Dart SDK内置`dart:convert`和已锁定Drift，`pubspec.yaml`与`pubspec.lock`不变；不引入LRC解析、HTTP、文件选择、安全存储或平台插件。JSON只作为既有`lyrics_cache.lines_json`的内部确定性编码，解码后仍必须通过Domain构造验证；不会把原始在线响应或文件内容直接当成可信row。
