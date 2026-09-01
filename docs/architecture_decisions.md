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
