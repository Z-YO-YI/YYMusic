# Changelog

## 2026-09-04 — Phase 4D Content URI 与受控 HTTPS 音频 POC

- 新增HEAD-only HTTPS探针，禁止自动重定向和响应持久化；将HTTP状态及offline/timeout/TLS失败映射为脱敏DomainFailure。
- 新增Android debug-only、不可导出、只读ContentProvider，仅暴露应用cache中的运行时生成WAV；main/profile不注册且不新增媒体/存储权限。
- 新增双平台loopback HTTPS服务器和candidate集成测试；短期自签名证书/私钥只在忽略目录运行时生成，原始文件立即删除。
- 新增仅供受控HTTPS POC使用的TLS绕过入口；默认candidate和生产Bootstrap保持不变，真实来源仍强制验证TLS。
- `foundation.yml`新增默认关闭的只读双平台来源POC模式，不使用Secret、不上传artifact、不创建Release。
- 153文件format、严格analyze、完整225项Flutter/32 Golden、31项Node、24项ZIP通过；Android Debug构建、48资产、Provider Manifest和v2单Debug签名通过。
- `913f3d75`标准PR运行33878401743的checks、Windows Debug、Android Debug均成功；专用运行33878710671的Windows HTTPS与Android HTTPS/`content://`均完成load/play/seek/completed且失败矩阵通过，artifact和匹配Release均为0。Phase4D出口关闭，但不外推为真机、实体扬声器、真实API、后台/焦点或许可证闭环。

## 2026-09-04 — Phase 4C 原生本地音频运行 POC

- 新增运行时确定性PCM16 WAV生成器，不提交用户音乐、媒体二进制或真实路径；固定3秒/16kHz/mono格式、96,044字节和SHA-256。
- 新增Windows/Android共用原生集成测试，覆盖load不自动播放、duration、play/position、seek、pause、volume/rate、completed、stop与dispose；生产入口继续不可用。
- 在已注册的foundation工作流增加默认关闭的只读双平台手动模式；Android emulator action固定完整SHA，不使用Secret、不上传产物、不创建Release。
- 普通push的Windows Debug上传保留14天的完整portable bundle，便于远程下载测试；PR不重复上传。
- 完整221项Flutter含32张Windows宿主Golden、149文件format、严格分析0问题、31项Node、24项ZIP、lockfile及生成/v1快照零差异通过；本机Android Debug和v2单Debug签名/48资产复核通过。
- 修复Windows托管runner无音频端点时position不推进：仅POC使用libmpv null sink，Android和生产默认创建路径不变。
- `622408e`专用运行33862786766 attempt 2在Windows/Android均成功；两边均完成load/play/seek/completed，专用运行无artifact/Release。用户明确授权将仓库设为公开后，账单限制不再阻塞标准runner。
- 无头运行不冒充实体扬声器、真机、后台/焦点、content URI或HTTPS验证；native许可证未闭合，候选仍不进入生产或发布。

## 2026-09-04 — Phase 4B media_kit 候选适配与原生打包验证

- 精确加入`media_kit 1.2.6`与`media_kit_libs_audio 1.0.7`；lockfile解析Android audio 1.3.8和Windows audio 1.0.9，未混入video库。
- 新增插件隔离的`MediaKitPlayerBackend`与项目自有`MediaKitAudioEngine`候选；只有单一backend文件导入插件类型，生产Bootstrap仍使用`UnavailableAudioEngine`。
- 映射Windows绝对文件URI、Android `content://`及无userinfo的HTTPS/Header瞬时来源；`open`固定不自动播放，插件错误只映射为脱敏`DomainFailure`。
- 将playing/completed/buffering/position/duration/buffer/volume/rate组合为既有八阶段Engine状态；串行化transport、Seek、音量、速率及并发幂等释放。
- 新增5项Fake backend测试，覆盖三类来源、状态与命令、0–1/0–100音量、错误脱敏、并发释放和非法输入；Fake不计作native播放证据。
- 完整219项Flutter含32张Windows宿主Golden、严格分析0问题、30项Node、24项ZIP、lockfile及生成/v1快照零差异通过。
- 本机Android Debug打包成功，APK为279083792字节、SHA-256 `f3026e694c597b83297405c6587d46dc2906aa422b471838796950f776c59dd8`；48资产、Manifest、权限、三种目标ABI audio-only库及v2单Debug签名已复核。
- Android原生JAR不携带LICENSE/NOTICE，Windows插件固定旧libmpv归档；传递许可证、真实双平台播放与性能未完成，因此候选不进入生产组合，本批不触发手动APK Release。
- 实现提交`b7e0b0f`的push运行33853006353与PR运行33853041607均为三个job success；该SHA没有workflow_dispatch或新Release。构建成功只代表解析/编译/打包，不代表扬声器输出、系统媒体会话或设备运行验收。

