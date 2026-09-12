# Phase 7F3 完成报告：内联遮罩收藏许可

2026-09-13。基线344ea0d41846689fb3f34187cf170df3d36a08e5，分支codex/shell-favorite-overlay-guard，Draft base codex/shell-current-favorite-ui；先计划再测试复现，非视觉修复，无共享API变更。

## 原因、变更与验证

SystemPlaylistScreen的内联菜单/历史确认框使用ExcludeFocus覆盖包括底栏的frame，不改变ModalRoute；原底栏许可只检查路由/活动/面积，因此保留的旧回调在菜单打开或关闭后仍可能保存。先加两平台×覆盖/关闭4项测试，均稳定复现期望0、实际1写入。

shell_favorite_actions.dart新增只读焦点许可，检查最近Focus及全部祖先的descendantsAreFocusable；ShellPlayer在didChangeDependencies依赖该焦点上下文，排除状态变化使用已有代数永久撤销旧闭包，执行时还实时复核。并非检查当前哪个控件获得焦点，不强制抢焦点，不使用全局可变锁；已接受写入继续由根排空。未被内联遮罩覆盖的区域不扩张禁用范围。

新增shell_favorite_overlay_test.dart：8项覆盖Windows/Android平板×真实系统歌曲菜单/历史确认×遮罩中/关闭后；旧回调无写入，关闭后新回调可正常保存。测试在finally显式关闭页面并排空根，避免仅addTearDown晚于Flutter未完成Timer断言。相关22项通过。

- `flutter test --no-pub --reporter expanded`：**1679全部通过，83秒**；**188旧Golden全部不变**。
- `node --test tools/*.test.mjs`：**139全部通过，18.5秒**；新增内联排除门禁，断言支持Dart格式器换行/尾逗号而不改语义。
- 格式检查 **512文件零改动**，严格analyze **零问题，21.6秒**。
- build_runner13秒及Drift迁移成功，生成/Schema零漂移；ZIP24条目和音频许可指纹通过。
- Android Debug **18.5秒成功**，48资产及完整音频许可、v2单签名者通过。APK **232226130 bytes**，SHA256 **f391df07d3747d78efce7afda8d9ccd6aefe95c93c486af6bdd6eac66e1d5d18**；保留Java native-access警告。

原始设计App.tsx（含NEW_ICON_SPRITE/POLISH_CSS）、HTML、资产、依赖、平台文件无修改；无WebView，无Golden更新。初次复现/夹具清理/Node格式断言失败日志保留，没有删除断言、关闭lint或降低比较阈值。

## GitHub与下一阶段

后续核验：提交6f9552a6d37650ca90621a977113edec064c66f8的[push 34708712276](https://github.com/Z-YO-YI/YYMusic/actions/runs/34708712276)及[PR 34708730171](https://github.com/Z-YO-YI/YYMusic/actions/runs/34708730171)均SUCCESS；Draft #84未合并。以下提交前描述保留为历史。

前置344ea0d的34707400406/34707403440均SUCCESS，报告和#83回填。本批提交push/Draft后按新SHA独立核验，禁止把前置或本地预检当作本批云端成功。不自动合并、不改默认分支、不发布Release，不提交凭据/媒体/构建包。

下一步继续Shell队列/全屏/Inspector导航及Phase7整体出口。此修复验证实际被ExcludeFocus覆盖的系统菜单/历史确认，未声称所有自定义遮罩和全部播放操作均已审计。既有SQLite全量重跑，本批没有新增UI-SQLite、设备安装/出声或本地Windows编译。Phase8真实导入、Phase9来源、Phase10完整后台媒体、Phase11正式发行未完成，新安装仍空库。
