# Phase 7E5D 开始：自建歌单条目队列菜单

2026-09-12。GitHub Z-YO-YI/YYMusic，fetch/ff-only pull后工作区干净，基线`5ec9d63766640669e16d68a3a97387c5a1e6a603`；分支`codex/playlist-queue-actions`，Stacked Draft base=`codex/catalog-queue-actions`。前置#77源码检查已通过，平台构建仍进行中，若失败先处理。

本阶段目标：自建歌单Phone/Tablet/Windows条目菜单添加下一首/添加队列，按准确PlaylistContent窗口和PlaylistContentEntry身份捕获源许可，保留重复条目与未解析/失效软引用。不修改原歌单，不自动播放。已读取来源：主指令Phase7/队列及阶段格式、已审计App.tsx NEW_ICON_SPRITE/POLISH_CSS与基础HTML、既有PlaylistContent Controller/Actions/Screen/Menu/Sections、根插入工厂与共享反馈及测试。Figma技能用于复用原生YY组件与准确SVG；本地完整导出无线上node URL，不虚构线上读取。

准备修改：AppRouter注入唯一QueueController；PlaylistContentActions增加窗口/条目许可；Screen菜单请求增加根与源许可，路由/尺寸/内容更新撤销旧请求；EntryMenu和Sections接线；README/状态/矩阵/ADR及Node。准备新增：playlist_queue_actions页面part、源许可单元、三端Widget/真实SQLite/Golden、阶段报告。

风险：播放队列ID不能复用歌单条目ID；重复TrackRef需独立新ID。未解析条目没有Track对象，仍使用其完整软引用且不可播放。窗口刷新/换组、元数据变更、根替换、隐藏/零面积/关闭/尺寸变化撤销旧回调；跨正常尺寸保持菜单但重捕获当前许可。失败留根、显式同ID重试，成功提示不可被旧回调清除，已接受SQL由根排空。更正旧菜单“只修改此歌单”的说明以明确队列和歌单独立。

出口：重复/未解析/失效条目、三端实际输入与键盘、旧窗口/尺寸/路由/菜单回调、忙态/失败/关闭与准确SQLite保存/回滚/歌单不变；完整测试/格式/分析/生成/迁移、源指纹和许可，仅更新受影响Golden并逐张查看。Android本地预检和GitHub新SHA双平台构建分别记录，无Schema/依赖/平台/原资产变更。不合并/发布/付费；系统歌单入口和Phase7其余、Phase8–11后续推进。

实施补充：新回归发现旧关闭菜单回调在卸载后可调用setState，dispose内清空请求与返回焦点后通过；惰性200条窗口测试用实际滚动定位而非估算最大偏移。前置#77两组精确CI均SUCCESS，已回填其报告与PR；不作为本批新SHA验收。