## 2026-09-04 — Phase 4A 播放核心合同与唯一状态源

- 新增脱敏`PlayableSource`与`PlaybackSourceResolver`，覆盖Windows绝对路径、Android `content://`及无userinfo的HTTPS临时流；locator/Header不进入字符串输出或持久化。
- 将AudioEngine升级为load/play/pause/stop/seek/volume/rate及独立八阶段事件合同；默认后端仍明确不可用，不伪造播放成功。
- `PlaybackState`覆盖当前曲目、位置、缓冲、时长、音量、速率、随机、循环、持久队列、输出设备和`DomainFailure`，对负时间、范围和错误阶段一致性做运行时验证。
- `PlaybackController`串行化命令，组合曲目解析与引擎事件，实现指定项/上一首/下一首、Seek夹紧、重复曲目、添加/下一首插入/移动/移除/清空、随机一轮与repeat off/all/one自动完成语义。
- `QueueController`改为同一PlaybackState的命令门面，不保存第二份队列；AppBootstrap初始化恢复CollectionRepository队列，但不自动加载或播放。
- 新增Android MediaSession/Windows SMTC共用Gateway与回调合同；平台更新失败不停止音频，根Graph统一初始化和幂等释放。
- 7项新增播放测试、完整214项Flutter/32 Golden、143文件format、严格分析0问题、30项Node、24项ZIP、lockfile及生成/v1快照零差异通过。
- 本机默认生产入口Android Debug构建成功；238997827字节、SHA-256 `ea40ebd646300b0f14c1dcef9aef2971d19fba6da515e83b6f88c8e05bd66ab1`，48资产、Manifest及v2单Debug签名已复核。
- 实现提交`ec508df`的push运行33845988715、PR运行33846020650与唯一手动运行33848236710均为三job success；私有草稿Release三资产已下载复核，APK为190735487字节，SHA-256、SHA256SUMS、metadata和API digest均为`3f95cea301d6710ac46a40a5fbfcd0d4561d91f310ca5d04506d5389a1272aa4`，48份资产匹配、Manifest禁用备份且v2单签名有效，临时副本已清理。
- 本批不新增音频插件、权限、可播放Fixture、下载/离线能力或Shell接线；Windows/Android真实音频POC尚未通过。

## 2026-09-01 — Phase 3H 生产数据引导与显式 Dev Fixture

- 新增`AppDataServices`生产组合：单一数据库共享四类正式Drift Repository，并按Android/Windows构造平台安全凭据Gateway；根Graph统一拥有和幂等释放。
- AppBootstrap异步建立生产空库，提供固定loading/脱敏failure状态；初始化中途失败、正常卸载与卸载后晚到完成均关闭所拥有资源。
- 新增独立`main_dev.dart`和内存Seeder；四首审计HTML曲目、四组专辑/艺人、两个歌单、三项队列和十行双语歌词全部经正式Repository往返。
- Fixture来源固定为禁用的`https://fixture.invalid`，无credentialRef、路径、媒体URI、可播放URL、收藏/历史或connected；默认`main.dart`与UI/Shell无法导入夹具/Drift实现。
- 不修改v1 Schema/快照、依赖、权限或可见业务页面；REST Adapter、来源事务、Controller和播放留后续批次。
- 8项新测试、完整207项Flutter/32 Golden、137文件format、严格分析、29项Node、24项ZIP、lockfile及生成/v1快照零差异已通过。
- 本机默认生产入口Android Debug构建成功；238963881字节APK的48资产、包名/标签/备份设置和v2单Debug签名已复核。
- 实现提交`27dd76c`的push运行33517332873、PR运行33517452005与触发前0/触发后1的唯一手动运行33518770911均为三job success；Draft PR #16保持待审核。
- 手动运行的私有草稿Release三资产已下载复核；APK为190701235字节，SHA-256、SHA256SUMS、metadata和API digest均为`e2d6e9be3d366a792c381662b3041f9ed9ac826e2d4c6bf19b8325c266e946e2`，48份资产匹配、Manifest禁用备份且v2单签名有效，临时副本已清理。

