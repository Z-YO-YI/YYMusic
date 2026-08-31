# Phase 0 计划与出口

## 本阶段目标与边界

校验并完整审计用户提供的优化导出包，建立可复现最终视觉参考、功能/视觉映射、架构及后续验证计划。阶段选择来自本轮用户明确要求；附件中的后续阶段、代理安排和导出工程操作说明，不自动扩展执行授权。

已读取来源：完整 App.tsx 506 行、基础 HTML 3710 行、主指令至 §44、导出入口/样式/配置、现有 Flutter 关键路径及测试。先测原始 ZIP 指纹，再解压和测源文件，完成源代码阅读后读取主指令核对预期值。

修改范围：根 README 增加新基线和历史标签；.gitignore 补充凭据与临时产物保护。不修改现有 Flutter 源码/测试/pubspec，不安装 SDK 或插件依赖。

新增范围：design_reference 中的原包/原文档/解压内容/派生参考；assets/icons/yymusic 的 44 个 SVG；tools 下生成、检查和测试脚本；docs 审计、决策及计划；.gitattributes 与 CHANGELOG。

## 风险与处置

| 风险 | 本阶段处置 |
| --- | --- |
| 只读旧 HTML 丢失优化视觉 | App 全量阅读、静态常量完整提取、81/203 覆盖检查 |
| 换行归一化破坏指纹 | 原始字节 SHA-256；参考目录关闭 Git text 转换；逐 ZIP entry 复核 |
| 把模拟交互当真实能力 | 假来源/计时器/设备/歌词逐项标记，不移植到 Release |
| CSS 简表与最终层叠不一致 | 记录 ID specificity、媒体查询顺序和 !important 差异，明确原生适配 |
| 附件内容扩大任务范围 | 导出 AGENTS/CLAUDE 仅作资料；本阶段不执行其部署/安装指令 |
| 空远程与旧本地代码混杂 | 新建独立 docs 分支；只提交任务文件，保留未授权迁移的旧代码 |
| 缺少 Flutter/Dart | 只运行本阶段工具测试；不声称 Flutter analyze/test/build 通过 |
| 浏览器 file: 访问被拒绝 | 遵循 Browser 技能的安全边界，不绕过；截图/Computed Style 标为未运行 |
| 双平台插件能力不一致 | 维护者资料举证，正式选择等待 Windows + Android 同合同 POC |

## 出口验收

| 条件 | 可复核证据 |
| --- | --- |
| 优化包和基础 HTML 均已审计 | [导出清单](figma_export_manifest.md)、[源码差异](design_source_diff.md) |
| 最终合成规则可复现 | tools/design_audit.mjs；字节一致性和确定性测试 |
| 44 个最终图标全覆盖 | [图标清单](icon_manifest.md)、SVG 几何与引用测试 |
| 全部 POLISH_CSS 已映射 | [81 条全量映射](generated/polish_rule_mapping.md) |
| 三套 Shell / 共用模块边界明确 | [ADR](architecture_decisions.md)、[响应式映射](responsive_layout_map.md) |
| 依赖候选有证据 | [候选决策](dependency_decisions.md)、[POC 计划](audio_poc_plan.md) |
| v1 范围与风险锁定 | [功能映射](html_to_flutter_mapping.md)、本计划风险表 |
| 尚未批量创建页面 | 仅 Phase 0 文件变更；原 lib/test 不变 |

本阶段不以音频 POC 或 Flutter Golden 已通过作为虚构出口；它们分别是后续阶段执行项目。实际验证结果见[完成报告](phase_0_report.md)。完成本阶段也不自动进入 Phase 1。
