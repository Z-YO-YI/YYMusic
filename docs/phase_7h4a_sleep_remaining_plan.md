# Phase 7H4A：睡眠剩余时间（下一增量）

来源：总指令§26及[H4能力审计](phase_7h4_capability_audit.md)。此文为计划，不是已经实现。

1. 根PlaybackController沿用注入_clock，以deadline.difference(now.toUtc())投影剩余时间；过期夹零，off/entry-end/failed不伪造分钟倒计时。保留原duration选中项，不靠取整的剩余值反推15/30/60。
2. 业务到期仍由唯一根one-shot调度器负责。展示刷新只能读取事实，不能另设会暂停音频的Timer；定义根Presenter可见订阅/释放契约后再做UI，隐藏、覆盖、关闭要停止无意义刷新，重新显示立即校准真实截止时间，不按tick累计时间。
3. 显示明确剩余分钟/秒，状态变化向读屏播报，但避免每秒liveRegion轰炸。手机/平板/Windows与大字号/短窗口验证；无论隐藏或暂停都不延长绝对截止。
4. 可控时钟测试：刚设置、边界取整、向前/向后时钟变化、延迟唤醒、过期夹零、重新设置、取消、根关闭、旧可见订阅失效；Widget确认文本刷新不会改变根队列、播放、选中项或睡眠generation。
5. 本曲结束继续显示准确条目意图，不用曲目duration-position冒充可靠墙钟；未来流媒体duration不可靠也不假报剩余秒数。

先细化ADR/共享API，再实现测试和生产绑定，运行完整检查后commit/push/Draft。此批不顺带做持久化、淡出、设备枚举或依赖升级；H4B/H4C后续分别验收。