## 2026-09-01 — Phase 3G Android / Windows SecureCredentialGateway

- 新增共用版本凭据编解码/串行store核心、`FlutterSecureStringStore`与Android/Windows正式Gateway；插件类型不进入Domain/UI/Drift。
- 引用由192-bit安全随机生成且严格验证；冲突不覆盖，JSON字段排序、版本/类型/尺寸受限，并发底层访问串行、删除幂等。
- 新增日志安全`SecureCredentialFailure`；插件异常、引用、载荷与凭据不进入错误字符串。Android使用独立namespace/崩溃安全迁移、禁止静默reset与应用备份；Windows关闭旧格式扫描。
- 锁定`flutter_secure_storage 10.3.1`和Windows 4.2.2解析；不选需compileSdk37的11.0.0。不改v1 Schema，不接AppBootstrap、REST、Fixture、Controller、UI或播放。
- 10项定向、199项Flutter/32 Golden、130文件format、严格分析、29项Node、24项ZIP及生成/快照零差异已通过；本机Android Debug构建/v2验签/48资产/manifest复核通过。
- 实现提交`4daf380`的push运行33510086595、PR运行33510153174与唯一手动运行33511421874均为三job success；Draft PR #15保持待审核。
- 手动运行的私有草稿Release三资产已下载复核；APK为189393711字节，SHA-256、SHA256SUMS、metadata和API digest均为`2623eab9590f4f333bc7327ee4d4dea49ee5b6f6789219f129b44f1e7108bcdf`，48份资产匹配、Manifest禁用备份且v2单签名有效，临时副本已清理。

## 2026-09-01 — Phase 3F Drift MusicSourceRepository

- 新增MusicSourceConfig严格JSON/row mapper与正式`DriftMusicSourceRepository`，不将Drift类型暴露到Domain/UI。
- 公开Header/endpoint/字段映射按key排序确定编码，HTTPS URL、枚举、延迟、UTC测试时间和错误分类返回前重走Domain验证。
- sourceType/builtIn身份不可转换，内置来源不可删除；自定义来源删除保留用户TrackRef。数据库只保存credentialRef，不接触凭据值。
- 不修改v1 Schema/快照、不新增依赖/权限，不接AppBootstrap、安全存储/网络、Fixture、Controller、UI或播放；8项真实SQLite、189项Flutter/32 Golden、125文件format、严格分析、29项Node、24项ZIP及生成/快照零差异已通过。
- 实现提交`22d68f2`的push运行33503815038、PR运行33503837936与手动运行33504877925均为三job success；Draft PR #14保持待审核。
- 手动运行的私有草稿Release三资产已下载复核；APK为183604101字节，SHA-256、SHA256SUMS、metadata和API digest均为`db2946d4b416971b2fbb89cc754ba77cdf0c03f36aff3f84b2ad425a281c24a2`，48份资产匹配且v2单签名有效。

## 2026-09-01 — Phase 3E Drift LyricsRepository

- 新增LyricsDocument严格JSON/row mapper与正式`DriftLyricsRepository`，不将Drift类型暴露到Domain/UI。
- 缓存按完整TrackRef隔离，plain/synchronized逐行时间、双语文字、语言和偏移量可确定往返；upsert/remove不要求catalog row且删除幂等。
- 非数组、未知/缺失字段、错误类型、kind/时间/顺序/翻译不一致、损坏缓存时间及SQLite异常统一返回脱敏DomainFailure。
- 不修改v1 Schema/快照、不新增依赖/权限，不接AppBootstrap、LRC/网络、Fixture、Controller、UI或播放；6项真实SQLite、181项Flutter/32 Golden、122文件format、严格分析、29项Node、24项ZIP及生成/快照零差异已通过。
- 实现提交`1e45532`的push运行33499761224、PR运行33499787210与手动运行33500756816均为三job success；Draft PR #13保持待审核。
- 手动运行的私有草稿Release三资产已下载复核；APK为183604101字节，SHA-256、SHA256SUMS、metadata和API digest均为`fd71936ef590dc18b1e851572c21cbf6d10f157a495298022dec3f2dd384020a`，48份资产匹配且v2单签名有效。

## 2026-09-01 — Phase 3D Drift CollectionRepository

