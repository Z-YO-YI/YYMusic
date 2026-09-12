# YYMusic

当前增量：**Phase 7G1 底栏队列导航**。Windows／平板现有队列按钮打开原生`/queue`，空库也可查看空态；返回不重复压栈，过期回调和遮罩不能触发导航，根队列与音频不变。1691 Flutter、140 Node、188 Golden、严格分析与Android Debug预检通过，见[报告](docs/phase_7g1_shell_queue_report.md)。沿用本地Figma导出与原生组件，65张基线仅更新队列图标启用态。全屏/Inspector剩余接线和Phase8–11仍未完成，非正式上线。以下为历史增量。

当前增量：**Phase 7F3 内联遮罩收藏保护**。修复系统歌单菜单/历史确认框打开后，旧底栏收藏回调仍能保存的问题；关闭遮罩后旧回调保持失效，新按钮可用。1679 Flutter、139 Node、188旧Golden、严格分析与Android预检通过，见[报告](docs/phase_7f3_overlay_guard_report.md)。下一步继续Shell导航入口和Phase7整体验收，尚未正式上线。以下为历史增量。

当前增量：**Phase 7F2C 底栏收藏**。Windows/平板宽底栏接唯一根收藏，支持独立保存忙态、未知状态、安全重试与跨主导航旧回调撤销；手机/窄栏保持原无心形布局。1671 Flutter、138 Node、188 Golden、严格分析与Android Debug预检通过，见[报告](docs/phase_7f2c_shell_favorite_report.md)。下一步审查Shell剩余导航入口和Phase7出口，真实导入、后台媒体与发行仍未完成。以下为历史记录。

当前增量：**Phase 7F2B 独立播放页收藏**。手机/平板/Windows原生播放页已接同一根收藏，支持独立busy、安全重试、切页撤销及与歌词页共享真值。1654 Flutter、137 Node、185 Golden、严格分析及Android Debug预检通过，详见[报告](docs/phase_7f2b_player_favorite_report.md)。底栏收藏接线和Phase7整体出口继续推进，真实导入、后台与发行仍未完成。以下为历史增量。

当前增量：**Phase 7F2A 歌词页收藏**。平板/Windows歌词Dock已接同一根收藏状态与持久化，含独立忙态、安全读写失败及显式重试；手机按原设计隐藏Dock心形，无存储预览不模拟收藏。1636 Flutter、136 Node、181 Golden、严格分析和Android Debug预检通过，见[报告](docs/phase_7f2a_lyrics_favorite_report.md)。下一步接播放页/Shell收藏；真实导入与Phase8–11仍未完成，尚非日常可用发行版。以下增量为历史记录。

当前增量：**Phase 7F1 当前曲目收藏核心**。新增共用根收藏投影与真实Repository写入，按当前队列/完整来源身份授权，支持安全失败、显式重试和关闭排空；空库不发起多余查询，位置更新不重读，不乐观伪造收藏。最终1621 Flutter、135 Node、178旧Golden、严格分析和Android Debug预检通过，见[计划](docs/phase_7f1_current_favorite_plan.md)与[报告](docs/phase_7f1_current_favorite_report.md)。本批不改UI，三端收藏按钮下一批接线；前置#79双平台云端成功，本批新SHA另验。仍在Phase7，真实导入/扫描与Phase8–11未完成，新安装仍为空库。以下“当前增量”为历史记录。

当前增量：**Phase 7E5E 系统歌单队列菜单**。我喜欢/最近播放的Android手机、平板和Windows菜单支持下一首/添加队列；保留重复和失效引用，不改收藏/历史或中断播放，清除历史仍单独确认。最终1590 Flutter、133 Node、178 Golden和严格分析通过，Android Debug预检成功。见[总进度与本批报告](docs/phase_7e5e_system_queue_report.md)及[计划](docs/phase_7e5e_system_queue_plan.md)。前置#78双平台云端成功，本批新提交独立验收；仍在Phase7，Phase8真实导入/扫描是日常可用的关键缺口，Phase9–11尚待完成，新安装仍为空库。以下“当前增量”均是历史记录。

当前增量：**Phase 7E5D 自建歌单队列菜单**。三端自建歌单条目支持下一首/添加队列，准确识别重复、失效和未解析引用，不改变原歌单或中断当前播放；旧窗口/菜单/路由回调失效，修复卸载后旧关闭回调。1544 Flutter、132 Node、173 Golden与严格分析通过，见[计划](docs/phase_7e5d_playlist_queue_plan.md)和[报告](docs/phase_7e5d_playlist_queue_report.md)。前置#77两组双平台云端通过，本批新SHA另验。系统歌单入口及Phase7其余、Phase8–11继续开发，新安装仍为空库。

当前增量：**Phase 7E5C 专辑/艺人队列菜单**。两类详情的Android手机/平板和Windows菜单已可下一首/添加队列，复用原始图标、唯一队列和E5B反馈；旧菜单在刷新/路由/尺寸/Tab变化后失效，旋转后的新菜单仍可用。1510 Flutter、131 Node、169 Golden与严格分析通过，见[计划](docs/phase_7e5c_catalog_queue_plan.md)和[报告](docs/phase_7e5c_catalog_queue_report.md)。前置#76双平台云端已通过，本批新提交独立验证；其他歌单入口与Phase8–11继续开发，新安装仍为空库。

当前增量：**Phase 7E5B 音乐库队列菜单**。Android手机/平板长按或更多菜单、Windows右键/键盘已可“下一首播放”“添加到队列”；支持成功提示、忙态、失败跨页重试/知悉与查看队列，添加不会中断播放。沿用审计后的Figma菜单和原始next/list-plus图标。1476 Flutter、130 Node、166 Golden与严格分析通过，见[计划](docs/phase_7e5b_library_queue_plan.md)和[报告](docs/phase_7e5b_library_queue_report.md)。本批覆盖音乐库歌曲入口，其他详情/歌单入口继续接入；真实导入/扫描及Phase8–11未完成，新安装仍为空库。以下“当前增量”是历史记录。

当前增量：**Phase 7E5A 添加/下一首根编辑**。末尾添加与下一首已具备快照权限、忙态、失败重试及关闭排空；修复随机模式的下一首优先序，后续末尾添加不打乱已指定的下一首，操作本身不启动或重载音频。1445 Flutter、129 Node、严格分析及原161张Golden通过，见[计划](docs/phase_7e5a_queue_insert_plan.md)与[报告](docs/phase_7e5a_queue_insert_report.md)。本批是核心能力，新增菜单入口将在E5B接线；Phase8导入/扫描和后续发行未完成，新安装仍为空库。以下“当前增量”均为历史记录。

当前增量：**Phase 7E4 原生队列拖拽排序**。Android 手机/平板长按条目，Windows 使用原始拖动手柄；支持边缘滚动，保留上下移与连续键盘操作。重复歌曲按队列条目独立排序，当前播放不中断，刷新/离页/尺寸变化撤销旧拖放。完整 1413 Flutter、128 Node、161 Golden 与严格分析通过，见[计划](docs/phase_7e4_queue_drag_plan.md)与[报告](docs/phase_7e4_queue_drag_report.md)。真实导入/扫描尚属 Phase 8，Phase 7 添加/下一首等剩余入口及 Phase 8–11 仍需开发；新安装仍为空库，不是日常可用发行版。以下“当前增量”均为历史记录。

当前增量：**Phase 7E3 独立原生队列页面**。音乐库、播放器及歌词的队列入口现在打开 `/queue`，复用唯一根队列，支持准确播放重复条目、上下移动、缺失项移除、当前项/清空确认、安全失败和显式重试。Android 手机/平板与 Windows 分别适配，使用既有 Figma 审计组件与原始图标。完整 1386 Flutter（新增 12 Golden）、127 Node 和严格分析通过，见[计划](docs/phase_7e3_native_queue_plan.md)与[报告](docs/phase_7e3_native_queue_report.md)。拖拽、更多添加入口及 Phase 7 剩余能力继续分批开发；新安装仍为空库，尚非日常可用发行版。以下“当前增量”为历史记录。

