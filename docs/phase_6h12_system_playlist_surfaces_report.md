# Phase 6H12 — 系统歌单原生页面与单项播放报告

2026-09-08，Z-YO-YI/YYMusic，分支`codex/system-playlist-surfaces`。
从fetch/pull后的干净`428a49f0049d51039da012639a07801e9880d025`开始；提交前再次fetch确认前置远程未变化，Draft PR #56六项常规检查成功。
本批出口为独立stacked Draft PR，base=`codex/system-playlist-sessions`；不合并、不改写历史、不发布Release。
此报告记录本地验收；本提交push/PR的精确云端结果将在对应PR回填，不能用前置CI代替。

## 实现与设计依据

- Library三系统入口采用固定枚举路由，拒绝额外/重复/未知参数，不复用自定义歌单ID，不创建伪系统父记录，不伪造未读取计数。
- `system_playlist_screen.dart`保持路由会话高于可替换Shell；独立Phone单列、Tablet横屏主从/竖屏列表、Windows桌面布局，复用YYSurface/YYPlaylistCard/YYTrackTile。
  真实加载/空/失败重试、20→200有界窗口、前后组、不可用/未解析引用和当前条目显示；尚无支持的管理动作时隐藏更多按钮。
- `system_playlist_actions.dart`借用根播放器，收藏/最近用完整TrackRef保留队列；queue按真实entry ID并核对完整引用，重复曲目不被误选为第一项。
  `PlaybackController.playEntry`新增可选canPlay，沿用已有查询/解析/持久化/load边界取消；不创建另一音频引擎或队列。
- 离页、遮挡、零尺寸、刷新/读失败撤销尚未开始的播放，正常离页不停止已开始音频。当前ID自身持久化通知不误取消自己的queue播放。
  根关闭等待已接受播放与读取/订阅结束，再关闭存储；旧回调、重复点击、安全错误及重试都有测试。
- AppNavigation/Router/YYMusicApp/DependencyGraph共享API变更先记录ADR-068；PlaylistEditorScope只读interactionEnabled阻止遮挡期间的旧入口导航。
- 复验5指纹、24项ZIP逐字节、44最终图标与52确定产物；本批完整复读App.tsx全部NEW_ICON_SPRITE/POLISH_CSS与品牌替换，复查基础HTML系统集合及主指令17.4/23/Phase6。
  使用figma-design-to-code技能的组件/Token/精确导出图标复用原则；只有本地Figma Make导出，未提供在线节点，不虚构get_design_context或网页像素对照。

## 本地验证

- 新增39项：16路由/播放动作、13界面/生命周期/键盘（含Windows入口焦点）、3真实SQLite页面、7 Golden。
- 全量907/907 Flutter通过（69秒），103/103 Node通过；严格分析零问题。366 Dart文件最终format零修改。
- 91张Golden通过；新7张包括Phone收藏/空/错误/入口、Tablet最近/队列和Windows队列，更新3张旧编辑器的音乐库背景；10张逐张查看，其余81张旧图字节不变。
- 初轮暴露测试缺少extension import、多行if lint、FocusState类型误用及滚动完成前点击；全部修正后通过。
  全量初轮另有1条旧文案断言与3张预期背景差异，已精确更新后全量重跑；无删测试/阈值放宽/警告静音。
- SQLite三系统页面从真实存储读取、点击、单根播放并精确持久化queue ID；重复项保留，曲库不删除，无系统父记录。
- build_runner与make-migrations通过，Schema/生成/lock/平台/资产零差异；原始指纹与六音频许可、完整原生材料检查通过。
- Android本地Debug预检通过（57.2秒），231,953,088字节，SHA256 `d3bfb2b55e73320e6dbe286240e65468650c2460b40f20af30cc4b6da6a22913`。
  48项SVG/字体/许可资产逐字节、NOTICES.Z六音频许可、完整原生材料、v2单签名验证通过；JDK native-access警告保留。
  APK及日志仅位于忽略build目录，不加入源码版本管理；本地预检不代替GitHub构建。
- 提交前36份变更文本的常见秘密模式扫描零命中，diff检查无空白错误；模式扫描不等于完整安全审计。

## 后续核验的精确GitHub记录

实现`07ee2dbe579456b24c96e80e6b262fa0fdfeb8c1`的[PR运行34245944539](https://github.com/Z-YO-YI/YYMusic/actions/runs/34245944539)成功。
[push运行34245902355](https://github.com/Z-YO-YI/YYMusic/actions/runs/34245902355)首次仅Windows上传FinalizeArtifact返回403，源码/编译/测试及包校验已通过，但当时没有完成的可下载artifact。
只重跑失败job后attempt2成功，未修改源码、工作流或权限；不据此猜测403根因。
两组最终六项常规检查成功，四项显式音频诊断跳过。Linux816通过/91 Golden按宿主跳过；Windows91 Golden及1真实窗口集成通过。
Android51个原生依赖坐标、3组原生材料、6包许可、48资产和v2单签名通过；Windows65项运行文件验证通过。
最终Windows artifact ID `10064972814`，67,382,759字节，SHA256 `30c63627892f0964a08aaee8e78c4bc1cef9883ae9641128facfb364dedb6798`，UTC到期2026-09-22T16:01:11Z。
该记录只经API和日志核验，未重新下载/手动启动；开发Debug依赖Debug CRT，非安装器。Draft PR #57保持未合并，没有创建Release。

## 剩余范围

本批未新增取消收藏/清历史/队列移除排序菜单、系统整体播放或自动记录真正开始的历史；最近视图读取已有真实记录。
下一阶段先验收真实播放历史和系统动作，再继续Local Music/Settings以及主Phase7–11。
真实导入/授权、完整播放器/歌词/队列、第三方来源、后台媒体、网页像素对照、实机大库性能与Release/签名/发行验收仍有缺口。
默认新安装仍为空库；测试夹具只存在test，不代表安装后可日常听歌。Windows开发Debug依赖Debug CRT，不是通用安装器。
