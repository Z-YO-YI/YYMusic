# 视觉还原与 Golden 计划

## Phase 5C 窗口 / Phase 6A 数据

Phase5C新增1440浅色首页、840深色许可页根窗口标题栏两张130%图；保留其余41张基线。
根控件在路由语义屏障之外可访问，提示在下方且不越过右缘；原生行为另有GitHub窗口测试，
不从Golden推断Win32操作成功。Phase6A只改数据，43张基线均未变且非更新比较通过。

## Phase 5B Inspector

新增320浅色播放、260深色播放、320白强调错误，均130%字号和固定Fake状态，完整内容高980。
原稿不透明now-panel、26radius/18padding/17文案间距、最终Artwork26与Transport56/38、图标24/20
及主按钮hover阴影纳入；260窄栏模式按钮换行，短高度通过独立滚动保持可达。
非更新首轮仅两张Windows整页图产生预期差异，确认后更新；新增3图逐张审查，其余36张旧图不变。
最终41张非更新比较通过；网页参考截图仍未补齐，不把Golden自洽当作对原稿的最终像素验收。

## Phase 5A Shell 播放状态

新增 phone_light 390×844、tablet_dark 1024×768、windows_white 1440×900 的 ShellPlayer
完整场景，固定测试曲目、1:14/3:00、130% 双语文字；Fake 引擎仅用于可重现状态，不冒充原生。
首次非更新比较确认 8 个预期差异后更新 2 Android/3 Windows Shell、3 PlayerSurfaces 基线。
后者修正 App.tsx `.player-control.primary` 后置深色轻阴影；静态元信息不因未开放详情按钮变灰。
11 张新增/变更图逐张检查，最终非更新全量回归通过；另 27 张旧图保持原字节，总数 38。
以上仅说明本仓库 Flutter 视觉回归稳定；网页合成参考截图仍缺，未宣称像素完全一致。

## Phase 4O 原生许可页回归

新增 `licenses_phone_light.png`（390×844）、`licenses_tablet_dark.png`（1024×768）、
`licenses_windows_text.png`（1440×900）：固定打包字体、真实原生许可资产、130% 文字与减少动态。
SDK 组件目录在 Golden 中为空以免宿主变化；真实 SDK 接口与无标签组另由单元测试覆盖。
逐张检查，修正弹层字体继承后重新捕获新图并非更新复测；旧 32 张基线未改，总数 35 张。
原文滚动区域保留全文，不把截屏中不可见段落删去。横屏/搜索/错误/返回另有 Widget 测试。
本批没有网页许可页面的直接像素参照，沿用最终主题与组件，不代替尚缺的 Phase2 网页对照。

## Phase 0 当时证据与限制

- 已生成与App.tsx合成顺序一致的静态HTML、44个SVG、完整polish.css及映射。
- 指纹、合成字节一致性、图标路径、CSS覆盖完整性、源JS语法、生成确定性已用Node测试验证。
- Browser技能连接成功，但file: URL被浏览器安全策略阻止；**未截图、未测computed style**。没有改用其他浏览器、localhost代理或底层协议绕过限制；临时viewport已恢复。
- 没有Flutter/Dart可执行命令，未运行Flutter Golden或真机性能检查。生成的参考HTML不是Golden通过证据。

## Phase 2A 新证据与未解决限制

现已使用本机Flutter3.47.2/Windows测试宿主、固定打包Inter/NotoSansSC生成3张原生Golden，逐张查看后非更新模式精确比较通过。基线在test/golden/baselines：浅/深组件390×900、文字130%；全部44SVG的800×590图标集。真实字体Widget另覆盖360×800、390×844、600×900、1280×800、844×390，不代表这些尺寸已完成参考截图比对。

这些是原生组件自身回归基线；没有Figma远端/网页截图，没有computed-style或设备Profile测量。此前浏览器拒绝仍不绕过，网页像素一致性保持待办。初次Golden捕获曾遗漏祖先背景，已将实际主题背景放入捕获边界，重新查看和非更新复测；未通过加宽像素容差掩盖差异。

