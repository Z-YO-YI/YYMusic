# YYMusic 当前实际架构

Phase2A增量：根DependencyGraph现在还拥有并释放唯一YYAppearanceController；YYMusicApp按系统亮度/动态偏好解析YYTheme，原路由/业务控制器不重建。Android增加独立`/design-system`预览，设计组件集中在lib/design_system，预览UI位于lib/features/design_gallery，无网络/数据/音频副作用。

Phase2B增量：Android Shell使用原生YYMobileBottomNavigation/YYTabletNavigationRail；它们接收受控选中项和回调，不导入go_router或持有Controller。Shell将index映射到既有AppRoute。YYSlider只发出预览/提交/取消事件，不访问播放层；Gallery拥有本页示例数值。YYArtworkPlaceholder只原生绘制经过审计的CSS几何，不加载媒体或伪造专辑。Windows保留原ShellNavigation。

Phase2C增量：YYToggle/YYSegmentedControl共用内部YYControlAction的触控、键盘和语义，不自行持久化；选中值来自调用方。YYSearchField使用调用方TextEditingController，选择/IME/剪贴板动作由Flutter编辑层处理，不创建搜索Repository；自有FocusNode随组件释放，外部Controller/FocusNode不释放。Gallery持有示例query/filter并通过原根Controller更新外观，ScrollNotificationObserver协调选择浮层与滚动。

Phase2D增量：YYAlbumCard与YYTrackTile复用Theme、Typography、Artwork、Button及内部动作层，只接收受控选中/播放/加载状态与回调。Track主动作和更多动作各自拥有语义与焦点边界，不导入播放器或菜单实现；Gallery只更新本页Fixture标签。手机隐藏时长并限制来源标签宽度，Tablet/桌面保留时长。

Phase2E增量：Windows Shell使用受控`YYWindowsSidebar`驱动四条现有路由，按1440/1024断点采用240/72dp形态；`YYWindowToolbar`保持42dp结构。正式Shell在窗口Gateway接入前隐藏应用内窗口按钮，由系统原生边框提供真实能力。Windows与Android共享`/design-system`路由，Windows额外展示明确标注的Toolbar/Sidebar Fixture。`YYGlassPanel`只服务父约束面板，既有Android `YYGlassSurface`的1dp高光占位和几何不变。

Phase2F增量：`YYMiniPlayer`和`YYDesktopPlayerBar`接收只读`YYNowPlayingViewData`与独立回调，复用最终SVG、Theme、Glass、Slider和Artwork；它们不读取播放/队列Controller，也不推进时间或执行循环算法。Android/Windows Gallery各自持有明确标注的本页Fixture。正式Shell的播放槽位继续保持“未接入”，等待Phase4播放真相和Phase5平台集成后由Feature/Presenter映射，不能把Fixture接入生产路由。

Phase2G增量：`YYContextMenu`、`YYDialog`、`YYBottomSheet`与`YYToast`只实现受控视觉、动作、焦点和Semantics。菜单的定位/显隐/右键/长按、Dialog/Sheet的Overlay或Route插入、Toast队列/时长仍由后续Feature编排。Dialog/Sheet使用不透明Surface，只有有界Context Menu使用Glass；Gallery以内联Fixture分别展示Windows Dialog与Android Sheet，不进入正式业务路由。

Phase2H增量：`YYThemeSwatch`、`YYEmptyState`、`YYErrorBanner`与`YYSkeleton`只渲染调用方提供的受控状态。Swatch接入既有会话级Appearance Controller，但不持久化；Error action只通知调用方；Skeleton为静止纯色且不启动任务。Gallery Fixture只改变局部说明文字，不创建网络、Repository、计时器或假数据。

Phase2I增量：`YYSourceCard`与`YYPlaylistCard`只渲染调用方提供的来源/歌单文字、状态和选择。Source状态色调与标签不由组件推断；Playlist的collection/create变体只发出动作。两者不导入Domain、Repository、网络、数据库、凭据、队列或持久化；Android/Windows Gallery只更新本页Fixture状态。

Phase2J增量：`YYQueueTile`、`YYLyricsLine`与`YYLyricsPlayerDock`只渲染调用方提供的队列、歌词和播放展示状态。队列主动作与上移/下移/移除、歌词行激活、Dock Transport/进度/收藏/返回均为独立受控动作；组件不读取现有播放/队列Controller，不Seek、不推进时间、不自动滚动、不排序或持久化。Android/Windows Gallery仍只更新本页Fixture。