- 新增Playlist/Entry、Favorite、History和Queue严格row mapper与正式`DriftCollectionRepository`，不将Drift类型暴露到Domain/UI。
- 系统歌单唯一且不可改身份/删除；自定义歌单条目在事务内整体替换，删除歌单不删Track或来源引用。
- 队列支持重复TrackRef/currentEntryId和跨启动快照，自定义watch同时依赖queue_state/entries且不发布事务中间状态。
- 收藏幂等移顶；历史按完整TrackRef去重并只保留最新20条。损坏row/SQLite异常只返回脱敏DomainFailure。
- 不修改v1 Schema/快照、不新增依赖/权限，不接AppBootstrap、Fixture、Controller、UI或播放；10项真实SQLite、175项Flutter/32 Golden、119文件format、严格分析、29项Node、24项ZIP及生成/快照零差异已通过。
- 实现提交`9468c2a`的push运行33495498260、PR运行33495519334与手动运行33496511117均为三job success；Draft PR #12保持待审核。
- 手动运行的私有草稿Release三资产已下载复核；APK为183604101字节，SHA-256、SHA256SUMS、metadata和API digest均为`d6b03be16d907103b7b3bbb421108f82a32a06e7687d115194be73a86b9fffb9`，48份资产匹配且v2单签名有效。

## 2026-09-01 — Phase 3C Drift LibraryRepository

- 新增Track/Album/Artist严格row mapper与正式`DriftLibraryRepository`，实现initialize/watch/list/get/upsert/setAvailability/dispose全合同；Domain/UI不暴露Drift类型。
- upsert使用单事务+batch，替换Track艺术家关联、重建Album credits/聚合计数并清理无引用派生实体；watch只在提交后发布一致快照。
- Track/Album/Artist采用确定排序和`limit + 1`/offset分页；TrackRef跨来源不冲突，缺失引用返回脱敏notFound，损坏row/SQLite异常返回脱敏databaseCorrupted。
- `crypto`3.0.7从已锁定传递依赖提升为直接依赖，用sourceId+精确艺术家名SHA-256派生稳定内部ID；不改v1 Schema/快照，不新增原生包/权限。
- 新增9项真实SQLite Repository与1项Domain JSON有限数测试；116文件format、严格分析、完整165项Flutter/32 Golden、29项Node、ZIP24项及生成/快照零差异已通过。
- 实现提交`a155d65`的push运行33490505244、PR运行33490538057与手动运行33491551841均为三job success；Draft PR #11保持待审核。
- 手动运行的私有草稿Release三资产已下载复核；APK为183604101字节，SHA-256、SHA256SUMS、metadata和API digest均为`ed964e21cbf6e4994c3829b330399d4b30a6ee31f80a8d3d1089b87f6d380be2`，48份资产匹配且v2单签名有效。

## 2026-09-01 — Phase 3B Drift Schema 与首版 Migration

- 新增Drift/SQLite3双平台数据层：主指令15张持久化表、单行`queue_state`与`schema_migrations`，共17张表及10个显式索引；稳定TrackRef、独立QueueEntry和用户集合引用不因来源删除级联消失。
- schemaVersion1显式创建全部表、开启外键、记录UTC迁移审计并初始化空队列状态；关联表和歌单entry使用受控级联，位置/时间/类型/本地引用等关键约束由SQLite验证。
- 默认数据库仅在显式调用时使用应用支持目录和`NativeDatabase.createInBackground`，AppBootstrap未接线；不实现正式Repository/Controller/UI，不写歌曲、在线来源或明文凭据Fixture。
- 采用drift2.34.3、sqlite3 3.5.2、path_provider2.1.6、drift_dev2.34.5、build_runner2.16.0；不引入旧`sqlite3_flutter_libs`/sqflite，不新增权限。提交生成代码、v1 Schema快照并在CI重生成后要求零差异。
- 8项数据库测试覆盖创建/官方Schema验证、表/索引、约束、队列重复、外键/级联、来源删除引用保留、敏感列白名单和后台文件打开；锁文件、113文件format、严格分析、完整155项Flutter/32 Golden、29项Node、生成复现和ZIP24项本地通过。
- 实现提交`31121d4`的push运行33484750785、PR运行33484779370和手动运行33485752421均为三job success；Draft PR #10保持待审核。
- 手动运行的私有草稿Release三资产已下载复核；APK为183603621字节，SHA-256、SHA256SUMS、metadata和API digest均为`3bdd3a74f8344df0c5124ffe25eee8c01d0d8985639ed91ff9084dac67defc69`，48份资产匹配且v2单签名有效。

