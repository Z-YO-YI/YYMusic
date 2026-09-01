# YYMusic 当前实际架构

Phase2A增量：根DependencyGraph现在还拥有并释放唯一YYAppearanceController；YYMusicApp按系统亮度/动态偏好解析YYTheme，原路由/业务控制器不重建。Android增加独立`/design-system`预览，设计组件集中在lib/design_system，预览UI位于lib/features/design_gallery，无网络/数据/音频副作用。

Phase2B增量：Android Shell使用原生YYMobileBottomNavigation/YYTabletNavigationRail；它们接收受控选中项和回调，不导入go_router或持有Controller。Shell将index映射到既有AppRoute。YYSlider只发出预览/提交/取消事件，不访问播放层；Gallery拥有本页示例数值。YYArtworkPlaceholder只原生绘制经过审计的CSS几何，不加载媒体或伪造专辑。Windows保留原ShellNavigation。

Phase2C增量：YYToggle/YYSegmentedControl共用内部YYControlAction的触控、键盘和语义，不自行持久化；选中值来自调用方。YYSearchField使用调用方TextEditingController，选择/IME/剪贴板动作由Flutter编辑层处理，不创建搜索Repository；自有FocusNode随组件释放，外部Controller/FocusNode不释放。Gallery持有示例query/filter并通过原根Controller更新外观，ScrollNotificationObserver协调选择浮层与滚动。

Phase2D增量：YYAlbumCard与YYTrackTile复用Theme、Typography、Artwork、Button及内部动作层，只接收受控选中/播放/加载状态与回调。Track主动作和更多动作各自拥有语义与焦点边界，不导入播放器或菜单实现；Gallery只更新本页Fixture标签。手机隐藏时长并限制来源标签宽度，Tablet/桌面保留时长。

Phase2E增量：Windows Shell使用受控`YYWindowsSidebar`驱动四条现有路由，按1440/1024断点采用240/72dp形态；`YYWindowToolbar`保持42dp结构。正式Shell在窗口Gateway接入前隐藏应用内窗口按钮，由系统原生边框提供真实能力。Windows与Android共享`/design-system`路由，Windows额外展示明确标注的Toolbar/Sidebar Fixture。`YYGlassPanel`只服务父约束面板，既有Android `YYGlassSurface`的1dp高光占位和几何不变。

这份文件描述已经存在的工程骨架，不把 Phase 0 的未来目录全部冒充实现。正式代码位于根 lib；旧原型和 Web 参考隔离在 archive/design_reference。

| 边界 | 已有责任 | 尚未实现 |
| --- | --- | --- |
| app/AppBootstrap | 根 ProviderScope，拥有单一 DependencyGraph | 数据库/权限/真实来源初始化 |
| app/DependencyGraph | 创建并释放 PlaybackController、QueueController、ViewState；可注入 AudioEngine/Repository/Gateway | Phase 3 模型和正式仓储、Phase 4 音频 |
| app/AppRouter | 私有 go_router，四个状态保留分支，根级 /player、/lyrics及跨平台/design-system；暴露自有 AppNavigation | 业务详情、菜单层级和平台全屏返回协调 |
| app/AdaptiveRoot | 实时 LayoutBuilder + 平台优先分类，选择三个 Shell；零尺寸时不动根依赖 | 生产级窗口约束/布局细化 |
| shells | Android原生Phone/Tablet导航、Windows 240/72受控导航与42工具区、三端未接入播放槽位；不直接网络/DB/音频 | Windows平台窗口Gateway、Inspector业务、MiniPlayer |
| design_system | Theme/Token/原始SVG/按钮/Surface/Profile、Android与Windows导航、Tooltip/Toolbar、Slider/Artwork、SearchField/SegmentedControl/Toggle、AlbumCard/TrackTile | 更多表单、通用菜单/弹层、MiniPlayer等 |
| playback | 唯一事件订阅、播放状态传播、错误/销毁边界；默认后端明确 unavailable | 加载曲目、Seek、队列算法、系统媒体会话 |
| domain / platform | LibraryRepository、FullscreenGateway 生命周期合同 | 具体实现和平台能力 |
| shared/FoundationButton | 仍用于工程骨架内容中的临时路由验证；44px命中区、Semantics/键盘激活 | 后续业务页以对应YY组件逐步替换 |

Riverpod 只用于 app 注入边界，业务 Controller 不依赖它；go_router 也只出现在 app 层。WidgetsApp.router 没有 Material Scaffold/默认 Material 3 可见控件；go_router 的传递依赖含 material_ui/cupertino_ui，不表示正式 UI 使用其默认外观。

## 状态与路由

主路由 `/home`、`/search`、`/library`、`/settings` 通过 StatefulShellRoute 保留各分支状态。单一 FoundationScreen 是可复用路由外壳，不是已实现四页业务；`/player`、`/lyrics` 也仅有路由验证内容。

player → lyrics → back 返回 player；主页面 → lyrics → back 返回原页；直接进入独立路由后返回落到 home。主页面根位置 Esc 不改变当前导航。当前 Esc/Alt+Left 只处理路由；未实现的 OS 全屏不伪装为成功。

AppViewState 保存会话内选中项和每路由滚动偏移，Shell 重建不清空。宽度变大使文本重排时，偏移只裁剪到新滚动范围；不是强行保留已越界的像素位置。它不是持久化仓储，重启恢复属于 Phase 3。

DependencyGraph 在 ProviderScope 销毁时释放一次；Shell 切换不创建/释放引擎。真实音频暂不存在，默认 UnavailableAudioEngine.play/pause 明确失败，不发布假 playing 状态。测试 FakeAudioEngine 仅存在 test/support。

## 当前限制

Windows 保留系统原生窗口边框/控制；应用内42dp工具区在正式Shell不显示伪窗口按钮，Gallery按钮只更新明确标注的Fixture状态。Android没有播放Service/媒体权限；Debug网络权限为Flutter调试模板。正式全屏/后台/导入/安全存储按后续阶段实现。平台runner默认启动图标暂未替换，发行资源在设计系统/发布阶段审核。
