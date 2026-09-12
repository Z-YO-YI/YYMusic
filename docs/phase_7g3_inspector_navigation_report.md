# Phase 7G3 完成报告：正在播放侧栏入口

2026-09-13，基线ea2f3a9d655c174c0be175c2e858e5ab686f5374，fetch/ff-only pull且干净；分支codex/inspector-playback-navigation，Draft base codex/shell-fullscreen-navigation。先计划/ADR096，再实现。

## 实现与边界

YYNowPlayingInspector增加可选onOpenFullscreen/onOpenLyrics，现有按钮接受控回调。AdaptiveRoot的Inspector Shell借已有全屏闭包、openLyrics、路由Listenable与页面/布局/尺寸身份，复用G1导航代数；跨主导航保留或窄窗隐藏/卸载后旧回调无效。Inspector不注入收藏控制器，不拥有播放/存储/原生会话。全屏播放复用G2原生进入意图，歌词沿现有独立/lyrics与平台自动沉浸策略：Windows歌词导航不等同系统级全屏，Android按原策略进入沉浸。无队列时歌词禁用、播放页可开空态。

四项ZIP/App.tsx/HTML/总指令指纹一致，24导出文件逐字节通过，未忽略NEW_ICON_SPRITE/POLISH_CSS。按设计转代码技能用完整本地Figma导出（无在线node），核对HTML2407/2413并复用原图标与按钮。未改布局、绘制资产或使用WebView；播放设置和侧栏队列摘要仍未接线，不称全部Inspector已完成。

## 验证证据

- 新增20 Widget：Windows/Android平板×全屏/歌词真实按钮、返回恢复与新旧回调、根队列/音频不变；两平台实际系统菜单覆盖/关闭撤销；空队列歌词禁用；两入口跨主导航切换/来回、隐藏、零面积、卸载保护。相关45全部通过。
- 142 Node全部通过，21.9秒；初次旧架构断言只允许无导航构造，更新为显式检查导航参数且继续禁止Inspector持有收藏/播放真值。未删除架构约束。
- 初次全量1703通过/21 Golden失败，均为侧栏按钮启用态。逐项查看21组对照及平板整页新旧图：12张仅全屏图标82像素；9张另含歌词按钮正文/边框/原组件阴影。非按钮区域差异仅单通道1级的合成取整，审核脚本单独量化但**实际Golden仍逐像素精确比较**，未改变测试比较器/阈值。生成后21图与审核testImage逐字节一致，167旧图不变，188 Golden通过。
- 515 Dart文件格式零改动；严格分析0问题、10.3秒。build_runner27秒、Drift迁移通过，生成/Schema零漂移；六音频包许可与两原生构建源指纹通过。
- Android Debug27.4秒，48资产/完整音频许可/v2单签名者通过。APK232228365 bytes，SHA256 baf25233d96d04f262ac33a7674c860ab5474f67537420e3f0dc4fb3c7f34a3f。保留Java native-access警告，APK不入库。

最终完整`flutter test --no-pub --reporter expanded`：**1724全部通过，78秒**，含188 Golden。

## GitHub与后续

后续核验：精确3be2863b5e65557a3ef4832582d052209c463ff7的[push34712365647](https://github.com/Z-YO-YI/YYMusic/actions/runs/34712365647)与[PR34712380763](https://github.com/Z-YO-YI/YYMusic/actions/runs/34712380763)均SUCCESS，Draft #87未合并；下方提交前状态保留为历史。

前置ea2f3a9的push34711115530/PR34711133249均SUCCESS，报告与#86已回填。本批提交push/Draft后按新SHA核验，不将前置或本地Debug当成本批云端通过；不自动合并、改默认分支或发布Release。

主要文件：adaptive_root.dart、shell_player.dart、yy_now_playing_inspector.dart、20项新Widget/Node及21基线与文档。原设计/资产/依赖/平台/Schema未改；既有SQLite全量重跑，无新增设备安装/出声、本地Windows编译或UI-SQLite验收。下一步剩余设置/队列摘要入口与Phase7出口，Phase8–11真实导入、来源、后台媒体与正式发行仍未完成。
