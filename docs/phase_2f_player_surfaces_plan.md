# Phase 2F 开始 — 跨平台播放器表面

日期：2026-09-01。开始前已确认`feat/windows-navigation-foundation@99b664a`与远端0/0同步、工作树干净；从该提交创建独立分支`feat/cross-platform-player-surfaces`，不在main/master开发。

## 本阶段目标

- 新增受控原生Flutter `YYMiniPlayer`与`YYDesktopPlayerBar`，复用现有Theme、Glass、Slider、Artwork和App.tsx最终SVG。
- 保留基础HTML桌面88/76、手机64高度；桌面54/50与手机48封面、14/12封面圆角、34/42控制视觉及44dp实际命中。
- Android Gallery展示Mini Player Fixture，Windows Gallery展示Desktop Player完整/紧凑Fixture；回调只更新本页状态。
- 覆盖曲目信息、播放/下一首、完整transport、进度、音量、歌词、收藏、队列的独立动作、语义、键盘与响应式状态。

## 已读取与校验的来源

- 主指令Phase2组件清单、Slider/Primary Transport阴影、Liquid Glass范围、Windows/Phone/Tablet播放器尺寸及Phase2→4→5边界。
- 基础HTML `.playerbar`、`.player-track`、`.player-artwork`、`.player-controls`、`.player-progress`、`.player-tools`、`.volume-wrap`及1439/1080/1023/760/599响应式规则和完整Footer标记。
- App.tsx完整`NEW_ICON_SPRITE`；播放器使用的图标均在44项最终Sprite。重新检索最终`POLISH_CSS`，没有播放器条选择器，不能臆造后置覆盖。
- 当前`YYSlider`预览/提交/取消合同、`YYControlAction`、`YYGlassSurface`、Artwork角色、Gallery与Golden Harness。

## 准备新增/修改

- `lib/design_system/yy_player_surface.dart`
- `lib/design_system/yy_player_data.dart`
- `lib/features/design_gallery/gallery_player_surfaces.dart`
- `lib/design_system/yy_artwork_placeholder.dart`
- `lib/design_system/yy_tokens.dart`
- `lib/features/design_gallery/design_gallery_screen.dart`
- `test/widget/player_surfaces_test.dart`
- `test/golden/player_surfaces_golden_test.dart`及经视觉检查的新基线
- ADR、架构、视觉矩阵、状态、README与CHANGELOG

## 风险与边界

- Phase4尚未选择双平台AudioEngine，本批不得调用现有不可用后端或新增音频依赖。
- `YYNowPlayingViewData`是只读UI模型，不是Domain Track/Queue模型；以后只能由Presenter映射，不能让Repository依赖设计系统。
- Gallery曲目、时间、进度和播放状态均明确为Fixture，不进入正式Shell，不写数据库、网络、文件、系统媒体会话或持久化。
- 不实现队列算法、随机/循环行为、全屏播放/歌词页面、后台通知、窗口/Android系统集成。

## 出口条件

- Mini64、Desktop88/76、Artwork54/50/48、34/42视觉控制和44dp命中有几何测试。
- 所有动作独立，不因点击工具按钮触发打开曲目信息；Hover/Pressed/Focus/Disabled/Loading、Tab/Enter/Space与Semantics准确。
- Slider沿用预览/提交/取消边界，长中英文在360/840/1024/1440及130%无溢出；低宽隐藏策略有断言。
- 新增关键Golden逐张检查，17张旧基线保持不变；完整Flutter/Node/ZIP/指纹门禁通过。
- 独立提交推送GitHub、更新Draft PR、双平台Debug成功，APK仍只由GitHub手动工作流构建。