## 2026-09-01 — Phase 3A Domain 模型与数据合同

- 新增稳定`TrackRef`、独立`QueueEntry`、Album/Artist/Playlist/Favorite/History/Lyrics/MusicSourceConfig模型；持久时间要求UTC，队列顺序连续且允许重复曲目。
- 新增显式idle/loading/data/empty/error、完整Domain错误分类、分页及Library/Collection/Lyrics/MusicSource Repository合同；测试Fake可替换并由根Graph释放Library Fake。
- 来源配置只允许无凭据的HTTPS base URL、公开Header和受限字段路径；敏感Header/换行/可执行映射运行时拒绝，Credential字符串固定脱敏且不提供数据库序列化。
- 不安装Drift、不创建Schema/Migration/数据库文件，不接UI、HTTP、安全存储、播放或生产Fixture；新增16项Flutter合同测试与1项Node架构边界。108文件格式、严格分析、完整147项Flutter/32张Golden、29项Node和24份ZIP核验均通过。
- 实现提交8506afc的push运行33480316280、PR运行33480358335与手动运行33481171269均为三job success；Draft PR #9保持待审核。
- 手动运行的私有草稿Release三资产已下载复核；APK为175891537字节，SHA-256、SHA256SUMS、metadata和API digest均为`1500bd28956befbb697cbe160c388d25a1c900e6454b180bed4335aaec05b712`，48份资产匹配且v2单签名有效。

## 2026-09-01 — Phase 2J 跨平台队列与歌词原语

- 新增受控`YYQueueTile`、`YYLyricsLine`与`YYLyricsPlayerDock`；队列动作、歌词状态及Dock播放展示全部由调用方提供，不接入Controller、音频或持久化。
- Queue实现50/60密度、36/42封面、10圆角、26视觉动作与44dp命中；Lyrics实现future/past/active、双语、780字重、1.018缩放和6px环；Dock实现82最小高、50/40/38封面、34/44控制、响应式重排及最终26圆角。
- Android/Windows共享确定性Gallery Fixture；不排序队列、不Seek、不解析LRC、不自动滚动、不启动计时器，也不使用渐变或模糊封面背景。
- 新增7项Widget与3张1280×900/130%队列歌词板，三张已逐张审计，旧29张Golden未更新。91文件格式、严格分析、完整131项Flutter、32张Golden、28项Node和24份ZIP字节核验均通过。
- a20e0fb的push、PR、手动运行均为三job success；草稿Release三资产已下载复核，APK为175880481字节，SHA-256/API digest为`864a557af71841280ed938e80090a07e3bd7764a8e3680a17b6eef81e19af43f`且v2签名有效。

## 2026-09-01 — Phase 2I 跨平台来源与歌单卡片

- 新增受控`YYSourceCard`与`YYPlaylistCard`；来源状态标签/色调和歌单collection/create动作均由调用方提供，不创建业务模型或持久化。
- Source保留72/12/42/16/6几何并应用App.tsx最终13图标圆角；Playlist应用最终20/14圆角、桌面16/44/18及Phone13/40响应式尺寸，Create使用纯色虚线边界。
- Android/Windows共享确定性Gallery Fixture；不测试来源连接、不读取凭据、不生成真实歌曲计数、不访问Repository、数据库、队列或歌单写入。
- 新增5项Widget与3张1280×720/130%集合卡片板，三张已逐张审计，旧26张Golden未更新。85文件格式、严格分析、完整121项Flutter、29张Golden、28项Node和24份ZIP字节核验均通过。
- c2948e8的push、PR、手动运行均为三job success；草稿Release三资产已下载复核，APK为175843741字节，SHA-256/API digest为`3035e3b5a031ef283af098514c78ee8264a5d03ed3aa71f335d177da3ad11417`且v2签名有效。

## 2026-09-01 — Phase 2H 跨平台状态与反馈原语

- 新增受控`YYThemeSwatch`、`YYEmptyState`、`YYErrorBanner`与`YYSkeleton`；Gallery五个强调色入口改用30px视觉/44dp命中的Swatch。
- Empty State保留28/16内边距、24图标与10px/1.6文字；Error Banner复用12/14/15 notice几何和error token；Skeleton为静止纯色、默认填宽且无渐变。
- Android/Windows共享本地状态Fixture；重试只更新说明文字，不访问网络、Repository、计时器、持久化或生成假数据。
- 新增6项Widget与3张1280×720/130%状态组件板，三张逐张审计并修复默认Skeleton宽度；旧23张Golden未更新。80文件格式、严格分析、完整113项Flutter、26张Golden、28项Node和24份ZIP字节核验均通过。
- 9f71d14的push、PR、手动运行均为三job success；草稿Release三资产已下载复核，APK为175828689字节，SHA-256/API digest为`b9494ff75b5176b97ac11360a4b496c5182acdc5b0e875087a25d299989f6231`且v2签名有效。

