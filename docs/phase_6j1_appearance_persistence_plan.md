# Phase 6J1 开始 — 外观设置持久化

2026-09-09，`codex/appearance-settings-persistence`，基于fetch/pull后的干净`b1adbce399ba1a798b2d0b65c2ecb2f11c9ccbd6`。
前置PR #61的源码与Android已成功，Windows仍运行；优先处理任何失败，不借用前置CI验收新代码。

## 目标与来源

设置页面前先接通真实外观存储：显示模式、五个预设/自定义色、玻璃和减少动态效果；复用现有app_settings表、同一根YYAppearanceController。
已读取主指令设置持久化/安全/阶段约束、完整App.tsx的44 SVG/两品牌替换/POLISH_CSS，以及HTML settings页面和主题/Toggle脚本。
复验5指纹/44图标/52产物。figma-design-to-code技能用于保留既有视觉Token与原始资产；只有本地导出，无在线node，不捏造get_design_context。

## 文件与风险

新增纯Domain外观模型/仓储合同、Drift外观仓储和根AppearanceSettingsController；修改AppDataServices、DatabaseAppDataServices、DependencyGraph、YYAppearanceController原子恢复API。
ADR-073先于共享API改动；更新Fake、单元/真实SQLite/启动与关闭回归、工程门禁、README/状态/矩阵/完成报告。
只读写白名单五键，不读取其他设置或任何凭据；单事务保存整个快照，未知/损坏值不默默覆盖，错误安全并可重试。
启动读取不写默认值；用户早到变更不被晚返回覆盖；连续变更串行合并，关闭排空已接受保存后关共享数据库，保存失败不停止音频。

## 出口

格式、严格分析、全量Flutter/Node、生成/迁移/指纹/许可、Android本地预检及精确GitHub双平台构建；104旧Golden不得无理由更新。
本批只交付可验证的外观存储/根接线，不把开发预览页称为正式设置页；下一批Phase6J2接原生设置页的保存/失败/重试状态。无Schema/依赖或平台权限变更。
