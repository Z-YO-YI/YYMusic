# Phase 7H4A2：倒计时展示生命周期

A2b开始于2b57143：共享面板在状态文案后绑定SleepRemainingText，active来自现有可见/关闭状态，isCurrent复用当前generation许可。DependencyGraph仅透传可选playbackClock（默认保持根生产时钟），Golden测试显式固定该时钟，不修改真实到期逻辑。新增面板刷新/旧动作/隐藏恢复测试，审查所有受影响Golden后更新，完整检查后提交。

基线747bf94；先完成A2a可独立验证的共享展示组件，再A2b绑定原面板并审核跨平台截图。A2a不声称用户界面已经接入。

组件借用PlaybackPresenter，监听业务变更，只在宿主声明active且isCurrent有效、应用前台时每秒查询真实剩余秒数。刷新Timer只属于展示，不执行播放命令；隐藏/关闭/后台取消刷新，恢复立即校准，不按tick减一。旧回调用revision撤销。null不显示、零显示00:00并停止周期刷新，等待根状态通知。读屏不是liveRegion。

宿主接入时必须把路由、TickerMode、焦点和关闭状态投影到active/isCurrent；本组件不能推测业务可见性。文本刷新只重建子组件，不撤销父面板已生成的操作许可。先验证可控时钟、取消/重设、隐藏/后台/卸载、无业务副作用，再接入面板、固定生产测试时钟、审查Golden变化。