## 2026-09-01 — Phase 2G 跨平台弹层原语

- 新增受控原生`YYContextMenu`、`YYDialog`、`YYBottomSheet`与`YYToast`；不使用Material默认弹层，不创建业务Overlay/Route/计时器。
- Context Menu保留224/244宽、20圆角、7内边距、30模糊并提升到44dp菜单命中；Dialog/Sheet使用不透明30圆角表面与72dp头尾，Toast保持42/420/14和live region。
- Android/Windows Gallery新增明确标注的本地Fixture；右键/长按、锚点避让、Toast队列/时长、播放/歌单/设备动作及正式业务弹层仍未接入。
- 新增6项Widget和3张1280×720/130%弹层组件板，三张已逐张视觉审计；既有20张Golden未更新。75文件格式、严格分析、完整104项Flutter、23张Golden、28项Node和24份ZIP字节核验均通过；GitHub结果以本阶段报告最终记录为准。
- a56d4aa的push、PR、手动运行均为三job success；草稿Release三资产已下载复核，APK为175818389字节，SHA-256/API digest为`836e97c46aef2ed0036aaec085b8fb6113beeb2fe363749a7dfa3e817f648a88`且v2签名有效。

## 2026-09-01 — Phase 2F 跨平台播放器表面

- 新增受控`YYMiniPlayer`、`YYDesktopPlayerBar`与只读`YYNowPlayingViewData`，复用最终SVG、Slider、Artwork、Theme和Glass；保留Mini64、Desktop88/76、封面54/50/48及44dp动作命中。
- 曲目信息、播放/下一首、完整Transport、进度预览/提交/取消、音量、歌词、收藏与队列均为独立动作；Repeat只表达受控视觉状态，不实现队列算法或模拟时间推进。
- Android/Windows Gallery新增明确标注的本地Fixture；正式Shell仍不接假播放器，不访问AudioEngine、QueueController、Repository、系统媒体会话或持久化。
- 新增4项Widget和3张1280×560/130%播放器组件板，三张已逐张视觉审计；旧17张基线不更新。69文件格式、严格分析、完整95项Flutter、20张Golden、28项Node和24份ZIP字节核验均通过；云端双平台结果以本阶段报告最终记录为准。
- a1eacd9的push、PR、手动运行均为三job success；草稿Release三资产已下载复核，APK为175792949字节，SHA-256/API digest为`df0b96062e96332206630ded3cc35117f244d31c079f2ec76c3f3b3d06a3254a`且v2签名有效。

## 2026-09-01 — Phase 2E Windows 导航基础与跨平台 Gallery

- 新增受控`YYWindowsSidebar`、`YYWindowToolbar`和Widgets-only Tooltip；1440/1024采用240dp展开侧栏，840采用72dp紧凑侧栏，保留42工具区、320 Inspector及88/76播放结构位。
- Windows Shell导航接入既有四条路由；正式Shell明确来源尚未接入，并在窗口Gateway存在前隐藏应用内窗口按钮，不伪造HTML的在线状态、歌曲数或系统窗口操作。
- Windows与Android共享原生Gallery路由；Windows增加明确标注且仅更新本页状态的Chrome Fixture。账户文字按App.tsx修正为`YY Listener / 本地账户`。
- 新增3项Windows交互测试和3张1440/1024/840原生Shell Golden；审查更新2张账户文字基线，旧Android导航几何不改。完整88项Flutter、17张Golden本地通过。
- 86d5cf5的push/PR/手动运行均为三job success；草稿Release三资产已下载复核，APK为175767817字节，SHA-256/API digest为`ee0030157e359d959373af760a09c4c23c7c6b7a0943a0771ecaf13bbd051a08`且v2签名有效。

## 2026-09-01 — Android Phase 2D 内容卡片与曲目行

