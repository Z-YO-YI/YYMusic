# Phase 6G3 — 搜索结果详情入口

2026-09-06，基于fetch/pull后的`7fe2e21`，分支`codex/search-detail-navigation`。
Phase6G2的push33989357683/PR33989396295两组checks/Android/Windows成功，先回填证据。
继续使用已审计完整App.tsx、NEW_ICON_SPRITE/POLISH_CSS与基础HTML；原件不变，不调用浏览器或Figma服务。

## 范围与顺序

1. 搜索专辑/艺人结果提供明确原生“查看专辑/查看艺人”按钮，使用已有AppNavigation完整引用。
2. 更新已过时的“详情仍在开发”说明，不改变Enter首条播放、筛选、防抖、历史写入或根数据合同。
3. 复用Phase6G2详情路由/三端布局/唯一播放器。详情归属音乐库，返回仍恢复原搜索页面；
   不引入新的URI参数、模型extra或第二详情实现。
4. 验证同名同ID不同来源、来源标识转义、连续详情返回、保持搜索输入/筛选/结果/滚动与键盘焦点，
   点击详情不隐式写历史或播放，已移除内容进入真实空态，覆盖搜索时撤销未完成播放意图。

改动文件：search_sections.dart、测试夹具可选注入浏览接口、新导航Widget回归、对应Golden/Node门禁
及README/实施状态/矩阵/报告。不修改Domain/Data/Schema/播放器/平台或公开导航合同，不新增ADR。
既有搜索六张Golden按实际说明文字/按钮变化更新并逐张查看，其他页面基线保持不变。

## 风险及出口

不能把来源类型local/rest当成sourceId、不能从显示名称猜关联；搜索结果被删除不应打开同名替代品。
新按钮必须在窄宽130%字体可达，键盘可操作且返回焦点正确；不让点详情触发搜索Enter播放。
全量Flutter/Node、格式/分析、ZIP/许可/生成代码、Android本机构建后审查提交推送，建立stacked
Draft PR并核验GitHub双平台；不自动合并或发布。无新音频实机验收，HTML截图限制仍保留。
