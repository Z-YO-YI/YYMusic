# Phase 7E3 — 独立原生队列页面

2026-09-12；分支 `codex/native-queue-route`，fetch/pull 后基线 `9a05089e9ef20bca2730bca5d5e5d81b7da3af91`，Stacked Draft PR base=`codex/queue-edit-feedback`。前置 E2 的 push 34302430226 / PR 34302434100 均 success。

目标：新增 `/queue` 原生页面，手机整页、平板横向布局、Windows 有界桌面面板，复用 YYQueueTile、YYDialog/BottomSheet、原始 SVG 与根队列编辑反馈。准确播放重复条目，上下移动、不可用项移除、清空确认、错误知悉/显式重试，有界读取及跨组浏览。拖拽和更多入口后续单独验收，不将本增量称为完整 Phase 7。

依据：主指令 20/Phase7/38–39、HTML queueOverlay/renderQueue，App.tsx 的 NEW_ICON_SPRITE 与 POLISH_CSS（队列 artwork 圆角 10 等）；四源指纹已复核。使用 figma-design-to-code 技能复用已有设计组件；输入为本地完整 Figma Make 导出，没有在线 node URL，不虚构 get_design_context。

文件：queue/common 页面投影绑定/页面/内容、三个布局、AppRouter/根注入、YYQueueTile 独立管理可用性、SystemPlaylistController 只读队列刷新、单元/Widget/Golden/Node、README/状态/矩阵/报告。

风险：数据库通知先于根发布、重复歌曲与同值替换、队列切换/离页/尺寸变化后的旧确认、停止后 SQL 失败、页面关闭后错误保留、大队列与缺失元数据、130% 字体及窄屏。只保留根快照身份标签，不复制队列；投影刷新不可撤销已接受的准确条目播放。确认当前项移除/清空会停止，不自动播放邻项。

出口：目标与完整测试、严格分析、格式/生成/迁移、源与许可门禁、Android 本地预检；审查无敏感数据后提交/push/Draft PR，GitHub 对精确新 SHA 构建双平台。无合并、Release、付费操作或手动原生诊断。新安装仍为空库，真实导入留 Phase 8。