当前增量：**Phase 7E2 根队列编辑反馈**。在同一QueueController加入共享busy、每次提交结果、跨页面保留的安全失败、同快照显式重试和按失败身份知悉；其他成功操作不抹旧失败，旧确认不改新队列，关闭先等待反馈排空。1350项Flutter（146旧Golden未改）、126项Node、严格分析和Android Debug预检通过，见[计划](docs/phase_7e2_queue_edit_feedback_plan.md)与[报告](docs/phase_7e2_queue_edit_feedback_report.md)。本批是独立队列UI所需状态接口，尚未新增管理页面；前置E1两组GitHub Android/Windows已SUCCESS，[精确回填](docs/phase_7e1_queue_edit_intents_report.md)。以下“当前增量”均为历史记录。

当前增量：**Phase 7E1 队列编辑核心**。新增绑定根快照的移除、清空和锚点排序；旧菜单/拖拽意图不能修改新队列，重复歌曲按独立条目处理，编辑共用既有串行持久化与关闭屏障。非当前项保存失败不冒充播放失败，停止后的失败不会擅自重播。详见[计划](docs/phase_7e1_queue_edit_intents_plan.md)及[报告](docs/phase_7e1_queue_edit_intents_report.md)。这是核心API，尚未新增独立队列管理UI；后续接编辑反馈及页面。前置全屏页面dff7c32的两组GitHub Android/Windows已SUCCESS，[精确回填](docs/phase_7d2_fullscreen_pages_report.md)。以下“当前增量”是历史记录。