Phase3A增量：新增平台/UI无关的Track/TrackRef、Album/Artist、Playlist/Queue/Favorite/History、Lyrics、MusicSourceConfig、显式LoadState与脱敏DomainFailure。Library/Collection/Lyrics/MusicSource Repository和SecureCredentialGateway只暴露项目自有类型；测试Fake可替换。当前没有数据库、HTTP、安全存储实现或生产Fixture，PlaybackState/Controller仍保持Phase4前骨架。

Phase3B增量：`data/database`使用Drift定义17张表、10个显式索引、schemaVersion1创建Migration、迁移审计与空队列状态。`database_connection.dart`是唯一`dart:io`/path_provider/NativeDatabase边界，显式调用时在Android/Windows应用支持目录后台打开；AppBootstrap不调用。Domain/UI不导入Drift row或executor，正式Repository映射留后续批次。

Phase3C增量：`data/repositories`新增Track/Album/Artist严格mapper与`DriftLibraryRepository`。该实现使用事务/batch更新catalog，提供确定分页、关联感知watch、TrackRef查询和availability更新；损坏row/SQL错误不泄露原始内容。AppBootstrap和DependencyGraph仍不打开/构造数据库实现。

Phase3D增量：`data/repositories`新增Collection严格mapper与`DriftCollectionRepository`。该实现保护系统歌单身份，用单事务替换歌单entries和可重复TrackRef队列，提供确定收藏/历史流和20条去重历史。用户集合不外键到catalog，来源删除不会抹除引用。AppBootstrap和DependencyGraph仍不打开/构造数据库实现。

Phase3E增量：`data/repositories`新增Lyrics严格JSON mapper与`DriftLyricsRepository`。该实现按完整TrackRef upsert/get/remove既有`lyrics_cache`，plain/synchronized逐行时间、双语文字、语言和偏移量返回前重走Domain验证；损坏JSON/row/SQLite错误只返回脱敏失败。它不解析LRC、不联网、不要求catalog row；AppBootstrap和DependencyGraph仍不打开/构造数据库实现。

Phase3F增量：`data/repositories`新增MusicSource严格JSON mapper与`DriftMusicSourceRepository`。该实现只持久化公开配置和credentialRef，按sourceId确定排序/watch，保护已存sourceType/builtIn身份及内置来源删除；自定义来源删除不级联用户TrackRef。它不导入SensitiveCredential、网络或安全存储；AppBootstrap和DependencyGraph仍不打开/构造数据库实现。

Phase3G增量：`platform/secure_credentials`新增共用版本codec/串行store核心、flutter_secure_storage适配器及`AndroidSecureCredentialGateway`/`WindowsSecureCredentialGateway`。该实现只向调用者暴露`SensitiveCredential`和不透明随机引用，插件异常统一脱敏；凭据值不进Drift、preferences、日志或UI。Android禁止应用备份，Windows使用新存储路径。AppBootstrap/DependencyGraph仍不构造生产Gateway，等待Dev Fixture与凭据/来源事务策略。

Phase3H增量：`AppDataServices`现在拥有单一数据库、四类正式Drift Repository和按Android/Windows选择的平台安全Gateway；`AppBootstrap`通过工厂异步建立并把项目合同注入根Graph，固定加载/失败文字且在失败、卸载和晚到完成时释放资源。默认`main.dart`只打开空白生产库，不写示例数据。独立`main_dev.dart`才使用内存数据库和禁用的`.invalid`来源，经正式Repository种入HTML审计Fixture；默认入口、UI和Shell均不能导入夹具或数据库实现。

Phase4A增量：`PlayableSource`把Windows绝对路径、Android content URI和HTTPS临时流封装在全量脱敏边界；`AudioEngineState`只表达后端音频事实，完整`PlaybackState`由根级`PlaybackController`合成。Controller串行处理解析/load/transport/Seek/音量/速率、队列持久化、随机遍历、三种循环与自然完成；`QueueController`仅委托命令并读取同一状态，不存第二份队列。`MediaSessionGateway`统一Android MediaSession与Windows SMTC回调/更新合同，真实平台实现与音频后端仍待后续POC。

这份文件描述已经存在的工程骨架，不把 Phase 0 的未来目录全部冒充实现。正式代码位于根 lib；旧原型和 Web 参考隔离在 archive/design_reference。

