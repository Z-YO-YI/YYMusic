# Phase 6H1 — 歌单元数据命令报告

2026-09-06，仓库`Z-YO-YI/YYMusic`，分支`codex/playlist-metadata-commands`，基于fetch/pull后的
`3ac653b2f5bf40515a2e7e33f39d499839936d6c`。本批只完成歌单编辑数据/状态基础，没有新UI或路由。
创建、改名、删除按钮尚未接线，不能宣称用户现在已经能管理歌单。

## 交付与边界

- ADR-057在公共合同变更前记录。CollectionRepository新增createPlaylist和renamePlaylist：
  前者只插入自定义歌单，ID已存在则失败；后者仅修改仍存在的自定义歌单，目标删除后不静默重建。
  两者在既有Drift事务中核验，保留savePlaylist既有引导/upsert语义，不改Schema。
- PlaylistName统一trim、1–512（沿用Dart字符串长度规则）、拒绝C0/C1控制字符；
  输入错误不写仓库，不携带输入原文。随机128位ID不由名称生成，同名歌单保持独立身份。
- 系统歌单禁止通过编辑命令创建、重命名、删除；改名保留description、createdAt和全部条目，
  updatedAt不因本机时钟回拨倒退。删除沿用既有幂等合同和级联条目删除，不删除曲目、收藏、历史、队列或文件。
- 根PlaylistController只管理命令，不订阅/缓存第二份列表，不在构造期读数据，不依赖Shell启动。
  复用同一CollectionRepository，真实Library投影收到实际数据库变更；没有隐式播放或引擎调用。
  busy拒绝并发点击，操作在通知前登记，已接受写入在关闭后继续排空，最后才关闭共享存储。
  返回明确安全结果，不暴露异常原文；创建碰撞不自动重试可能已成功的写入。
- UI未提交草稿、确认删除和布局适配属于Phase6H2。本批删除仅发生在内存测试库，没有操作用户歌单。
  未改平台/播放引擎/路由/设计原语/参考HTML，未添加依赖或生产Fixture。

## 验证与修正

- 551/551 Flutter，包括全部70张未改动的Windows宿主Golden。新增12项Controller和8项真实SQLite测试。
- 创建碰撞不覆盖旧名称/说明/条目，并发同ID请求只有一次成功；系统三类型均拒绝编辑命令。
  空白/超长/换行/C0/C1输入、512长度边界、同名不同ID、缺失目标、读后不upsert、删除幂等通过。
- 改名保留混合来源引用、条目ID/顺序/addedAt以及元数据，时钟回拨不倒退；删除后曲目、收藏、历史、
  当前队列及其他歌单/条目仍完整。SQLite触发器模拟UPDATE或级联DELETE失败，事务回滚且错误脱敏。
- 根构造无读/订阅，重复通知重入被busy挡住；ID工厂建立过程中关闭仍完成已登记写入。
  写入成功/失败两种情况下根都等待在途任务，再恰好一次关闭借用的共享库；不把失败伪装成功。
- 初始SQLite删除范围测试忘记初始化LibraryRepository，补正确生命周期后通过，未改变生产初始化要求。
  Node根关闭顺序断言显式加入playlists；另一个新断言错误假设条件分支后有逗号，改为验证两个目标存在且顺序正确。
  未放宽SQL系统保护、关闭排空或Golden要求。
- 82/82 Node，严格analyze零问题，278 Dart文件格式零修改。
  build_runner和make-migrations重跑，生成代码、迁移、Schema及lockfile零差异。
  五份设计指纹与ZIP24一致，源码/包内六音频包及原生完整许可通过。
- 最终本地Android Debug通过（Gradle16.1秒）；48 SVG/字体/许可资产逐字节匹配，v2单Debug签名有效。
  Java原生访问警告保留，未关闭或绕过。APK 231,787,538字节，SHA256：
  `fcc85ed5dbdd5748b68625ff5c6fbf273364ec2a7bc5785b075439a61c4f3b3f`。
  本地产物`build/app/outputs/flutter-apk/app-debug.apk`不提交Git，不替代用户要求的GitHub构建。

命令：`dart format --output=none --set-exit-if-changed lib test integration_test`、
`flutter analyze --no-pub --fatal-infos`、`flutter test --no-pub --reporter expanded`、
`node --test tools/*.test.mjs`、`dart run build_runner build`、`dart run drift_dev make-migrations`、
指纹/ZIP/源码及包内许可脚本、`flutter build apk --debug --no-pub`和`apksigner verify --verbose`。

## GitHub与下一步

前置3ac653b的push33992962833/PR33992970922两组checks/Android/Windows均success，
已回填Phase6G4报告及Draft PR #45。专用音频job为skipped，不计作新增音频证据。
本批提交推送后以`codex/catalog-detail-track-actions`为base建立stacked Draft PR；
精确提交的云端源码/Android/Windows结果在PR记录，不以前置或本地成功替代本提交云端成功。
不合并main、不发布Release，不改写历史。普通push的Android job不上传APK，Windows Debug保留14天，
依赖开发Debug运行环境，不是通用发行包；本机Windows C++/Debug CRT限制仍在，Windows由GitHub构建。

2026-09-08续检：实现`1dd92eff6db50aa3ee6fd6e14f95321114c77746`的
[push 33994757759](https://github.com/Z-YO-YI/YYMusic/actions/runs/33994757759)与
[PR 33994765770](https://github.com/Z-YO-YI/YYMusic/actions/runs/33994765770)
均completed/success，源码检查、Android Debug、Windows native build均success。
Windows宿主Golden和窗口握手通过，专用音频任务skipped，不计作新音频证据；
普通push的Release步骤skipped，未发布。Draft PR #46仍OPEN，base为codex/catalog-detail-track-actions。

下一批推进Phase6H2原生创建/改名/删除界面、确认和离页交互。
歌单详情/添加移除排序/播放全部、导入恢复、REST、完整播放器歌词、设置与发行仍未完成。
完整App.tsx NEW_ICON_SPRITE/POLISH_CSS与基础HTML继续作为设计依据，未绕过网页对照安全限制；
Golden不代替HTML视觉对照或实机音频验收，默认新安装仍是无Fixture空库，不是上线版本。