## Phase 2B 新证据与差异记录

Phase2B另增5张Windows宿主基线（总8张）：三张800×1000组件总览，浅珊瑚/深翡翠/白色ReduceGlass；真实Android Shell为390×844及600×900，均130%字号，Shell包含24dp上/下安全区。新增图像逐张查看，再使用非更新模式精确复测；Phase2A原3张文件未修改。

本批视觉适配：导航标签11dp代替旧HTML8/9dp，Phone64/32与无左条；白色/黑色等低对比accent保持原值并增加可读边界。回归曾拦截默认珊瑚色误加边框，已修正生产组件的条件，不更新正常珊瑚/原Shell截图掩盖差异。组件总览初始画布高度940不足容纳全部素材，调整为1000；仅扩大测试总览画布，不修改真实设备窗口或隐藏溢出。

七种封面是App.tsx原CSS的原生绘制，不是新设计或图标替代。Signal/Local固定px偏移、Mono5px圆角、边框内缩与裁剪保留；没有把所有数值按封面宽度统一缩放。仍无网页截图对照，不声称像素还原比例或设备帧率。

## Phase 2C 新证据与差异记录

Phase2C新增三张原生输入控件总览390×1080/130%：浅珊瑚、深翡翠、自定义白；总计11张。已逐张检查输入文字/错误消息/清空图标、分段选中与开关四态，新旧图像均以非更新模式通过，原8张字节未变。白色开关以可读外边界与thumb边界补足辨识度；分段保留白/深elevated选中面，长标签横向滚动，不强行缩小字体。测试Harness增加与正式路由一致的Overlay以测试原生文字选择，并未去掉错误检查。

本批Search使用15/460，常规58/20、Phone52/18（130%时高度最低52.275避免裁切）；触控覆盖整个输入表面，分段旧34px命中提高到44。选择高亮使用可读派生accent的20%透明度，保留原用户HEX。输入工具栏/句柄为原生编辑适配，不替代App.tsx应用图标。仍没有网页参考截图或真机像素一致性证据。

## Phase 2D 新证据与差异记录

Phase2D新增三张原生内容组件总览390×1080/130%：浅珊瑚、深翡翠、自定义白；总计14张。已逐张检查Album默认/选中/禁用/加载及Track播放/默认/禁用/加载状态，没有文字或几何溢出；旧11张文件未修改。新旧图像均须在非更新模式精确比较通过。

Album按最终POLISH使用20圆角、默认与hover阴影、12.5/700标题。Track使用14行圆角、10封面圆角、36封面及58最小高度；Phone隐藏时长，来源标签最长72并省略，Tablet/桌面最长120且显示时长。选中/播放面保留原accent soft填充；自定义白色使用既有可读派生色补足边界和文字辨识度，不改用户HEX。

这些仍是原生组件自身的确定性Fixture，不是首页、曲库、搜索结果或真实播放截图。没有网页参考截图、Android设备Golden、真机TalkBack/hover或性能证据；不能据此声明完整页面像素一致。

## Phase 2E Windows 新证据与差异记录

Phase2E新增三张真实Windows Shell基线：1440×900浅色珊瑚展开布局、1024×720深色翡翠标准布局、840×640浅色自定义白紧凑/ReduceGlass布局，全部DPR1、130%文字。已逐张查看顶部42dp工具区、240/72侧栏、3×18选中条、1440专有320 Inspector结构位、88/76播放结构位、长中文及白色强调色辨识度；非更新模式精确比较通过。

账户Fixture从旧组件中的`YYListener`修正为App.tsx最终替换要求的`YY Listener`，因此既有浅/深组件基线各有0.54%局部像素差；失败图确认只涉及账户文字后才更新这两张。新增`YYGlassPanel`的首次复用曾使旧`YYGlassSurface`的1dp高光线不再占据布局空间，14张旧套件中的5项导航基线随即失败；实现恢复原渲染树后旧导航基线原样通过，没有用重录掩盖位移。最终总计17张，变更为3张新增Windows图和2张有明确文字修正原因的旧组件图。

