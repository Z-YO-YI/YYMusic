# Phase 6G4 — 详情曲目菜单与收藏报告

2026-09-06，仓库`Z-YO-YI/YYMusic`，分支`codex/catalog-detail-track-actions`，基于已fetch/pull的
`4386bd425ac1751fc1a83205fe86c9c0e13beb3c`。只完成Phase6详情动作增量，不是整个Phase6或上线完成。

## 交付与边界

- ADR-056先定义收藏借用与排空合同。根CatalogDetailSessions借用同一CollectionRepository，
  私有收藏投影在首次打开曲目菜单时才订阅；普通只读详情不新增收藏查询，也不阻塞摘要/分页。
- 完整TrackRef守卫可见引用及来源；可用与失效曲目都能收藏，失效曲目仍禁止播放。
  未知收藏状态禁止写入，读错误提供独立重试；成功写入后重新订阅，旧代次不可覆盖新投影。
- 播放/收藏共享busy拒绝重复命令；收藏已被接受后不因刷新、离页或关闭而丢弃。
  根关闭先拒绝新命令，等待在途写入及订阅创建/取消，再释放共享数据库。
- 新受控CatalogDetailTrackMenu复用YYContextMenu，不在构造/build内读写仓库。
  更多/长按/右键→播放、收藏/取消收藏；读失败可重试，所有状态均保留关闭菜单入口。
  Phone内容区靠底，Tablet/Windows居中，Shell独立；背景点击/焦点/语义被隔离。
  Android Back/Esc先关菜单，恢复仍有效的入口焦点；刷新、切分区、路由失活关闭旧菜单。
- 未改Library/Search/Domain/Data/Schema/Playback/平台或公开AppNavigation合同，未增加依赖。
  不包含下载、删除文件、歌单编辑、播放全部、网络图片或第二存储/播放实例。

## 验证与修正

- 531/531 Flutter，含70张Windows宿主Golden；新增9项单位、7项Widget、3张菜单Golden。
  真实SQLite跨会话收藏/取消收藏保持来源隔离，原只读详情SQLite回归和查询预算通过。
- 覆盖按需订阅、未知/失败关闭写入、独立重试、重复命令、读写错误安全文案、失效引用、
  离页/刷新/关闭写入排空、listen创建过程重入关闭，以及旧订阅取消未完成时根关闭等待。
  不要求在ChangeNotifier自己的notifyListeners回调内dispose；该行为被Flutter禁止，测试用
  显式订阅建立重入覆盖真正需要的“listen返回前已关闭”路径。
- 原生路由Widget覆盖更多/长按、右键、Tab/Enter/方向键/Esc及恢复焦点、Android双次Back、
  菜单播放只调用根播放器一次、实际路由移除后的收藏持久化、刷新/覆盖路由清理旧菜单。
  Android390/600/1024及844×390低高度、Windows840×900均在130%文字下通过。
- 初始Widget关闭断言暴露测试助手只flush微任务、不推进零延迟事件的问题。改为
  `tester.pump(Duration.zero)`并保留真实区SDK取消回调排空，未降低“关闭必须完成”断言。
  路由本身还有ModalBarrier，测试明确定位本菜单语义而不是错误假设整树只有一个Barrier。
- 原67张Golden仅3张歌曲列表因新增更多入口更新；其余64张PNG完全不变。新增Phone失效曲目菜单、
  Tablet取消收藏菜单、Windows深色读取失败/重试菜单，六张新增/改动PNG逐张查看，无溢出、无阈值调整。
- 80/80 Node；严格analyze零问题，273 Dart文件格式零修改。生成代码、Schema、迁移助手、lockfile零差异。
  五份设计指纹和ZIP24逐字节匹配；源码/包内六音频包与原生完整许可通过。
- 本机Android Debug通过（Gradle17.5秒），48 SVG/字体/许可资产一致，v2单Debug签名有效；
  Java原生访问警告保留，未关闭警告或改变平台设置。
  APK为231,779,561字节，SHA256：
  `4af41ed146c34cb5885313b16f929845196c417b65273164bf9e014173487535`。
  本地产物`build/app/outputs/flutter-apk/app-debug.apk`不提交Git，不替代用户要求的GitHub构建。

命令：`dart format --output=none --set-exit-if-changed lib test integration_test`、
`flutter analyze --no-pub --fatal-infos`、`flutter test --no-pub --reporter expanded`、
`node --test tools/*.test.mjs`、`dart run build_runner build`、`dart run drift_dev make-migrations`、
源码指纹/ZIP/源码及包内许可脚本、`flutter build apk --debug --no-pub`、`apksigner verify --verbose`。

## GitHub与后续

前置4386bd4的push33990865572/PR33990924357两组checks/Android/Windows均success，
已回填Phase6G3报告和Draft PR #44。专用音频job明确skipped，不计作新增实机音频证据。
本批独立提交推送后以`codex/search-detail-navigation`为base建立stacked Draft PR，
精确提交的云端源码/Android/Windows结果记录在PR；未完成前不把本地或前置成功当成本提交云端成功。

后续核验：实现`3ac653b2f5bf40515a2e7e33f39d499839936d6c`的
[push33992962833](https://github.com/Z-YO-YI/YYMusic/actions/runs/33992962833)与
[PR33992970922](https://github.com/Z-YO-YI/YYMusic/actions/runs/33992970922)均completed/success，
两组checks、Android Debug、Windows native build逐job通过；专用原生音频job为skipped，不计新增音频证据。
对应[Draft PR #45](https://github.com/Z-YO-YI/YYMusic/pull/45)开放未合并。

不合并main、不改写历史、不发布Release。普通push的Android job不上传APK，Windows开发Debug产物保留14天，
依赖Debug运行环境，并不是通用发行包；本机仍缺Windows C++/Debug CRT，Windows由GitHub构建。

下一批先核验当前精确提交双平台，然后按主指令Phase6顺序推进歌曲/歌单的真实操作；
歌单管理、导入/恢复、REST、完整播放器/歌词、设置与发行仍未完成，默认新安装仍是实际空库。
完整App.tsx NEW_ICON_SPRITE/POLISH_CSS和基础HTML继续作为设计依据，没有WebView或生产Fixture。
网页对照安全限制未绕过，Golden不是HTML视觉对照、原生音频实机验证或上线验收。
