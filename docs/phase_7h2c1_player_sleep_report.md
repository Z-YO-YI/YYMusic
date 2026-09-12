# Phase 7H2C1：正式播放页睡眠设置入口

2026-09-13；基线d039bb064740d450a11553ab200fcda1df558137，已fetch并ff-only pull核对最新；开发分支codex/player-sleep-settings，Draft base codex/native-sleep-settings。沿用[计划](phase_7h2c1_player_sleep_plan.md)/ADR101分阶段实现，不改默认分支。

## 实现与边界

- 正式/player标题栏复用YYButton与原i-more资产打开SleepSettingsPanel；未注入回调的孤立预览不增加入口。AppRouter拥有唯一RawDialogRoute，面板借既有PlaybackPresenter，不新增播放器、计时器或平台真值，无WebView。
- 重复打开被拒绝；路由实例、拥有者路径与生命周期共同限制操作。离开页面先撤销权限，再于帧后准确移除该弹层，不能误pop新页面。关闭、遮罩、Esc与返回只关闭设置，不取消根定时，也不自动恢复音频。
- 主题/尺寸实时继承；Tab/Enter打开、Tab/Space选择、Esc恢复原焦点。非控件Space被弹层消费，不穿透全局播放快捷键。切歌后旧本曲结束动作失效，新动作绑定新queue entry。
- 仅接入正式播放页；歌词/底栏/Inspector入口及其他真实播放设置仍待后续H2C增量。新装应用真实音乐导入、后台媒体能力与发行验收尚未完成，不能视作日用/上线版本。

## 设计审核

使用Figma设计转代码技能的复用规则；无线上节点，继续已审计本地导出，不宣称调用线上设计上下文。原HTML nowOverlay使用i-more，最终图标与样式遵循App.tsx NEW_ICON_SPRITE/POLISH_CSS；源ZIP24条目逐字节验证通过，Node指纹门禁核对ZIP/App/HTML/总指令。

新增4张生产路由Golden：手机390×900、横屏844×390、暗色平板800×1000、Windows1440×1000，均130%字号且开启阴影，全部逐张查看。横屏正文可滚动，ensureVisible后实际点击30分钟并断言根状态，截图展示滚动后的正文，不把裁剪误作不可访问。

首次严格Golden回归出现15处预期差异：8张native_player、4张player_favorite、3张fullscreen。逐张对比新旧标题栏，并计算整图像素差异边界，全部在y=14–58标题栏内；仅新增更多按钮及相邻标题位置调整，正文无变化。只更新这15张旧图；179旧图不变，新增4图，合计198，未放宽像素阈值。

## 验证

- 新增17项真实App Widget测试与4项Golden；完整Flutter **1859通过，88秒**；Node **146通过，28.5秒**。
- 严格分析 **0问题，11.4秒**。首次格式检查发现新增Golden断言排版差异，格式化后 **531文件零改动**。
- build_runner **12秒**，Drift迁移通过，无生成/Schema漂移。
- Android Debug **17.1秒**；48项资产、完整音频许可、v2单签名者验证通过。APK **232257834 bytes**，SHA256 `985db86bef0067490c907b20409cfd7e96a7c93d938b72ef788599565d5b5dfa`。Java native-access警告保留，构建产物不提交。
- 无新增设备安装/出声、本地Windows编译或发行验收；双平台云端按本批新SHA另验，不能用本地测试代替。

## GitHub

前置d039bb0的[push34719698577](https://github.com/Z-YO-YI/YYMusic/actions/runs/34719698577)与[PR34719716804](https://github.com/Z-YO-YI/YYMusic/actions/runs/34719716804)均已SUCCESS。本批提交、Draft PR与新云端运行在提交后的PR记录；不自动合并或发布Release。

主要变更：app_router.dart、sleep_settings_route.dart、player_screen.dart、Widget/Golden测试、19张新增/审核更新基准、player_sleep_settings.test.mjs及开发文档。
