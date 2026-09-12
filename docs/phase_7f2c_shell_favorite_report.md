# Phase 7F2C 完成报告：底栏收藏

2026-09-12开始，09-13完成本地验证。基线a4faf905af6c65f077fe230a664291c9c50c844f，分支codex/shell-current-favorite-ui，Draft base codex/player-current-favorite-ui；先计划/ADR093再开发。

## 变更与来源

AppRouter五处frame注入根收藏与路由Listenable；AdaptiveRoot转交底栏，并提供选中主页面/布局/尺寸身份。ShellPlayer借根监听无I/O，路由事件即撤销旧收藏代数，不仅依赖卸载；尺寸/身份/依赖更换、活动/ModalRoute与真实面积同样检查。shell_favorite_actions.dart捕获准确根投影和显式目标，执行前根再次复核；已接受写入换页仍排空。

YYDesktopPlayerBar仅新增受控favoriteKnown/favoriteBusy，心形未知语义不假装未收藏，保存不锁播放。复用F2A安全反馈并限制在窗口高度20%内滚动。窄底栏/Phone/Inspector保持无新增心形入口，无第二份播放器/收藏流，不改Schema/依赖/平台。

依据设计转代码技能复用本地完整Figma导出（无在线节点）、App.tsx NEW_ICON_SPRITE/POLISH_CSS和基础HTML2431原底栏收藏；24导出文件逐字节及原始指纹门禁通过，原SVG/字体未改。不使用WebView。

## 测试与构建

- 新增14 Widget：宽Windows/平板真实点击/保存且队列音频不变；主导航/来回/覆盖/resize/零面积/重复条目/卸载旧回调撤销；立即导航撤销未接受保存；接受后跨Tab排空与独立busy；写失败跨Tab保留、旧知悉无效、同目标重试；读失败未知语义及重试；手机/窄栏不增加图标。
- `flutter test --no-pub --reporter expanded`：**1671全部通过，79秒**，含**188 Golden**。新增3张，17旧图精确更新，168旧图字节不变。20张变更逐张查看，17旧图差异均为底栏原心形950/952像素（0.07–0.13%）进入真实已收藏状态，无几何变化；另检查隔离差异图。
- `node --test tools/*.test.mjs`：**138全部通过，36秒**。新增路由事件/精确scope/捕获目标门禁；旧禁止收藏接线断言改为精确受保护回调，继续禁止未接队列/全屏回调。
- `dart format --output=none --set-exit-if-changed lib test integration_test`：**511文件零变更**；严格analyze **零问题，8.7秒**。
- build_runner12秒、Drift迁移成功，生成/Schema零漂移；六音频包LICENSE/两个原生源与24ZIP条目校验通过。
- Android Debug本地预检 **18.3秒通过**，APK **232226251 bytes**，SHA256 **c1e925708373a66873725a4b64878efe53d91c670e3272e0b7a60472a01378a0**；48资产及完整许可、v2签名/单签名者通过。Java native-access警告保留。

首轮全量1651通过/17Golden失败（新增3Golden当时尚未纳入首轮），确认心形变化后只重生成对应六文件的34项，最终完整1671含新增图通过。初次2条大括号lint已修复；旧Node禁止收藏接线约束更新后重跑。初次日志保留，不删除测试/关闭lint/降低图像阈值。

## GitHub与限制

2026-09-13后续核验：精确head `344ea0d41846689fb3f34187cf170df3d36a08e5` 的[push34707400406](https://github.com/Z-YO-YI/YYMusic/actions/runs/34707400406)和[PR34707403440](https://github.com/Z-YO-YI/YYMusic/actions/runs/34707403440)均SUCCESS。本阶段成功不代替后续遮罩修复新SHA验收。

前置F2B精确a4faf90双CI34706094820/34706097249均SUCCESS，报告及#82回填。本批提交push/Draft后另按新SHA核验Android/Windows，不借前置结果。不自动合并、不改默认分支、不发布Release，不提交凭据/媒体/构建包。

本批无本地Windows编译、真实设备安装/出声或新增UI-SQLite联调，既有SQLite在全量中重跑。下一步审查Shell队列/全屏/Inspector导航剩余入口、内联菜单遮罩与键盘焦点许可，完成Phase7整体出口核查；不声称所有遮罩或所有播放交互已全面验收。Phase8真实导入、Phase9来源、Phase10完整后台媒体、Phase11正式发行仍待完成，新安装仍空库。
