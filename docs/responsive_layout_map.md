# 响应式与三套 Shell 的边界

基础HTML有16个media块（包括重复断点），完整行号在generated/design_inventory.json。App.tsx没有增加媒体查询，但后置样式参与层叠。以下网页行为来自源码，浏览器尺寸截图本轮未运行。

## 原始 CSS 断点（按源码出现顺序）

| 行 | 条件 | 内容 |
| --- | --- | --- |
| 默认 | >1439 | 240 Sidebar + 主区 +320 Inspector；42标题栏/88播放器；padding16、gap14；专辑5列 |
| 955 | max-width1439 | 隐藏Inspector；保留240 Sidebar；专辑4列 |
| 968 | max-width1080 | Hero列比例变更、content/settings单列、source2列、专辑3列、隐藏volume |
| 977 | max-width1023 | 72 Rail、76播放器、gap12、隐藏window bar/profile/footer；专辑又变4列；隐藏player progress |
| 1005 | max-width760 | Hero单列/隐藏唱片，专辑3列；player center隐藏 |
| 1014 | max-width599 | 固定底部64导航+64mini player，相隔8；main padding-bottom166；专辑2列；dialog全屏、SafeArea |
| 1105 | max-width370 | Nav最小52/label8、Hero29、album strip132 |
| 1112 | prefers-reduced-motion | animation/transition .01ms、scroll auto |
| 1361 | max-width1180 | Playlist3列、local单列 |
| 1366 | max-width760 | Feature/summary2列、Playlist2列、来源actions换行 |
| 1373 | max-width599 | Track更多按钮保留；settings导航重新显示为横向可滚动；local block；menu限宽 |
| 1542 | (max-width900 AND portrait) OR max-width700 | immersive player单列、封面min(67vw,46vh,430)、details不固定max-height |
| 1565 | max-height620 AND landscape | player紧凑双列/封面min(66vh,38vw,350)/主控制54；覆盖前面规则 |
| 1588 | max-width380 | Feature/summary/options1列 |
| 1955 | max-width900 | lyrics字体34–58；Dock track/actions一层+center第二层 |
| 1976 | max-width599 | lyrics顶栏/字体29–43、Dock紧凑；去装饰YY、收藏隐藏 |
| 2038 | max-height620 AND landscape | lyrics缩小padding/字体27–42/translation12/Dock64 |

重要顺序：1023规则晚于1080所以761–1023专辑是4列，不是3列。设置导航在第一个599规则隐藏，后续599规则又显示。最终Polish覆盖nav/Sidebar/dialog/Dock等部分radius，但不会取消这些布局变化。

## Flutter 分类决策

| 平台与当前约束 | 分类 / UI | 保持的共用状态 |
| --- | --- | --- |
| Windows width>=1440 | windowsExpanded：42标题栏、240 Sidebar、320 Inspector、88player | 与下列分类共用相同状态 |
| Windows 1024<=width<1440 | windowsStandard：224–240 Sidebar、无固定Inspector、88player | 同上 |
| Windows width<1024 | windowsNarrow：72 Rail、76player、平台窗口操作；840×640最低检查 | 所有分类均保留路由/滚动/选中/当前Track/queue/position |
| Android width<600 | androidPhone：64底部胶囊导航、mini player、单列、SafeArea | 同上 |
| Android width>=600且width<=height | androidTabletPortrait：72 Rail、主内容、3–4专辑列、72–76player | 同上 |
| Android width>=600且width>height | androidTabletLandscape：72 Rail、主从分栏、72–76player、可选Inspector | 同上 |

分类使用实时LayoutBuilder constraints，并先判断平台；禁止仅按宽度认Windows，禁止设备型号/一次性启动宽度。Shell只布局、输入和平台Chrome，根依赖图拥有Controller。Android分屏599↔600不能重建音频引擎。

“Phone844×390横屏”与width规则的冲突：按主文档§6，844归TabletLandscape，不做设备硬编码；player/lyrics另用低height规则紧凑双栏。同一APK不会因此复制播放器；该解释写入ADR-002并作为后续视觉评审项。

## 与网页的主动适配（不可隐瞒）

- Windows窄窗仍需真实window控制，不复制HTML把window bar彻底隐藏后的平台操作缺失。
- Android1024×768不能出现HTML的Windows Sidebar；用Tablet Shell。
- Phone导航按主文档32圆角胶囊，active用底色/胶囊，不用全局polish的左竖条。
- 安全区以实际平台insets为准，页面bottom padding由导航/mini player和insets算出，不固定166。
- Touch44×44与视觉14px thumb分离；textScale1.3与长中文不能挤掉更多/返回按钮。
- 播放与歌词为独立路由，进入时隐藏Shell导航；队列/来源弹层使用相同导航层级语义。

边界测试：599/600、1023/1024、1439/1440，短横屏height620/621；Windows840×640，Android700×900分屏，反复缩放/旋转时保留状态。截图尺寸与主题矩阵见visual_parity_plan.md。

## Phase 2B 已实现部分

AndroidPhone已接入64高/32圆角导航，沿用Shell12dp横边距及SafeArea，64高播放槽与导航相隔8；槽仍非正式MiniPlayer。AndroidTablet改用72宽导航Rail，条目默认60高、3×18选中条，低高度可滚动。标签11dp，极大字号时导航/条目高度可扩展。600dp按当前窗口宽度判断，不按手机型号判断。

Widget覆盖599/600、1280×800、844×390与返回390×844，根路由/Controller保留；Phone和600宽Tablet另有130%字号截图。上表专辑列数、Inspector与正式播放器仍是后续目标，不冒充本批完成。
