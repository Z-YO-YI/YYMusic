# Phase 7G1 完成报告：底栏队列导航

2026-09-13。基线6f9552a6d37650ca90621a977113edec064c66f8，fetch/ff-only pull成功，独立分支codex/shell-queue-navigation；先计划/ADR094，再实现，Draft base codex/shell-favorite-overlay-guard。

## 实现与设计

AdaptiveRoot传入既有AppNavigation.openSystemPlaylist(queue)，ShellPlayer新增可选onOpenQueue，接YYDesktopPlayerBar原按钮。空队列允许打开原生空态，复用已有路由恢复/去重和根队列，不引入另一套播放/存储状态。F3交互许可改通用名称，导航执行前检查路由/活动/面积/代数/焦点排除并立即撤销旧许可；通知重建避免当前已在队列页时旧收藏许可永远失效。手机/窄栏/Inspector不增加布局入口，全屏/设置仍为后续任务。

四项ZIP/App.tsx/HTML/总指令指纹与Phase0一致，ZIP24条目逐字节通过；核对NEW_ICON_SPRITE的i-queue、POLISH_CSS及基础HTML队列入口。设计转代码技能沿用本地完整导出（没有在线node），使用现有原始图标和组件，无WebView/新绘制图标/样式调整。

## 验证

- 新增12 Widget：Windows/Android平板×空/非空队列，真实点击、重复调用、返回再调用旧/新闭包，根快照/音频不变；内联菜单打开和关闭后旧回调均不能导航；主导航切换/来回、独立页覆盖、尺寸/零面积/卸载撤销。相关34通过。
- 完整`flutter test --no-pub --reporter expanded`：**1691通过，84秒**，含188 Golden。新增Node门禁，**140通过，32.4秒**。
- 初次完整1623通过/68失败：65张基线启用态变化与3项旧“队列尚未接线”断言。逐项审查65张旧/新图：每张仅队列图标12×12范围内67像素变化；更新后字节与审核图一致，另123图不变，未降低阈值。3旧断言改成入口可用，其他音频和未实现全屏断言保留。
- 新测试最初误用系统路由导致2项失败，改为现有/system-playlist?type=favorites后通过；严格分析发现导入顺序和扩展调用受保护setState，已修正为既有State通知方法，无忽略规则。所有初次日志保留。
- 513 Dart文件格式零改动；严格分析**0问题，6.1秒**。build_runner **13秒**及Drift迁移成功，生成/Schema零漂移；音频六包许可/两原生构建源指纹通过。
- Android Debug **38.5秒**成功；48资产、完整音频许可、APK v2单签名者通过。APK **232226718 bytes**，SHA256 **ba65d7b0a28eb9b2e124d4d2be0731c8c388cd02b7f678e30f743163e697ac40**。保留Java native-access警告，构建包不入库。

## GitHub与剩余边界

后续核验：精确a5dc821a2fc03c538a0287a9fc8d571c0df49222的[push34709946561](https://github.com/Z-YO-YI/YYMusic/actions/runs/34709946561)和[PR34709964739](https://github.com/Z-YO-YI/YYMusic/actions/runs/34709964739)均SUCCESS；Draft #85未合并。下方提交前状态保留为历史。

前置6f9552a的push34708712276/PR34708730171均SUCCESS，回填#84及报告。本批提交推送/Draft后按新SHA核验Android/Windows云端结果，不用前置CI或本地Debug冒充本批云端成功，不合并或发布Release。

主要文件：adaptive_root.dart、shell_player.dart、shell_favorite_actions.dart、新导航Widget/Node、旧未接线断言、65 Golden和阶段文档。原设计/资产/依赖/平台/Schema未修改；既有SQLite测试全量重跑，无新增UI-SQLite或设备安装/出声，本地未编译Windows。下一步全屏/Inspector剩余入口和Phase7出口；真实导入/扫描、来源、后台媒体及正式发行仍待Phase8–11，不是已上线。
