# PR 草稿：Cross-platform overlay primitives

Head：`feat/cross-platform-overlay-primitives`；Base：`feat/cross-platform-player-surfaces@6ecbbd8`；Draft PR待目标提交推送后创建。不自动合并、不改写历史。

## 变更

- 新增Widgets-only受控`YYContextMenu`、`YYDialog`、`YYBottomSheet`、`YYToast`，实现最终几何、焦点、键盘、语义和状态。
- 仅Context Menu使用有界Glass；Dialog/Sheet保持不透明Surface。Phone Sheet明确为平台适配，Toast显隐与时长由调用方所有。
- Android/Windows Gallery新增本地Fixture；正式Shell不接假Overlay/Route，不引入新依赖、权限或用户数据访问。
- 新增6项Widget、3张130%弹层组件Golden，以及ADR、架构、视觉、映射、矩阵和阶段文档。

## 测试

- 75个Dart文件格式无变更，严格分析0问题；完整104项Flutter通过，包含23张Windows宿主精确Golden，三张新增图已逐张视觉审计且旧20张不更新。
- 28项Node、五份源指纹/44 SVG/52项派生产物与24个ZIP entry逐字节核验通过；云端push/PR/手动工作流和APK证据待提交后补入。

## 影响与未验收项

影响范围限于设计系统弹层原语、跨平台Gallery Fixture、测试与文档；正式路由、业务Overlay Manager、Controller、Repository和CI合同不变。

本机Windows C++工具链仍受UAC限制。网页截图对照、Windows本机安装/系统无障碍/GPU性能、Android真机、右键/长按与锚点避让、Toast计时/队列、未保存确认及真实业务动作均未验收。
