# Phase 7E5C 开始：专辑/艺人详情队列菜单

2026-09-12；已确认GitHub Z-YO-YI/YYMusic，fetch及ff-only pull后基线`4f508195f9a1977a23f44895c8437e4778ef246b`，工作区干净；分支`codex/catalog-queue-actions`，Stacked Draft base=`codex/library-queue-actions`。前置#76两组云端仍在运行，失败先处理，不计作本批通过。

目标：两类详情的三端原生歌曲菜单接下一首/添加队列，借唯一根工厂/提交/反馈，不自动播放。来源已读：完整审计的HTML与App.tsx NEW_ICON_SPRITE/POLISH_CSS、主指令Phase7/队列/阶段格式、现有详情控制器/菜单/路由/测试及E5B实现。Figma输入是本地导出，继续用精确原图标与YYContextMenu，无在线node URL，不虚构线上读取。

准备修改：AppRouter根注入；CatalogDetailController准确Track/读取意图许可；Screen生命周期和反馈接线；TrackMenu与Sections；受菜单顺序影响的键盘测试；README、状态/矩阵/ADR与Node门禁。准备新增：详情queue_actions part、许可/Widget/真实SQLite回归、必要Golden与阶段报告。

风险：保留原详情菜单跨布局可见和同一session/滚动，但尺寸变化必须使旧回调无效并重新捕获当前根；刷新、路由覆盖、零面积、关闭、艺人Tab切换撤销旧意图；正常选择关闭菜单不能撤销提交，已接受SQL排空；歌单选择器返回恢复许可。缺失文件仍不可播放，仅可添加软引用。失败留根、显式重试，成功提示不复活旧页面或抹除新提示。

出口：两类详情三端实际手势/键盘，重复TrackRef及下一首/current不变，旧菜单/刷新/布局/路由/Tab/关闭、忙态双点、失败跨页同ID重试、SQLite回滚/存储；完整测试、严格分析、格式/生成/迁移和原资产许可；只更新受影响Golden并逐张验看。Android本地预检与GitHub新SHA双平台构建分别记录。无Schema/依赖/平台改动，不合并/Release/付费。其他歌单入口及Phase8–11仍待后续。

实施补充：前置#76两组云端最终均SUCCESS，已回填。增加两个菜单项使短横屏需滚动至关闭项，保留原菜单跨布局测试并增加滚动可达检查；SQL测试用已保存UTC时间，并在finally内排空异步session和数据库，保留严格定时器检查。
