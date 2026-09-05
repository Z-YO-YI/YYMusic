# YYMusic 架构决策记录

ADR-001至008记录Phase 0边界与规划；ADR-009起记录Phase 1迁移及实现选择。实际已存在模块见architecture.md，不把规划当作全部实现。

## ADR-001：原生 Flutter 与设计参考隔离（确定）

唯一正式客户端是Flutter Widget；React/Vite/Tailwind/Blob/iframe只保存在design_reference。构建阶段提取SVG，不在Flutter启动时解析App.tsx/HTML，不加载源JavaScript。所有Fixture通过开发/测试注入，Release不包含参考工程。

## ADR-002：平台优先、窗口宽度实时分类（确定；横屏解释待视觉复核）

Windows先分1440/1024；Android以600决定Phone/Tablet，然后orientation由当前width>height决定。三套Shell不各建一个项目，也不各建播放控制器。844×390横屏在该规则下是TabletLandscape；“Phone横屏”验收指测试设备尺寸，低高度player布局独立于设备命名。若后续要改变这个分类，必须修改ADR并获得范围确认，不能悄悄用设备型号判断。

## ADR-003：业务真相位于根依赖图（确定）

App bootstrap构造唯一PlaybackController、QueueController、Repositories、Theme等Controller。Shell/route创建销毁不重建AudioEngine。队列entryId与trackId分开，允许重复曲目且排序稳定；UI不持有插件类型，不直接HTTP/SQL/文件扫描。Controller状态显式idle/loading/data/empty/error，播放器有独立phase。

模块流向：Shell/Feature → Controller/UseCase → Repository接口 → Data/Platform实现。AudioEngine/MediaSession/Fullscreen/LocalMusic/SecureCredential独立Gateway；平台回调只驱动共用Controller。

## ADR-004：player、lyrics独立路由（确定）

/player与/lyrics可各自从主页面进入；player→lyrics关闭返回player，主页面→lyrics关闭返回原页。全屏OS状态不是route本身：Esc/系统返回先处理最上层菜单/弹层与OS全屏，再按栈返回。保存并恢复窗口/Android系统UI。不能复制HTML对象反序关闭作为正式路由语义。

## ADR-005：分离配置、秘密与媒体引用（确定）

SQLite存TrackRef/来源公共配置/credentialRef，安全存储保存凭据和敏感header；日志脱敏并丢弃敏感query。HTTPS默认。用户映射是受限字段表达式，不执行任意代码；UI不保留持久stream URL。删除来源保留用户歌单/收藏/队列中的不可用引用；不提供音频下载或长期缓存。

## ADR-006：插件条件选择（待POC）

候选以当前维护者文档为证据，具体版本待兼容解析。Audio优先比较media_kit与just_audio+Windows backend；音频/后台会话分层。只有Windows和Android合同测试均通过，才能选正式实现，详见dependency_decisions.md及audio_poc_plan.md。

## ADR-007：旧原型保留、不自动收编（确定）

任务开始本地有未跟踪的Sonic Gallery代码，但没有.git；远程没有任何refs。初始化独立docs/phase-0-design-audit并fetch空远程，不伪称拉取了已有main。原有lib/test/pubspec/analysis_options/album_atlas保留原地、不修改、不纳入本阶段提交；审计产物是本轮GitHub基线。

因此本阶段推送成功不意味着整份工作目录与远程相同。后续Phase 1需明确旧原型迁移/归档方案，保留可恢复历史后再整理，不能覆盖或删除未经授权的本地文件。

## ADR-008：合成事实与原生目标分别记录（确定）

源码哈希不变；完整polish映射带来源行号。CSS高specificity导致的全屏滑条、Artwork、移动端圆角差异保留在审计中。平台和无障碍硬约束优先，但任何视觉主动适配在Golden报告明确写出，不把通用Material外观当设计还原。

## ADR-009：Phase 1 的可恢复原型迁移（2026-08-31）

用户要求继续开发后，选择先原样归档旧原型再建立正式根工程。13 个旧文件移动前后逐字节核验，放入 archive/sonic_gallery 并单独提交。它们不再保持 Phase 0 的“未跟踪、位于根目录”状态；ADR-007 是历史状态，不是当前文件位置。

根分析排除只读 archive 与 design_reference，原因是它们是独立历史/设计资料，不是关闭正式客户端 Lint。旧测试、旧图标和图片完整保留但不代表正式 YYMusic 测试。新测试验证新契约，不以修改旧断言掩盖问题。

## ADR-010：Phase 1 注入与路由选择（已实现）

采用已解析兼容版本的Riverpod 3.4.2与go_router18.0.0。Riverpod仅负责根ProviderScope与依赖图，Controller使用Flutter基础ChangeNotifier；go_router封装在AppRouter，Shell只收到AppNavigation自有接口。StatefulShellRoute保存主导航分支，player/lyrics位于根Navigator。

