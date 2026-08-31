# 实施状态

更新：2026-08-31。本轮只执行 Phase 0，不是完整客户端交付。

| 阶段/能力 | 状态 |
| --- | --- |
| Phase 0 输入身份、源码审计、合成与映射 | 已形成可复核产物，结果见 phase_0_report.md |
| Phase 1 Flutter 工程骨架 | 未开始 |
| Phase 2 Token/图标/组件 | 只有 SVG 和映射计划；未接入 Flutter |
| Phase 3 Domain/数据库/状态 | 未开始；只有边界决策 |
| Phase 4 双平台音频 | 仅 POC 计划；没有真实播放验证 |
| 后续页面、歌词、导入、来源、平台集成 | 未开始 |
| 浏览器参考截图 / Computed Style | 未运行：file: 导航被安全策略阻止 |
| Flutter format/analyze/test/build/Golden | 未运行：Flutter/Dart 不在当前 PATH，且没有平台 runner |

## Phase 1 的前置条件

1. 明确下一阶段授权以及旧 Sonic Gallery 原型的迁移/归档方案。旧文件仍在本地，不能以新骨架覆盖；应先在独立阶段保存可恢复历史，再按范围迁移。
2. 确认 Flutter SDK、Windows 构建工具、Android SDK/设备；运行 flutter doctor 并记录可用平台。不要把 Phase 0 的 Node 工具通过当作 Flutter 构建通过。
3. 按所选 SDK 重新验证候选依赖兼容性，分阶段添加并提交 lockfile；音频后端仍等待双平台 POC。
4. 建立平台优先的实时 LayoutClassifier、三个空 Shell 和共用根依赖图。不要提前一次生成所有业务页面。
5. 为后续视觉验证准备获准且可访问的预览环境；遵守 Browser 技能边界，不绕过本轮 file: 拒绝。参考 screenshot 与 Flutter Golden 必须分别记录。

## 仓库边界

开发分支：docs/phase-0-design-audit。初始 origin 无 refs，不存在可拉取的 main/master。GitHub 同步以本轮任务提交与远程分支一致为准；未跟踪的旧原型仍仅在本机，不声称整份目录已同步。

本阶段不创建空 main 来制造 PR 基线；首次推送没有独立目标分支时不创建 PR。提交号和实时同步状态通过 git log / git status / git ls-remote 核验，最终交付消息报告实际结果。