当前增量：**Phase 7D2 原生全屏页面与生命周期**。播放/歌词页已接入原始全屏图标；Windows支持F、Esc先退出全屏再返回，Android进入页面自动请求沉浸。路由覆盖、后台、零尺寸和关闭会撤销旧请求并恢复，切换全屏不重建播放器。1287项Flutter（146张Golden）、124项Node、严格分析及Android Debug包预检通过，详见[计划](docs/phase_7d2_fullscreen_pages_plan.md)与[报告](docs/phase_7d2_fullscreen_pages_report.md)。前置D1最大化恢复失败已在独立[PR #69](https://github.com/Z-YO-YI/YYMusic/pull/69)修复，精确提交e68fffa的两组Android/Windows均SUCCESS；本批页面的新提交云端验证另见对应Draft PR，不借用前置结果。Android真机系统栏和Windows多显示器/DPI仍待验收，尚非完整Phase7或日常可用发行版。下方各“当前增量”均为历史记录。

当前增量：**Phase 7D1 原生全屏通道与恢复保护**。Windows 保存/恢复进入前的窗口位置、最大化和边框状态；Android 保存/恢复系统栏状态，并在失焦/后台/解绑时恢复。通道命令串行处理，关闭撤销未开始的操作并等待已接受操作完成。最终1245项Flutter（138张旧Golden不变）、123项Node、严格分析和Android Debug包预检通过，详见[计划](docs/phase_7d1_fullscreen_gateways_plan.md)与[报告](docs/phase_7d1_fullscreen_gateways_report.md)。本批仅完成平台能力，**尚未接入正式页面的全屏按钮、F或自动沉浸**；新Windows原生用例按本批GitHub提交单独验收。前置7C2两组Android/Windows已SUCCESS，[精确回填](docs/phase_7c2_native_lyrics_report.md)。以下“当前增量”是历史记录。

当前增量：**Phase 7C2 原生独立歌词页**。正式 `/lyrics` 已接入手机、平板、Windows 三套布局，共用根歌词同步器和播放器；支持双语切换、同步行跳转、纯文本、读取/无歌词/空库/错误重试、真实播放 Dock 和独立返回。设计转代码流程复用了审计后的原始图标、字体和组件，不使用 WebView。详见[计划](docs/phase_7c2_native_lyrics_plan.md)与[验收报告](docs/phase_7c2_native_lyrics_report.md)。本批不是整个 Phase 7 完成；系统全屏/沉浸、独立队列管理、真实导入/扫描、后台媒体与发行仍待后续。以下各“当前增量”保留其历史阶段含义。

当前增量：**Phase 7C1 原生歌词正文与跟随视口**。新增双语大字号正文、当前行精确居中、手动浏览后五秒恢复、原生焦点和过期回调保护；一万行按需构建，不新增媒体时钟。同步修复歌词的减少动态与只读语义。最终1188项Flutter（127张Golden）、119项Node、严格分析和Android Debug预检通过，详见[本批报告](docs/phase_7c1_lyrics_viewport_report.md)与[计划](docs/phase_7c1_lyrics_viewport_plan.md)。这是待接入的正文组件，正式 `/lyrics`、顶部/Dock、翻译入口与平台沉浸仍需后续增量。前置 7B1 两组 GitHub Android/Windows 均 SUCCESS，[精确回填](docs/phase_7b1_native_player_report.md)。

当前增量：**Phase 7B1 原生独立播放页**。底栏曲目信息可打开 `/player`，Phone / Tablet / Windows 三套布局共用根播放器，接入真实播放、切歌、随机/循环、进度与音量；当前队列按钮复用已有队列浏览。1160 项 Flutter（含 120 张 Golden）、118 项 Node、严格分析及本地 Android Debug 预检通过。详见[本批报告](docs/phase_7b1_native_player_report.md)与[计划](docs/phase_7b1_native_player_plan.md)。前置 7A 两组 GitHub Android/Windows 均已 SUCCESS，[验收回填](docs/phase_7a_lyrics_synchronization_report.md)。本批精确云端状态见对应 Draft PR，不以前置构建代替。

当前增量：**Phase 7A 共享歌词同步核心**。新增真实仓储读取、偏移时间轴、根播放位置同步、快照授权 Seek 与关闭排空；三端共用一个状态，未接入原生歌词页面。1127 项 Flutter、117 项 Node、112 张旧 Golden、严格分析和本地 Android Debug 预检通过，精确 GitHub 构建状态见对应 Draft PR。详见[本批报告](docs/phase_7a_lyrics_synchronization_report.md)与[计划](docs/phase_7a_lyrics_synchronization_plan.md)。前置 J2 两组 Android/Windows 已 SUCCESS，[验收回填](docs/phase_6j2_native_settings_report.md)。下方保留各历史阶段记录。

当前增量：**Phase 6J2 原生外观与关于设置**。正式“设置”已替换工程占位页，提供三套原生布局，共用根外观与本机保存。包含浅色/深色/系统、五预设/自定义 Hex、玻璃/减少动态、保存进度与失败重试，以及关于/开源许可。详见[本批报告](docs/phase_6j2_native_settings_report.md)和[计划](docs/phase_6j2_native_settings_plan.md)。前置 J1 `993aab2` 的 GitHub Android/Windows 两组构建均已成功，[验收回填](docs/phase_6j1_appearance_persistence_report.md)。以下是前置阶段记录，不代表新功能已全部上线。

当前增量：**Phase 6I2 本地音乐原生概览**。音乐库→本地已接入真实统计、20条目录分页、配置状态和历史扫描日期，手机、平板、Windows采用独立布局并共用根状态。隐藏/覆盖取消读取，旋转保留分页，错误可重试；不展示私有路径或冒充当前授权。最终1029项Flutter（104张Golden）、113项Node、严格分析和Android本地Debug预检通过。详见[本批报告](docs/phase_6i2_local_music_surfaces_report.md)、[计划](docs/phase_6i2_local_music_surfaces_plan.md)及对应Draft PR；本批精确云端结果另行核对。前置I1 `79540d0` 的push/PR双平台均已成功，见[I1回填](docs/phase_6i1_local_library_overview_report.md)。下一步按Phase6推进Settings；下方旧阶段记录保留历史归属。

当前阶段：**Android + Windows · Phase 6H14 系统歌单管理**。喜欢列表已支持更多/长按/右键菜单取消喜欢，包括失效和未解析歌曲；最近页已加入原生确认清除。操作共用根写入器，离页不丢失写入失败，关闭等待完成；不删除音乐文件或改动队列。984项Flutter（98张Golden）、108项Node通过，严格分析零问题。精确GitHub双平台状态见[本批报告](docs/phase_6h14_system_playlist_management_report.md)/对应Draft PR；前置Phase6H13 `891a9f1` 两组源码/Android/Windows已成功。Local Music/Settings、真实导入、完整播放器与发行仍待开发，默认新安装为空库。

距离“新安装后可日常听本地音乐”主要还有三组工作：Phase7完整播放器/歌词/队列；Phase8双平台真实导入、扫描与授权；Phase10—11后台/系统媒体控制、Release打包与设备验收。完整产品还需要Phase9第三方来源；设置中的相应分类随真实能力接入。现有Debug构建不等于可用发行版：默认空库没有导入入口，Windows开发Debug包还依赖Debug CRT；不以测试数量或阶段编号换算虚假完成百分比。

Phase6E 后续修正：初始云端 Android/源码成功，Windows 旧首页 Golden 因测试样本逐首读取时钟而排序不稳定。
已固定样本批次时间；425 Flutter/71 Node 与本地 Android 通过，55 张基线和生产代码均未改。
修复后的云端双平台结果以 [PR #40](https://github.com/Z-YO-YI/YYMusic/pull/40) 为准。

Phase4C新增确定性PCM16 WAV生成器、2项单元测试，以及默认关闭、只允许手动选择、`contents: read`且不上传产物的Windows/Android原生集成模式。完整221项Flutter含32张Windows宿主Golden、严格分析0问题、31项Node、24项ZIP、lockfile及生成代码/v1快照零差异已通过；本机Android Debug也完成资产与v2单Debug签名复核。精确提交`622408e`的专用运行33862786766 attempt 2已在Windows与Android成功，且没有artifact或Release；普通push另提供保留14天的Windows开发Debug文件包。它依赖本机Debug CRT，并非通用免安装发行包；Phase4J的Profile诊断模式与正式应用分开。

历史 Phase4D 实现提交 `913f3d75` 增加 HEAD-only 脱敏网络探针、Android Debug-only 只读 Provider 及受控 HTTPS 测试；标准 PR 33878401743 和原生运行 33878710671 均成功。该原生证据属于后来被移除的 media_kit 候选，不能替代当前 just_audio 的 HTTPS 验收。历史记录和定位不变，生产入口、TLS 默认值及 Release Manifest 未改变。

设计依据为 `design_reference/YYMusic_HTML.zip` 中完整的 `src/App.tsx` 和基础 HTML，不能只使用旧 HTML。App 的 `NEW_ICON_SPRITE`、两项账户文字替换、全部 `POLISH_CSS` 均已纳入合成。YYMusic 是产品名，YY Listener 是账户 Fixture。

## 原生独立播放页

点击手机迷你播放器或桌面底栏的曲目信息，进入独立播放页。播放/暂停、上一首/下一首、随机/循环及音量控制使用同一个根播放器；进度拖动只预览，松手才提交一次跳转，取消拖动不改变播放位置。缓冲中或时长未知时不能跳转。播放失败显示可重试的安全提示，不展示私有路径或原始异常。

“收起播放页”或系统返回会回到原页面，直接进入播放页则回首页；不会停止音频或重建队列。右上角队列按钮打开现有真实队列浏览，尚非独立队列管理页。手机纵向上下排布，短横屏紧凑双栏；平板横竖独立编排，Windows 即使窄窗口仍为桌面双栏。小尺寸和放大字体时可滚动查看全部控制。

切歌、覆盖页面、改变窗口尺寸或离页后，旧手势不能跳转新曲目。封面明确显示“暂无封面”兜底，暂停时轻微缩小；开启减少动态则不缩放。右上角歌词图标打开独立原生歌词页。真实封面读取与独立队列编辑仍待后续 Phase 7；不提供模拟入口。默认新安装为空库，Phase 8 导入/扫描尚未接入。

## 原生独立歌词页

播放页右上角歌词按钮、桌面底栏已启用的歌词图标可打开 `/lyrics`。有曲目时也可长按手机/窄窗底栏的曲目信息直接打开；普通点击仍进入播放页。Windows 按 L 打开歌词，输入框内不生效；Ctrl+L 仍打开音乐库。关闭按钮、Esc或系统返回回到来源页；Dock“返回播放界面”复用已有播放页，没有已有播放页时替换当前歌词页，反复切换不堆叠页面，也不重启音乐。

正文从真实歌词仓储读取，不生成演示歌词。同步行随根播放时间居中，手动浏览暂停跟随五秒，也可点击“回到当前歌词”；点击歌词按文档时间偏移跳转，纯文本仅阅读。有翻译时显示切换按钮。Dock 使用真实曲目信息、播放/切歌、进度和时间；拖动仅预览，释放提交一次，取消不跳转。隐藏、窗口零面积、切歌及布局变化使旧跳转意图失效。

尚无歌词、未选歌曲和读取失败有独立提示；重试歌词不停止音频，也不显示私有异常。当前为固定深色纯色兜底，不冒充封面提色；未接收藏及LRC导入，不以页面可打开宣称这些能力已完成。新安装仍需后续 Phase 8 的真实导入功能才能建立本地音乐库。

## 原生全屏与恢复

播放和歌词页顶部提供“进入全屏/退出全屏”按钮，只有原生能力握手成功才显示。Windows可按F切换；在非输入框、没有弹层的其他页面按F，会打开播放页并请求全屏。Esc在全屏中先恢复窗口，再按一次才返回；页面关闭按钮仍直接离页并恢复。全屏隐藏自绘标题栏，退出恢复原位置、边框及最大化状态；音乐、队列和歌词会话保持不变。

Android进入播放/歌词页会请求系统栏沉浸，系统手势仍可临时显示栏；系统返回离页并恢复。两种平台切后台、失焦、零尺寸、被队列或弹层覆盖时退出，回到前台不因恢复焦点自动重进，可点击按钮再次进入。播放与歌词直接切换可保持同一全屏会话。

全屏失败显示安全提示及可用时的“恢复系统显示”按钮，不停止音乐；操作忙时避免重复提交。Windows关闭先等待全屏清理，再释放音频/数据库并关闭原生窗口。Android实际系统栏行为和Windows多显示器/DPI尚待设备验收，截图测试不代表这些系统行为已通过。

## 原生设置与外观持久化

打开底部导航/侧栏“设置”（Windows 也可按 Ctrl+,）。外观修改即时生效并保存本机；自定义颜色输入六位 Hex，点击“应用颜色”或按 Enter 才应用，输入草稿不会自动入库。选择预设会放弃当前颜色草稿。关闭“Liquid Glass 导航”即减少玻璃效果；“减少动态效果”同时尊重系统偏好。

页面明确区分读取中、保存中、已保存和错误。读取失败不覆盖原设置，重试成功后才可编辑；保存失败保留当前视觉并可重试，播放不因此停止。Android 旋转/分屏、页面切换保留草稿与本次会话状态；退出应用只恢复已成功保存的偏好。仅持久化已实现的外观选项，不保存凭据或启用未实现的音频/授权能力。

“设置 → 关于 YYMusic → 开源许可”可查看实际打包组件许可。音乐源、本地扫描和高级播放分类将在相应能力阶段接入，目前不提供模拟开关。

## 本地音乐概览

在音乐库选择“本地”，可查看已入库本地歌曲数、保存的可用性、总时长和文件夹记录；目录每页20条，用“上一页目录/下一页目录”切换。“刷新概览”只刷新数据库读取，不会扫描文件或申请权限。文件夹的启用状态和上次扫描时间仅是保存记录，不代表当前可以读取；尚无导入/扫描/重授权入口，新安装显示真实零值和空态。读取失败显示重试；保留旧数据时会明确提示更新失败。

手机纵向排列统计，平板横屏统计与目录分栏、竖屏横排统计，Windows采用横排统计。旋转与分屏保留同一目录页；离开/覆盖页面会停止监听并丢弃晚到结果，回到页面重新读取。Windows可用Tab和Enter刷新，操作不改变播放或队列。

## 系统歌单浏览与播放

当前队列的新入口为独立 `/queue`；旧 `/system-playlist?type=queue` 链接保留只读兼容。队列按独立 entry ID 操作，缺失文件仍能排序/移除，不会删除原音乐文件。移除当前项或清空会先确认、停止播放，移除后不会自动播放相邻项。读取从 20 条扩展到每组最多 200 条，可浏览上一组/下一组；上下移动可跨组边界。Windows 操作在悬停/键盘焦点时出现，Android 手机和平板常显；Enter/Space 操作、Esc 先关闭确认再返回页面。失败后“重试队列操作”只作用于原快照，“知道了”仅清除当前失败提示。

音乐库→歌单中的“喜欢的音乐”“最近播放”“当前队列”读取实际本机数据，不创建可删除的系统父歌单。收藏按时间倒序，最近读取已有的最多20首记录，队列按真实顺序保留重复项。点击收藏/最近曲目复用或追加到当前队列；点击队列则播放该条目而非同曲第一项。失效和未解析引用仍显示但不能播放。更多歌曲逐步扩展至200条，再用上一组/下一组继续；返回、旋转和分屏保留会话，离页或最小化取消尚未开始的播放，已开始音频不受影响。Windows支持Tab、Enter/Space及Esc返回并恢复入口焦点。

真正开始的播放现在会自动写入历史：播放状态下观察到位置前进才记录，不以点击或加载成功代替。最近页保存失败不会停止音频，可重试最新失败记录；更早失败只能知悉或重新播放对应歌曲。首页的既有“清除历史”确认入口仍可使用，不删除歌曲或队列；清除前的待写记录不会在随后复活，清除后的新聆听仍可记录。为保证同毫秒和时钟回拨时仍置顶，历史排序时间必要时比已有最大值增加1毫秒。

在喜欢列表点击更多、长按或Windows右键打开菜单，可“取消喜欢”；不可用歌曲也能移除收藏引用。菜单用“已喜欢”和明确文字表示状态，不只依赖颜色。取消喜欢不删除歌曲、文件、历史、自定义歌单或队列。

最近页的“清除播放历史”会先显示确认面板，取消/Esc/返回不写入；确认只清除历史，正在播放的音乐不停止。手机使用底部面板，平板与Windows使用对话框。刷新、被其他页面覆盖或零尺寸会撤销旧确认；操作失败保留在共享根状态，返回系统页仍可查看并重新操作。写入前的旧菜单/确认不能操作新快照。

本批没有新增队列移除/排序菜单或系统歌单播放全部。新安装没有曲库导入入口，因此这里显示真实空态，不自动填入测试歌曲。

## 自定义歌单整体播放

打开歌单后，“播放全部”按原歌单顺序开始并关闭随机，“随机播放”打乱播放次序；二者都会**替换当前队列**，不是追加，也不只播放当前显示的一组。缺失或已标记不可用的条目被跳过并提示数量，重复歌曲保留为不同队列条目，原歌单不会修改。全部不可用时保留现有队列。读取/加载期间离开或最小化不会在稍后突然开始播放；已经开始的音频继续由根播放器管理。读取之后才发生的文件/来源失效仍可能进入安全错误态，尚未实现所有运行时错误的自动跳过。

## 开发入口

- [Phase 6H14 系统管理计划](docs/phase_6h14_system_playlist_management_plan.md)、[报告](docs/phase_6h14_system_playlist_management_report.md)：完整来源取消喜欢、原生确认清除、根写入/失败保留与关闭排空；新增33项测试及5张Golden，精确更新4张旧基线，其余89张不变。

- [Phase 6H13 播放历史计划](docs/phase_6h13_playback_history_plan.md)、[报告](docs/phase_6h13_playback_history_report.md)：时钟确认、完整来源去重、串行写入/清除、安全重试与根关闭排空；新增44项测试和两张Golden，旧91张不变。

- [Phase 6H12 系统歌单界面计划](docs/phase_6h12_system_playlist_surfaces_plan.md)、[报告](docs/phase_6h12_system_playlist_surfaces_report.md)：闭合枚举路由、三套原生布局、精确队列单项播放、离页取消和键盘焦点；新增七张/更新三张受影响Golden，其余81张未改。

- [Phase 6H11 系统歌单会话计划](docs/phase_6h11_system_playlist_sessions_plan.md)、[报告](docs/phase_6h11_system_playlist_sessions_report.md)：固定类型、同根只读会话、失效合并、完整窗口替换、旧回调/关闭排空；尚无新增系统页面。

- [Phase 6H10 系统歌单数据计划](docs/phase_6h10_system_playlist_data_plan.md)、[报告](docs/phase_6h10_system_playlist_data_report.md)：枚举选择的喜欢/最近/队列投影、计数/当前项一致性、限页后署名展开、失效通知、真实SQLite损坏与重开验证；UI接线另行开发。
- [Phase 6H9 歌单整体播放计划](docs/phase_6h9_playlist_playback_plan.md)、[报告](docs/phase_6h9_playlist_playback_report.md)：单SQL轻量完整播放计划、根串行队列替换与随机顺序、不可用引用过滤和Windows最小化保留页面。
- [Phase 6H8 分组浏览计划](docs/phase_6h8_playlist_windows_plan.md)、[报告](docs/phase_6h8_playlist_windows_report.md)：原生范围/前后组导航、单SQL有界快照、末组删除恢复、旧回调保护和根关闭排空，真实SQLite遍历1003条且不合并跨版本页。
- [Phase 6H7 新建并添加计划](docs/phase_6h7_create_and_add_plan.md)、[报告](docs/phase_6h7_create_and_add_report.md)：父歌单/首条引用同事务保存、碰撞不覆盖、真实SQLite故障回滚和根排空；三端复用原生名称表单与原始plus SVG，没有独立创建后再追加的半成品窗口。
- [Phase 6H6 歌单选择器计划](docs/phase_6h6_playlist_add_picker_plan.md)、[报告](docs/phase_6h6_playlist_add_picker_report.md)：歌曲菜单→已有歌单，原生筛选/返回/焦点、根原子追加、真实SQLite与查询/写入排空；复用App.tsx最终SVG及YY组件，无WebView，无音频复制或新依赖。
- [Phase 6H5 原生内容管理计划](docs/phase_6h5_playlist_content_surfaces_plan.md)、[报告](docs/phase_6h5_playlist_content_surfaces_report.md)：三端原生歌曲列表与条目菜单、稳定身份路由、共享播放/移除/移动、过期回调隔离和离页写入反馈；复用原始SVG与YY组件，无WebView。
- [Phase 6H4 内容会话计划](docs/phase_6h4_playlist_content_plan.md)、[报告](docs/phase_6h4_playlist_content_report.md)：单条SQL一致读取、条目身份/完整来源保留、窗口刷新/重试和实际查询排空；自定义歌单最多200条可见前缀，系统视图与原生管理入口后续接入。
- [Phase 6H3 条目命令计划](docs/phase_6h3_playlist_entry_commands_plan.md)、[报告](docs/phase_6h3_playlist_entry_commands_report.md)：原子追加/移除/锚点排序、完整软引用和事务回滚，复用根 busy/排空；不宣称歌曲管理界面已接线。
- [Phase 6H2 歌单界面计划](docs/phase_6h2_playlist_editor_plan.md)、[报告](docs/phase_6h2_playlist_editor_report.md)：三端创建/改名/确认删除，原生文本选择、草稿代次和关闭后失败反馈；条目管理仍待开发。
- [Phase 6H1 歌单命令计划](docs/phase_6h1_playlist_metadata_plan.md)、[报告](docs/phase_6h1_playlist_metadata_report.md)：原子创建/改名、系统歌单保护、根写入排空；界面已在H2增量接线。
- [Phase 6G4 详情菜单计划](docs/phase_6g4_catalog_detail_actions_plan.md)、[报告](docs/phase_6g4_catalog_detail_actions_report.md)：按需收藏投影、原生菜单、返回／焦点恢复和关闭期间写入／订阅排空。
- [Phase 6G3 搜索详情入口计划](docs/phase_6g3_search_detail_navigation_plan.md)、[报告](docs/phase_6g3_search_detail_navigation_report.md)：专辑/艺人完整引用跳转、搜索返回状态/焦点及取消安全，不改变既有搜索语义。
- [Phase 6G2 原生详情计划](docs/phase_6g2_catalog_detail_surfaces_plan.md)、[报告](docs/phase_6g2_catalog_detail_surfaces_report.md)：完整来源路由、三端布局、保留返回/滚动状态、取消安全播放和可重试的真实状态。
- [Phase 6G1 详情会话计划](docs/phase_6g1_catalog_detail_sessions_plan.md)、[报告](docs/phase_6g1_catalog_detail_sessions_report.md)：强类型摘要/分区、根注册与排空、真实SQLite回归和短页容量修复；不宣称详情页面已经接线。
- [Phase 6F 原生音乐库计划](docs/phase_6f_library_surfaces_plan.md)、[报告](docs/phase_6f_library_surfaces_report.md)：分类/排序/筛选、惰性目录列表、取消安全播放、实际收藏与曲目菜单；既有55张Golden未改。
- [Phase 6E 音乐库浏览计划](docs/phase_6e_catalog_browse_plan.md)、[报告](docs/phase_6e_catalog_browse_report.md)：只读单语句分页、排序/组合筛选、来源隔离详情及根数据合同；未改音乐库UI。
- [Phase 6D 原生搜索计划](docs/phase_6d_native_search_plan.md)、[报告](docs/phase_6d_native_search_report.md)：三端页面、防抖/输入法、根接线、独立分页、搜索历史与取消安全的首条播放。
- [Phase 6C 搜索数据计划](docs/phase_6c_catalog_search_plan.md)、[报告](docs/phase_6c_catalog_search_report.md)：单语句一致分页、来源身份、取消与持久搜索历史；无新页面、无在线请求或搜索结果入库。
- [Phase 6B 原生首页计划](docs/phase_6b_home_surfaces_plan.md)、[报告](docs/phase_6b_home_surfaces_report.md)：三套布局、真实Repository投影、独立状态、队列保留与关闭排空；封面仍用占位，来源配置和曲库导入尚待开发。
- [Phase 6A 首页最近添加数据计划](docs/phase_6a_home_catalog_plan.md)、[报告](docs/phase_6a_home_catalog_report.md)：v1→v2无损迁移、真实首次入库时间、索引与时间分页；首页UI尚待实现。
- [Phase 5C Windows 窗口计划](docs/phase_5c_windows_window_plan.md)、[报告](docs/phase_5c_windows_window_report.md)：只控制本应用窗口、根级语义/浮层、关闭顺序和独立原生 CI；位置记忆/多屏/全屏留待 Phase10。
- [Phase 5B 正在播放面板计划](docs/phase_5b_now_playing_inspector_plan.md)、[报告](docs/phase_5b_now_playing_inspector_report.md)：Windows320/Tablet260 独立滚动 Inspector、同根双表面操作和重载清除预览；本仓库增量编号，不表示主指令所有 Phase5 子项均完成。
- [Phase 5A 共用 Shell 播放器计划](docs/phase_5a_shell_player_plan.md)、[报告](docs/phase_5a_shell_player_report.md)：根 Presenter、三套原生布局、拖动/切歌/关闭边界和 Space；修正原稿后置阴影及静态曲目信息可读性，不代表完整播放页面完成。
- [Phase 4P 正式音频根接线计划](docs/phase_4p_production_audio_plan.md)、[报告](docs/phase_4p_production_audio_report.md)：根单实例后端、本地引用解析、可等待的有序关闭及初始化失败清理；工程选型 ADR-044，不代表上线批准。
- [Phase 4O 许可查看计划](docs/phase_4o_license_viewer_plan.md)、[报告](docs/phase_4o_license_viewer_report.md)：设置 → 开源许可，SDK 与原生完整原文、搜索/重试、原生模态路由和三张新视觉基线；不使用 WebView 或默认 Material 许可页面。
- [Phase 4N 原生音频许可计划](docs/phase_4n_native_notices_plan.md)、[报告](docs/phase_4n_native_notices_report.md)：51个实际Android依赖坐标、POM/归档指纹及三份完整许可原文，新增双平台包内校验；`f324ed2` 两组云端 checks/Android/Windows 全部通过。
- [Phase 4M 音频许可基础计划](docs/phase_4m_audio_license_plan.md)、[本批报告](docs/phase_4m_audio_license_report.md)：本批完成，最终修正`c0e3706`的两组GitHub三job通过；完整许可原文指纹与源码/双平台打包校验、参数大小写回归，不把六包覆盖当成完整发行批准。
- [Phase 4L HTTPS 原生验证计划](docs/phase_4l_native_https_plan.md)、[本批报告](docs/phase_4l_native_https_report.md)：Android 三来源、Windows 双来源两轮真实原生测试和标准双平台构建通过；默认关闭、诊断隔离，不属于业务功能交付。
- [Phase 4K Android本地来源原生验证计划](docs/phase_4k_android_native_sources_plan.md)、[本批报告](docs/phase_4k_android_native_sources_report.md)：WAV 复跑和只读 content URI 的失败、恢复、播放及释放已在 GitHub 通过；该原生运行无 artifact/Release。
- [Phase 4J Windows原生诊断计划与运行方式](docs/phase_4j_windows_native_validation_plan.md)、[本批报告](docs/phase_4j_windows_native_validation_report.md)
- [Phase 4I播放会话计划](docs/phase_4i_playback_consistency_plan.md)、[本批报告](docs/phase_4i_playback_consistency_report.md)
- [Phase 4H media_kit候选移除计划](docs/phase_4h_media_kit_candidate_removal_plan.md)、[本批报告](docs/phase_4h_media_kit_candidate_removal_report.md)、[本批 PR 草稿](docs/phase_4h_media_kit_candidate_removal_pr_draft.md)
- [Phase 4G media_kit分发审计计划](docs/phase_4g_media_kit_redistribution_plan.md)、[失败关闭报告](docs/phase_4g_media_kit_redistribution_report.md)、[原生产物清单](docs/phase_4g_media_kit_redistribution_inventory.md)、[本批 PR 草稿](docs/phase_4g_media_kit_redistribution_pr_draft.md)
- [Phase 4F just_audio原生运行计划](docs/phase_4f_just_audio_native_poc_plan.md)、[未关闭报告](docs/phase_4f_just_audio_native_poc_report.md)、[本批 PR 草稿](docs/phase_4f_just_audio_native_poc_pr_draft.md)
- [Phase 4E just_audio + Windows WinRT备用候选计划](docs/phase_4e_just_audio_candidate_plan.md)、[本批报告](docs/phase_4e_just_audio_candidate_report.md)、[依赖与许可证清单](docs/phase_4e_dependency_license_inventory.md)、[本批 PR 草稿](docs/phase_4e_just_audio_candidate_pr_draft.md)
- [Phase 4C原生本地音频计划](docs/phase_4c_native_local_audio_poc_plan.md)、[本批报告](docs/phase_4c_native_local_audio_poc_report.md)、[本批 PR 草稿](docs/phase_4c_native_local_audio_poc_pr_draft.md)
- [Phase 4D Content URI与受控HTTPS音频计划](docs/phase_4d_native_audio_sources_plan.md)、[本批报告](docs/phase_4d_native_audio_sources_report.md)、[本批 PR 草稿](docs/phase_4d_native_audio_sources_pr_draft.md)
- [Phase 4B候选适配器计划](docs/phase_4b_media_kit_audio_adapter_plan.md)、[本批报告](docs/phase_4b_media_kit_audio_adapter_report.md)、[本批 PR 草稿](docs/phase_4b_media_kit_audio_adapter_pr_draft.md)
- [Phase 4A播放核心报告](docs/phase_4a_playback_core_contracts_report.md)、[本批范围](docs/phase_4a_playback_core_contracts_plan.md)、[本批 PR 草稿](docs/phase_4a_playback_core_contracts_pr_draft.md)
- [Phase 3H数据引导与夹具报告](docs/phase_3h_dev_fixture_bootstrap_report.md)、[本批范围](docs/phase_3h_dev_fixture_bootstrap_plan.md)、[本批 PR 草稿](docs/phase_3h_dev_fixture_bootstrap_pr_draft.md)
- [Phase 3G安全凭据报告](docs/phase_3g_secure_credential_gateway_report.md)、[本批范围](docs/phase_3g_secure_credential_gateway_plan.md)、[本批 PR 草稿](docs/phase_3g_secure_credential_gateway_pr_draft.md)
- [Phase 3F MusicSourceRepository报告](docs/phase_3f_music_source_repository_report.md)、[本批范围](docs/phase_3f_music_source_repository_plan.md)、[本批 PR 草稿](docs/phase_3f_music_source_repository_pr_draft.md)
- [Phase 3E LyricsRepository报告](docs/phase_3e_lyrics_repository_report.md)、[本批范围](docs/phase_3e_lyrics_repository_plan.md)、[本批 PR 草稿](docs/phase_3e_lyrics_repository_pr_draft.md)
- [Phase 3D CollectionRepository报告](docs/phase_3d_collection_repository_report.md)、[本批范围](docs/phase_3d_collection_repository_plan.md)、[本批 PR 草稿](docs/phase_3d_collection_repository_pr_draft.md)
- [Phase 3C LibraryRepository报告](docs/phase_3c_library_repository_report.md)、[本批范围](docs/phase_3c_library_repository_plan.md)、[本批 PR 草稿](docs/phase_3c_library_repository_pr_draft.md)
- [Phase 3B 数据库报告](docs/phase_3b_database_schema_report.md)、[本批范围](docs/phase_3b_database_schema_plan.md)、[本批 PR 草稿](docs/phase_3b_database_schema_pr_draft.md)
- [Phase 3A Domain 合同报告](docs/phase_3a_domain_contracts_report.md)、[本批范围](docs/phase_3a_domain_contracts_plan.md)、[本批 PR 草稿](docs/phase_3a_domain_contracts_pr_draft.md)
- [Phase 2J 队列与歌词原语报告](docs/phase_2j_queue_lyrics_primitives_report.md)、[本批范围](docs/phase_2j_queue_lyrics_primitives_plan.md)、[本批 PR 草稿](docs/phase_2j_queue_lyrics_primitives_pr_draft.md)
- [GitHub APK 构建与下载](docs/github_apk_build.md)、[CI 隐藏文件校验修复](docs/ci_reference_audit_fix.md)
- [Phase 2I 集合卡片报告](docs/phase_2i_collection_cards_report.md)、[本批范围](docs/phase_2i_collection_cards_plan.md)、[本批 PR 草稿](docs/phase_2i_collection_cards_pr_draft.md)
- [Phase 2H 状态原语报告](docs/phase_2h_state_surfaces_report.md)、[本批范围](docs/phase_2h_state_surfaces_plan.md)、[本批 PR 草稿](docs/phase_2h_state_surfaces_pr_draft.md)
- [Phase 2G 弹层原语报告](docs/phase_2g_overlay_primitives_report.md)、[本批范围](docs/phase_2g_overlay_primitives_plan.md)、[本批 PR 草稿](docs/phase_2g_overlay_primitives_pr_draft.md)
- [Phase 2F 播放器表面报告](docs/phase_2f_player_surfaces_report.md)、[本批范围](docs/phase_2f_player_surfaces_plan.md)、[本批 PR 草稿](docs/phase_2f_player_surfaces_pr_draft.md)
- [Phase 2E 跨平台报告](docs/phase_2e_cross_platform_report.md)、[本批范围](docs/phase_2e_cross_platform_plan.md)、[本批 PR 草稿](docs/phase_2e_cross_platform_pr_draft.md)
- [Phase 2D 报告](docs/phase_2d_android_report.md)、[本批范围](docs/phase_2d_android_plan.md)、[本批 PR 草稿](docs/phase_2d_android_pr_draft.md)
- [Phase 2C 报告](docs/phase_2c_android_report.md)、[本批范围](docs/phase_2c_android_plan.md)、[本批 PR 草稿](docs/phase_2c_android_pr_draft.md)
- [Android Phase 2B 报告](docs/phase_2b_android_report.md)、[本批范围](docs/phase_2b_android_plan.md)、[本批 PR 草稿](docs/phase_2b_android_pr_draft.md)
- [Phase 2A 历史报告](docs/phase_2_android_report.md)、[字体与图标接入记录](docs/design_assets.md)
- [Phase 1 报告与限制](docs/phase_1_report.md)、[阶段计划](docs/phase_1_plan.md)
- [当前架构](docs/architecture.md)、[验证矩阵](docs/test_matrix.md)、[工具链盘点、安装与恢复记录](docs/toolchain_setup.md)
- [PR 描述草稿](docs/phase_1_pr_draft.md)

Android 启动后，底部或左侧导航可切换首页、搜索、音乐库、设置；宽度跨越 600dp 时保留当前路由和根状态。在首页点“设计基础预览”进入 `/design-system`：切换浅色/深色/系统、五种预设/自定义 HEX、减少动态/透明，查看原生组件、滑块、七种占位封面与图标。滑块横向拖动预览、松开提交示例数值，系统取消不提交，支持键盘/无障碍增减，但不触发播放。

外观仅在本次运行保留，重启恢复默认。预览页的点击/收藏/进度只是标注清楚的本页示例状态。正式首页、搜索、音乐库、详情和底栏接根数据库/播放器；设置主体仍是骨架（开源许可入口已可用）。首页右上调色板进入设计预览，刷新按钮重新读取目录与来源/历史；来源状态仅为Repository保存值，不代表重新联网测试。目前没有可操作的曲库导入流程，因此默认新安装显示真实空库。

音乐库点击专辑卡或艺人条目的“查看艺人”打开原生详情；专辑署名可进入艺人，艺人“专辑”分区可继续打开专辑。返回保留原音乐库和详情栈的分类、已加载页与滚动位置；Windows支持Tab/Enter、Esc/Alt+Left。详情摘要显示公开来源名、真实目录计数和明确封面占位；歌曲/专辑独立分页与重试，每区最多读取200条。点可用曲目复用或追加到唯一根队列，不清空其他队列内容；离页或刷新取消尚未执行的播放意图，不停止已播放音乐。文件失效等原因在短标签中显示；本批没有假“更多”、播放全部或收藏按钮。

音乐库→歌单→自定义歌单“查看歌曲”进入原生内容页。点可用歌曲调用唯一根播放器；点更多、长按或Windows右键打开条目菜单，可上移/下移一位或从本歌单移除。重复歌曲分别保留条目身份，失效或未解析引用不能播放但仍可移除；移除不删除歌曲文件。首组从20条逐步扩展至200条，随后用上下两处“下一组／上一组”浏览后续内容；每次读取不超过200条，范围显示如“当前第201–400条／共405条”。切组后回到顶部，刷新/旋转保留当前组和滚动，删除末组后回到最后有效组。未知组边缘的移动仍禁用，不猜测邻居。Back/Esc先关闭菜单，再返回音乐库并恢复入口焦点。离页或读取失败撤销待执行播放，已接受写入继续完成，离页后的写入失败可返回音乐库查看。歌曲菜单已可添加到已有歌单或新建并添加；默认新安装仍无曲库导入，因此空歌单不会自动出现演示歌曲。

正式搜索页输入曲目、专辑、艺术家或来源名，完成输入法合成后防抖查询。点击“搜索目录”只搜索；Enter搜索并播放当前可见的首个可用曲目，优先本地，专辑/艺术家筛选不播放隐藏结果。六个数据区域分别分页/重试，每页20条、每区最多读取200条后提示缩小查询。仅显式提交才保存本机搜索历史；清除历史需确认，不删除音乐或清空查询。Windows Ctrl+K会返回输入位置并聚焦，输入空格不触发播放；离开搜索会撤销尚未执行的播放意图。专辑/艺人结果中的“查看专辑/查看艺人”打开完整来源对应的详情；返回保留搜索条件、滚动与结果，Windows键盘打开后Esc恢复原按钮焦点。查看详情不隐式提交搜索历史或播放，已移除内容显示真实空态，不用同名项目替代。实时联网搜索仍未接入。

“输入与选择”可输入中文/英文、按软键盘搜索提交本页文字、清空或长按选择/复制/粘贴，切换示例筛选和加载状态。不会发送网络查询或保存搜索历史；“减少动态/透明”开关实际更新根外观状态。分段控件支持Tab定位、Enter/Space选择和窄宽横向滚动。

“内容组件 · Fixture”展示AlbumCard和TrackTile的默认、选中/播放、禁用与加载状态。点击专辑、曲目或更多按钮只修改预览页状态标签，不开始播放、不打开菜单，也不读取曲库；Phone隐藏时长，Tablet/桌面显示时长。

Windows按1440/1024断点显示240dp展开或72dp紧凑侧栏，导航驱动同一组四条路由；1440布局显示320dp正在播放Inspector，Android横屏宽度达到1200时显示260dp详情栏。两者共用根状态与播放操作；收窄只隐藏详情，不重建引擎。首页同样可进入设计预览，Windows Chrome Fixture只验证按钮、Tooltip和侧栏状态，不调用系统窗口或伪造在线音乐源。Phase5C正式根窗口已接本Runner的原生Gateway，握手成功后显示自绘标题区及真实窗口动作；位置记忆和全屏仍待后续实现。

“播放器表面 · Fixture”在Android展示64dp Mini Player，在Windows展示88/76dp Desktop Player；播放、下一首、进度、音量、随机/循环、歌词、收藏和队列均为独立的受控回调，只更新预览页状态。这个预览本身不调用 AudioEngine、QueueController、系统媒体会话、数据库或持久化；Phase5A 正式 Shell 底栏则通过根 Presenter 操作唯一播放控制器，两者不可混同。

“弹层原语 · Fixture”展示最终Context Menu、Windows不透明Dialog或Android Phone Bottom Sheet，以及受控Toast；键盘/Esc/焦点与无障碍由原生Flutter组件处理。Fixture只更新本页文字，不创建正式Overlay/Route，不监听真实右键/长按，不启动Toast计时器，也不执行播放、队列、歌单或设备操作。

“状态与反馈 · Fixture”展示播放队列空态、错误Banner与静止纯色Skeleton；强调色预设使用30px视觉/44dp命中的ThemeSwatch。重试只更新本页文字，不访问网络；组件不启动加载、计时器、Repository或生成假结果。

“来源与歌单 · Fixture”展示调用方控制的来源状态、普通/选中/禁用/加载歌单与Create虚线卡片。点击只更新本页说明或选择；不测试连接、不读取凭据、不创建真实歌单，也不访问Repository、数据库、队列或持久化。

“队列与歌词 · Fixture”展示标准/沉浸队列行、future/past/active双语歌词和响应式Lyrics Dock。上移/下移/移除、歌词行、Transport、进度、收藏和返回只更新本页状态；不修改真实队列、不Seek、不解析LRC、不自动滚动或推进计时。

Phase3A数据合同不新增可见页面。TrackRef保留来源身份，QueueEntry使用独立ID以允许重复曲目；来源公开配置只保存credentialRef，秘密仅通过SecureCredentialGateway。当前Fake只用于测试，不会在正式Shell中伪造在线来源、歌曲、歌词或数据库成功。

Phase3B批次本身不新增可见页面。Drift schema覆盖主指令15张建议表，并用`queue_state`保存空队列游标/更新时间、`schema_migrations`记录首版创建；SQLite文件只在显式调用后台打开函数时写入应用支持目录。Phase3H起默认AppBootstrap会打开该空白生产库，但仍不会写入Fixture。

Phase3C批次不新增可见页面或启动接线。DriftLibraryRepository提供事务upsert、确定分页、关联感知watch、TrackRef查询和availability更新；不扫描文件、不访问网络/凭据、不生成假曲库，Phase3H再统一接入生产数据作用域。

Phase3D仍不新增可见页面或启动接线。DriftCollectionRepository提供系统/自定义歌单保护、原子entries/队列替换、收藏和最近20首历史；不实现队列播放算法，不生成系统歌单Fixture。

Phase3E仍不新增可见页面或启动接线。DriftLyricsRepository以完整TrackRef缓存已验证LyricsDocument，严格区分plain/synchronized及双语逐行JSON；不解析LRC、不联网获取歌词，也不把原始响应或文件塞入数据库。

Phase3F仍不新增可见页面或启动接线。DriftMusicSourceRepository只保存公开来源配置和credentialRef，保护稳定类型/内置身份并在删除来源时保留用户TrackRef；不接触凭据值、不测试连接、不访问网络。

Phase3G批次不新增可见页面或启动接线。Android/Windows SecureCredentialGateway使用平台安全存储、严格随机引用、版本载荷与脱敏失败；不记录、不入Drift、不触发网络或伪造来源连通。Phase3H只构造对应平台Gateway，仍未把Fake store测试冒充真机KeyStore/Credential Manager运行验收。

Phase3H仍不新增业务页面。默认入口现在异步打开空白生产数据库、四类正式Repository和当前平台安全Gateway；初始化失败只显示固定脱敏文字。开发样本只在显式`main_dev.dart`中使用内存库：四首HTML曲目、歌单、队列和歌词通过正式Repository写入，但来源为禁用的`.invalid`地址，不含凭据、路径、媒体URI、收藏/历史或假在线状态。

Phase4A仍不新增可见页面或真实音频插件。`PlaybackController`现在是当前曲目、引擎状态、位置/缓冲/时长、音量/速率、随机/循环、持久队列、输出设备与失败的唯一真相；`QueueController`只转发命令和同一份状态。短期网络URL/Header在`PlayableSource`中全量脱敏且不持久化，Android MediaSession与Windows SMTC先共用项目接口。默认后端继续明确不可用，不能把Fake合同测试冒充双平台POC。

Phase4B曾新增隔离的`MediaKitAudioEngine`候选；Phase4C/4D完成了受控原生POC，Phase4G随后证明其分发来源与发行材料无法闭环。Phase4H已从当前源码、依赖、生成注册和CI删除该候选及专用POC，旧实现和运行证据只保留在Git历史与Phase4B—4G报告中。生产入口始终未创建该Player，Shell/Fixture也未获得播放能力。

Phase4G进一步确认Android JAR→APK和Windows release→GitHub Debug bundle的native字节完全匹配，并从SO/DLL核实两端都以LGPL模式构建、关闭GPL/nonfree。审计同时证明现有发布链不能闭环：Windows公开历史脚本与实际DLL配置相反且构建时自定义命令/cache不可恢复；Android helper由可变main取得；两个上游归档都没有完整NOTICE、对应源码或重新链接材料。仓库以机器可读清单和反向测试锁定`blocked`，不把不完整许可证集合打入assets，也不接生产或创建候选Release。

Phase4H把Phase4G的失败关闭结论落实到活动工程：`media_kit`及其13个直接/传递包、两个适配器、5项Fake测试和四个历史POC job已移除，Windows生成注册与Android干净APK均不再包含候选。历史manifest仍完整保留，但明确标记`decision=rejected`与`activeDependency=false`；审计器会拒绝依赖、源码、CI或原生库被重新引入。干净Android Debug为194,098,216字节，较候选基线减少84,986,831字节；这只证明移除，不代表Phase4或正式播放已完成。

Phase4E新增隔离的`JustAudioEngine`备用候选，精确锁定`just_audio 0.10.6`与`just_audio_windows 0.2.3`。只有`just_audio_backend.dart`接触插件，三类来源、状态、控制、错误脱敏和幂等释放由7项Fake测试覆盖；Header能力必须由创建方显式声明，Windows直接Header未支持时在插件调用前失败关闭。生产入口不创建候选，也未启用缓存/下载。本机Android Debug与完整门禁通过；本机Windows因Developer Mode关闭无法创建插件symlink，但`a2b517b`的GitHub push/PR运行均已完成Windows与Android Debug。没有新Release；普通push只有14天Windows Debug审查artifact。

Phase4C的专用`integration_test`在测试进程运行时生成3秒、16kHz、PCM16单声道低幅度WAV，写入应用私有临时目录后执行load、play、position推进、seek、pause、音量、速率、completed、stop与dispose。`622408e`的专用运行记录Windows load 62 ms/首进度197 ms/seek 2 ms，Android load 580 ms/首进度155 ms/seek 4 ms，两边均到达completed。仓库不包含音频二进制或用户路径；该测试不接生产入口，也不证明扬声器可听、音质、后台/焦点、Android `content://`或HTTPS/Header，后两类来源进入Phase4D。

## Phase 0 审计入口

- [Phase 0 完成报告](docs/phase_0_report.md)与[阶段计划及出口](docs/phase_0_plan.md)
- [指纹和完整导出清单](docs/figma_export_manifest.md)
- [合成规则及 CSS 层叠差异](docs/design_source_composition.md)
- [HTML → Flutter 功能映射](docs/html_to_flutter_mapping.md)
- [架构决策](docs/architecture_decisions.md)、[依赖候选证据](docs/dependency_decisions.md)、[双平台音频 POC 计划](docs/audio_poc_plan.md)
- [实施状态与下一阶段前置条件](docs/implementation_status.md)

## 运行与验证

开发基线：Flutter 3.47.2 / Dart 3.13.2（stable），CI 固定相同 Flutter 版本。先确认 flutter doctor；Windows 需要 Visual Studio Desktop development with C++，Android 需要 SDK 命令行工具及用户认可的 SDK 许可。本机缺失项见工具链文档，不能将分析/测试通过当作构建通过。

2026-08-31 环境补齐：复用已安装的 Flutter、Android Studio 和 JDK；新增 Android 命令行工具 22.0、API 36 与 NDK 28.2.13676358，配置用户级路径并保留恢复备份。Android Debug APK 已构建并通过签名校验；Windows C++ 安装仍等待管理员确认，双平台构建状态以工具链记录为准。安装包、机器配置及构建产物不提交仓库。

```powershell
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub --fatal-infos
flutter test --no-pub --coverage
# 只有需要审查开发样本时才选择临时内存入口；默认入口不含样本。
flutter run -t lib/main_dev.dart -d <windows-or-android-device-id>
# APK交付由GitHub Actions执行；不要用旧本机APK替代云端产物。
# Windows 工具链就绪后单独验收；本地尚未完成。
flutter build windows --debug --no-pub
```

工具链完整后使用 `flutter run -d windows` 或 `flutter run -d <android-device-id>`。不要重新运行 flutter create 覆盖现有工程。Android 发行签名未配置，禁止使用 Debug 签名冒充 Release。

需要APK时，在[GitHub Actions](https://github.com/Z-YO-YI/YYMusic/actions/workflows/foundation.yml)对目标分支手动运行工作流；成功后从该次运行生成的私有草稿Release下载。Phase4A实现提交`ec508df`已由唯一[运行33848236710](https://github.com/Z-YO-YI/YYMusic/actions/runs/33848236710)生成并完成[草稿Release](https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-271d9f07baf51fb6bb95)复核，APK为190735487字节，SHA-256为`3f95cea301d6710ac46a40a5fbfcd0d4561d91f310ca5d04506d5389a1272aa4`。必须确认Android任务、Release标签、metadata完整commit和SHA256SUMS一致；普通push/PR只验证构建，不创建下载产物。APK不提交Git源码，证据见[Phase4A报告](docs/phase_4a_playback_core_contracts_report.md)，详情和临时Debug签名限制见[构建说明](docs/github_apk_build.md)。

本机无Android模拟器，Windows原生工具链仍受远程UAC/Developer Mode限制；本地构建成功不等于已安装运行。Phase4C只读手动作业取得的云端原生进程证据只能证明初始化、解码、时钟与控制链，不能外推为实体扬声器或真机体验。32张组件/原生Shell Golden使用打包字体、Flutter 3.47.2 / Windows测试宿主，精确像素比较；Linux对这些宿主专用测试执行明确跳过，仍运行全部非Golden回归，Windows CI另执行Golden。只在审查视觉变更后对指定测试使用`--update-goldens`，日常测试不得更新基线。

## 设计与归档完整性

需要 Node.js 22 或更高版本及PATH中的PowerShell 7（`pwsh`），无额外包依赖；这些命令不执行参考 HTML 的脚本，不构建 Flutter。新增归档回归仅改动临时副本，覆盖隐藏文件与完整性失败情形：

```powershell
node --check tools/design_audit.mjs
node --check tools/design_audit.test.mjs
node tools/design_audit.mjs --check
node --test tools/design_audit.test.mjs tools/design_assets.test.mjs tools/legacy_archive.test.mjs tools/foundation_architecture.test.mjs tools/android_artifact.test.mjs tools/reference_archive.test.mjs
pwsh -NoProfile -File tools/verify_reference_archive.ps1
```

重新生成派生资产使用 `node tools/design_audit.mjs --write`。输入指纹不匹配时失败，不能直接更新预期哈希掩盖变动。

开发参考：[最终合成 HTML](design_reference/generated/YYMusic_Figma_Composed_Reference.html)。仅用于获准环境中的视觉对照，不是正式客户端或已通过的截图基线；不应将 `design_reference` 声明为 Flutter Release assets。

## Git 与历史原型

仓库：[Z-YO-YI/YYMusic](https://github.com/Z-YO-YI/YYMusic)，用户于2026-09-04明确授权设为公开。变更前检查当前已跟踪文件及可见Git历史，未发现常见Token、私钥、`.env`或签名密钥文件。当前开发分支`feat/just-audio-native-poc`基于已拉取并同步的`feat/native-audio-content-network-poc@3da2f61`，未在main/master开发。临时GitHub API访问令牌不持久化、不进入仓库；Git提交/推送和云端产物状态以每次交付时实际核验为准。

旧原型 13 个文件已原样迁入 [archive/sonic_gallery](archive/sonic_gallery/README.md)，并在 `f96197b` 单独提交；源码、两份测试、配置和图片可恢复，不再散落为根目录未跟踪文件。Phase 0 中“保留原地、未纳入提交”的说明是当时历史状态。

正式客户端只来自根 lib/，不依赖 archive 或 design_reference。归档目录有独立 pubspec，但不是当前工程的测试目标；禁止对整个仓库递归格式化，破坏原始指纹。
