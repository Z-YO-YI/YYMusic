# Phase 0 依赖候选与证据

2026-09-05 当前工程决策（ADR-044）：锁定的 just_audio 0.10.6 / just_audio_windows 0.2.3
由应用 Bootstrap 正式创建一个根后端。依据 Phase4L 真实双平台运行、Phase4M/N 完整材料与包内校验、
Phase4O 许可查看；保持无代理/Header、无下载，REST 仍需 Adapter。`media_kit` 继续 rejected/inactive。
这不是应用发行批准；未提高原生 manifest 的 scope，不把六包许可证清单说成覆盖所有依赖。
下文 Phase0 候选表及后续隔离候选文字均保留当时归属，最新接线以 Phase4P 报告为准。

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

## Phase 4A 合同结果（2026-09-04）

项目已在隔离POC分支将`media_kit 1.2.6`和对应audio native libs加入pubspec，但生产组合仍未选择它。项目自有`PlayableSource`、`PlaybackSourceResolver`、`AudioEngine/AudioEngineState`、完整`PlaybackState`和`MediaSessionGateway`已确定，候选只能在`lib/playback`或`lib/platform`适配器内出现，不能改变UI/Domain。该候选现已通过Android/Windows本地文件、网络URL、HTTP Header、Seek及Android `content://`受控原生矩阵；正式选择仍取决于原生二进制分发/License、实体设备与生命周期审核。

