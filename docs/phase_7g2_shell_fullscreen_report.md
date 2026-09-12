# Phase 7G2 完成报告：底栏原生全屏入口

2026-09-13，基线a5dc821a2fc03c538a0287a9fc8d571c0df49222；fetch/ff-only pull成功、独立codex/shell-fullscreen-navigation，Draft base codex/shell-queue-navigation。先计划和ADR095，再实现。

## 实现与设计边界

核对基础HTML openPlayerFullscreen后明确入口不只是导航，还请求系统全屏。AppRouter构造闭包组合既有FullscreenPresenter.enterOnNextPlayer与openPlayer，给五处AdaptiveRoot传同一意图；ShellPlayer新增可选onOpenFullscreen，经G1通用导航许可调用，接受前立即撤销旧代数。队列复用同一导航方法，收藏许可不削弱。实际原生进入/恢复/错误仍由根会话和路由观察器驱动，无额外平台通道或播放真值；不支持时仍进入独立播放页、不谎称全屏成功。

四项ZIP/App.tsx/基础HTML/总指令指纹与已审计记录一致，24导出条目逐字节通过。使用设计转代码技能的本地完整导出路径（没有在线node），保留NEW_ICON_SPRITE/POLISH_CSS、原图标与组件，不画新图标、不使用WebView、不改布局。手机/Inspector无新增入口，Inspector后续接线。

## 验证证据

- 13新Widget：两平台×原生支持/不支持真实点击，仅一次enter，返回恢复，旧闭包失效、新闭包可再进入，根队列/音频不变；两平台实际菜单覆盖和关闭后失效；主导航切换/来回、歌词覆盖、尺寸、零面积、卸载；原生进入失败显示安全正文且不影响播放。
- 初次相关40通过/1失败：宽泛文本查找同时匹配错误标题和正文，修为完整正文精确断言，不降低错误验证。初次全量1639通过/65失败均为已接线全屏图标启用态；3条旧未实现全屏断言已精确改成可用，音频与收藏断言保留。
- 最终完整`flutter test --no-pub --reporter expanded`：**1704全部通过，77秒**。**141 Node通过，15.9秒**。
- **188 Golden通过**。65旧图每张只改变全屏图标14×14内62像素；3张带编号对照表逐项查看，生成后逐文件SHA与已审核testImage一致。123旧图不变，未降低比较阈值或关闭断言。
- **514 Dart文件格式零改动**；严格analyze **0问题，9.9秒**；build_runner **27秒**及Drift迁移通过，生成/Schema零漂移。音频六包LICENSE与两原生构建源指纹通过。
- Android Debug **44.9秒**；48资产/完整音频许可和v2单签名者通过。APK **232227649 bytes**，SHA256 **47407a50d91cf53b6e23f7cff9e8b1e5aab90179dc1252e212d0c652664183eb**。Java native-access警告保留，构建包不入库。

## GitHub与后续

后续核验：精确ea2f3a9d655c174c0be175c2e858e5ab686f5374的[push34711115530](https://github.com/Z-YO-YI/YYMusic/actions/runs/34711115530)和[PR34711133249](https://github.com/Z-YO-YI/YYMusic/actions/runs/34711133249)均SUCCESS，Draft #86未合并；下方提交前状态保留为历史。

前置a5dc821的push34709946561/PR34709964739均SUCCESS，#85及报告回填。本批提交推送并创建Draft后按新SHA核验，不用前置CI代替本批Android/Windows云端成功，不自动合并或发布Release。

主要文件：app_router.dart、adaptive_root.dart、shell_player.dart、导航许可part、新Widget/Node、旧禁用断言、65基线及阶段文档。原设计/资产/依赖/平台/Schema未改；无新增设备安装/出声、本地Windows编译或UI-SQLite测试，既有SQLite全量重跑。下一步Inspector剩余入口、Phase7出口；Phase8真实扫描导入及9–11来源/后台/发行仍未完成，非上线。