| 边界 | 已有责任 | 尚未实现 |
| --- | --- | --- |
| app/AppBootstrap | 异步建立Android/Windows生产数据作用域并恢复持久队列；根ProviderScope拥有单一DependencyGraph；固定、脱敏的加载/失败状态 | 权限、真实来源连接与播放自动恢复策略 |
| app/DependencyGraph | 创建、初始化并释放唯一PlaybackController、委托QueueController、AudioEngine、MediaSession、ViewState和AppDataServices | Phase4真实音频/媒体会话适配器及后续业务Controller |
| app/AppRouter | 私有 go_router，四个状态保留分支，根级 /player、/lyrics及跨平台/design-system；暴露自有 AppNavigation | 业务详情、菜单层级和平台全屏返回协调 |
| app/AdaptiveRoot | 实时 LayoutBuilder + 平台优先分类，选择三个 Shell；零尺寸时不动根依赖 | 生产级窗口约束/布局细化 |
| shells | Android原生Phone/Tablet导航、Windows 240/72受控导航与42工具区、三端未接入播放槽位；不直接网络/DB/音频 | Windows平台窗口Gateway、Inspector业务、正式播放器接线 |
| design_system | Theme/Token/原始SVG/按钮/Surface/Profile、Android与Windows导航、Tooltip/Toolbar、Slider/Artwork、SearchField/SegmentedControl/Toggle、AlbumCard/TrackTile、MiniPlayer/DesktopPlayerBar、ContextMenu/Dialog/BottomSheet/Toast、ThemeSwatch/EmptyState/ErrorBanner/Skeleton、SourceCard/PlaylistCard、QueueTile/LyricsLine/LyricsPlayerDock | 业务弹层编排与页面级组合 |
| playback | 脱敏PlayableSource/Resolver、独立EngineState、完整PlaybackState；唯一Controller串行播放命令、持久队列/随机/循环/自动下一首及错误映射；QueueController只委托 | 真实双平台AudioEngine、实际流/Seek POC、历史与正式UI接线 |
| domain / platform | 稳定TrackRef/QueueEntry、四Repository合同、LoadState/错误分类、Android/Windows SecureCredentialGateway实现，以及MediaSession/Fullscreen项目合同 | 真机安全存储、Android MediaSession、Windows SMTC与其余平台实现 |
| data/database | 17张Drift表、v1创建Migration/快照、外键/约束/索引及后台双平台打开；Library/Collection/Lyrics/Source严格映射与正式Repository，仅保存credentialRef；生产组合已接根启动 | Controller、真实来源Adapter、v2+保数据迁移 |
| shared/FoundationButton | 仍用于工程骨架内容中的临时路由验证；44px命中区、Semantics/键盘激活 | 后续业务页以对应YY组件逐步替换 |

Riverpod 只用于 app 注入边界，业务 Controller 不依赖它；go_router 也只出现在 app 层。WidgetsApp.router 没有 Material Scaffold/默认 Material 3 可见控件；go_router 的传递依赖含 material_ui/cupertino_ui，不表示正式 UI 使用其默认外观。

## 状态与路由

主路由 `/home`、`/search`、`/library`、`/settings` 通过 StatefulShellRoute 保留各分支状态。单一 FoundationScreen 是可复用路由外壳，不是已实现四页业务；`/player`、`/lyrics` 也仅有路由验证内容。

player → lyrics → back 返回 player；主页面 → lyrics → back 返回原页；直接进入独立路由后返回落到 home。主页面根位置 Esc 不改变当前导航。当前 Esc/Alt+Left 只处理路由；未实现的 OS 全屏不伪装为成功。

AppViewState 保存会话内选中项和每路由滚动偏移，Shell 重建不清空。宽度变大使文本重排时，偏移只裁剪到新滚动范围；不是强行保留已越界的像素位置。它不是持久化仓储，重启恢复属于 Phase 3。

DependencyGraph 在 ProviderScope 销毁时释放一次；Shell 切换不创建/释放引擎。AppBootstrap只恢复队列，不自动解析、加载或播放。真实音频暂不存在，默认 UnavailableAudioEngine 的全部命令明确失败，不发布假 playing 状态；测试 FakeAudioEngine/Resolver/MediaSession 仅存在 test/support。

## 当前限制

Windows 保留系统原生窗口边框/控制；应用内42dp工具区在正式Shell不显示伪窗口按钮，Gallery按钮只更新明确标注的Fixture状态。Android没有播放Service/媒体权限；Debug网络权限为Flutter调试模板。正式全屏/后台/导入/安全存储按后续阶段实现。平台runner默认启动图标暂未替换，发行资源在设计系统/发布阶段审核。
