# Phase 6J2 开始 — 原生外观与关于设置

2026-09-09，`codex/native-settings-surfaces`，基于已 fetch/pull 的干净 `993aab2`。
前置 #62 Push 34270115448 与 PR 34270151512 均成功；这不是本批验收证据。

## 本阶段目标与来源

替换正式 `/settings` 工程占位页，消费根 AppearanceSettingsController，不创建第二份主题或存储。
已复验 5 指纹、44 SVG、52 合成产物及 ZIP 24 文件；重读完整 App.tsx、HTML 设置结构/交互及总指令。
按 figma-design-to-code 技能复用 YY 组件、原始 Sprite 和 POLISH_CSS；仅有本地导出，没有在线节点，不编造 Figma 调用。
实现外观、关于两项已支持分类。音乐源管理、平台导入/扫描、播放高级参数分别留在 Phase 9/8/7–10，不复制浏览器模拟开关。

## 文件与风险

先记 ADR-074，再接 AppRouter/YYMusicApp；新增 SettingsScreen、共用受控 Sections、Phone/Tablet/Windows 布局。
复用 YYTextField/Toggle/Swatch/SegmentedControl/Surface，添加精修设置导航圆角 11 Token。
控件操作即时生效，保存中/未保存/读取失败/保存失败/重试状态真实可见。自定义 Hex 草稿显式应用，不在每个输入字符时写库。
草稿、选区和滚动在布局切换中保留；隐藏、覆盖、零尺寸、卸载不授权旧回调；不停止根已接受的保存。
测试覆盖真实根路由、持久化反馈/失败重试、颜色校验、键盘/语义、130% 字体和三端尺寸；新增设置 Golden，不无理由改旧图。
更新 README/状态/测试矩阵、前置 CI 记录和完成报告。

## 出口条件

格式、严格 analyze、全量 Flutter/Node、生成/迁移/设计指纹/许可检查、本地 Android Debug 预检与精确 GitHub 双平台 CI。
提交前审阅与敏感信息扫描，独立 Conventional Commit、push、以 #62 分支为基线的 Draft PR；未完成构建明确标记运行中。
本批不改数据库 Schema/依赖/平台权限，不称 Phase 7–11 或正式发布已完成。
