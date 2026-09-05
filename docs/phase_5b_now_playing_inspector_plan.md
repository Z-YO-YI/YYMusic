# Phase 5B 增量 — Windows / 宽屏平板正在播放面板

2026-09-05，`codex/now-playing-inspector`，基于已 fetch/pull 的 `05f818d`（Draft PR33）。
这里的 5B 是仓库增量编号，覆盖主指令 Phase5 Windows/Tablet；不等同于主指令5B手机子项已全部结束。

已重读：主指令 Phase5/断点/Inspector、基础 HTML 758–786 和 2406–2417、App.tsx now-artwork
及 transport-button 后置规则。沿用完整合成参考与原图标，不改其指纹。

目标：替换 Windows >=1440 的320dp、Android横屏 >=1200 的260dp详情占位，显示真实当前曲目、
来源类型、状态和队列数量；使用现有26dp封面占位及完整字号/阴影，连接根播放、前后曲、模式和
进度。面板纵向独立滚动，260dp/130%/短窗口不溢出，窄断点隐藏面板但不丢播放状态。

设计系统新增受控面板，ShellPlayer 用同一绑定层渲染 Inspector；不复制 Controller、计时器或
队列算法。原稿歌词/设备/队列扩展业务仍按 Phase7/10 后续接入，不放空回调或假歌曲/在线状态。
当前无 Artwork Gateway，真实图片加载未完成，继续明确使用占位。

测试：双表面同步控制、失效 Seek/取消、空/加载/失败、长标题/字号/短高度、宽窄隐藏恢复；
新增3张面板Golden，旧受影响整页基线逐一确认后更新，其余不变。全量测试/分析/源码/打包审计，
阶段提交、GitHub push/PR；前置05f818d若CI失败先修复。窗口Gateway和完整业务页另批继续。
