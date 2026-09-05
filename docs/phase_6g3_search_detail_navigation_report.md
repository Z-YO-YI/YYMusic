# Phase 6G3 — 搜索详情入口报告

2026-09-06，仓库`Z-YO-YI/YYMusic`，分支`codex/search-detail-navigation`，基于fetch/pull后的
`7fe2e21`。这是Phase6专辑/艺人页面的搜索接线增量，不是全部Phase6或上线完成。

## 交付与边界

- `lib/features/search/common/search_sections.dart`：专辑/艺人结果增加明确“查看专辑/查看艺人”
  原生按钮，按AlbumRef/ArtistRef调用已有AppNavigation。结果Key也携带完整引用；不使用名称、
  sourceType或临时模型extra猜路由。说明文字与当前功能一致，Enter首条播放语义不变。
- 复用Phase6G2三端详情及根会话/播放器；详情归属音乐库，系统返回仍恢复原搜索页面。
  搜索→专辑→艺人→专辑→搜索的返回栈、搜索条件/结果/滚动和Windows按钮焦点保持。
- 查看详情不重新搜索、不隐式写搜索历史或播放；已移除引用进入详情真实空态，不打开同名替代品。
  搜索播放加载期间进入详情会撤销未完成意图，返回后搜索仍可用。
- 仅一个生产文件改变；无Domain/Data/Schema/根导航合同/播放器/平台/依赖改变，无新ADR或第二详情实现。
  测试夹具新增可选浏览接口和专辑/艺人查询钩子，不改变原夹具默认行为，不进入生产。
- README、实施状态、矩阵、计划/报告同步，回填Phase6G2双组CI成功记录和PR #43正文。

## 验证与修正

- 512/512 Flutter，67张Windows宿主Golden全部通过；新增6项Widget覆盖Phone390×1000、
  Tablet1024×768、Windows840/1024×900及130%文字。6张搜索基线逐张查看，仅说明/按钮及
  其正常文流变化；其他61张PNG不变，未调整比较阈值或忽略错误。
- 同名同ID的两来源，实际sourceId不是local/rest且含`/?%#+`与中文，真实AppRouter收到的引用
  必须与搜索结果完全一致；测试同一专辑署名继续进入正确艺人，逐层返回。
- Tab/Enter打开搜索结果、Esc恢复原按钮焦点；仅点详情时搜索history无record、引擎无play。
  关闭详情后会话注册归零；搜索原查询/筛选/滚动不变且不增加搜索请求。
- 新测试最初因ValueKey记录类型被Object拓宽而无法定位按钮，改用强类型AlbumRef/ArtistRef
  Key定位后通过。另一断言错误地把切换筛选新增的两来源查询算作返回重搜，按现有selectFilter
  合同分别验证切换前后及详情返回次数；未修改生产查询逻辑或放宽“返回不重搜”要求。
- 78/78 Node，严格analyze零问题，267 Dart文件格式零修改。
- build_runner、drift make-migrations重跑；生成代码、Schema、迁移助手与lockfile零差异。
  五份设计指纹及ZIP24逐字节匹配，六包及原生完整许可源/包内验证通过。
- 本机Android Debug构建通过（Gradle16.6秒）；48 SVG/字体/许可资产、音频NOTICES、
  原生完整许可和v2单Debug签名通过。Java原生访问警告保留，未关闭警告或更改平台设置。
  APK为231,771,589字节，SHA256：
  `7b190316248e8ba6432d6ee991001284643ad68fcb218b0e28c003888e338737`。
  本地产物`build/app/outputs/flutter-apk/app-debug.apk`不提交Git。

命令：`dart format --output=none --set-exit-if-changed lib test integration_test`、
`flutter analyze --no-pub --fatal-infos`、`flutter test --no-pub --reporter expanded`、
`node --test tools/*.test.mjs`、`dart run build_runner build`、`dart run drift_dev make-migrations`、
ZIP/源码/包内许可脚本、`flutter build apk --debug --no-pub`、`apksigner verify --verbose`。

## GitHub与下一步

前置`7fe2e21`的push33989357683/PR33989396295均已success，checks/Android/Windows逐job通过；
两个专用音频job明确skipped，不计为新音频证据。前置Draft PR #43未合并。
本批独立提交推送后以`codex/catalog-detail-surfaces`为base建立stacked Draft PR，精确提交
的云端源码/Android/Windows结果在PR记录，不将前置或本地通过当作本提交云端通过。

下一步先核验此提交GitHub双平台，再补详情曲目收藏/原生菜单及关闭期间写入排空。
歌单管理、本地导入/恢复、REST、完整播放器/歌词、设置与发行仍未完成，默认新安装是真实空库。
本机Windows C++/Debug CRT限制未改变，Windows继续由GitHub构建；没有新音频实机验收。
完整App.tsx NEW_ICON_SPRITE/POLISH_CSS与基础HTML仍是参考，没有WebView或生产Fixture，
没有绕过浏览器安全限制，Golden不替代HTML网页对照或上线验收。