## Phase 2F 播放器表面新证据

Phase2F新增三张1280×560、DPR1、130%文字的组件板：浅色珊瑚、深色翡翠、浅色自定义白/ReduceGlass。每张同时覆盖桌面88dp、窄窗76dp、Android Mini64dp和Loading/Disabled；已逐张查看封面、文字、进度、Transport、工具区、音量及低对比强调色，无裁切或溢出。基准只表示受控视觉Fixture，不表示真实AudioEngine、队列或系统媒体会话已接入。

新增图锁定后，既有17张基线不更新；全套20张必须在非更新模式精确比较。桌面54/50与Mini48封面、14/12圆角、42/34视觉控制及44dp命中另由Widget几何测试约束，避免只凭截图推断交互区域。

## Phase 2G 弹层原语新证据

Phase2G新增三张1280×720、DPR1、130%文字的组件板：浅色珊瑚、深色翡翠、浅色自定义白/ReduceGlass。每张同时覆盖224dp Context Menu、680dp不透明Windows Dialog、248dp Android Bottom Sheet及Toast；已逐张查看菜单局部玻璃、Dialog/Sheet不透明表面、30/20/14圆角、长中文、禁用/加载/选中/危险状态和白色强调色，无裁切或溢出。

新增图锁定后，既有20张基线不更新；全套23张已在非更新模式精确比较。Golden只锁定受控Fixture外观，不表示右键/长按、锚点避让、Overlay/Route插入、Toast计时或真实播放/歌单动作已接入；焦点闭环/恢复、键盘和live region另由Widget测试约束。

## Phase 2H 状态与反馈原语新证据

Phase2H新增三张1280×720、DPR1、130%文字组件板：浅色珊瑚、深色翡翠、浅色自定义白/ReduceGlass。每张覆盖五个预设与白色/加载Swatch、Empty State、可用/禁用Error Banner和三种Skeleton宽度；已逐张查看30px色样、白色选中内环、错误色、长中文、禁用对比度和纯色占位，无裁切或溢出。

首次查看发现未传宽度的Skeleton在左对齐Column内收缩为0，已改为填满有界可用宽度并补Widget约束后重新生成三图。新增图锁定后既有23张基线不更新；全套26张非更新精确比较通过。Golden不表示真实网络加载、重试、搜索结果或Controller异步状态已接入。

## Phase 2I 来源与歌单卡片新证据

Phase2I新增三张1280×720、DPR1、130%文字组件板：浅色珊瑚、深色翡翠、浅色自定义白/ReduceGlass。每张覆盖四种来源状态、选中/禁用/加载来源卡片、普通/选中/禁用/加载歌单和Create虚线卡片；已逐张以原始分辨率查看，长中文、状态点、图标、虚线边界和低对比强调色均无裁切或溢出。

Source锁定72/12/42/16/13/6最终几何；Playlist锁定桌面16/44/18与最终20/14圆角，Phone的13内边距和40图标另由Widget测试约束。新增图锁定后既有26张基线不更新；全套29张非更新精确比较通过。Golden只表示受控Fixture外观，不表示来源连接、歌单Repository、真实计数、创建流程或持久化已接入。

## Phase 2J 队列与歌词原语新证据

Phase2J新增三张1280×900、DPR1、130%文字组件板：浅色珊瑚、深色翡翠、浅色自定义白/ReduceGlass。每张覆盖Queue当前/默认/禁用/加载及沉浸密度，歌词past/active/future/双语和Lyrics Dock；三张已逐张查看，动作、时间、进度、状态点和低对比强调色均无裁切或溢出。