ProviderScope拥有注入依赖的释放责任，依赖图dispose幂等。默认AudioEngine不可用且不模拟播放；Repository/FullscreenGateway未注入时为null。Phase 3/4扩展合同前先更新ADR，不在Phase 1编造完整模型或虚假实现。

## ADR-011：骨架验证与阶段出口分开（已采用）

本机分析/Widget测试可以用现有SDK执行，但缺少Visual Studio与Android命令行工具/明确许可。提交可验证的骨架与CI不代表双平台构建通过；没有真实构建结果不进入Phase 2。CI只构建Debug，不发布或部署，不读取用户音乐和凭据。

## ADR-012：按用户要求分离 Android 优先验收（2026-08-31）

用户在 Android 工具链/APK 已通过、Windows UAC 无法远程确认后明确要求“先开发安卓平台”。从本批起，允许以 Android 已通过的 Phase1 基础推进 Android Phase2 分批增量；ADR-011 的“等待双平台后再推进”在此范围内被用户的新指示覆盖。

这不是 Windows 构建成功或整个 Phase1/2 完成的声明。保留 Windows runner、平台优先分类、共用 Domain/Controller 和现有测试；不删除 Windows CI，不另开 Android 仓库，不重复实现业务逻辑。Windows 本机安装、原生构建/真机视觉与后续平台能力仍单独待验收。

## ADR-013：Phase 2B 受控输入与可读导航（2026-08-31）

导航的当前项来自路由；Phone使用胶囊选中、不显示3×18左条，Tablet保留左条。保留正常强调色外观；当原始accent相对elevated底色对比不足3时，补派生色边框，选中内容及边框相对实际选中底色对比至少4.5，原HEX/填充不改。标签提升至11dp并随文字缩放，单个触控区不小于44dp。

YYSlider的onChanged只表示预览，只有onChangeEnd可供未来业务提交Seek；系统取消走onChangeCancel，不冒充提交。已接受的Flutter横向Drag在收到原始PointerCancelEvent时仍可能调用onEnd，因此用Listener先清除本次拖动并发取消回调。禁用、零范围、加载或范围改变会使内部拖动失效，不提交；范围/禁用变化时父状态负责决定预览回退。键盘/语义动作走离散开始→更新→结束，滑块不订阅音频流。

几何占位直接实现原始CSS的百分比、旋转及固定px线宽/偏移，区分album20/track10/player26圆角。不使用随机或AI封面，不创建假Track数据；未来真实Artwork应优先。只对kind和local accent变化重绘，模糊仍限定导航区域，ReduceGlass保留几何。

