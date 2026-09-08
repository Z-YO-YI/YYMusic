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

## ADR-035：无真实Windows播放端点时原生POC必须失败关闭（2026-09-05）

Phase4F为`just_audio`建立与media_kit合同相同的运行时WAV原生测试，且不启用Header代理、缓存、下载或
插件内部队列。Android API36完成duration、position、seek、pause、completed等链路。Windows适配层修复
WinRT插件在position和natural duration同为0时提前报告completed的问题，但修复后托管机调用play仍不推进
position。

专用Windows job会启动AudioEndpointBuilder与Audiosrv，并用PnP设备事实要求至少一个可用播放端点。
GitHub Windows Server 2025两项服务均Running但播放端点为0，因此测试在端点门失败；当前远程本机同样为
0端点，且Developer Mode关闭阻止Flutter创建plugin symlink。构建通过、服务Running、Android成功、Fake
时钟或media_kit无头sink都不能替代本候选的Windows真实端点证据。

因此Phase4F只关闭Android小批A，Windows与整个阶段保持打开，小批B不扩大。生产继续创建
UnavailableAudioEngine。后续可在有播放端点的Windows runner重跑同一测试；并行可审计media_kit的native
分发许可证，但任何候选都必须在自身剩余门禁关闭后才能接入Bootstrap。

## ADR-036：原生分发来源无法重建时只提交失败关闭清单（2026-09-05）

Phase4G不以Dart wrapper的MIT许可证推断native bundle合规，也不因SO/DLL内嵌配置显示LGPL模式就自动
批准发行。Android四个release JAR、APK三ABI以及Windows release DLL/Phase4C bundle已经用SHA-256逐字节
映射；真实FFmpeg/mpv配置也确认关闭GPL/nonfree。该证据回答“打包了什么”，没有回答“发行者如何交付
对应源码、patch、NOTICE和重新链接能力”。

现有Android脚本从可变main取得helper；Windows实际DLL配置与release前最近历史脚本相反，构建workflow
又允许未记录自定义命令和恢复cache，旧运行记录无法取回。故机器manifest固定为`inventory-only`、
`releaseApproved=false`、`productionWiringApproved=false`。不完整许可证集合不得放入应用assets；测试同时
锁定生产`UnavailableAudioEngine`、native哈希映射和阻断项。只有自行从不可变revision与记录patch重建、
补齐逐组件审查/NOTICE/对应源码/重新链接方案并验证双平台候选包后，才可通过新决策显式改写本门禁。

## ADR-037：失败关闭的native候选必须退出活动依赖图（2026-09-05）

Phase4G已经确定当前media_kit发布链无法满足来源重建、逐组件NOTICE、对应源码和重新链接材料门禁。
继续让候选留在pubspec、生成注册和每次Debug包中不会增加有效证据，只会扩大体积与误发面。因此Phase4H
从活动工程删除media_kit直接/传递包、隔离适配器、对应Fake/集成测试和历史专用CI job；旧代码仍可由
Git历史复核，Phase4B—4G报告与原生哈希manifest不得删除或改写成“从未评估”。

历史manifest新增`decision=rejected`和`activeDependency=false`，审计同时验证历史指纹仍完整、当前依赖与
入口为0。Android交付校验逐ZIP entry拒绝`libmpv.so`、`libmediakitandroidhelper.so`和media_kit路径；
Windows由生成注册门禁及GitHub干净portable bundle清单复核。该删除决定不等价于选择just_audio：后者仍须
在真实Windows播放端点通过自己的原生POC，生产Graph继续构造`UnavailableAudioEngine`。

旧Android debug-only Provider、受控TLS生成器和HEAD探针是与候选无关的受控测试基础设施，可供后续来源
验证复用；它们不接生产、不持久化响应、不加入release Manifest。Phase4H不进入Phase5，也不增加下载、
缓存、离线保存、WebView、后台服务、SMTC/MediaSession或新权限。

## ADR-038：队列元数据不等于已加载的播放会话（2026-09-05）

Phase4I不改公共API。PlaybackController内部单独记录成功load的QueueEntry身份：stop或idle后
保留当前曲目信息供UI显示，但后续play必须重新resolve/load；暂停恢复可复用已加载会话。
load失败不能因为currentTrack非空而绕过重试加载。显式重播已完成项从零开始。

队列替换、清空和移除共用提交路径：丢弃当前Entry身份或完整TrackRef前先stop，stop失败不写入新队列；
保存队列失败保留原快照，已成功停止的音频不自动恢复。只重排且保留当前身份/引用时不中断音频。
同一当前曲目的error phase与failure必须同时保留，不能清除failure却保留error phase。

自动下一首绑定触发时的会话revision和Entry身份；一次完成只入队一次。手动选择、停止、暂停、Seek或
新一轮播放使旧自动操作失效。完成后的重复快照仍可更新控制值，但更改循环模式不应把重复completed
伪造为新播放周期。旧循环测试补显式重播，不移除随机/列表循环/单曲循环断言。

dispose在异步曲目查询、来源解析、load返回后检查，已关闭Controller不再发起play。Controller仍不拥有
Engine的dispose；根依赖释放职责不变。该门禁不宣称能识别一个没有来源身份的Engine流在新load完成后
错误发送的旧曲快照；插件适配器仍须隔离自身过期事件。双平台原生POC和生产接线门禁保持不变。

## ADR-039：把原生编译与有播放端点的运行分开记录（2026-09-05）

Phase4J证实GitHub Debug EXE需要本机缺失的Debug CRT，实际启动为`0xC0000135`，而不是播放失败。
不通过公共artifact补发Debug运行库、不改系统权限或安装驱动。使用明确的Profile诊断入口，
由GitHub编译完整AOT包、核对原生导入和Commit；有真实端点的本机再执行原来的WAV集成测试。
Profile是测试构建，不是Phase11 Release，也不是正式业务应用；默认入口仍使用UnavailableAudioEngine。

手动`build_windows_audio_probe`默认false，只运行checks/Windows job并生成1天诊断artifact，
与原有双平台无产物POC互斥；Android APK/Release交付明确跳过。原有POC无产物门禁不放宽。
运行者必须从API取得精确artifact digest/head SHA，核对SDK引擎与AOT身份、路径安全与全文件清单，
不允许用旧结果或本地改过的资产宣称某个GitHub Commit通过。Debug拆分路径单独记录Dart/native身份。