首次捕获使用较长英文歌词，在固定900高画布准确暴露328px底部溢出；只缩短测试Fixture文案后重新生成，没有缩小正式字号、隐藏组件或放宽差异。Queue锁定50/60、36/42、10圆角与26视觉动作；Lyrics锁定24%/50%/active、780字重、1.018缩放和6px环；Dock锁定82、50、34/44及最终26圆角。Phone、低高度及44dp命中由Widget测试约束。新增图锁定后既有29张不更新；全套32张非更新精确比较通过。Golden不表示队列算法、Seek、LRC解析、自动滚动或正式歌词页已接入。

正式Windows Shell明确显示“音乐源尚未接入”，不使用HTML演示的在线状态、来源数或歌曲数；窗口控制在Gateway实现前隐藏。截图中的首页仍是工程骨架，不是完整Windows业务页，也没有网页参考、Windows真机安装、GPU模糊性能或系统无障碍工具验收。

## 后续合法可访问预览环境的参考采集

在获准且可访问的开发预览环境中加载原样合成参考，不加载旧HTML单独截图，也不加载用户真实音乐库/凭据。固定浏览器版本、字体、DPR1、语言、时区与逻辑viewport。用测试Fixture固定时间、曲目、队列、收藏、源状态；通过UI暂停demo播放并将进度设为固定值，避免每秒变化。

如需专门测试入口，只能在开发副本中显式新增并记录差分，不能改动归档原文件及其指纹。不要通过读用户浏览器存储取得测试状态。截图不包含用户真实媒体或秘密。

| UI | 参考尺寸 | 正式Flutter验收尺寸 |
| --- | --- | --- |
| Windows | 1440×900、1024×720 | 同上 +840×640 |
| Android Phone | 390×844、430×932 | 同上 +360×800、844×390横屏 |
| Android Tablet | 1024×768、1280×800、800×1280 | 同上 +700×900分屏 |

横屏Phone测试设备使用当前窗口宽度分类，见ADR-002。网页Tablet大宽度不等同正式Tablet Shell，平台主动适配应进入差异报告而不是用错误截图强行验收。

## 场景与顺序

1. Home Light/Dark；核对Shell/Profile/导航/mini或desktop player。
2. Library albums/tracks/artists/playlists/local，Search idle/results/empty/error。
3. Fullscreen Player、独立Lyrics（active/past/future/translation/empty）、Queue。
4. Source Manager/form/testing/auth error，Appearance与局部离线错误。
5. 先结构，再Token，再字体，再图标，再状态，再断点，再动效，最后主题变体。

所有关键组件覆盖Light/Dark、Coral/Cobalt/Jade/Amber/Graphite、自定义亮/暗accent、Reduced Glass、Reduced Motion。状态覆盖Hover/Pressed/Focus/Selected/Disabled/Loading；Phone不模拟持续Hover。

每个关键Golden检查App.tsx新图标路径、44px双Ring账户、Windows/Tablet3×18指示条、Phone替代选中样式、Hero28/Artwork20/Dialog30/Dock26、多层轻阴影、歌词Dock两层重排及130%字体缩放。

## 比对方法与出口

固定同一平台字体和Flutter renderer，不把CSS blur42直接当sigma42。先建立截图基线和无变化重跑噪声，再确定容差；不能在没有测量时发明“99%一致”或任意通过阈值。像素差/半透明叠图用于定位，结构、安全区、文字截断、焦点和图标漏绘不能被总平均分掩盖。

差异记录格式：Screen / Reference size / Flutter size / Difference category / Expected / Actual / Root cause / Token-or-component fix / Validation result。

必须单独记录：全屏slider5/15与4/12 → 正式3/14；Phone导航24 →32；大宽Tablet Shell；immersive artwork ID specificity；Pressed优先Hover；Reduce Glass范围。不要修改原参考隐藏冲突。

先修共享Token/组件，再修必要布局。Flutter Golden通过后仍需Windows与Android真机Profile：模糊区域/帧时间、长列表、频繁位置流、封面解码、歌词滚动。没有重大未解释差异才进入下一视觉阶段。
