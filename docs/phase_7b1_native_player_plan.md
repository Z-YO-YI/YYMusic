# Phase 7B1 开始 — 原生独立播放页面与真实控制

2026-09-09；Z-YO-YI/YYMusic；`codex/native-player-route`，基线 `ffb83e6`。
已 fetch/pull，干净工作区；前置 7A Push 34279329106 / PR 34279334384 的源码、Android、Windows 均 SUCCESS。

## 目标与已读来源

- 将正式 `/player` 占位页替换为 Phone / Tablet / Windows 三套布局，消费唯一根 PlaybackPresenter。
- 接入播放/暂停、前后曲、随机/循环、进度、音量，以及真实已有当前队列浏览；从底栏曲目信息打开。
- 已重读完整 506 行 App.tsx 的 44 SVG / 品牌替换 / POLISH_CSS；基础 HTML 独立播放区和 immersive CSS、主指令第 18 节、既有路由/播放投影/控件。
- 指纹 5 / SVG 44 / 确定产物 52 复验通过。使用 figma-design-to-code；无在线 node，仅使用已审计本地导出，复用原始图标和现有控件，不伪造 get_design_context。

## 文件与共享 API

- 先写 ADR-076；新增 `features/player/common/player_screen.dart` 与三端 player_layout，新增设计系统受控全页播放内容，复用 TransportButton/Slider。
- AppRouter 接线独立页面与只读活动状态，ShellPlayer 接受打开回调；PlaybackPresenter.seek 新增可撤销的排队手势参数。
- 根不新增播放器、仓储或时钟；不改数据库/依赖/平台 runner。
- 新增路由/交互/尺寸/Golden 回归，更新报告、README、状态、测试矩阵与前置云端证据。

## 风险、边界与出口条件

- 页面隐藏/覆盖/零面积/卸载/切歌和布局变化撤销旧手势；已接受普通播放命令继续播放，离页不停止音频。
- Windows 始终桌面双栏；Android 依据当前宽度切换，横屏紧凑双栏、竖屏上封面下控制。小尺寸/130% 字体可滚动，保留真实状态。
- 封面采用现有明确“暂无封面”的纯色几何兜底；本批不宣称真实封面读取。播放 scale 1、暂停 .94；减少动态禁止缩放。
- 不把尚未实现的 OS 全屏、收藏/完整歌词/高级音频入口伪装成可用。当前队列按钮先打开既有真实系统队列浏览；独立 `/queue` 管理与 `/lyrics` 页、系统沉浸继续后续 7B/7C 批次。
- 严格分析、全部 Flutter/Node、针对尺寸与旧回调回归、Golden 视觉复核、生成/迁移/指纹/许可、Android 预检及 GitHub 精确提交双平台验证分别记录。
- 审查、Conventional Commit、push、以上阶段为 base 的 Draft PR；不合并/发布，不提交敏感信息或安装包。
