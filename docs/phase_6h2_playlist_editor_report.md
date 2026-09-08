# Phase 6H2 — 原生歌单编辑界面报告

2026-09-08，仓库 `Z-YO-YI/YYMusic`，分支 `codex/playlist-editor-surfaces`，
基于 fetch/pull 后的 `1dd92eff6db50aa3ee6fd6e14f95321114c77746`。
本批接上自定义歌单创建、重命名和确认删除；不等于歌单条目管理或主指令 Phase 6 全部完成。

## 交付

- ADR-058 先于公共接线：AppRouter 借用根 PlaylistController，编辑宿主位于 AdaptiveRoot 上方。
  Library 显示创建及自定义歌单改名/删除入口；既有 Library 订阅更新实际写入结果，无第二列表缓存。
  系统歌单无编辑按钮，UI 请求与原子仓库命令分别校验保护，不生成假的系统歌单。
- Phone 使用 YYBottomSheet，Tablet/Windows 使用 YYDialog；Windows 窄窗口不切换手机界面。
  名称输入使用原生 EditableText、基础 HTML field 的 44 高度/13 圆角/13 水平内边距和表单字号，
  共用原有选择手柄和剪切/复制/粘贴菜单。搜索框外观及 search 语义不变，新名称输入使用 done。
  App.tsx 的 NEW_ICON_SPRITE/POLISH_CSS、30 圆角弹层及不透明表面继续保留，无 Material/WebView。
- 每次打开的独立代次保护草稿；600 断点、横竖屏、零可绘制区域恢复不丢文本/选区。
  背景点击/焦点/语义被隔离，Tab 限于弹层，Back/Esc/Alt+Left 先关闭弹层，返回有效原焦点。
  快捷导航离页或覆盖 Shell 的路由关闭未提交草稿，不改变共享播放器或曲库条件。
- 名称校验沿用 ADR-057 的 trim/1–512 个 Dart 字符单元/控制字符规则，错误保留文本。
  整个弹层属于原生输入 tap region，点击提交不会先失焦清除输入法组合；未完成候选不触发命令。
  SafeArea/viewInsets 参与可用空间，低高度时整个弹层可滚动，130% 文字下操作按钮可达。
- 保存中禁止重复提交，关闭弹层不撤回已接受写入；根仍排空后关闭共享存储。
  关闭后的失败在返回 Library 时显示固定安全反馈，可显式确认清除；迟到结果不关闭新草稿。
  删除面板默认焦点为取消，明确说明只删除歌单及条目，不删除歌曲文件/来源内容；确认才执行删除。
  本次只在隔离测试库执行删除，未操作用户歌单。

## 验证与发现

- 最终 572/572 Flutter：新增 18 项 Widget 回归、3 张三端 Golden；原 70 张基线字节未改。
  三张新图均逐张查看，覆盖手机创建、深色平板改名、Windows 删除确认，均为 130% 文字。
- 回归涵盖三端 CRUD 与实际投影、确认/取消、系统保护、缺失目标不复活、名称/IME、复制/粘贴、
  并发点击、Tab/Space/Back/Esc、快捷导航/覆盖路由、草稿旋转/零尺寸/SafeArea/键盘、根关闭排空。
  现有真实 SQLite 命令、事务及删除范围测试继续全量通过；不将 Fake Widget 测试称为新实机音频验收。
- 边界审查发现连续创建请求可能是同一 Dart const 对象，旧的 identical(request) 检查不足。
  新增先失败的重开回归后，改为独立递增代次；旧操作成功/失败都不能关闭随后打开的草稿。
- IME 测试进一步发现点击弹层外部的提交按钮会先清空组合范围；把整个弹层纳入 TextFieldTapRegion
  后 done 和显式提交均正确等待组合结束。长按测试在文本实际布局后取 caret 坐标，手机行为固定 Android 变体。
  初始测试 ValueKey<Object> 与实际 ValueKey<String>/Record 类型不匹配，改为验证明确的 key.value，
  没有删除业务断言；严格分析要求的花括号/多余 import 全部修正。
- 84/84 Node、严格 analyze 零问题，283 个 Dart 文件最终格式零差异。
  build_runner / make-migrations 重跑；生成代码、Schema、迁移、依赖锁文件零差异。
  五份参考指纹、ZIP 24 项逐字节、源码及包内完整音频许可均通过。
- 本地 Android Debug 成功（Gradle 39.9 秒），48 SVG/字体/许可资产逐字节匹配，v2 单 Debug 签名有效。
  APK 231,807,449 字节，SHA256 `c4ff8211fe28a124854346736b4a591d14217e7711f6f12da76659c85a1d68ee`。
  Java 原生访问和 Android SDK XML 版本警告保留，未关闭检查或安装/升级全局组件。
  `build/app/outputs/flutter-apk/app-debug.apk` 仅本地预检，不提交 Git，不替代 GitHub 构建。

命令：`dart format --output=none --set-exit-if-changed lib test integration_test`、
`flutter analyze --no-pub --fatal-infos`、`flutter test --no-pub --reporter expanded`、
`node --test tools/*.test.mjs`、`dart run build_runner build`、`dart run drift_dev make-migrations`、
指纹/ZIP/许可检查、`flutter build apk --debug --no-pub`、APK 资产与 `apksigner verify --verbose`。

## GitHub 与剩余工作

前置实现 `1dd92ef` 的 [push 33994757759](https://github.com/Z-YO-YI/YYMusic/actions/runs/33994757759)
与 [PR 33994765770](https://github.com/Z-YO-YI/YYMusic/actions/runs/33994765770)
均 checks/Android/Windows success，已回填 H1 报告；Draft PR #46 仍 OPEN。
本批审查提交后推送 stacked Draft PR，base 为 `codex/playlist-metadata-commands`。
本批精确提交、Android 与 Windows 云端结果记录在对应 PR，不用前置或本地结果替代本提交云端验收。

没有合并 main、发布 Release、改写历史、上传日志/凭据/用户数据/构建产物。
普通 push 的 Android job 不上传 APK；Windows Debug 为开发包，不能当作通用发行安装包。
本机 Windows C++/Debug CRT 限制仍在，Windows 由 GitHub 构建。
下一批继续歌单内容读取、条目管理与播放动作，仍需独立计划和验证；随后才推进 Local/Settings 等阶段。
导入/恢复、实时 REST、完整播放器/歌词、平台集成及发行未完成，默认新安装仍为空库，不是上线版本。
网页对照仍受既有安全限制；本批未绕过，也不将 Golden/构建成功等同于 HTML 视觉对照或用户设备运行通过。