- 新增受控原生`YYAlbumCard`与`YYTrackTile`，复用既有主题、字体、七种Artwork和图标；覆盖默认、Hover、Pressed、Focus、禁用、选中/播放及加载状态。
- Track主动作与更多操作使用独立命中/语义边界，Phone隐藏时长并约束长来源标签；Album选中语义不错误声明为互斥单选组。
- Gallery新增明确标注的本地Fixture，仅更新预览状态标签，不访问音频、数据库、网络、文件或持久化。
- 新增4项Widget和3张390×1080/130%真实字体Golden，旧11张不改；完整82项Flutter、28项Node、严格分析与24份ZIP字节核验通过。
- 9a3a345的GitHub手动运行33455489191完成checks、Android/Windows Debug、验签和资产核验；草稿Release三资产经独立下载复核，APK SHA-256为`5e1b7ca66b8ddd801f60999e1373e858f8ce83ac4e16e6dd23e43851437cd860`。

## 2026-09-01 — 私有草稿 Release APK 交付

- 8e6915a的GitHub运行已完成Android编译、Debug验签、48项资源比对及Windows构建，但Actions产物存储额度已满，未伪称存在可下载APK。
- 经用户明确允许，APK交付改为仅在workflow_dispatch手动运行时创建私有draft/prerelease；普通push/PR仍执行构建但不产生Release。
- Release只附加APK、SHA256SUMS及构建metadata，使用唯一run/attempt标签，不覆盖或删除既有资产；个人令牌不进入runner。
- 全局与非Android任务保持contents:read；Android任务单独申请contents:write，上传前的测试、验签与资源字节门禁不放宽。
- 4be8ba2的手动运行33451875605三项任务成功；三个草稿Release资产已独立下载，核对commit/run/metadata/API digest/SHA256SUMS并再次通过APK v2验签。

## 2026-08-31 — GitHub Android SDK 工具路径修复

- 隐藏文件修复9f08a71已在Linux通过源码/分析/测试；随后Android在SDK安装阶段暴露sdkmanager不在PATH的问题（exit 127）。
- 从ANDROID_HOME显式定位并校验cmdline-tools/latest/bin/sdkmanager，保留JDK与三个固定SDK组件版本；不安装新的Action或批量接受许可。
- 新增1项真实YAML合同回归，记录首次失败与第二次云端证据；PR #1保持待审核，不自动合并。

## 2026-08-31 — GitHub CI 隐藏参考文件校验修复

- 首次获得远程运行证据：cafb942的ZIP校验读取隐藏`.gitattributes`失败，Android任务跳过、未产生APK；不把本地回归通过当作云端成功。
- `Get-Item -LiteralPath`增加`-Force`，只允许校验器读取隐藏文件属性；24份原始参考、ZIP哈希、文件数量和字节比对不变，没有跳过失败门禁。
- 新增5项实际执行PowerShell校验器的Node回归，在临时副本中覆盖隐藏文件、隐藏文件篡改/缺失/多余与ZIP改动；Windows显式设置Hidden属性以复现Linux故障。
- 不改Flutter业务、设计基线、依赖、签名或账号/仓库权限；云端复验与证据见docs/ci_reference_audit_fix.md。

## 2026-08-31 — Android Phase 2C 输入与选择

- 新增YYSearchField，使用原生EditableText/选择手势/工具栏，支持IME组合输入、搜索提交、清空、错误公告与只读加载/禁用；不访问真实音乐服务。
- 新增受控YYToggle、YYSegmentedControl，共用触控/键盘/语义处理；保留46/28/22开关几何、分段14/11圆角，触控不小于44dp，支持RTL/减少动态与焦点自动滚入视野。
- Gallery实际外观开关接入根状态，新增纯本地文本与筛选示例；未加入假搜索结果、数据库或模拟音频。
- 新增11项Widget与3张130%真实字体Golden，旧8张不改；总计74项Flutter及23项Node检查。APK不在本机重建，云端状态仍待授权核验。

## 2026-08-31 — GitHub Actions APK交付

- 按用户要求，APK交付改由GitHub runner编译；补齐原工作流缺失的验签、资产比对、APK/校验和/构建身份上传与摘要下载链接。
- 固定官方upload-artifact v7.0.1提交，14天保留、严格文件白名单、不覆盖历史、失败不上传；不提交本地APK或签名密钥。
- 新增4项打包元数据测试与1项真实YAML门禁测试；云端运行/产物仍待GitHub连接器仓库授权，未宣称远程成功。

## 2026-08-31 — Android Phase 2B 导航与媒体基础控件

