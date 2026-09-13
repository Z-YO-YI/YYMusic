# Phase 7H3B：侧栏队列摘要与入口

2026-09-13；基线6d357add5d4dadd0c10b1d01d25755dd8c89e3a7，fetch/ff-only pull且干净；分支codex/inspector-queue-access，Draft base codex/inspector-queue-summary。先[计划](phase_7h3b_inspector_queue_plan.md)/ADR106、受控API，再生产绑定。

## 实现与设计

- Inspector显示根摘要totalCount/currentOrdinal，文本为当前第N首、按列表顺序；无当前条目明确说明，空队列保留空态。清除预留开发提示，不将重复曲目或随机顺序误解释为下一首。
- 原queue-section-heading/queue-open通过YYButton quiet实现展开入口，Wrap保留130%字号下换行和触控目标。AdaptiveRoot传原openSystemPlaylist(queue)，ShellPlayer走既有_queueAction一次性导航许可，不新建队列、路由、读取会话或音频实例。空队列也能打开空队列页。
- 使用设计转代码技能复用本地导出组件；无线上节点，沿用已审计HTML2416和App.tsx NEW_ICON_SPRITE/POLISH_CSS，不虚构线上Figma返回或模拟曲目。当前是只读列表摘要+完整队列页入口，不声称已经在侧栏渲染真实下一首元数据列表。

## 交互与视觉验证

14新增Widget覆盖Windows/Android空与非空真实点击、原根队列与音频命令不变、返回和旧回调、重排/清空摘要更新、隐藏/零面积/往返/歌词覆盖/卸载、短窗口滚动、同帧重复、菜单覆盖恢复以及键盘Enter。系统队列Fixture清空在tester.runAsync正确区执行，避免跨区等待；未遗弃关闭或关闭不变量。

3新增130%生产Golden：Windows1440×1000浅色、Android1280×900深色、Windows1440×600深色空队列，实际滚动到入口，逐张查看。首轮测试绘制标志恢复过晚触发绑定不变量，改为测试体try/finally及时恢复，并严格复验通过。

22张旧截图逐张审核旧/新/差异图：变化为页脚摘要、44px触控入口、内容高度带来的侧栏滚动位置及相关绘制；3张为独立Inspector预览，其余为生产页面/弹层背景。仅更新相关测试基准；186旧图不变，共211。没有放宽像素阈值、删除截图测试或用新图遮盖来源排序问题。

## 验证结果

- 完整1954 Flutter通过（93秒），含211 Golden；最终参数顺序兼容调整后新增14Widget+3Golden再次通过。151 Node通过（15.6秒），既有Node入口门禁依赖命名参数顺序，恢复原顺序后通过，未弱化检查。
- 542 Dart文件格式零改动，严格分析0问题（23.9秒）；build_runner26秒、Drift通过，生成/schema无差异。
- ZIP/App.tsx/基础HTML/总指令四份SHA256与原审计一致；24解压条目逐字节匹配，音频许可源指纹通过。
- Android Debug18.4秒；48资产、完整音频许可、v2单签名者通过。APK232265242 bytes，SHA256 `2121c4be831a9839a0d9dc227c284b8f14687888e65598e1087e29eee4dd4ca5`；Java native-access警告保留，构建产物不入库。
- 无新增设备安装/出声、多屏/DPI或本地Windows编译验收；Debug不等于上线。

## GitHub与后续

前置6d357ad的[push34726594415](https://github.com/Z-YO-YI/YYMusic/actions/runs/34726594415)/[PR34726626442](https://github.com/Z-YO-YI/YYMusic/actions/runs/34726626442)均SUCCESS，已回填Draft #98，确认此前Windows测试排序修复在云端有效。本批新SHA另验，精确提交/PR/运行链接记录在Draft，不自动合并或Release发布。

主要文件：adaptive_root.dart、yy_now_playing_inspector.dart、shell_player.dart、Widget/Golden/Node、25张新增/审核更新截图及README/状态/矩阵/ADR/计划/报告/出口审计。

下一项审计输出设备及其他播放偏好的真实后端能力和语义，不复制HTML模拟设备，不把存储假开关当作完成。Phase7整体、Phase8真实导入至Phase11设备/发行仍未完成。