本方案只解决诊断交付，不把构建成功、时钟推进或自动测试当作主观听感/后台/媒体会话验收。
真实结果和范围记录于[Phase4J报告](phase_4j_windows_native_validation_report.md)。

## ADR-040：HTTPS POC 使用不可变上游测试夹具与默认 TLS（2026-09-05）

旧 Phase4D 自签名服务器依赖测试信任绕过，不能用于当前 just_audio 的原生 TLS 验收。
Phase4L 使用 AndroidX Media 自身 WavExtractorTest 的公开 `media/wav/sample.wav`，固定
提交 `43e3af79dabb43a69badffbbdfa6d421a1cdb36c`、88,278 字节、SHA-256
`1b35cc093f3d56732b19ff936c21b5bca8195135d63708f6c6488eba5803ddce`。
RIFF 为 PCM16、mono、44100Hz、88200 字节/秒、1秒。上游仓库 LICENSE 为 Apache-2.0，
该文件 SHA-256 为 `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30`。
这是公开测试数据的来源记录，不代替最终应用逐组件许可证审计。

此决策只调整 Phase4F 的 HTTPS 夹具策略：HTTPS 内容不再要求由本测试运行时生成，
本地3秒 WAV 仍使用原生成器。测试先以默认 HttpClient 信任、禁重定向、限时/限额在内存核验
完整字节与 Range；随后引擎直接读取固定 HTTPS URL，不把预检字节转换为本地或字节流音源。
没有证书回调、测试 CA 安装、代理、Authorization、用户 URL 配置、文件写入或产品下载接口。
不提交、打包、上传媒体或其 Base64；服务不可用或指纹漂移均失败关闭，不自动换源。

新增显式 `include_https_audio_poc=false` 的 CI 选择；Windows Profile 诊断扩展同名编译模式，
两用例与1秒/3秒计时分别验证，旧一用例模式不放宽。模式进入构建元数据、准备 manifest 和结果，
调用者必须匹配模式，旧单项结果不能被当成 HTTPS 通过。原生产物与真实端点规则沿用 ADR-039。
本批无生产公共接口修改，不接音频/业务页面；HTTPS通过也不自动批准最终选型和应用发布。