- 手机64dp/32圆角胶囊与平板72dp Rail 接入原有四条路由；599/600实时切换、SafeArea及根状态保留，Windows骨架不变。
- 新增原生受控 YYSlider：3dp轨道、14dp滑块、44dp命中区，拖动/取消、键盘、RTL、语义增减及Disabled/Loading；修复系统取消被识别器当作结束而误提交的问题。
- 新增七种 CSS 几何封面占位，采用 App.tsx 最终配色/尺寸与原生绘制，保留固定px偏移；Gallery只展示明确标注的示例，不伪造曲库或播放。
- 自定义低对比度强调色保留原值，仅增加可读导航边界；不改变正常珊瑚/深色翡翠基线。
- 新增14项Widget与5张Golden，保留既有40项回归和3张原始基线；无新增依赖、权限、系统安装，完整验证见Phase2B报告。

## 2026-08-31 — Android 优先 Phase 2A 设计基础

- 按用户最新要求先推进 Android；Windows 工具链与原生验收暂缓，保留 runner、布局分类和 CI，不标记整个 Phase 2 完成。
- 新增语义 Token、Light/Dark/System、五种预设及自定义 HEX；原色保留，文字/前景另行派生满足对比度的颜色；根 Controller 持有会话级外观。
- 按 App.tsx 原始 Sprite 接入44个 SVG，保留 POLISH_CSS 的字体、双环44dp账户头像、圆角与阴影；打包固定提交的 Inter / Noto Sans SC 及 OFL，不安装系统字体。
- 新增 YYButton / YYIconButton / YYSurface / YYGlassSurface / YYProfileHeader 和 Android 设计预览入口；触控、键盘、语义、减少动态/透明可验证，无 WebView、默认 Material 外观或假播放。
- 新增字体资产与架构检查、主题/对比度/控件/导航测试，以及3张原生 Golden。40项 Flutter 测试通过；Android Debug APK 构建及签名校验通过，未进行真机或网页像素一致性验收。

## 2026-08-31 — Android 工具链与 Debug 构建通过（Windows 待确认）

- 用户确认后复用现有 Flutter / Android Studio / JDK，仅补 Android 命令行工具 22.0、API 36 与 NDK 28.2.13676358。
- 配置用户级工具路径，统一 ADB 来源；原环境设置保存在本地忽略目录，未删除旧工具。
- 校验官方 Android ZIP 哈希和微软安装程序签名；Windows C++ 安装等待系统 UAC 确认，不绕过管理员权限。
- 记录安装范围、恢复方式及实际测试/构建状态，不改变设计参考、业务代码、项目依赖或发布签名。
- Android Debug APK 构建及签名校验通过；format/analyze、24 项 Flutter 测试、15 项 Node 测试和 24 个 ZIP entry 核验通过。Windows 尚未安装完成，不标记 Phase 1 全部完成。

## 2026-08-31 — Phase 1 工程骨架（构建出口待验证）

- 将旧 Sonic Gallery 的 13 个文件原样归档并单独提交，增加指纹测试。
- 使用 Flutter 3.47.2 创建 Android/Windows 原生 runner，品牌改为 YYMusic，不使用 WebView。
- 增加平台优先分类、三个空 Shell、根依赖注入、播放生命周期边界和独立 player/lyrics 路由。
- 增加分类、状态/滚动保留、路由返回、无障碍和 CI 配置测试，启用严格静态分析。
- CI 配置源码审计、分析/测试、Windows/Android Debug 构建；Action 固定 SHA、仅 contents:read。
- 本机 Windows 构建缺 Visual Studio；Android 工具/许可待确认，双平台出口未完成，不进入 Phase 2。

## 2026-08-31 — Phase 0 设计审计

- 校验 ZIP、App.tsx、基础 HTML、package.json 指纹，并锁定主指令文档本次 SHA-256。
- 归档完整导出包，复现 Sprite → 账户替换 → Polish 注入的最终参考合成。
- 提取 44 个 SVG、全部 81 个 CSS 规则块 / 203 个声明，生成可复核清单及映射。
- 记录四个页面、七个 Overlay、交互与模拟行为、状态、持久化、16 个媒体查询及层叠冲突。
- 建立 Token、三套 Shell 边界、视觉验收计划、依赖候选证据和双平台音频 POC 计划。
- 提供零外部依赖的生成/检查工具和测试；未进入 Flutter 骨架、页面实现或音频 POC。
- 保留原有 Sonic Gallery 源码与测试不变；未将它们自动纳入新 Git 基线。
