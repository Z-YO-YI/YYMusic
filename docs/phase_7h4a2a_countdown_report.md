# Phase 7H4A2a：倒计时展示组件

2026-09-13；基线747bf94，fetch与ff-only确认最新；分支codex/sleep-countdown-ui，Draft目标codex/sleep-remaining-projection。先计划/ADR109，再共享组件与独立测试。前置747bf94的GitHub运行34729425639和34729433659均已确认success。

SleepRemainingText借用Presenter，使用独立子组件状态和每秒一次的只读刷新。每次从真实根截止重新取值，不按tick减一；宿主active/isCurrent许可失效、应用后台或卸载时停止刷新，重新激活后校准。业务变更撤销旧刷新；零显示00:00并停止周期刷新，null不显示。根业务Timer、队列、音频、原选择和动作许可均不由显示更新改变。复用既有caption/secondary样式，非liveRegion，避免每秒自动播报。

8项新增Widget测试覆盖时钟前跳/回拨、隐藏与恢复、宿主失效/异常、后台恢复、取消重设、过期夹零和卸载；验证无业务通知/音频命令、原动作仍有效。初次测试编译因取消接口名称错误失败，修正为已有setSleepTimer(null)；后台测试改为先inactive再paused/resumed，因为paused禁止绘帧，不能要求其立即重绘隐藏文本。

验证：完整1980 Flutter测试通过（100秒）；153 Node通过；545 Dart文件格式零修改；严格静态分析0问题（14.7秒）。211既有Golden无更改。四份设计源文件SHA256与历史审计一致，24解压条目与ZIP逐字节一致；未忽略App.tsx的NEW_ICON_SPRITE/POLISH_CSS。无Figma节点链接，使用本地审计导出并复用现有设计样式。

Android Debug本地预检成功（16.7秒），48打包资产和音频许可校验通过；保留Java native-access警告。本批无schema/依赖/生成接口变更，未重跑codegen，无本地Windows编译或新设备安装/出声验收。新提交的Android/Windows GitHub构建需单独确认，不以父提交成功代替。

**这是独立可验证的组件阶段，不是正式界面倒计时完成。** 尚未修改SleepSettingsPanel，用户可见布局不变。A2b须绑定路由/TickerMode/焦点/关闭许可、固定生产测试根时钟并审查跨平台大字号/短窗口Golden。随后继续未过期恢复、平滑暂停、真实输出设备及其余上线验收。不自动合并或发布Release。
