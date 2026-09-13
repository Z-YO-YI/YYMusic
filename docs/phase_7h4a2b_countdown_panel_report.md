# Phase 7H4A2b：正式面板倒计时

2026-09-13；基线2b57143617fb5c1e7941411edfa0c2390436bc31，fetch/pull --ff-only确认最新且工作区干净后建codex/sleep-countdown-panel，Draft base codex/sleep-countdown-ui。先扩展A2计划，再生产绑定与测试。父提交push34730407355/PR34730418800均已核实success。

SleepSettingsPanel将SleepRemainingText放在原状态文案后，借用同一Presenter；使用既有可见/关闭状态和generation许可，倒计时子组件刷新不会撤销选项按钮。播放页、歌词页、底栏、Inspector的唯一原生设置弹层自动获得显示能力，无新路由/播放器/WebView。原定时选中项不变，本曲结束/关闭/失败不伪造剩余分钟。恢复可见后从绝对截止读取，不延长定时。

DependencyGraph新增可选playbackClock并原样传给唯一根；默认生产时间行为不变。LyricsFixture/fullscreen生产测试宿主透传该时钟，分钟定时Golden显式固定UTC，以消除构建耗时引起的秒数波动，不放宽像素阈值。

新增6项面板Widget（安卓/Windows×TickerMode、焦点、关闭）：61秒后13:59、原15分钟仍选中、旧30分钟按钮仍有效、隐藏期间截止不变、恢复校准为27:57，无音频命令。3新Golden验证流逝时间，1新Node约束展示层只读及宿主许可。已有面板和生产播放页定向42项先通过。

先运行旧Golden，12处差异均由分钟定时多一行文本及弹层高度/阴影/滚动位移引起；三页旧/新/差分拼图逐张审查后更新，不改8张关闭/失败/本曲结束截图。新增手机/深色平板/短Windows的13:59截图逐张查看，130%字号文字与操作区可用。全项目214Golden：12旧图更新，199旧图保持原字节，3新增。

验证：完整1989 Flutter测试通过（109秒）；154 Node通过（27.7秒）；547 Dart文件格式零修改；严格分析0问题（32.6秒）。build_runner25秒、Drift迁移通过，生成/schema无差异。四份设计文件SHA256与历史一致，24ZIP条目逐字节匹配；沿用App.tsx的NEW_ICON_SPRITE/POLISH_CSS审计，未更改原设计资产。无在线Figma节点，按技能复用已审计本地导出与现有caption/secondary样式。

Android Debug18.3秒，48资产、音频完整许可、v2单签名者验证通过。APK232270343 bytes，SHA256 `866e1582dbd4d3fa8050902d0d64267b3d01e2dc4421faff6ec707c4c6fac8a5`。保留Java native-access警告；APK和临时审查图不提交。不新增本地Windows编译、设备安装/出声或发布验收；新SHA的Android/Windows GitHub构建另行核实，父阶段成功不能代替。

主要文件：sleep_settings_panel.dart、dependency_graph.dart、测试时钟宿主、倒计时Widget/Golden/源检查、README/ADR/状态/矩阵/计划。下一阶段H4B持久化与未到期恢复，之后H4C平滑暂停；输出设备/其他偏好及Phase8–11仍待验收，不自动合并或发布。
