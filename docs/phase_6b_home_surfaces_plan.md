# Phase 6B — 原生首页组合计划

2026-09-05，`codex/home-surfaces`，fetch/pull 后基于 `b2e561d`，不在 main 开发。
按主指令 17.1/Phase6 的 Home 首位继续；参考基础 HTML 2144–2229 及 App.tsx
NEW_ICON_SPRITE、POLISH_CSS 的 Hero28/双阴影/标题字距，设计输入保持不变。

- 根作用域 HomeController 读取 Repository，独立最近添加/历史/来源的 Loading、Empty、Error；
  7天最近添加最多20条，历史最多20条按完整TrackRef解析，不扫描整个曲库到UI。
- 今日精选优先可用历史，其次首批本地曲目。无数据不制造歌曲、连接成功、曲库计数或封面。
- Phone 单列、Tablet 横屏主从组合/竖屏栅格、Windows Hero+内容双栏，共用投影和唯一播放器。
- 首页播放复用已有队列条目，否则追加后播放，不静默覆盖已有队列；禁用不可用曲目，显示安全错误。
- 来源卡仅显示名称/类型/持久状态，不显示endpoint、路径、credentialRef或Header；来源管理入口
  暂引导到设置骨架，不宣称REST配置完成。提供明确刷新、音乐库入口和开发设计预览。
- 路由/Shell切换保存滚动，不因断点新建Controller；关闭先停止监听并排空首页读取，再关闭存储。
- 以Controller竞态/故障隔离/播放合同、实际Drift接线、三端Widget/Golden及全量门禁验证。
  原有包含首页的整屏Golden会有预期变化，必须逐张检查，不能盲目更新全部基线。

本批不实现导入/REST、全屏页面或发布，不把Fake播放/Golden当原生播放验收。Phase2网页截图
对照缺口仍保留，不绕过浏览器安全拒绝。