来源：[上游测试](https://github.com/androidx/media/blob/43e3af79dabb43a69badffbbdfa6d421a1cdb36c/libraries/extractor/src/test/java/androidx/media3/extractor/wav/WavExtractorTest.java)、
[夹具](https://github.com/androidx/media/blob/43e3af79dabb43a69badffbbdfa6d421a1cdb36c/libraries/test_data/src/test/assets/media/wav/sample.wav)、
[许可](https://github.com/androidx/media/blob/43e3af79dabb43a69badffbbdfa6d421a1cdb36c/LICENSE)。

## ADR-041：验证实际打包的完整许可证，不重复维护原文（2026-09-05）

Phase4M核对 Flutter 3.47.2 的 LicenseCollector 与 ServicesBinding：构建器会收集 Pub 包 LICENSE，
按完整文本去重并保留包名，原生包保存为 GZip `NOTICES.Z`，运行时由 LicenseRegistry 按需读取。
Phase4L Windows 实际包的四个许可组已包含当前音频六个 Dart 包，逐组原文字节/哈希等于 Pub 原件。
因此新增独立副本并不能提高准确性；本批为已打包原文增加不可静默跳过的源码与产物校验。

`docs/legal/just_audio/manifest.json` 固定六个版本、原文长度/SHA-256和两个原生构建源文件指纹。
源码检查必须匹配lockfile和实际Pub缓存。APK/Windows检查必须找到唯一 NOTICES.Z，限4 MiB压缩体积、
16 MiB展开体积、严格UTF-8及最多10000组；每个目标包恰好出现一次，必须完整文本匹配，
不能通过重命名、只保留许可证名称、重复标注或篡改段落让校验通过。原有48项设计资产校验不变。

技术能力仍以Phase4L同提交的真实POC为准：Android file/content/无Header HTTPS，Windows file/无Header HTTPS。
六包原文检查不等于所有Android Maven传递材料、系统组件、完整发行或用户可见许可页面已经验收。
Media3 1.4.1 的注释tag解析到 `c35a9d62baec57118ea898e271ac66819399649b`，根LICENSE为11358字节，
Apache-2.0，SHA为 `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30`；
just_audio包原文本身包含ExoPlayer的Apache全文，但这不能替代其Maven传递NOTICE覆盖检查。
Windows候选没有额外bundled player libraries，实际使用系统WinRT MediaPlayer。

manifest显式保持 `releaseApproved=false`、`productionWiringApproved=false`、
`transitiveNoticeReviewComplete=false`。下一批继续原生传递材料/许可展示与正式接线，
不得把新增校验“通过”解读为整个应用已获发布批准。被拒绝media_kit清单与历史不变。

来源：[just_audio 0.10.6](https://pub.dev/packages/just_audio/versions/0.10.6)、
[Windows 0.2.3](https://pub.dev/packages/just_audio_windows/versions/0.2.3)、
[AndroidX Media精确LICENSE](https://github.com/androidx/media/blob/c35a9d62baec57118ea898e271ac66819399649b/LICENSE)。

## ADR-042：随应用保留 Android 音频闭包的原生许可材料（2026-09-05）

Phase4N以应用真实解析的Media3闭包为范围，共51个坐标，而非仅插件声明的10个Media3模块。
Gradle报告只解析选定外部模块，避免AGP本地插件的多变体歧义；相同文件名且SHA相同的重复
变体归档去重，BOM/重定向坐标保留为空归档列表，不伪造二进制。解析版本和每份实际归档的
长度/SHA均进入可比对清单；开发机绝对缓存路径只存在忽略的build报告中。

生成器读取精确POM及必要父POM，禁用DTD/外部实体；查找AAR/JAR及嵌套classes.jar中的
LICENSE/NOTICE/COPYING/AL2.0/LGPL2.1文本，完整UTF-8原文有界读取并去重。
当前有三份不同原文：固定Media3上游Apache-2.0、ExifInterface归档内Apache原文、
checker-qual归档内包含著作权的MIT原文。Guava/failureaccess/listenablefuture的许可继承
精确父POM；没有用通用MIT模板替换带著作权原文。生成结果为66,604字节JSON，SHA见机器清单。

该数据随两平台应用资产打包，Windows携带的条目明确属于Android能力，不声称其二进制
进入Windows。Android构建后重新解析真实闭包并逐项验证归档及重新生成原文；两平台均对
实际包内资产逐字节校验。新增唯一资产白名单项，原48项设计资产与六个Dart包门禁不变。

额外只读解析Profile与Release：Profile同为51项；Release为48项，恰好不含jsr305、
error_prone_annotations和checker-qual三项注解依赖。机器清单明确记录三个变体的差异，
逐项精确比对，不能允许任意子集缺失。随应用保留51项材料超集；这不是Release构建成功证据。

这关闭当前音频闭包的工程材料缺口，保留releaseApproved=false；整个应用仍须Phase11发行
审核和Release构建，未来依赖版本改变必须重审材料。用户可见许可入口和生产播放器接线尚待
下一批，不在本批翻转已声明的生产状态。没有运行时联网收集许可或媒体下载。

来源：[固定Media3源码](https://github.com/androidx/media/tree/c35a9d62baec57118ea898e271ac66819399649b)、
[Guava精确版本POM](https://central.sonatype.com/artifact/com.google.guava/guava/33.0.0-android)、
[Checker Framework 3.41.0](https://checkerframework.org/releases/3.41.0/manual/)。

## ADR-043：许可查看使用自有合同与原生控件（2026-09-05）

新增纯Dart `SoftwareLicense` 与 `LicenseRepository`，自有app适配器读取Flutter
`LicenseRegistry`和Phase4N已审资产；UI只接收合同，不读取文件或导入第三方插件。
SDK条目保留全部段落内容，Android材料逐文档长度/SHA校验并按同文档聚合组件，不请求网络。
适配器限制数量/文本大小/总时长，失败仅返回固定安全错误，允许用户主动重试。

设置入口推入独立`/settings/licenses`路由，搜索组件名、按需显示全文，使用YYSearchField、
YYButton及自有Dialog/BottomSheet；不是Material LicensePage，不复制完整Settings功能。
模态原文进入导航栈，返回先关原文再离开许可页；长文本在模态内部滚动。依赖由Graph注入，
不在build启动异步请求，不保存第三方许可内容到数据库，不引入全局播放状态或媒体文件。

## ADR-044：当前音频工程选型与根资源所有权（2026-09-05）

选择锁定的 just_audio 0.10.6 + just_audio_windows 0.2.3（Media3/WinRT），
依据 Phase4L 同实现双平台原生运行、Phase4M/N 源码/实际包内全文核验、Phase4O 可见许可入口。
只批准当前无代理/Header 的工程接线；全应用发行仍未批准。更新六包清单的工程能力标志，
但保持其六包覆盖范围和 releaseApproved=false，原生范围仍以独立 manifest 为准。

新增 app 层 AudioEngineFactory，默认 Bootstrap 在数据作用域之后只创建一次后端，再移交 Graph。
Widget 测试注入 Fake，main_dev 显式不可用；不按布局断点创建播放器。平台限定本地解析器只将
已经由 Repository 提供的 Track 转为短期 PlayableSource，不读磁盘、访问网络或取得权限。
Android 优先 content URI，回退绝对 POSIX 路径；Windows 接受驱动器绝对路径或明确 UNC 文件，
拒绝设备命名空间、相对路径和跨平台引用。REST 必须等待 Adapter，不解析 metadata URL。

PlaybackController.close() 同步停止接受命令/状态更新，并等待订阅取消、已有命令和媒体同步；
Graph.close() 共享同一个 Future，逐项释放 engine/media/data，即使一项失败也继续，最后给固定
app.shutdown-failed。dispose() 保留 Flutter 同步接口，安全启动关闭；有验证需求调用 close()。
Bootstrap 获取资源期间的异常或晚到结果都执行清理，不展示原始路径/插件异常；恢复队列不自动播放。

## ADR-045：Shell 播放器只消费根 Presenter（2026-09-05）

新增 app/PlaybackPresenter，订阅根 PlaybackController，只计算只读 YYNowPlayingViewData 与
控件可用性，转发既有播放/队列/随机/循环命令；不复制位置时钟、队列算法、历史或音频实例。
Presenter 仅保留 UI 命令执行中与脱敏动作错误，Graph 在 Controller 前解除其订阅。
三个 Shell 接收已构造的播放器 Widget 插槽，由 AdaptiveRoot 选择 Mini 或 Desktop Compact/Full。
因此宽度/路由变化不重建 Presenter/播放核心，也没有平台专属业务控制器。

ShellPlayer 的短期拖动值由 Widget 持有；Seek 绑定队列条目身份并以该身份重建拖动子树，
换曲/换 Shell 不把旧手势提交到新曲。持久位置、音量仍只来自 Controller，预览不调用引擎。
命令串行期间禁用相应操作，失败使用固定文案；空队列/不可用后端不假装播放。
未实现的收藏、歌词/全屏、队列/设备工具保持空回调即禁用；不打开骨架页冒充业务功能。
当前无封面来源 Gateway，播放器暂用既有纯几何占位，后续真实 Artwork 接口优先替换。
Controller.seek 增加可选 expectedEntryId，并在串行命令真正执行时再次核对；Presenter 的前置核对
不能代替队列内部保护，防止 Seek 排在外部换曲操作之后。系统媒体接口仍可不传此参数。
修正旧播放器主按钮误用 accent 阴影：采用 App.tsx .player-control.primary 的 (0,8)/22/16% 深色，
不影响普通 Primary Button；对应基线只在确认几何与颜色差分后更新。
未开放详情的曲目信息使用静态 Semantics，保留正常文字对比度且没有按钮/onTap 语义；
动作按钮仍按可用性禁用，不修改公共控件的全局禁用样式。

## ADR-046：Inspector 与底栏共享同一个绑定入口（2026-09-05）

设计系统的 YYNowPlayingInspector 仅消费视图与受控回调；ShellPlayer 的 inspector 模式复用
根 Presenter 和相同的手势预览/提交/entryId 保护，不生成新 Controller。多个可见表面只各自持有
短期手势，提交后从根状态收敛。Windows320/Tablet260使用同一内容组件、不同几何容器；
短高度独立滚动，收窄卸载面板不停止或重建音频。来源只显示 local/rest 类型，不暴露路径或URL。
未开发的完整队列/歌词/设备入口禁用，队列仅显示真实总条目数，不把物理顺序冒充随机后的下一首。

## ADR-047：窗口生命周期独立于播放根资源（2026-09-05）

YYMusicApp根作用域拥有WindowPresenter/Gateway，三个Shell只接收已构造Chrome，不调用Win32。
窗口通道只操作本Runner HWND；握手成功前保留系统caption，成功后保留原生resize边界，Flutter
42dp非交互标题区域驱动移动/双击最大化，控件区域不作为拖动区。窗口快照以原生状态为准。
WM_CLOSE/Alt+F4触发closeRequested，Presenter幂等等待业务Graph.close所有释放尝试完成后调用
原生completeClose，才允许WM_CLOSE销毁。窗口Gateway不能作为Graph内的提前释放资源，否则
退出握手会在最终关闭前断开。UI卸载时解除通道/订阅，晚到回调不能更新已销毁状态。
没有新包、全局系统修改、尺寸/位置持久化或全屏能力。本批CI先跑原生窗口测试再重新构建正式
Debug，原生测试不关闭测试进程，只证明关闭请求被Dart接收且批准前窗口仍存在。

## ADR-048：首页“最近添加”使用首次入库时间（2026-09-05）

不能用文件修改时间或标题排序伪造“最近添加”。tracks.added_at_ms由Repository首次插入时记录，
后续upsert保留原值；v1迁移旧行保持NULL而非给全部旧库写“今天”。v2新增排序索引和有界时间/分页
合同，首页不订阅全曲库来做客户端排序。起止时间包含端点、按首次时间倒序及完整TrackRef稳定排序。
迁移保留v1快照、引用、收藏和队列，不删库，审计与新增列/索引在同一事务。真实业务界面后续接线。

## ADR-049：首页是根数据的有界投影，不拥有播放器（2026-09-05）

HomeController由DependencyGraph持有，三个独立布局只组合受控原生组件；路由/断点变化不创建
新数据库或AudioEngine。最近7天查询20条，历史20条按完整TrackRef去重解析；精选最多6首，
优先可用历史，否则只过滤普通曲库首20条中的本地曲目。这不是完整推荐算法或全库本地筛选。
目录显式刷新，历史/来源订阅更新，分区失败互不覆盖；请求与事件版本拒绝晚到结果，错误为固定文字。
来源只显示持久公开状态，不读取端点或秘密，也不把卡片当连接测试。选择曲目先复用已有队列条目，
没有则追加后播放，不替换整队列。清除历史必须由视图确认，只修改历史Repository。
根关闭同步禁止新操作并取消监听，等待首页在途读取/动作完成，再释放底层存储；不把Widget销毁
等同于数据Future已经结束。无曲目使用真实空态，不注入HTML样本；本批封面保留明确占位。

## ADR-050：搜索先按实体分页，再于同一只读语句展开关联（2026-09-05）

CatalogSearchRepository由正式DriftLibraryRepository实现，但不扩张普通LibraryRepository合同或让UI
订阅全库过滤。歌曲、专辑、艺人各自分页：CTE先筛选/稳定排序并取limit+1个实体，外层连接有序
艺人信息再按完整身份归组，避免多艺人吃掉页容量或两次读取混合不同版本。查询值/来源/分页全部绑定。
初版尝试用Drift transaction保护两次读取；真实双连接测试发现其BEGIN IMMEDIATE会排斥并发写入，
因此改为一次SELECT，不改全局SQLite设置、不开写事务。子串搜索仍可能扫描数据库，不是FTS/拼音索引，
大曲库真实设备性能仍待Phase6出口验收；不把450首合成测试外推到任意规模。
内建lower只保证ASCII大小写折叠，中文按字面子串；百分号/下划线不是通配符。取消为合作式结果丢弃，
不谎称底层语句已中断。取消异常独立于数据库损坏错误；空查询不触发SQL。
SearchHistoryRepository只在显式record时保存用户本机搜索，ASCII归一查询和可空来源共同确定身份。
旧ID等价项替换、写入与保留20项在同一事务，clear只清历史；查询本身无写入、网络或音乐下载。
共享存储默认不归历史Repository关闭，拥有存储时排空在途操作再关闭。根/UI接线属于下一增量。

## ADR-051：搜索按独立结果区域投影，播放意图可撤销（2026-09-06）

Phase6D把原生Search接入根图，同一个Library实例提供CatalogSearch合同，不创建另一套数据库或引擎。
三类实体按本地/已入库REST引用分为六区；每页20条，完整身份去重但offset仍按原始返回行数递增。
每区200条上限和Sliver惰性构建约束内存；新查询取消旧token，仅丢弃迟到结果，不承诺打断SQLite。
页面明确实时在线搜索尚未实现。输入法结束后300ms防抖，历史只在显式提交时写入，record/list/clear
串行防止清除后复活；任何异常都以固定文案呈现，公开来源名之外不读取配置私密字段。
Enter只在可见曲目区域选第一个可用结果，先本地后已保存在线引用；已有本地结果不等慢在线/其他实体。
输入/筛选/离页/销毁撤销播放意图；根播放器在队列调度和异步读/解析/加载边界检查，撤销加载不播放。
原子复用或追加完整TrackRef，保留其他队列条目；不因撤销而回滚已提交的追加。普通playEntry行为保留。
根关闭先禁止新工作、取消搜索timer/订阅，等待在途查询/历史/播放任务后释放存储；控制器借用的合同
不由其关闭，正式数据作用域负责历史Repository与数据库。Ctrl+K聚焦/滚动属于UI，不在业务层持有FocusNode。

## ADR-052：音乐库浏览使用来源隔离的只读分页合同（2026-09-06）

CatalogBrowseRepository独立于普通Library和Search接口，但正式实现共享DriftLibraryRepository、
数据库和生命周期。排序/过滤/专辑与艺术家详情是数据能力，不能让页面先读取整库再排序分页。
AlbumRef/ArtistRef按既有Schema保留sourceId与实体ID；曲目仍使用完整三元TrackRef。
私有Dart part封装浏览SQL；排序仅由闭合枚举映射，所有外部ID、状态、来源和页参数使用绑定值。
单条CTE先过滤/排序并取limit+1实体，再展开有序艺人，避免关联截断、N+1和多读版本混合。
NULL始终最后，主排序支持升降序，完整身份后备顺序保持升序；文字只用SQLite ASCII lower，
按艺人排序指首位credit，不假称拼音/区域化排序。不同分页请求不提供跨写入快照保证。
专辑/艺人筛选使用存在匹配曲目的条件；组合来源/可用性/艺人要求同一条曲目满足，不能分开匹配。
返回计数是完整实体的既有聚合值，不是过滤后条数。来源配置已被删除也不自动隐藏保存的引用。
复用SearchCancellation合作式丢弃，不声称中断原生SQL；缺失返回null，数据库损坏保持固定安全错误。
本批只导出根数据合同，不改UI/Schema/依赖，不写搜索历史、联网、扫描文件或创建新的音频实例。

## ADR-053：音乐库分类页是根目录的有界投影，曲目不可播放不等于不能收藏（2026-09-06）

LibraryController由根图拥有，三端布局共用分类/排序/筛选与播放器，不在Widget创建业务引擎或存储。
目录分类各保存一个有类型实体的分页投影，每页20、最多200条原始返回行；完整身份去重不改变offset。
排序按分类保留，来源/状态改变使所有目录旧token失效，切分类保留其他页；一次查询错误不清除旧行。
歌单暂使用既有元数据流并截取200项，不假装该合同支持数据库分页、目录来源筛选或完整歌单管理。
收藏/歌单/来源订阅互相独立；公开来源名可用则显示，否则显示未配置，不解析URL/凭据到界面。
播放使用根playCatalogTrack原子复用/追加，切分类/筛选/离页/关闭撤销未执行意图。已接受的收藏写入
排空后才释放共享数据库，离页不会悄悄回滚用户操作；引用不可用仍允许收藏，并不允许实际播放。
YYTrackTile新增默认false的allowMoreWhenDisabled，只有Library显式启用；主动作仍禁用/变淡，
更多按钮保留可见性和操作能力，旧组件调用方和Golden不变。菜单为页面内原生Flutter浮层，
不覆盖Shell播放栏/导航；Esc、Android Back或页面失活关闭菜单，返回焦点由页面持有。
根关闭先同步停命令/取消token，等待本页在途读写与订阅释放后，再关闭共享存储。
专辑/艺人/歌单本批只展示真实元数据；不添加模拟详情/导入/连接成功按钮，不把持久REST引用称为实时在线。

## ADR-054：详情为根注册的短期只读会话，分页与摘要独立（2026-09-06）

CatalogDetailSessions由根图持有，只借用既有CatalogBrowseRepository。每次打开专辑或艺人创建
独立会话，目标固定为完整AlbumRef/ArtistRef；不以显示名称猜关联、不创建第二个数据作用域。
摘要先确认身份；缺失不发子查询，错误不伪装空目录。艺人专辑与歌曲各自请求、错误、重试，
保持完整目录计数。分页20、200原始行上限、完整身份去重，不把去重后的数量用于offset。
刷新取消摘要及全部分区旧token；迟到结果不通知、不改变新一轮loading/错误。取消不承诺中断SQL。
可由模型验证的来源/专辑关系不符时整页失败，保留已加载数据；艺人关联由Repository的曲目credit
合同保障。Track只有艺人显示名，合辑的album artist也不必包含曲目艺人，不做名字/专辑credit猜测。
关闭会话同步禁用新查询并取消token，注册表保留它直到在途Future排空。根关闭先停止所有会话，
再等待其关闭，最后关闭共享数据库；不将Widget.dispose等同于底层读取已经完成。
Phase6G1只提供可测试读模型与生命周期；路由、三套布局及曲目动作在Phase6G2接入。
审查补充：详情、Library和Search均按剩余容量计算末页limit，并按该limit截断实际响应。
只检查offset>=200再固定取20，遇到15/18条的短中间页会越界；新增三个先失败的回归后修复，
原始offset语义、重试、去重和UI不变，不降低200上限或更改Golden。

## ADR-055：详情路由保留来源与返回栈，界面复用根播放（2026-09-06）

AppNavigation增加类型化openAlbum/openArtist，URI路径只放实体ID，source查询参数单独转义；
入口禁止名字查找和模型对象extra兜底，非法/重复/缺失来源参数显示安全错误，不输出原始路由。
详情Page Key同时包含路由栈Key和强类型完整引用；系统替换同路径的来源/ID时关闭旧会话及滚动Bucket，
相同完整引用更新则保留状态，不能只按/album/:id模板复用旧来源的数据。
详情路由为普通非全屏页面，使用相同AdaptiveRoot/PlaybackPresenter，push/pop保留原主页面与详情栈。
每个详情Widget只持有根注册的会话、滚动与选区；平台/尺寸改变不创建另一会话或播放器。
详情State位于可切换Shell之上，由App注入frame包装内容；不能把State放在Phone/Tablet
不同父类型之下，否则600断点会销毁路由会话。视图层不自行依赖或选择Shell。
三套布局使用同一PageStorageKey，在各自路由Bucket内恢复滚动位置；不串页或因横竖屏归零。
详情会话增加借用根PlaybackController与MusicSourceRepository；公开来源名独立加载，失败回退，
不等在线连接或接触凭据。仅当前可见、可用曲目可以播放；刷新/覆盖路由/销毁撤销在途播放意图。
根追加/复用队列已经提交的部分不因撤销回滚，播放仍持续于正常离页；会话关闭等待在途动作。
本增量暂不提供详情收藏菜单；YYTrackTile新增默认true的showMore，详情显式false隐藏无动作按钮，
现有调用方保留原样。音乐库专辑卡启用和艺人明确详情按钮引起的视觉变化分别更新Golden，
不降低比较阈值，不改变其他旧页面基线。详情外观延续App.tsx标题/图标/20圆角/阴影，封面明确占位。

## ADR-056：详情收藏为按需投影，已接受写入排空后关闭（2026-09-06）

详情会话借用根CollectionRepository，不创建收藏存储或依赖Library页面启动。首次打开曲目菜单才订阅
收藏流，普通详情读取不新增收藏查询；私有投影只缓存完整TrackRef集合、ready和安全错误，不以名字关联。
读取失败禁用收藏写入并允许单独重试，不把未知状态当成未收藏；旧订阅代次取消，迟到事件丢弃。
收藏命令按可见完整引用和已知状态执行，失效曲目也允许收藏；与详情播放共享busy，防止重复提交。
成功写入后重新订阅取得当前状态，旧代次不能覆盖成功后的新投影。离页/刷新不撤回已经接受的收藏写入；
关闭同步停止新命令、关闭投影，根注册表等待写入、订阅取消及其他在途工作后才释放共享数据库。
订阅的创建/取消也登记在会话pending中，即使订阅建立过程重入关闭也必须清理刚创建的订阅。
菜单仅为原生受控UI，不执行构造期查询；操作反馈不含原始错误。Phone底部/桌面居中，Esc/Back先关闭
菜单、恢复有效焦点；刷新、分区切换、失活关闭菜单。复用既有设计原语和根播放，不引入下载或假动作。

## ADR-057：歌单编辑采用原子命令与根级写入排空（2026-09-06）

既有savePlaylist是引导/数据层upsert，不适合用户创建或重命名：ID碰撞可能覆盖，读取后保存也可能
复活已经删除的目标。CollectionRepository新增createPlaylist（只插入自定义歌单）和renamePlaylist
（只修改仍存在的自定义歌单名称），Drift事务中核验身份，不改变Schema或既有savePlaylist语义。
编辑名称统一trim、1–512字符并拒绝控制字符；创建不允许系统身份，改名保留description/createdAt/
全部条目，updatedAt取现有值与当前UTC时间较晚者。重命名不存在目标失败，禁止静默重建；删除保持既有幂等行为。
删除复用已有系统保护/级联条目删除，不删除曲目、收藏、历史、队列或来源内容。

根PlaylistController只管理命令生命周期，借用根CollectionRepository；列表仍属于既有Library投影，
不建立第二列表/存储，不在构造期查询，不依赖某个Shell的启动。ID采用随机128位值，不按名称生成。
单命令busy拒绝并发点击；结果为固定状态/安全文案而不是异常原文；UI负责未提交草稿与删除确认。
所有命令在发出通知前登记，已接受的写入不因离页或根关闭而撤回，关闭拒绝新命令并等待已登记工作，
最后才释放共享数据库。创建碰撞失败而不是覆写，用户可重试；不自动重试可能已成功的存储写入。
Phase6H1只提供这个数据/状态基础，Phase6H2再接三端原生编辑界面，未接线不得宣称用户已能管理歌单。

## ADR-058：歌单草稿位于自适应 Shell 之上，确认与写入分离（2026-09-08）

AppRouter借用根PlaylistController，在StatefulShellRoute的AdaptiveRoot上方放置编辑宿主，
以受控作用域向Library提供创建/重命名/删除请求，不扩展持久化或建立第二份列表。
宿主拥有未提交文本与焦点，Phone/Tablet Shell替换和窗口尺寸变化不销毁草稿；
离开Library或覆盖其路由时关闭草稿。接受的命令仍由根Controller排空，不因Widget销毁取消。
异步完成必须检查宿主挂载及每次打开的独立递增代次，不能关闭或覆盖随后打开的新草稿。
请求值可能是Dart规范化的同一const对象，不能用identical(request)作为会话身份。
关闭后的失败在Library显示可确认的安全提示，不改变新草稿；进程关闭后不尝试通知已销毁的界面。

删除请求只打开确认UI，明确只删除歌单和条目，不删除歌曲文件或来源；确认按钮才调用命令。
系统歌单无编辑入口，命令层系统保护仍独立生效；busy禁用输入/提交，失败保留文本及安全反馈。
列表继续响应既有Library投影，不乐观捏造成功或对已删除身份执行upsert。

Phone使用YYBottomSheet，Tablet/Windows使用YYDialog；原生名称输入保持field语义与done动作，
共享搜索输入既有的原生选择手柄/编辑菜单，不复制搜索图标、清空搜索文案或search输入动作。
宿主覆盖整个Shell的点击、焦点和语义，处理Back/Esc及快捷导航离页，输入时不触发播放快捷键。
SafeArea和viewInsets参与可用高度计算；变更后仍按完整App.tsx覆盖层与基础HTML检查三端Golden。

## ADR-059：歌单条目以身份和锚点原子编辑（2026-09-08）

既有 replacePlaylistEntries 保持引导/导入整表替换合同；交互不能读取列表后整表覆盖，
否则会丢失期间的追加或改序。新增 PlaylistEntryDraft（ID、完整 TrackRef、UTC addedAt），
appendPlaylistEntry 在事务内确定尾部位置；removePlaylistEntry 按条目 ID 移除；
movePlaylistEntry 的 beforeEntryId 指定同歌单现存锚点，null 表示移动到当前末尾。
条目身份独立于曲目，同一曲目可重复加入，本地/在线/已失效来源的完整软引用均保留。

三命令只允许现存自定义歌单，系统歌单拒绝交互编辑。追加 ID 为全表唯一，碰撞失败而非覆盖。
缺失歌单、移动目标或锚点，以及跨歌单条目引用返回 notFound。移除真正不存在的条目幂等；
自己作为锚点、已相邻或已在末尾均无操作，无操作不修改 updatedAt。
位置必须从零连续；通过 count/max 与既有唯一/非负约束验证，不默默修复损坏数据。
受影响位置先移入空闲正数区间，再回填最终位置，避免 SQLite 唯一冲突和负数 CHECK 失败；
目标移动、邻居位移、父歌单 updatedAt 在同一事务，任何失败整体回滚。
仅真实改变触发父歌单时间更新，取当前 UTC 与旧值较晚者；不改变名称、说明、createdAt、
条目 addedAt、曲目/收藏/历史/队列/来源或文件，不添加 schema/依赖。

根 PlaylistController 复用已有命令通道，追加 ID 采用独立随机 128 位身份且仅在接受命令后生成。
元数据与条目命令共享 busy；接受后先登记再通知，关闭排空后才能释放根存储。
失败使用固定状态/安全文案，不自动重试不确定写入，不构造第二份列表或播放实例。
Phase6H3 只实现可验证命令基础，后续增量再接读取会话和原生管理入口。

## ADR-060：歌单内容以一致窗口读取，通知和在途查询分别排空（2026-09-08）

CollectionRepository 增加 readPlaylistContent(id, PageRequest) 与 watchPlaylistContentChanges()。
前者返回单条 SQL 的 PlaylistContent 或缺失 null；包含父歌单、真实总数和按位置排序的窗口，
每项为 PlaylistContentEntry（PlaylistEntry 与可空 Track）。完整 TrackRef 左连接，条目 ID 聚合，
重复歌曲不去重；缺失曲目保持引用而非自动删除或杜撰标题/路径。现存空歌单与父歌单缺失不同。
SQL 先分页后展开艺人，禁止逐条 getTrack/N+1，不扫描解析窗口外曲目；count/max 检查位置连续性。
本合同限自定义歌单，系统歌单实时视图由收藏/历史/队列合同另行提供，不能把持久空条目误报为空系统歌单。

失效流不做内容查询或携带整库数据，可因相关表的其他歌单改变或事务回滚而保守失效。
它不是提交日志，收到通知必须重读当前持久内容，不能把通知本身当作写入成功。
根 PlaylistContentSessions 创建惰性独立会话；首次 start 先订阅再读取。会话保留单个一致窗口，
初始20，按20扩展至200，达到上限明确 capped；仓库 offset 合同仍可读取任意窗口。
重新读取整个可见前缀而非拼接不同数据库版本的页，条目增删改序及曲目/艺人更新同时刷新。
不把 updatedAt 当作可靠版本：时钟回退或同毫秒编辑仍必须刷新。通知合并，读取期间失效就丢弃旧结果再读。
读取失败保留旧内容但标记过期，禁止把其当作可操作的新数据；失效流错误/提前结束也进入安全错误并可重建订阅。

库中 Drift 的查询流取消不保证原生 SQL Future 已结束。因此失效通知与显式查询分开，
每个查询、订阅创建/取消都在通知 UI 前登记，关闭同步停止新工作并等待真实在途读取及取消完成，
最后才从根注册表移除并关闭共享数据库。订阅构造/取消中的重入、旧事件/旧结果均有代次隔离。
ChangeNotifier 通知期间发生同步根关闭时，先停止新工作并登记 close Future，
待通知栈退出才调用 super.dispose；不能在活动通知栈中清空监听器，也不能因此漏掉在途查询。
本增量不改 UI/路由/播放/Schema/依赖，不做网络解析，不复制第二份曲库或依赖 Library 页面启动。

## ADR-061：原生歌单内容路由与受控条目动作（2026-09-08）

AppNavigation增加openPlaylist(id)，严格URI编解码只携带稳定自定义歌单ID；错误链接不回显原始参数。
页面状态在AdaptiveRoot之上，路由借用根PlaylistContentSessions，会话借用根PlaybackController/PlaylistController。
不新增播放器、数据库、曲库缓存或来源查询；既有单语句读取和20→200上限保持，系统歌单仍拒绝此合同。

会话按独立entryId定位当前内容，逐首播放复用根playCatalogTrack，不替换整个队列。
任何失效刷新/离页/覆盖/关闭撤销尚未执行的播放意图；持久化可用性仅作界面提示，最终解析仍由根播放器负责。
移除和上/下移动仅在当前一致窗口与根writer可用且空闲时接受；锚点按当前条目身份传递，
未知窗口尾部禁用下移，不以null将其误移到整张歌单末尾。写入不做乐观整表覆盖或自动重试。
动作Future在通知前登记；writer同步接受后即使离页/根关闭也排空；根保存安全的条目错误文案，
由原有PlaylistEditorScope传给音乐库，关闭内容路由后的失败仍可见、可显式清除。

菜单使用独立请求身份和快照身份，过期/同ID重开/迟到回调都不能执行；失效或覆盖路由关闭菜单。
菜单覆盖包括Shell的页面交互，Back/Esc优先关闭菜单，完成后仅向仍有效的控件恢复焦点。
Phone/Tablet/Windows各自布局使用原有YY组件/SVG/Token，不将HTML运行时或在线Figma节点猜测带入客户端。
本批不交付添加选择器、播放全部/随机、拖拽、系统视图或超过200条的连续浏览，不能声明整个Phase6完成。

## ADR-062：添加歌单选择器使用显式有界读取与根原子追加（2026-09-08）

CollectionRepository增加readCustomPlaylists(PlaylistNameQuery, PageRequest)，只读自定义歌单元数据。
名称为修剪后0–512字符、无控制符的字面子串，仅ASCII大小写折叠（中文原样匹配）；百分号/下划线不是通配符。
按updatedAt降序、ID的Unicode标量顺序升序稳定分页；SQLite BINARY UTF-8与Fake同序。
limit+1在单次查询判断hasMore，窗口外元数据不解码，不查询歌曲/条目/来源或返回假计数。

根PlaylistAddSessions拥有惰性独立会话，复用watchPlaylistContentChanges的失效信号与显式读取，
查询Future/订阅创建取消/已接受写入分别登记排空，最终才释放共享库。会话不依赖Library页面是否启动。
20→200完整可见前缀，每次重读而非拼接异步排序版本；达到上限明确提示筛选缩小范围。
筛选输入显式提交；草稿与已读筛选不同或IME合成时旧选项不能提交，快照/请求代次阻止迟到回调。

AppNavigation添加Future<void> addToPlaylist(TrackRef, title)，根原生模态路由不将完整Track、路径或URI传入路由参数。
调用页面在模态期间撤销待执行播放并阻止旧菜单；关闭后仅在原页面仍有效时恢复活动状态与行焦点。
Phone BottomSheet与Tablet/Windows Dialog共用业务会话，模态覆盖Shell并阻隔键盘/语义，Back/Esc关闭。
写入只调用根PlaylistController.addTrack，目标必须是当前快照的自定义歌单，最终原子命令再次校验父身份。
重复TrackRef允许独立条目；只保存引用，不解析/下载/复制文件，也不创建第二播放或持久状态。
接受后即使离页或关闭仍排空；失败安全化，离页后的错误由既有根entryFailure返回Library显示。
本批仅已有歌单选择；新建并添加需要后续真正原子组合，不将两个独立成功/失败冒充原子操作。

## ADR-063：新建并添加必须是一个原子根命令（2026-09-08）

CollectionRepository.createPlaylistWithEntry(Playlist, PlaylistEntryDraft)在同一事务内创建自定义父歌单及首条引用。
复用新建名称/系统身份/父ID碰撞保护，entry ID全局唯一，首位置0，元数据与addedAt按输入保留。
只保存完整TrackRef，允许来源缺失；不复制或读取音乐文件，不更新旧父歌单或条目。
任一插入/校验失败整体回滚；不是UI先create再append，也不自动重试不确定写入。

根PlaylistController.createPlaylistWithTrack只生成一次父ID/entry ID与UTC时间，调用单个Repository合同；
所有写入仍共用busy/错误/关闭排空，失败纳入既有entryFailure，离页可见且可清除。
PlaylistAddController.createAndAdd复用已接受写入的登记/完成逻辑；不要求已有列表读取成功，
因为创建不依赖列表内容，最终数据库事务负责名称/身份校验。没有生成第二个持久列表或播放实例。

选择器保留独立名称草稿，显式“新建并添加”，不复用/自动提交名称筛选草稿。
提交前同时确认活动路由、当前草稿、非IME合成与根可写状态；旧按钮不能提交修改后的新草稿。
成功只显示真实提交反馈；旋转/零尺寸保留草稿，关闭后的已接受写入继续排空，不误关后来的弹层。

## ADR-064：歌单用有界一致窗口遍历，不无限累积分页结果

2026-09-08，Phase6H8。复用CollectionRepository.readPlaylistContent的现有offset合同，
每次仍最多200个条目；首组20条递增，达到200条后切换下一组，上一组完整读取。
分页动作绑定当前快照并检查活动路由/busy；每次查询替换完整窗口，失效通知刷新同一目标，
不合并跨版本页、不使用updatedAt充当版本、不复制整份歌单或建立第二存储。
删除导致目标offset越界时，先依据本次一致总数回退最后有效200条组，再查询并发布；
旧响应/错误通过readRevision隔离，根关闭继续排空真实Future和订阅。
界面显示真实范围及上一组/下一组，只有组偏移改变才重置滚动；系统投影与跨组移动另行设计，
不推测未读取的相邻条目身份。Schema、SQL、播放实例及安全边界不变。

## ADR-065：歌单整体播放使用轻量一致计划和单个根队列命令

2026-09-08，Phase6H9。CollectionRepository新增readPlaylistPlaybackPlan：一个绑定SQL，
读取父身份和全部条目ID/位置/完整TrackRef/持久可用性，不取曲目Metadata/封面/艺人、不N+1、不拼分页。
计划是仅供显式播放命令的一次性轻量快照，不是第二个内容缓存；重复条目与不可用软引用保留，系统视图另行实现。

PlaylistContentController从当前快照接受动作，先登记Future，读取计划后按可用性过滤；没有可用项时不动队列。
根PlaybackController.playCatalogSelection冻结完整引用集、唯一ID和随机次序，在一个串行任务内持久化/安装队列与模式，
再调用现有根播放流程。播放全部从首项开始且关闭随机；随机播放预先打乱队列项ID（不改持久歌单顺序），首项也随机，
后续沿同一随机序列前进。随机源失败必须发生在队列/音频变动之前。队列与模式在同一次通知中一致可见。

UI明确说明替换当前队列；不是追加，也不是只取当前200条。读取时已不可用的条目跳过并显示计数，原歌单保留。
活动路由/代次/菜单/当前快照/busy保护接受动作；提交前撤销不写，持久化已开始则排空并保留真实提交，不补偿覆盖。
根关闭等待计划查询与批量播放操作，再释放SQLite/后端；已真正开始的播放不会因正常离页而停止。
读取之后新失效/解析/引擎错误使用现有安全错误态，完整队列运行时跳过策略留在后续Phase7，不宣称全部异常自动跳过。

本批回归暴露Windows WindowFrame零尺寸卸载Navigator的问题：改为保留上一次有效约束离屏布局，
Offstage/ExcludeFocus/TickerMode共同隐藏、隔离焦点并暂停页面；未曾显示时仍保持空占位。
不新建播放器/路由、不发明最小尺寸；恢复后保持同一会话，最小化期间撤销延迟播放，正常已开始音频继续。

## ADR-066：系统歌单是枚举选择的只读集合投影，不是持久父歌单

2026-09-08，Phase6H10。CollectionRepository提供按SystemPlaylistType读取的有界内容窗口与类型相关失效流。
模型不含Playlist父记录或可删除伪ID；喜欢的条目身份为完整TrackRef，历史/队列为已有真实记录ID。
时间按来源语义投影（收藏addedAt、历史startedAt、队列addedAt），缺失曲目仍保留引用，队列重复曲目不去重。
一个SQL选择受信任的枚举固定查询，所有分页值绑定；计数与队列当前ID同快照，先页后艺人展开。
喜欢时间倒序/完整身份正序，历史时间倒序/ID正序且最多20，队列原position顺序。
队列状态缺失/悬空或全局位置不连续安全失败；当前条目在页外合法，不为显示窗口重置当前播放。
失效流不自动读取内容；只监听对应集合及曲目/署名表，取消后不继续通知，不包装为提交日志。
不新增写入/Schema/播放实例；UI与根会话的查询排空、历史真实开始记录和系统操作随后接入并验收。

## ADR-067：系统歌单用固定类型、根注册的只读窗口会话

2026-09-08，Phase6H11。SystemPlaylistSessions由DependencyGraph持有，仅借用根CollectionRepository；
open(SystemPlaylistType)创建独立会话但不工作，start显式订阅类型相关失效流后首次读取，无伪Playlist ID或第二队列真相。
状态包含明确idle/loading/data/empty/error；加载和失败期间可保留旧窗口供显示，但isCurrent与导航授权关闭。
类型在会话寿命内不变，跨类型响应、错误offset/limit安全拒绝，不把缺依赖当成空歌单。

沿用已有自定义歌单的有界窗口交互：20条增至200，随后前后整组；每次仅一个整体窗口，不累积跨版本分页。
导航必须绑定当前快照并校验活动状态，末组删除越界会重读最后有效组，不发布伪空歌单。
每个会话单worker串行读取，失效风暴只补一次最新读，revision隔离旧成功/错误；显式refresh重建监听并保留目标窗口。
订阅错误/结束使内容失效；取消异步Future、重入产生的订阅及已接受读取必须注册并排空，之后根才关闭存储。
只读会话关闭不停止根播放；当前队列ID完全来自同一投影，可在页外且不触发选曲。
本批没有写命令/新UI/Schema/平台或播放器变更，系统入口与动作以及真正开始播放后的历史持久化分批验收。
