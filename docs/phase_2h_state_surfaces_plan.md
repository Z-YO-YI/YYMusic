# Phase 2H 开始 — 跨平台状态与反馈原语

日期：2026-09-01。开始前已fetch并确认`feat/cross-platform-overlay-primitives@6642ad0`与远端0/0同步、工作树干净；从该提交创建`feat/cross-platform-state-surfaces`，不在main/master开发。

## 本阶段目标

- 新增原生受控`YYThemeSwatch`、`YYEmptyState`、`YYErrorBanner`与`YYSkeleton`，并实际让Gallery强调色选择使用Swatch。
- Theme Swatch保留基础HTML的30px圆形视觉、3px elevated边和1px外边界，同时使用44dp命中、键盘与Semantics。
- Empty State保留28/16内边距、24图标、10px/1.6文字；Error Banner复用notice 12/14/15几何和既有error token。
- Skeleton遵循主指令组件清单，只使用主题纯色与边界，不发明参考中不存在的渐变shimmer或假数据。

## 已读取与校验的来源

- 主指令第12节异步状态、第14节Token/Reduce Motion、第16节组件清单与Phase2出口。
- 基础HTML`.swatches`、`.swatch`、五种预设、599断点、`.empty-state-compact`、`.notice`和error badge token。
- 完整App.tsx最终`POLISH_CSS`；未发现Swatch、Compact Empty、Error Banner或Skeleton后置覆盖，不能臆造覆盖值。
- 既有Theme/Accent、ControlAction、Button、Surface、Gallery、Widget与Golden Harness；阶段开始时五份指纹/44图标/52派生产物和24份ZIP仍已通过上一阶段门禁。

## 风险与边界

- 本批不创建网络请求、自动重试、Repository状态、假搜索结果、扫描任务、加载计时器或持久化。
- `YYErrorBanner`只显示调用方提供的错误并通知可选action；Feature以后负责真实retry与错误生命周期。
- `YYSkeleton`是无梯度的结构占位，不自行启动任务或推断数据；真实idle/loading/data/empty/error归Controller所有。
- Gallery所有状态均明确为Fixture，正式业务页仍未接入。

## 出口条件

- Swatch 30视觉/44命中、Hover/Pressed/Focus/Selected/Disabled/Loading、键盘和互斥选择语义有测试。
- Empty/Error/Skeleton几何、live region、动作独立、130%/窄宽/Light/Dark/自定义白无溢出。
- 新增Golden逐张检查，既有23张保持不变；完整Flutter/Node/ZIP/指纹门禁通过。
- 独立提交推送GitHub、创建Draft PR、双平台Debug成功，APK仍只由GitHub手动工作流构建并独立复核。