回退比较项是just_audio加Windows backend，而不是单独just_audio。`just_audio_windows 0.2.3`公开能力含本地/URL/Seek/playlist/loop/shuffle，但请求Header项为空；`just_audio_media_kit 2.1.0`支持Windows但声明忽略shuffle order。YYMusic的随机顺序已经由PlaybackController负责，因此后者限制不直接否决，但带认证Header的网络测试与原生依赖仍必须单独通过。来源：[media_kit](https://pub.dev/packages/media_kit)、[media_kit维护者仓库](https://github.com/media-kit/media-kit)、[just_audio_windows](https://pub.dev/packages/just_audio_windows)、[just_audio_media_kit](https://pub.dev/packages/just_audio_media_kit)。

## Phase 4B media_kit候选解析与阻断项（2026-09-04）

POC分支精确声明`media_kit 1.2.6`与`media_kit_libs_audio 1.0.7`，lockfile解析Android audio
1.3.8、Windows audio 1.0.9；聚合包也解析iOS/macOS/Linux audio实现，但YYMusic本阶段仍只构建
Android/Windows，未引入`media_kit_video`或`media_kit_libs_video`。官方API确认初始化先于Player、
`open(play:false)`、文件/URL、HTTP Header、Seek、独立状态流、0–100音量和异步dispose；插件只
进入playback backend文件，不进入Domain/UI/Shell/生产组合。

本机Android构建实际下载Android v1.1.8四ABI默认JAR，package脚本只用MD5固定下载。当前APK
包含arm64-v8a/armeabi-v7a/x86_64的`libmpv.so`与`libmediakitandroidhelper.so`，不含video库，
权限仍只有既有Debug网络权限与Android生成的动态receiver权限。四个下载JAR各只有两个native
entry，没有LICENSE/NOTICE；Windows插件则固定下载2023-09-24、mpv commit 652a1dd的归档。

因此“wrapper为MIT”不足以批准发行。libmpv/FFmpeg精确编译flags、LGPL及其他传递库NOTICE、
对应源码提供和用户替换策略仍须完成；在这项发布审核与真实双平台播放矩阵都通过前，候选保持
Draft POC，不进入生产Bootstrap，也不为该实现触发手动APK Release。回退候选B仍保留，不因
media_kit能编译就取消比较。

Phase4C/4D随后补齐受控原生运行矩阵：Windows与Android本地WAV、双平台HTTPS/Header、Android
`content://`及HTTP/offline/timeout/TLS脱敏失败均通过，同一专用运行无artifact或Release。该结果解除
“仅编译未运行”的阻断项，但不改变上述传递许可证阻断，也不证明实体设备输出、后台/焦点或真实API。

来源：[media_kit 1.2.6](https://pub.dev/packages/media_kit)、
[media_kit API](https://pub.dev/documentation/media_kit/latest/)、
[media_kit_libs_audio 1.0.7](https://pub.dev/packages/media_kit_libs_audio/versions)、
[Android audio build](https://github.com/media-kit/libmpv-android-audio-build/releases/tag/v1.1.8)、
[Windows audio build](https://github.com/media-kit/libmpv-win32-audio-build/tree/2023-09-24)、
[LGPL 2.1](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html)。

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

## Phase 3F MusicSourceRepository依赖结果

本批只复用Dart SDK内置`dart:convert`和已锁定Drift，`pubspec.yaml`与`pubspec.lock`不变；不引入HTTP、OAuth、REST Adapter或安全存储插件。公开配置Map使用排序JSON写入既有列，`credentialRef`仅作为不透明引用保存；真正的SensitiveCredential仍完全位于后续SecureCredentialGateway实现边界。

## Phase 3G 安全存储选择（2026-09-01）

本批新增直接依赖[flutter_secure_storage 10.3.1](https://pub.dev/packages/flutter_secure_storage/versions)，实际lockfile解析Android同版本与Windows实现`flutter_secure_storage_windows 4.2.2`、`win32 6.4.0`。10.3.1官方Android构建使用compileSdk 36/minSdk 23，与YYMusic现有compile/target SDK 36及minSDK 24兼容；11.0.0要求compileSdk 37，故不为追随major而擅自抬升项目SDK。Windows插件仍要求原生工具链/ATL，必须以GitHub Windows 2025构建结果为准，本机Android成功不能替代该证据。

插件只由`platform/secure_credentials`适配器导入。Android使用独立命名空间、RSA-OAEP/AES-GCM迁移选项，并在应用Manifest禁用Auto Backup；失败不回退到SharedPreferences、文件、Drift或其他明文存储。Windows关闭旧版兼容迁移，使用平台保护存储；应用不申请网络、媒体、存储、通知或生物识别权限，也不把凭据同步到云端。

参考：[10.3.1 Android配置](https://raw.githubusercontent.com/juliansteenbakker/flutter_secure_storage/v10.3.1/flutter_secure_storage/android/build.gradle)、[插件README](https://raw.githubusercontent.com/juliansteenbakker/flutter_secure_storage/v10.3.1/flutter_secure_storage/README.md)、[Windows 4.2.2 API](https://pub.dev/documentation/flutter_secure_storage_windows/latest/)、[Android Keystore](https://developer.android.com/privacy-and-security/keystore)、[Android备份规则](https://developer.android.com/identity/data/autobackup)、[Windows密码处理与DPAPI](https://learn.microsoft.com/en-us/windows/win32/secbp/handling-passwords)。本批不接AppBootstrap、REST Adapter或Controller；数据库继续只保存随机`credentialRef`。

## Phase 3H 数据组合与 Fixture 依赖结果

本批不新增或升级依赖，`pubspec.yaml`和`pubspec.lock`保持Phase 3G解析。生产工厂复用已锁定的Drift/path_provider/flutter_secure_storage；显式开发入口复用`NativeDatabase.memory()`，没有引入mock数据库、fixture生成器、HTTP、音频、文件选择或额外平台插件。

内存executor的构造仍封装在`data/database`，Dev Fixture只依赖应用数据作用域和Domain合同。`flutter pub get --enforce-lockfile`已严格复现，build_runner与drift_dev重新生成后g.dart/v1快照零差异；18个不兼容约束内的新版本仅由工具提示，不在本批做无关升级。

## Phase 4E just_audio备用候选解析结果（2026-09-05）

本批精确加入`just_audio 0.10.6`和`just_audio_windows 0.2.3`，实际新增解析
`just_audio_platform_interface 4.6.0`、`just_audio_web 0.4.16`、`audio_session 0.2.4`及
`rxdart 0.28.0`。Android Gradle实际解析AndroidX Media3 1.4.1的ExoPlayer、DASH、HLS和
SmoothStreaming模块；没有just_audio专属SO。Windows包构建一个WinRT MediaPlayer插件，CMake的
bundled libraries为空，不下载或捆绑额外Windows播放器DLL。

包内许可与构建文件指纹见[Phase4E清单](phase_4e_dependency_license_inventory.md)。just_audio主项目为
MIT，但其LICENSE同时收录ExoPlayer Apache-2.0全文；rxdart为Apache-2.0，其余新增包为MIT。该记录
不构成法律结论，最终应用仍需可复核的第三方NOTICE/许可展示。

`just_audio_windows`能力表不声明直接请求Header支持。因此候选backend用显式能力标志失败关闭；
本批不启用或评估just_audio本地代理，不增加Android cleartext配置。Android直接Header与Windows认证来源
进入Phase4F单独验证；未通过前不能把顶层聚合能力表当成YYMusic结论。生产入口继续使用
UnavailableAudioEngine，不添加缓存、StreamAudioSource、下载或离线API。

## Phase 4F just_audio原生运行结果（2026-09-05）

`just_audio` Android API36原生运行已通过运行时生成WAV的load不自动播放、3000 ms duration、
position、seek、pause、volume/rate、completed、stop与dispose；运行时继续显式关闭Header代理和Header能力。
`just_audio_windows`的WinRT适配在真实运行中暴露0/0提前completed，项目层已只在实际播放后接受completed，
对应回归测试通过。

修复后Windows MediaPlayer能够load并保持ready，但GitHub Windows Server 2025在play后20秒仍没有position；
后续预检成功启动AudioEndpointBuilder/Audiosrv，却确认可用播放端点为0。当前远程Windows会话也为0端点，
且Developer Mode关闭阻止本机构建plugin symlink。因此现有环境不能满足Windows真实端点验收，不能以Fake、
构建成功或Android结果替代。Phase4F保持未关闭，未继续HTTPS/content URI小批，`just_audio`仍是隔离备用候选。

## Phase 4G media_kit原生分发审计结果（2026-09-05）

四个Android v1.1.8 JAR的GitHub release SHA-256与本机下载完全一致；当前APK中三ABI
`libmpv.so`/`libmediakitandroidhelper.so`也逐entry相等。Windows固定归档的SHA-256为
`583af5a291fc99ae2641794ede1955c368eb4c19dc05f4f0a9c7f9456edeb6a8`，其中`libmpv-2.dll`
与Phase4C GitHub Windows bundle字节一致。实际SO/DLL内嵌配置都关闭GPL/nonfree，libav模块报告
LGPLv3+；因此不再把许可模式当作未知猜测。

发布结论仍为阻断。Android构建从可变main克隆helper，release JAR只有两个SO；Windows release前最近
历史脚本仍启用GPL/nonfree，与实际DLL相反，workflow允许未记录自定义命令并恢复可变cache，静态组件
revision/patch无法完整映射。两个归档都缺LICENSE/NOTICE、对应源码清单和重新链接材料。机器清单固定为
`inventory-only`/`blocked`，生产仍使用UnavailableAudioEngine；完整证据见
[Phase4G清单](phase_4g_media_kit_redistribution_inventory.md)。后续只能从不可变来源重建并承担发行材料，
或继续与音频选型解耦的业务实现，不能把wrapper MIT或Debug构建成功当作发布许可。

## Phase 4H 被拒绝候选的活动依赖处置（2026-09-05）

Phase4G的`blocked`结论现在落实为工程状态：`media_kit 1.2.6`、`media_kit_libs_audio 1.0.7`
及11个只由它们带入的传递包已从当前lockfile移除；两个适配器、对应Fake/原生测试、Windows生成注册和
四个历史手动POC job也不再活动。Git历史、Phase4B—4G报告和原生哈希清单保留，不删改既有运行证据。

机器manifest明确区分“历史审计对象”和“当前依赖”，固定`decision=rejected`与
`activeDependency=false`。门禁要求pubspec/lockfile、生产入口、活动候选文件、双平台生成注册、CI输入和
Android APK均不得重新出现该候选；若未来从不可变源码建立新候选，必须通过新的显式决策和完整发行审查，
不能直接翻转历史清单。

当前音频选择仍未完成。`just_audio`只保留为隔离备用候选，其Android原生POC已通过、Windows仍缺真实
播放端点；生产继续使用`UnavailableAudioEngine`。移除media_kit不授权Phase5、不引入代理、下载、缓存、
离线保存、WebView、后台服务或新的平台权限。

## Phase 4L/4M 当前候选证据更新（2026-09-05）

上方Phase4F/4H缺Windows端点的文字为历史结果。Phase4L同一 `8c4aa6e` 的 Android 三来源原生、
Windows 本机两轮 file/HTTPS均已通过，参考[实际计时与归档证据](phase_4l_native_https_report.md)。
这补齐当前无Header候选的播放运行证据，但不扩大认证Header、后台、听感或发行结论。

Phase4M将Phase4E六个Pub包的完整许可原文和两个原生构建文件指纹写入
`docs/legal/just_audio/manifest.json`。源码与实际APK/Windows NOTICES.Z均须逐包全文校验，
沿用Flutter自动汇总/LicenseRegistry，而不是另外维护可能漂移的原文副本。
详细范围见ADR-041：本批仅关闭六个音频Dart包的来源与打包覆盖，不伪称已经审完全部Maven传递材料，
也不接生产AudioEngine。完整原生NOTICE与最终选型/许可展示仍是正式接线前的剩余工作。

## Phase 4N 原生材料（2026-09-05）

当前Media3实际Debug/Profile闭包51项、Release48项均已按精确POM/父POM和归档哈希核对，
保留三份完整许可原文并打包为单一JSON资产。没有新增或升级运行时依赖。
Windows无额外播放器DLL的结论不变，随两端携带的Android材料明确标注平台范围。
许可查看与正式音频入口尚待下一批；本批不是整个应用发行批准。详见ADR-042及
[Phase4N报告](phase_4n_native_notices_report.md)。
