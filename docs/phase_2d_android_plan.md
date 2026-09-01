# Phase 2D 开始 — Android 内容卡片与曲目行

日期：2026-09-01。开始前已执行`git fetch --prune origin`，确认`fix/reference-audit-hidden-files@b0abd9d`与远端0/0同步、工作树干净；从该提交创建独立分支`feat/android-content-cards`，不在main/master直接开发。

## 本阶段目标

- 实现原生Flutter `YYAlbumCard`与`YYTrackTile`，复用Phase2A字体/主题/44个SVG及Phase2B七种几何封面，不使用WebView、Material默认视觉、渐变或近似重画图标。
- 覆盖Default、Hover、Pressed、Focus、Disabled、Selected/Playing、Loading、Light、Dark与自定义Accent；交互命中区不小于44dp，支持指针、Enter/Space和明确语义。
- 将两个组件加入设计Gallery，所有文案明确标为组件Fixture；选择、播放和更多操作只改变Gallery本页状态，不访问音频、数据库、网络、文件或持久化。
- 新增Widget与真实字体Golden；保留已有75项Flutter、28项Node和11张Golden，不更新旧基线或放宽容差。

## 已读取的来源

- 主指令第4.5、16、16A、36/Phase2、38、39和41节。
- 最终合成参考HTML的`.album-card`、`.track-row`结构、响应式规则及交互脚本；同时读取基础HTML继承规则与App.tsx最终`POLISH_CSS`覆盖。
- `docs/generated/polish_rule_mapping.md`中的YYAlbumCard/YYTrackTile映射，以及现有Theme、Artwork、ControlAction、Gallery和测试Harness。

最终目标采用App.tsx覆盖后的Album Artwork 20圆角、默认/hover阴影、Album Title 12.5/700/-0.15；Track Artwork 10圆角、Track Row 14圆角。基础HTML的36dp封面、58dp最小行高、12/670标题、10dp元数据及手机隐藏时长规则作为继承行为，冲突处以后置POLISH为准。

## 准备修改

- `lib/design_system/yy_tokens.dart`
- `lib/features/design_gallery/design_gallery_screen.dart`
- Gallery与测试、Golden、README/CHANGELOG/架构/状态/视觉差异文档

## 准备新增

- `lib/design_system/yy_album_card.dart`
- `lib/design_system/yy_track_tile.dart`
- `lib/features/design_gallery/gallery_content_cards.dart`
- `test/widget/content_cards_test.dart`
- `test/golden/content_cards_golden_test.dart`及经视觉检查的新基线

## 风险与边界

- Album/Track文案沿用参考中的演示内容只用于确定性组件Fixture，不声明为真实曲库。
- Track整行主动作与更多按钮是两个独立语义节点；更多操作不得冒泡触发主动作。
- 本批不实现`YYMiniPlayer`、ContextMenu、弹层、业务页面、Domain/数据库或真实播放，不提前进入Phase3/4。

## 出口条件

- 两个组件及Gallery在390dp Phone、600dp Tablet、130%字号、Light/Dark/自定义Accent下无溢出，交互/键盘/语义/禁用/加载状态有测试。
- 新旧Golden以Flutter 3.47.2 Windows宿主精确比较通过；旧11张字节不变。
- format、fatal-infos analyze、全量Flutter/Node、24个ZIP entry与指纹门禁通过。
- 阶段提交推送GitHub并创建或更新PR；Android APK仅由GitHub runner构建。
