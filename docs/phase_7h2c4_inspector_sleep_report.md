# Phase 7H2C4：侧栏睡眠设置与窄屏可达性

2026-09-13；基线4784cba69b7adecbc01c67920f836f3f4a2047e0，已fetch/ff-only pull父分支且最新。分支codex/inspector-sleep-settings，Draft base codex/shell-sleep-settings；遵循[计划](phase_7h2c4_inspector_sleep_plan.md)/ADR104，保留分阶段开发。

## 实现与设计依据

- YYNowPlayingInspector新增可选onOpenSettings；顶部原i-more与下方原i-device共用动作。AdaptiveRoot将原完整URI闭包传入Inspector ShellPlayer，沿用_navigationAction的一次性生命周期许可和根唯一弹层，不新增播放器、Timer、数据库或WebView。
- 手机、平板竖屏、840px及500px Windows保留原布局，通过实际点击曲目信息→原生播放页→设置验证可达；不挤入设计没有的新按钮。
- 使用设计转代码技能复用项目组件及原导出图标。没有线上Figma节点，继续已审计本地导出；HTML2407/2414的入口结合App.tsx NEW_ICON_SPRITE/POLISH_CSS，未仅取旧HTML。四份源文件SHA256与既有审计一致，24个解压条目逐字节匹配ZIP。

## 验证与视觉审计

- 新增18 Widget：Windows/Android双入口真实点击、与底栏重复请求、根意图/旧选择、短窗口滚动、四类窄屏路径、隐藏/零面积/切页/往返/覆盖/卸载、菜单恢复及Enter/Esc精确焦点恢复。与前批22项合测40通过。
- 新增3张130%生产Golden：Windows1440×1000浅色、Android平板1280×900深色、Windows1440×600深色，均实际选择15分钟并断言根状态；逐张查看。测试仓库内容与错误状态不代表真实线上来源。
- 首轮严格比较发现24张旧图因两个按钮启用产生差异；逐张旧/新/差异图核对，变化为侧栏图标、文本、按钮边框及阴影。仅更新相关测试基准，181张旧图保持不变，合计208图，未放宽像素阈值。
- 新Windows截图另出现背景行52085像素差异，单独重跑又通过。定位测试在截图前才切换全局debugDisableShadows，导致已有背景缓存与重绘时机不一致；改为挂载前固定阴影策略并在清理时恢复，初始化后继续固定Reduce Motion。重新生成并逐张查看，完整测试及之后3图严格重复比较均通过，不把不稳定截图直接接受为新设计。
- 完整 **1926 Flutter通过（95秒）**、**149 Node通过（24.4秒）**；537 Dart文件格式零改动，严格分析零问题（9.4秒）。build_runner48秒、Drift迁移通过，生成代码/schema无差异。
- Android Debug预检18.7秒；48项打包资产、完整音频许可及v2单签名者通过。APK232263124 bytes，SHA256 `5c204be7c50371d58618263e702516dc7afd6f2c3dd3fee37765a3946e3448de`。Java native-access警告保留；APK和日志不提交仓库。

## GitHub与剩余范围

2026-09-13后续纠正：本批push34725547000/PR34725576246的Windows Golden失败，分别为inspector_sleep_modal_windows（53887像素）与shell_sleep_modal_windows（52085像素），Android及源码检查成功。上文对背景差异仅归因阴影/动画的判断不完整：LyricsFixture创建FakeLibraryRepository时每首曲目分别读取DateTime.now，主机时钟精度决定时间是否相同，改变最近添加排序，进而改变首个同名行是否为当前曲目。后续codex/inspector-queue-summary固定一次导入批次时间并补独立回归；208原Golden不改基准严格通过，完整1937测试通过。旧运行仍为failure，不冒称旧SHA通过；修复由新提交云端复验。

前置4784cba的[push34724213791](https://github.com/Z-YO-YI/YYMusic/actions/runs/34724213791)/[PR34724254216](https://github.com/Z-YO-YI/YYMusic/actions/runs/34724254216)均SUCCESS，已回填Draft #96。本阶段精确提交、Draft PR与新SHA云端状态记录于提交后的PR信息；不以父分支成功替代本批Windows/Android验证，不自动合并或发布Release。

主要文件：adaptive_root.dart、yy_now_playing_inspector.dart、shell_player.dart、Widget/Golden/Node测试、27张新增/审核更新基准以及README/状态/矩阵/ADR/计划/报告。

下一增量为侧栏队列摘要；其余真实播放设置、Phase7整体、Phase8真实导入、后续来源/后台/设备验收及正式发行仍未完成。本批无新增设备安装/出声、本地Windows编译或上线验收。
