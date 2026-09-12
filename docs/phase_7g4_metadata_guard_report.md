# Phase 7G4 完成报告：底栏元数据与歌词入口许可

2026-09-13，基线3be2863b5e65557a3ef4832582d052209c463ff7；fetch/ff-only pull成功且干净，分支codex/shell-metadata-navigation-guard，Draft base codex/inspector-playback-navigation。先计划和失败复现，内部许可复用，无共享API变更。

## 原因与实现

手机MiniPlayer与桌面/平板底栏onOpen/onOpenLyrics直接转发导航，不检查生命周期。先4项真实测试，切换主导航后调用旧回调，均错误打开PlayerScreen/LyricsScreen（期望无目标页，实际1个）。复用G1–G3的_navigationAction，为两处onOpen与两处onOpenLyrics绑定页面/路由/尺寸/焦点排除代数，接受导航立即撤销旧许可。根控制器、页面路由和歌词可用条件保持原样，不增加全局锁或原生会话。

## 验证

- 22新Widget：4项复现保留；手机/平板/Windows×封面/歌词×正常返回、另一独立页覆盖、实际菜单覆盖/关闭。正常路径用真实点击/长按，重复旧调用无重入，返回旧许可不复活、新回调可用，根队列与音频不变。相关67全部通过。
- 完整`flutter test --no-pub --reporter expanded` **1746通过，87秒**；**188旧Golden全部不变**。**143 Node通过，28.7秒**，新增门禁要求全部元数据入口使用现有许可。
- **516 Dart文件格式零改动**，严格分析**0问题、25.1秒**；build_runner **29秒**和Drift迁移通过，生成/Schema零漂移。ZIP24条目、六音频包许可与两原生构建源指纹通过。
- Android Debug **19.2秒**，48资产/完整音频许可/v2单签名者通过；APK **232227826 bytes**，SHA256 **8ce83df142656cf2d7ba3800177aefa345194f7b664676380c66bb3a6ad30d37**。Java native-access警告保留，构建包不入库。

本批非视觉修复，原设计App.tsx（含NEW_ICON_SPRITE/POLISH_CSS）、HTML、资产、依赖、平台、Schema无修改，无Golden更新。保留失败复现日志，未删除测试或忽略lint。既有SQLite全量重跑，本批无新增UI-SQLite、实机安装/出声或本地Windows编译。

## GitHub与后续

前置3be2863的push34712365647/PR34712380763均SUCCESS，报告和#87回填。本批push/Draft后按新SHA独立核验云端Android/Windows，不用前置或本地预检代替成功，不自动合并/改默认分支/发布Release。

主要文件：shell_player.dart、shell_metadata_navigation_test.dart、shell_navigation.test.mjs及阶段文档。下一步剩余设置/队列摘要和Phase7出口核查；不声称所有传输/Seek控件旧回调已全部审计，Phase8–11真实导入、来源、后台和发行仍未完成。
