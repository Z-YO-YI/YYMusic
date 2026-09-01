# Phase 2G 开始 — 跨平台弹层原语

日期：2026-09-01。开始前已fetch并确认`feat/cross-platform-player-surfaces@6ecbbd8`与远端0/0同步、工作树干净；从该提交创建`feat/cross-platform-overlay-primitives`，不在main/master开发。

## 本阶段目标

- 新增原生受控`YYContextMenu`、`YYDialog`、`YYBottomSheet`与`YYToast`，不使用Material默认Dialog/BottomSheet/Menu/SnackBar。
- 保留最终合成视觉的Context Menu 224/244宽、20圆角、7内边距、30模糊，Dialog 680最大宽、30圆角、72头尾，Toast 42最小高、420最大宽与14圆角。
- Android Gallery展示Phone Bottom Sheet Fixture，Windows Gallery展示Dialog与Context Menu Fixture；所有动作只更新本页状态。
- 覆盖Hover/Pressed/Focus/Disabled/Selected/Loading、方向键/Tab/Esc、焦点闭环与恢复、130%文字及Reduce Motion/Glass。

## 已读取与校验的来源

- 主指令第7节平台适配、第16节组件清单、第31节无障碍及Phase2出口；Phone允许Dialog转全屏Route或Bottom Sheet，Windows Esc按层关闭。
- 基础HTML`.overlay`、`.dialog`、header/body/footer、`.context-menu`、header/item/separator、`.toast`、599断点以及open/close/focus/Esc脚本。
- 完整App.tsx最终`POLISH_CSS`：`.dialog`/`.now-dialog`最终30圆角、`.context-menu`最终20圆角；未发现Bottom Sheet或Toast后置覆盖。
- 既有Widgets-only Button、ControlAction、Glass、Theme、Tooltip、Gallery与Golden Harness；重新执行五份指纹/44图标/52派生产物检查和24份ZIP逐字节核验均通过。

## 准备新增/修改

- `lib/design_system/yy_context_menu.dart`
- `lib/design_system/yy_dialog.dart`
- `lib/design_system/yy_toast.dart`
- `lib/features/design_gallery/gallery_overlay_primitives.dart`
- `lib/design_system/yy_button.dart`
- `lib/design_system/yy_tokens.dart`
- `lib/features/design_gallery/design_gallery_screen.dart`
- `test/widget/overlay_primitives_test.dart`
- `test/golden/overlay_primitives_golden_test.dart`及经视觉检查的新基线
- ADR、架构、视觉矩阵、状态、README与CHANGELOG

## 风险与边界

- 本批不实现业务Overlay Manager、Route、右键/长按触发、菜单锚定/窗口避让、触觉反馈、未保存确认或业务动作。
- Toast为受控可访问状态，不内置2300ms计时；Feature以后负责排队、时长与真实操作结果，不用模拟Toast代替平台行为。
- Gallery的“播放/收藏/关闭”等文案均明确是Fixture，不调用Playback/Queue/Repository、网络、文件、数据库、平台API或持久化。
- Dialog/Sheet组件不包含真实来源表单、队列、歌单或播放设置内容；这些属于后续Domain/页面阶段。

## 出口条件

- Context Menu、Dialog、Bottom Sheet、Toast几何和最终圆角有Widget/Golden约束，44dp命中及低宽/130%无溢出。
- 菜单项动作独立；禁用/加载不触发；Tab/方向键、Enter/Space、Esc与焦点闭环/恢复有测试。
- Dialog/Sheet使用不透明Surface，Context Menu才使用局部Glass；ReduceGlass只关闭菜单Blur并保留几何。
- 新增关键Golden逐张检查，既有20张基线保持不变；完整Flutter/Node/ZIP/指纹门禁通过。
- 独立提交推送GitHub、创建Draft PR、双平台Debug成功，APK仍只由GitHub手动工作流构建并独立复核。
