# Phase 7C2 阶段报告 — 独立原生歌词页

2026-09-09；GitHub `Z-YO-YI/YYMusic`；分支 `codex/native-lyrics-route`；基线 `aad2d06`，Draft PR base=`codex/lyrics-follow-viewport`。
开始前核对分支/状态并 fetch；原计划已在前置 fetch/pull 后创建独立分支，本轮续做无覆盖他人修改。前置 C1 两组源码/Android/Windows 均 SUCCESS，报告和 #66 已回填。

## 实现范围

- 正式 `/lyrics` 使用 `LyricsScreen`，Phone/Tablet/Windows 独立无状态排版组件。root `LyricsController` 与 `PlaybackPresenter` 只注入一次，页面只拥有翻译显示、进度草稿和可撤销代次。
- 顶部含返回、明确封面兜底、真实歌曲/艺人/状态、翻译开关和重新读取；正文复用 C1 惰性视口，消费完整歌词快照及根当前行/位置。支持同步、偏移、纯文本与双语，不创建新时钟或生产 Fixture。
- 真实 Dock 绑定上一首/播放暂停/下一首、时间、原生进度手势及返回播放页。未实现的收藏显式隐藏；旧 Dock 默认行为不变。
- app 只读路由信号结合 ModalRoute、TickerMode、正尺寸判断活动；激活合并到安全后帧，失效即时撤销页面意图。根 `seekLine` 新增可选 `isIntentCurrent`，入队与实际根 Seek 执行前均检查，覆盖退出/旋转前已排队的动作。
- 普通关闭回原始入口；Dock返回复用已有命名播放路由，否则替换歌词路由。修复配置先更新、Navigator尚未构建时重复打开导致误弹栈的竞争。十轮循环和跨队列返回保留同一Player State及根音频。
- 播放页显式歌词按钮、已有桌面底栏图标启用；有曲目时底栏元数据长按打开歌词，普通点击仍打开播放页。共享输入组件增加可选原生长按语义/手势，旧消费者默认无变化。Windows L 不拦截 EditableText，Ctrl+L仍为音乐库。

## 设计与回归审查

使用 figma-design-to-code 的组件复用流程。来源仅为已完整审计的本地 Figma Make 导出，没有在线node，未伪造 get_design_context。主指令19/Phase7、App.tsx的NEW_ICON_SPRITE/POLISH_CSS和基础HTML均纳入；原始5指纹/44SVG/52确定产物与24ZIP条目复验通过。
背景为单一固定深色兜底 `#34454D`，保留减少玻璃/动态偏好，不声称真实封面提色。没有WebView、渐变、预设紫色、Material默认图标或新依赖。
新增11张完整页面Golden：手机竖/横、平板横竖、Windows宽/窄、空曲目/缺失歌词/读取中/失败/纯文本；均以130%字号逐张查看。英文歌词与曲目信息只来自test Fixture。
首次全量回归出现17张预期旧图差异，行为测试未失败：8张播放页顶部新增入口（2097–2519像素、0.16–0.77%）；9张底栏图标由禁用启用（各120像素、0.01–0.02%）。逐张查看隔离差异，并抽查完整结果后定向更新，其他110张旧图字节不变，未降低阈值。

## 验证记录

新增30项Widget与11项Golden：41/41通过，含真实根状态和受控Fake音频，不冒充实机出声。原生入口旧测试改为实际点击新歌词按钮，不删除返回断言。
120项Node门禁通过；24ZIP条目逐字节一致，六音频包License/两个原生构建来源与完整原生许可材料通过。
build_runner 14秒成功；drift make-migrations成功，生成/Schema/lock/原始assets/Android/Windows平台文件零差异。
最终435个Dart文件格式零修改；`flutter analyze --no-pub --fatal-infos --fatal-warnings`零问题，6.2秒。
`flutter test --no-pub --reporter expanded`最终1229/1229通过，58秒，包含138张Golden；不是首次1212通过/17截图待更新的中间结果。
`flutter build apk --debug --no-pub`成功，20.0秒；包内48原始资产/六音频包与完整原生许可通过，v2单签名者验证通过。APK 232,105,044 bytes，SHA-256 `ead101f585f55a55156aca5f61eb2137658c8fcd390249962a6fcb9f30ab103f`。仅保留忽略的build目录，正式云端构建仍按新提交独立验收。
53个候选文件包含25个文本与28张Golden（11新增/17精确更新）；提交前文本敏感模式零命中，没有凭据、环境文件、原始音频或构建包，`git diff --check`通过。

## 边界与下一步

这是Phase7的独立页面增量，不是整个Phase7完成。OS全屏/F、Android沉浸与恢复、真实封面读取/提色、收藏和独立队列管理尚未接；LRC解析导入、真实音乐扫描/授权、第三方来源、后台/系统媒体能力及Release/AAB/设备验收仍待后续Phase8–11。
本轮没有Windows本机构建、Android安装/出声、性能Profile或人工读屏验收。Windows云端按新SHA独立核对；开发Debug包依赖Debug CRT，普通Android构建未上传APK artifact。未自动合并、发布Release或触发手动诊断。
源码、测试与文档提交后push并创建Stacked Draft PR；云端运行链接与SHA在PR中记录，不借用前置C1成功。用户凭据、环境文件、构建包和临时日志不进入Git。

## 精确GitHub验收回填

实现提交`0a9e6d0cee9b01e3beef26bb011247dd455bbb61`，[Draft PR #67](https://github.com/Z-YO-YI/YYMusic/pull/67)。[Push 34291806866](https://github.com/Z-YO-YI/YYMusic/actions/runs/34291806866)与[PR 34291810669](https://github.com/Z-YO-YI/YYMusic/actions/runs/34291810669)均完成SUCCESS，head SHA一致。
两组Linux1091通过/138Windows宿主截图预期跳过；Windows138Golden和1项真实窗口测试通过，65文件Debug包及六音频包/原生许可通过；Android51原生坐标/3完整法律文本/48资产/v2单签名者通过。
[Windows开发Debug包](https://github.com/Z-YO-YI/YYMusic/actions/runs/34291806866/artifacts/10082007867)为67,528,393 bytes，SHA256 `75894a389d27407ecb1ebe1d37cc2965f050354ed98c1d532c30b65d3a7a30bc`，到期UTC`2026-09-22T23:57:04Z`。仅为依赖Debug CRT的开发包，不代表真实导入或发行版完成；Android无普通APK artifact，未发布Release。
以上成功仅归本批C2，不替代后续原生全屏通道的新提交及实机验收。
