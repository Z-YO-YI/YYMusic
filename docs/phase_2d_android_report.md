# Phase 2D — Android 内容卡片与曲目行报告

2026-09-01。开始前已fetch/pull并确认`fix/reference-audit-hidden-files@b0abd9d`与远端同步、工作树干净；从该提交创建`feat/android-content-cards`，未在main/master开发。阶段范围、来源和出口见[计划](phase_2d_android_plan.md)。

## 当前实际进度

Phase0的五份源指纹、完整App.tsx、基础HTML、`NEW_ICON_SPRITE`和`POLISH_CSS`审计仍是设计依据；Phase2A主题/字体/图标、Phase2B导航/Slider/Artwork、Phase2C输入组件均保留。本次只推进两个原生内容组件及Gallery Fixture。整个Phase2尚未结束；正式业务页、MiniPlayer、弹层、数据库、网络来源和真实音频均未接入。

## 实现

1. `YYAlbumCard`：受控选中/加载状态，复用七种原生Artwork；最终POLISH的Artwork 20圆角、默认/hover阴影及12.5/700标题；指针、Enter/Space、焦点、禁用和加载语义。Album选中不声明为互斥单选组。
2. `YYTrackTile`：14行圆角、10封面圆角、36封面、58最小高度、12/670标题及10dp元数据；播放态使用accent soft面与可读文字。Phone隐藏时长并将来源标签限制为72宽，Tablet/桌面限制120并显示时长。
3. Track主动作与更多按钮分离为独立Semantics/Focus/命中节点；点击更多不会触发曲目主动作。禁用或加载时两个动作均不可用；组件本身不调用播放器或菜单。
4. Gallery新增“内容组件 · Fixture”，覆盖Album默认/选中/禁用/加载及Track播放/默认/禁用/加载。所有回调只更新本页状态标签，不读写音频、数据库、网络、文件或持久化。
5. `YYControlAction`增加内部`inMutuallyExclusiveGroup`选择，仅用于准确表达复用组件的语义合同；原Toggle/Segmented默认行为不变。共享API和边界见ADR-015。

## 设计与视觉依据

本批重新读取主指令相关章节、最终合成参考HTML中的`.album-card`与`.track-row`、基础HTML继承规则、App.tsx最终`POLISH_CSS`以及生成的规则映射。冲突处按后置POLISH覆盖；没有只读旧HTML，没有使用WebView、渐变、Material默认外观或近似重画图标。

新增三张390×1080、130%文字、DPR1的Windows宿主Golden：浅珊瑚、深翡翠、自定义白。三张均逐张查看，无文字/几何溢出，状态可辨；随后非更新模式精确比较通过。旧11张PNG未修改，总计14张。白色accent保留原HEX，以既有可读派生色补足边界和选中文字。

## 本地验证结果

| 检查 | 实际结果 |
| --- | --- |
| 格式 | `dart format lib test`检查58个Dart文件，0个改动 |
| 严格分析 | `flutter analyze --fatal-infos`通过，0问题 |
| Flutter完整回归 | 82项通过：此前75 + 新Widget4 + 新Golden3；非更新模式、无本地跳过 |
| 内容组件 | Default/Hover/Pressed/Focus/Disabled/Selected或Playing/Loading、键盘、语义、独立更多动作、长来源省略、390/600与130%覆盖 |
| Golden | 新3张逐张查看；旧11张未改；14张精确比较通过 |
| Node/源码门禁 | 28项Node通过；5份指纹、44 SVG、52份确定性产物与原型13文件保持完整 |
| ZIP复核 | 24个entry与原始ZIP逐字节一致，包含隐藏文件 |
| 依赖与权限 | 无新依赖、Android权限、机器环境、媒体或用户数据变更 |

## 云端与限制

本报告先记录本地可复核事实。目标提交推送后，普通push/PR只做checks、Windows Debug和Android Debug；APK必须再由该commit的手动`workflow_dispatch`生成私有草稿Release，并下载核对metadata、SHA256SUMS和Debug签名。没有本机重建或上传旧APK。

Golden是原生组件回归，不是网页截图或正式页面像素一致性证明。尚无Android真机/模拟器、TalkBack、IME、GPU性能或真实播放验收；Gallery状态不是用户曲库或业务实现。

## 主要文件

- `lib/design_system/yy_album_card.dart`
- `lib/design_system/yy_track_tile.dart`
- `lib/design_system/src/yy_control_action.dart`
- `lib/features/design_gallery/gallery_content_cards.dart`
- `test/widget/content_cards_test.dart`
- `test/golden/content_cards_golden_test.dart`及三张新基线
- ADR、架构、视觉、矩阵、README和CHANGELOG状态文档

下一批仍应从Phase2的独立小范围开始，例如菜单/弹层或MiniPlayer的设计系统边界；不得借本批组件直接进入数据库、音频或一次性生成完整业务页面。