实现依据为本地Flutter3.47.2源码，以及Flutter官方[Semantics](https://api.flutter.dev/flutter/widgets/Semantics/Semantics.html)、[FocusableActionDetector](https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html)、[CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)。Widget语义与绘制测试不代替设备TalkBack或性能验证。

## ADR-014：云端APK与Phase2C输入边界（2026-08-31）

用户明确要求APK在GitHub构建：交付必须对应目标commit的GitHub运行、私有草稿Release与校验和，不能上传旧本机包冒充云端编译。Actions artifact额度耗尽后，经用户允许改为仅手动workflow_dispatch创建draft/prerelease；普通push/PR只做验证。Actions先验签/比对资产再按三文件白名单上传，元数据不复制环境变量，签名仍为临时Debug；正式发布、Release签名和稳定升级密钥另行授权。

输入控件是设计系统，不是搜索功能。YYSearchField保留原生TextEditingValue/composing/selection，不在onChanged重写IME组合文字，只通过onSubmitted通知调用方。调用方Controller/FocusNode所有权不转移；启用/加载状态阻止输入和提交。剪贴板正文只有用户发出复制/粘贴等编辑动作才访问，测试全用替身；无网络搜索、输入历史或隐藏持久化。

选择手势、工具栏和原生编辑句柄基于Flutter Widgets层；工具栏复用YYButton和主题，不引入Material外观。支持Tab/Enter/Space的分段选择按按钮组语义实现（不是切换页面的选项卡），窄宽横向滚动且键盘焦点自动可见。11px/650字重和14/11圆角保留，34px旧命中高度提升至44；Search15/460、52/18或58/20，随字号适度增高，不截断文字。

参考Flutter官方[EditableText](https://api.flutter.dev/flutter/widgets/EditableText-class.html)、[TextSelectionGestureDetectorBuilder](https://api.flutter.dev/flutter/widgets/TextSelectionGestureDetectorBuilder-class.html)。本地单元测试包含IME消息但不替代安卓真机输入法/TalkBack验收。

## ADR-015：Phase 2D 内容组件的动作与语义边界（2026-09-01）

`YYAlbumCard`与`YYTrackTile`是受控展示组件，不拥有收藏、选择、播放、队列或菜单业务状态。Album的`selected`表示调用方选择，但它不是互斥单选组，因此复用`YYControlAction`时显式关闭`inMutuallyExclusiveGroup`；Track的`playing`同样只用于受控外观及“正在播放”语义，不触发或模拟音频。

Track整行主动作与尾部更多动作必须是两个独立的Semantics/Focus/命中节点。更多按钮不位于主动作的GestureDetector内，不冒泡调用`onPressed`；禁用或加载时两个动作同时不可用。Album与Track只公开回调，Gallery回调仅修改本页Fixture状态，不访问Controller、Repository、网络、文件、数据库或持久化。

Album保留最终POLISH的20圆角与默认/hover双阴影；Track保留14行圆角、10封面圆角、36封面、58最小高度与手机隐藏时长。手机来源标签限制宽度并省略，避免长来源挤压标题或越界；这属于响应式防溢出，不改写来源内容。白色等低对比accent保留原HEX填充，边界和选中文字使用既有可读派生色。

## ADR-016：Phase 2E Windows Chrome 与平台能力分界（2026-09-01）

Windows设计系统先实现受控`YYWindowsSidebar`与`YYWindowToolbar`，但窗口控制不在Widget内直接调用插件。Toolbar只公开最小化、最大化/还原、关闭回调；正式Shell在`WindowsWindowGateway`实现前隐藏这组控制，继续由操作系统原生窗口边框提供真实能力。Gallery可用明确标注的Fixture回调验证视觉与动作，但不能冒充真实窗口操作。

竖向Sidebar需要适配父约束，因此新增`YYGlassPanel`；既有`YYGlassSurface`保留原固定高度、高光线占位和渲染树，不委托新组件。视觉回归曾准确拦截把高光线改为覆盖层造成的Android导航内容约1dp位移，因此恢复旧实现而不更新旧导航基线。Glass仍只覆盖Sidebar等有界区域，不扩展到全屏滚动层；Reduce Glass关闭Blur但保留Fill、Stroke和Shadow。

Sidebar的选中路由来自`AppRouter`，只发出`onSelected`，不持有Controller。展开布局显示顶部`YY Listener / 本地账户`与显式的“音乐源尚未接入”；紧凑布局只保留账户头像和图标导航。HTML中的“128首”“音乐源在线”“2个在线来源”是演示状态，在Phase3 Repository之前不得进入正式Shell。

## ADR-017：Phase 2F 播放器表面只表达受控状态（2026-09-01）

`YYMiniPlayer`与`YYDesktopPlayerBar`属于Phase2设计系统，只接收`YYNowPlayingViewData`及回调。它们不读取`PlaybackController`、`QueueController`、AudioEngine、Repository或插件，也不在Widget内推进进度、循环队列或模拟播放；Gallery Fixture只修改页面局部状态。Phase4确定播放合同后由Feature/Presenter把唯一播放真相映射到该UI模型，Shell不得再创建播放器状态。

曲目信息主动作与播放、下一首、随机、循环、歌词、收藏、队列、音量和进度必须保持独立Semantics/Focus/命中节点。进度`onChanged`仅预览，`onChangeEnd`才提交；系统取消不冒充Seek。Repeat的off/all/one只是受控视觉枚举，不实现循环算法。Loading或空回调使对应动作不可用，组件不以假成功状态回应。

播放器条使用基础HTML的88/76/64高度、24/22/21外圆角、54/50/48封面及14/12封面圆角；新增Artwork role而不改26圆角的全屏Now Playing role。App.tsx的POLISH没有播放器条选择器，因此保留基础HTML播放器规则，同时仍使用最终Sprite的play/pause/prev/next/shuffle/repeat/volume/queue/fullscreen/lyrics等原始SVG。正式Shell在Phase4/5前继续显示明确的未接入结构槽，不把Gallery Fixture接成假播放器。

## ADR-018：Phase 2G 弹层原语与弹层编排分离（2026-09-01）

`YYContextMenu`、`YYDialog`、`YYBottomSheet`与`YYToast`只负责可复用的原生视觉、焦点、键盘和语义，不自行创建业务Overlay、路由、计时器、右键/长按监听或平台触觉。Feature/Shell以后决定何时插入Overlay、如何锚定/避让窗口边缘、Android使用Sheet还是全屏Route以及业务动作；Gallery只以内联Fixture验证组件。

Context Menu沿用基础HTML的224宽、7内边距、30模糊和菜单标题/元信息结构，最终POLISH把圆角从17覆盖为20；HTML的38高菜单项提升为44dp命中以满足主指令。组件接收受控item列表与`onSelected(id)`，不解释“播放/队列/收藏”等业务含义；方向键/Tab在闭环FocusScope内移动，Esc只通知`onDismiss`。右键坐标、窗口边缘限制、长按520ms和外部点击关闭属于后续调用层。

普通Dialog保持680最大宽、30圆角、72头尾与不透明Surface，不误用Liquid Glass；Phone Bottom Sheet是主指令允许的主动平台适配，复用30顶部圆角和同一焦点合同，不冒充基础HTML在599px下的全屏Dialog像素复制。两者打开时可聚焦关闭按钮、Tab闭环、Esc通知关闭，并在销毁时恢复先前焦点。Toast保持42最小高、420最大宽、14圆角与可访问live region，但显示时长由调用方控制，组件不内置2300ms计时或模拟业务成功。

## ADR-019：Phase 2H 状态原语不拥有异步工作（2026-09-01）

`YYThemeSwatch`、`YYEmptyState`、`YYErrorBanner`与`YYSkeleton`只表达调用方状态。Swatch通知选色但不持久化；Error Banner通知可选action但不重试；Skeleton不启动加载、计时或生成假数据。未来Controller显式拥有idle/loading/data/empty/error，Feature只把状态映射到这些组件。

Swatch保留基础HTML的30px视觉，但实际命中提升到44dp并增加键盘、焦点和互斥选择语义；选中内环使用相对色样可读的黑/白色，解决自定义白色上原网页白环不可辨识的问题。Empty State保留28/16内边距、24图标和10px/1.6文字。Error Banner没有App.tsx后置样式，最小化复用基础HTML notice的12/14/15几何以及既有error badge色值。主指令要求Skeleton但设计导出没有对应CSS，因此只用`bg-subtle`、默认边界和10圆角的静态纯色占位；明确禁止臆造渐变shimmer。

## ADR-020：Phase 2I 集合卡片不拥有来源或歌单业务（2026-09-01）

`YYSourceCard`与`YYPlaylistCard`是受控展示组件，只接收调用方给出的文字、图标、状态、选择和动作。来源状态标签及positive/warning/error/neutral色调由调用方映射；组件不测试连接、不读取凭据、不启动网络或计时器。歌单卡片的collection/create变体只通知动作，不创建歌单、不读取曲目、不打开页面或Dialog，也不持久化选择。

Source沿用基础HTML的72最小高、12内边距、42图标、16卡片圆角和6状态点，并应用App.tsx最终`POLISH_CSS`的13图标圆角。Playlist采用最终20卡片圆角、14图标圆角、桌面16内边距/44图标/18标题间距；Phone沿用13内边距和40图标。Create虚线边界由纯色`CustomPainter`绘制，不使用Material默认卡片或渐变。

Gallery只展示明确标注的确定性Fixture，点击只更新本页说明或选择；HTML中的“在线”“128首”等演示内容不得进入正式Shell。未来Phase3由Repository/Controller提供真实来源和歌单状态，Phase2组件不先发明Domain模型。

## ADR-021：Phase 2J 队列与歌词原语不拥有播放真相（2026-09-01）

`YYQueueTile`、`YYLyricsLine`与`YYLyricsPlayerDock`是受控展示组件。Queue主动作与上移、下移、移除分别拥有Semantics/Focus/命中边界；组件不修改列表或实现拖拽排序。Lyrics Line只表达future/past/active和可选动作，不解析LRC、不Seek、不自动滚动。Dock只转发Transport、进度、收藏和返回动作，不订阅AudioEngine、PlaybackController或QueueController，也不推进时间。

Queue沿用基础HTML的50/7/36标准与60/9/42沉浸几何、26视觉动作，并应用App.tsx最终10封面圆角；实际动作命中仍不小于44dp。Lyrics保留future 24%、past 50%、active纯白与1.018缩放，并应用最终780字重、紧字距和6px激活外环。Dock保留82最小高、11/13内边距、50封面、34/44控制和900px两层重排；App.tsx最后的`POLISH_CSS`把各断点外圆角统一覆盖为26。Phone/低高度仅做40/38封面和控制尺寸降级。

Dock歌词背景使用单一纯色Atmosphere，不使用渐变或封面模糊铺满。减少玻璃时只关闭Blur并改用不透明混合面，几何不变；减少动态时歌词缩放即时切换。Gallery只保存确定性Fixture标签与受控数值。正式QueueEntry、LyricsDocument、LRC解析、拖拽、跟随滚动、Seek、持久化及独立歌词页留给后续Domain/Feature阶段。

## ADR-022：Phase 3A 先固定 Domain 合同再选择数据库实现（2026-09-01）

Phase3拆分交付。首批只建立纯Dart Domain模型、Repository/Gateway合同和测试Fake，不安装Drift、不建表、不接UI或Controller。下一批Schema/Migration必须依赖这些项目自有类型并用内存数据库验证，不能让Drift row、SQLite句柄或平台插件类型进入Domain/UI。这样数据库候选或安全存储实现可替换，不改三套Shell。

`TrackRef(trackId, sourceId, sourceType)`是跨来源稳定引用；`QueueEntry.id`与TrackRef分离，允许同一曲目重复入队。所有持久时间先规范为UTC，Queue位置连续且顺序显式。来源删除或本地文件失效只改变`TrackAvailability`，不级联抹除用户歌单、收藏、历史或队列引用。HTML按标题slug、数组trackId和object URL生成的示例状态不迁入正式模型。

`MusicSourceConfig`只保存HTTPS无userinfo/query/fragment的公开base URL、公开Header、受限字段路径和`credentialRef`；Authorization、Cookie、API Key、Token、Secret、Password、换行Header均运行时拒绝。`SensitiveCredential`只为SecureCredentialGateway提供临时内存值，字符串输出固定脱敏，不提供数据库序列化。DomainFailure只保留枚举、来源ID、retryable和日志安全diagnosticId，不携带原始异常、URL或Header。

所有Controller异步状态使用显式idle/loading/data/empty/error，但Repository返回Domain数据/流而不返回UI组件。Phase4前不扩展现有PlaybackState为假播放实现；Phase3后续只负责数据库、Repository和Controller数据真相，音频状态机仍按原阶段执行。

## ADR-023：Drift原生后台数据库与不可变v1快照（2026-09-01）

Android和Windows共用Drift的`NativeDatabase.createInBackground`，SQLite由3.x build hooks打包；不选只支持移动端的sqflite，也不增加已被当前Drift原生路径取代的`sqlite3_flutter_libs`。路径由Flutter官方path_provider提供应用支持目录，测试注入内存executor或临时目录。只有data层可导入Drift/sqlite3/path_provider，UI、Domain和Shell继续只依赖项目接口。

首版包含主指令15张建议表、独立`queue_state`和`schema_migrations`。用户集合里的TrackRef不外键指向tracks/music_sources，避免来源删除时级联丢失歌单、收藏、历史和队列；catalog内部track_artists/album_artists及playlist_entries使用外键级联。Queue位置唯一、entryId与TrackRef分离；连续性仍由Domain QueueSnapshot/Repository事务验证。

schemaVersion1只处理首装`onCreate`并记录审计行，不伪造v1→v2。`make-migrations`生成的v1 JSON一经本批提交即不可覆盖；未来必须升版本、保留旧快照并用官方SchemaVerifier和数据完整性测试验证。生成的g.dart和快照在CI重新生成后要求Git零差异。

普通来源配置仍可能包含公开Header JSON，但数据库没有Authorization/API Key/Token/Password等独立列，只保存`credential_ref`；所有写入必须经过后续Repository对Phase3A MusicSourceConfig的运行时验证。安全凭据永不进入Drift row、迁移Fixture或日志。

## ADR-024：LibraryRepository使用原子catalog事务与脱敏row映射（2026-09-01）

Phase3C只实现`LibraryRepository`，不同时接Collection/Source/安全存储/Controller。Track/Album/Artist从Drift row返回前必须重走Domain构造验证；枚举、URI、JSON、时间或关联损坏统一转成无原始数据的`DomainFailure(databaseCorrupted)`，不将SQLite异常、路径、URI或metadata写入日志安全封装。

TrackRef仍以sourceType/sourceId/trackId为主身份。由于当前Track合同只包含艺术家显示名，data层用`SHA-256(sourceId + NUL + exact UTF-8 name)`生成source范围内可复现的派生artist ID；禁止随机/时间ID。如来源适配器需保留真实artist ID，必须先以独立Domain升级批次解决，不暗中塞进metadata。

upsert在一个Drift transaction中先替换Track关联，再batch conflict-update主表/关联，最后重建Album credits与计数。任一失败整批回滚，外部watch只在提交后看到一致快照。分页在limit/offset前固定标题、来源与ID排序，使用`limit + 1`判定hasMore。

Repository默认不拥有共享`AppDatabase`；显式`.owned`才在dispose关闭。生产initialize只执行user_version/quick_check/foreign_keys，官方`validateDatabaseSchema`留在测试，避免生产导入dev-only `drift_dev`。AppBootstrap在Dev Fixture和其余Repository策略完成前仍不打开DB。

## ADR-025：CollectionRepository保留用户引用并原子替换队列（2026-09-01）

Phase3D只实现`CollectionRepository`，不同时接Lyrics/Source/安全存储/Controller。Playlist、Entry、Favorite、History和Queue从Drift row返回前重走Domain构造；损坏枚举、时间、位置、引用或SQL异常只返回不含用户数据的`DomainFailure(databaseCorrupted)`。

系统歌单的`isSystem/systemType`是不可变身份，同一systemType只能有一个且不允许删除。自定义歌单删除只使用Schema已定义的playlist→entries级联，不触及catalog。歌单条目整体替换前必须验证playlistId、唯一entryId和0起始连续position，之后在单事务内delete+batch insert。

队列在单事务中先清除queue_state.current引用，再整体替换entries并写回current/updated。watch query显式`readsFrom`queue_state与queue_entries，外部只观察提交后快照。QueueEntry.id仍独立于TrackRef，同一曲目可重复。收藏幂等更新addedAt；历史按完整TrackRef删旧插新并裁剪到20条。

用户集合不要求catalog Track存在，来源被删除或文件失效时仍保留TrackRef，由后续Library/Source状态标记不可用。Repository默认共享`AppDatabase`，只有`.owned`在幂等dispose时关闭；AppBootstrap在其余Phase3数据策略完成前仍不接线。

## ADR-026：LyricsRepository只持久化已验证文档，不承担解析与获取（2026-09-01）

Phase3E只实现`LyricsRepository`，不同时实现LRC解析、在线歌词获取、Controller或UI。缓存主键继续使用完整sourceType/sourceId/trackId，歌词无需catalog Track或MusicSource row存在；来源暂时不可用时不会级联删除用户已有歌词缓存。

`lines_json`使用确定性的四字段数组对象：`startMs`、`endMs`、`text`、`translation`。读取必须拒绝非数组、未知/缺失字段、非整数时间及错误文字类型，再交由`LyricsLine/LyricsDocument`验证plain/synchronized时间一致性、同步顺序、非空行和翻译语言一致性。缓存更新时间即使未暴露给当前Domain也必须是可解析UTC毫秒；任何JSON/row/SQLite异常都转成不含歌词、TrackRef或SQL的`DomainFailure(databaseCorrupted)`。

单行upsert使用既有复合主键和`insertOnConflictUpdate`，删除不存在行幂等成功。Repository默认不拥有共享`AppDatabase`，只有`.owned`在幂等dispose时关闭。AppBootstrap在Source、安全存储与Dev Fixture策略完成前仍不接线；未来解析器或来源适配器必须先构造合法LyricsDocument再保存，不能把未验证原始LRC或响应体塞入数据库。

## ADR-027：MusicSourceRepository只保存公开配置与凭据引用（2026-09-01）

Phase3F只实现`MusicSourceRepository`，不同时选择安全存储插件或实现REST Adapter。Drift row保存MusicSourceConfig中的公开base URL、公开Header、相对endpoint、受限字段路径、状态/延迟及`credentialRef`；Repository和mapper不得导入或接收`SensitiveCredential`。凭据引用不是凭据生命周期：替换或删除引用时如何清理安全存储必须由后续Controller协调，data层不能猜测并删除外部秘密。

三个Map使用按key排序的确定性JSON；读取必须拒绝非对象、非字符串值，再重走MusicSourceConfig验证HTTPS无userinfo/query/fragment、敏感Header名、相对路径、受限映射、枚举和UTC时间。损坏JSON/row/SQLite异常只返回不含名称、URL、Header、credentialRef或SQL的`DomainFailure(databaseCorrupted)`。

sourceId是稳定身份；已存sourceType或builtIn不得转换，内置来源不可删除。自定义来源删除只移除配置，Schema刻意没有从用户集合TrackRef指向music_sources的外键，因此收藏、歌单、历史、队列和歌词引用仍保留，后续Library/Controller标记不可用。Repository默认共享数据库，只有`.owned`负责关闭；AppBootstrap继续等待安全存储与Dev Fixture策略。

## ADR-028：凭据只以随机引用跨越平台安全存储边界（2026-09-01）

Phase 3G选择`flutter_secure_storage 10.3.1`：其Android实现与项目现有API 36工具链一致，Windows解析为`flutter_secure_storage_windows 4.2.2`；暂不采用要求compileSdk 37的11.x。插件只能出现在`platform/secure_credentials`边界，Domain、Drift、Repository、Controller和UI不得直接依赖插件，也不得把凭据正文写入数据库、日志、异常或诊断字段。

`SecureCredentialGateway`返回192位`Random.secure()`生成的不可推导引用，存储前检查碰撞且绝不覆盖已有值。正文使用带schemaVersion和kind的确定性JSON，字段按key排序，读取时拒绝未知字段、非规范编码、非法引用及超限载荷，并重新通过`SensitiveCredential`验证。所有插件、随机数和编解码失败只映射为固定的日志安全失败类型；Dart `String`无法可靠原地清零，因此调用方必须缩短凭据驻留时间且禁止缓存。

Android使用独立`yymusic_credentials_v1`命名空间、RSA-OAEP/AES-GCM迁移策略，关闭resetOnError，并在Manifest明确`allowBackup=false`，避免加密数据与设备密钥分离后静默重置。Windows关闭旧版兼容迁移，使用当前Windows安全存储实现；其ATL/原生编译要求必须由GitHub Windows runner实际验证，不能以Android成功代替。

本批只实现Android/Windows Gateway与可注入字符串存储适配器，不在`AppBootstrap`提前接线。后续Controller更新来源凭据时必须按“先保存新秘密、成功更新数据库credentialRef、最后幂等删除旧引用”的顺序协调；任何中间失败都不得覆盖旧秘密或产生虚假的成功状态。

## ADR-029：生产空库与开发样本使用不同入口（2026-09-01）

Phase 3H用`AppDataServices`定义一个明确拥有资源的数据作用域：单一`AppDatabase`供四类Drift Repository共享，Android/Windows各构造对应`SecureCredentialGateway`，根`DependencyGraph`只暴露项目自有合同。`AppBootstrap`不直接导入Drift或插件；它异步请求作用域并负责正常销毁、失败和卸载后晚到完成的关闭。平台初始化错误只显示固定文案，不把异常、路径、URL或秘密带到UI。

默认`main.dart`始终使用生产工厂，在应用支持目录打开空白数据库；禁止为了让骨架“有内容”而自动填充HTML示例。独立`main_dev.dart`才调用内存数据库工厂和`DevFixtureSeeder`。Fixture写入前要求曲目、歌单、队列和来源均为空，进程结束后整体丢弃，不能指向生产文件或平台安全存储。

HTML四首示例曲目、两个歌单、队列和双语歌词通过正式Domain/Repository写入，但统一挂在禁用的`https://fixture.invalid`来源，曲目标记`sourceDisabled`。它不保存credentialRef、用户路径、content URI、artwork URI、可播放URL、收藏/历史或connected状态。这样可验证HTML状态到真实接口的映射，又不把网页假延迟、对象URL、在线状态或秘密冒充为生产能力。

只有`data/database`可以构造Drift内存executor；除`main_dev.dart`外的生产入口不得导入`dev_fixture`，UI/Shell继续不能导入data层。REST Adapter、来源凭据替换事务与Controller仍需后续独立决策；Phase 3H只关闭主指令规定的Domain/Database/Repository/安全存储接口/Dev Fixture出口。

## ADR-030：PlaybackController合成唯一播放与队列真相（2026-09-04）

Phase 4A先锁定项目合同与状态语义，再选择真实音频插件。`AudioEngineState`只报告idle/loading/buffering/ready/playing/paused/completed/error、时间、音量、速率和安全失败；它不知道Track、队列或UI。根级`PlaybackController`是唯一将Library Track、短期PlayableSource、Engine事件、Collection队列和MediaSession组合为完整`PlaybackState`的对象。`QueueController`仍作为主指令列出的业务入口存在，但只委托命令并返回`playback.state.queue`，不得保存第二个QueueSnapshot。

`PlayableSource`是仅在resolve到load之间存活的适配器输入：本地文件必须是绝对路径，Android引用必须是`content://`，网络必须是无userinfo的HTTPS。过期URL可能含短期query，授权Header可能含秘密，因此locator/Header在`toString`中无条件显示`<redacted>`，不得写入Drift、Fixture、公开状态或日志。插件异常由适配器优先分类；Controller对未知异常只产生固定diagnostic ID，不复制异常文字。

播放命令使用单一串行队列，避免快速点击导致load/seek/queue持久化交错。随机模式生成一轮稳定entryId顺序，关闭列表循环时一轮内不重复；repeat all才开始下一轮，repeat one只处理自然completed，用户手动next仍前进。删除当前项/清空队列停止引擎并清除当前Track；删除同TrackRef的另一个重复entry不得中断。持久队列在AppBootstrap期间恢复，但不自动解析或播放，避免启动即访问用户文件/网络。

MediaSessionGateway只把Android MediaSession/Windows SMTC动作转回同一Controller，并接收项目Track/PlaybackState；其失败是辅助能力退化，不能停止正在播放的音频。Phase4A不添加插件或平台实现，默认Engine仍不可用。只有后续Windows+Android对同一合同完成本地授权文件、受控HTTPS流、Seek/状态/错误和打包验证后，才可锁定正式backend并关闭Phase4出口。

## ADR-031：media_kit先作为隔离候选验证，不进入生产组合（2026-09-04）

Phase4B解析`media_kit 1.2.6`与`media_kit_libs_audio 1.0.7`，但它们仍是POC候选而非正式
backend。只有`lib/playback/media_kit_audio_backend.dart`可以导入插件；该文件把Player即时状态和
事件压成项目自有snapshot，并在边界直接丢弃原始error文字。`MediaKitAudioEngine`只依赖这个
可注入backend与现有AudioEngine合同，Windows路径转为file URI，content URI原样传递，HTTPS
Header只交给单次Media构造；所有open/transport/stream失败只暴露固定DomainFailure。

候选Engine串行接受命令，`open`固定`play:false`，0–1项目音量与0–100插件音量在边界换算。
loading、buffering、ready、playing、paused、completed、idle与error从同一backend snapshot组合；
dispose先停止接收新命令、等待已接受工作、取消订阅并幂等释放Player。队列、随机和循环继续由
唯一PlaybackController处理，不启用插件自己的playlist/shuffle/repeat，也不在Shell复制状态。

本批刻意不在`main.dart`、AppBootstrap或DependencyGraph创建候选Player；Fake backend测试不加载
native库。后续Phase4C/4D已在Windows/Android补齐本地WAV、Android content URI、受控HTTPS/Header、
Seek事件和脱敏失败矩阵，因此受控双平台POC已通过；实体扬声器、真机生命周期和许可证仍未通过，
候选继续不得上线。

发布合规也是选型门：已解析的wrapper包带MIT文件，但Android v1.1.8四个固定JAR只含两个`.so`
且没有LICENSE/NOTICE；Windows 1.0.9在构建时下载2023-09-24 libmpv归档。它们包含libmpv/FFmpeg，
不能用wrapper的MIT声明替代传递二进制义务。补齐精确构建配置、LGPL/第三方NOTICE、可替换/源码
提供策略并经发布审核前，不触发包含该候选的手动APK Release，也不正式锁定backend。

## ADR-032：真实本地音频证据使用运行时生成材料与隔离手动作业（2026-09-04）

Phase4C不向仓库加入WAV/MP3等媒体二进制，也不使用用户音乐或下载在线样本。专用测试在运行时生成
固定3秒PCM16单声道WAV，单元测试锁定RIFF结构、长度与SHA-256，再写入测试进程私有临时目录。
测试只把该绝对路径交给候选`MediaKitAudioEngine`，退出时依次取消状态订阅、释放Player并删除临时目录；
日志只记录平台和三项耗时，不输出路径、URI、Header或原生错误。

真实运行复用默认分支已注册的`foundation.yml`，但只有手动输入`run_native_audio_poc=true`时才调度；
该路径只运行checks及Windows/Android两个只读job，带`contents: write`的Android发布job明确跳过。
Windows 2025进程和Android API36 x86_64模拟器执行同一测试，不上传artifact、不创建Release。position推进与completed
可以证明native初始化、解码、时钟和控制链工作，但无头runner不能证明扬声器可听、音质、音频焦点、
后台或设备切换。生产`main.dart`继续使用`UnavailableAudioEngine`；Android `content://`与受控HTTPS
已在Phase4D专用作业通过，但许可证闭环前仍不能正式锁定或发布候选backend。

## ADR-033：受控来源POC使用debug-only Provider与短期loopback TLS（2026-09-04）

Phase4D不访问用户文件或真实第三方源。Android只在debug source set注册不可导出、不可授权给外部应用的
只读Provider，并仅打开cache中的固定运行时WAV；main/profile不注册。Windows/Android共用loopback HTTPS
server，短期证书与私钥运行时生成到Git忽略目录，原始文件立即删除且专用工作流不上传artifact。

POC Header是公开sentinel；网络探针只发HEAD、禁止自动重定向并将HTTP/offline/timeout/TLS映射为脱敏
DomainFailure。自签名TLS绕过与Windows无头sink只存在于名称明确的POC构造入口，生产默认继续验证TLS并
使用真实设备。精确提交`913f3d75`的专用运行33878710671双平台成功且零artifact/Release，关闭来源POC
出口；该证据不授权下载/离线能力，也不替代真实API、实体设备、后台/焦点或发布许可证审核。

## ADR-034：just_audio备用候选显式声明Header能力并保持生产隔离（2026-09-05）

Phase4E精确解析`just_audio 0.10.6`和`just_audio_windows 0.2.3`，但只作为与media_kit比较的
备用候选。`package:just_audio`只能由`lib/playback/just_audio_backend.dart`导入，插件对象和错误
不得越过项目snapshot；`JustAudioEngine`继续实现既有AudioEngine合同。生产main/AppBootstrap/Graph、
Shell、UI、数据库与Fixture均不得创建或引用该候选。

`just_audio_windows`没有声明直接请求Header能力，而just_audio内置代理会引入loopback cleartext及额外
安全审计。本阶段不默认启用两者：backend创建方必须显式声明Header是否支持，若来源带Header但能力为
false，则在调用插件前失败关闭并只暴露固定脱敏DomainFailure。Phase4F可以分别验证Android原生Header
和Windows无Header HTTPS；任何代理方案必须单独审计绑定地址、会话隔离、Range转发、生命周期与日志，
不能通过静默丢弃Header换取表面成功。

候选只映射一次性file/content/HTTPS来源，不使用插件playlist/shuffle/repeat，不启用
LockCachingAudioSource、StreamAudioSource或缓存清理，不实现下载/离线保存。Debug编译和Fake合同通过只
证明适配与打包；真实native运行、实体设备、后台/焦点、系统媒体会话及第三方NOTICE完成前不锁定正式
backend，也不触发包含备用候选的手动APK Release。
