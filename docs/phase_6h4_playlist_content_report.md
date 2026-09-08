# Phase 6H4 — 歌单内容读取会话报告

2026-09-08，`Z-YO-YI/YYMusic`，分支 `codex/playlist-content-sessions`，
基于 fetch/pull 后的 `cbe7bdc1b8c3e11bde293250db82d48162e9693c`。
本批交付下一阶段管理界面的读取基础；没有新增 UI，不把通过测试称为歌单管理或上线完成。

## 交付

- ADR-060 先于公共合同修改。新增 PlaylistContent/PlaylistContentEntry，内容不可变，
  强校验父身份、完整窗口、连续位置和独立条目 ID；同一 TrackRef 可以重复出现。
- CollectionRepository.readPlaylistContent(id, PageRequest) 用一条绑定参数 SQL 读取父信息、
  总数、窗口、曲目和有序艺人；先限制条目再展开艺人，按条目 ID 聚合，不逐首 getTrack。
  1000 条重复记录读取 offset980/limit7 只返回7条/14个双艺人展开行；窗口外损坏曲目不解码。
  完整三字段 TrackRef 左连接；曲目缺失保留条目/引用和 null Track，不捏造标题、路径或删除引用。
  count/max 联合既有非负/唯一约束验证全部位置连续性，损坏时失败关闭。
- 缺失父歌单返回 null，现存空歌单保留名称/说明且总数0；系统歌单拒绝本合同，
  收藏/历史/队列实时系统视图仍需后续单独接线，不把其持久条目为空误报为系统列表为空。
- watchPlaylistContentChanges 只通知相关表失效，不做查询或发初始全量数据。
  Drift 可能在事务回滚或其他歌单变化时保守通知；这不是提交日志，必须重读已存内容。
  根会话先订阅再首次读取，同毫秒改序/名称/曲目/艺人/可用性/删除恢复均能刷新，不以时间戳作版本号。
- 根 PlaylistContentSessions 管理惰性独立会话，构造/空闲零读取和订阅，不复制第二份曲库。
  单个一致前缀按20扩展到200；每次重读整个窗口，不拼接不同排序版本的页。
  超过200明确 capped，仓库仍可通过 offset 读取任意窗口；本批不宣称完整大歌单浏览已交付。
- 失效合并、旧结果/旧错误/旧事件代次隔离，Loading/Empty/Missing/Error 与重试明确；
  失败保留旧内容但 isCurrent=false，失效流出错/提前结束/建立抛错均可重建订阅后重读。
- 原生 SQLite 读取 Future 与订阅建立/取消分别登记排空，不假设 Stream.cancel 会终止原生查询。
  根关闭先拒绝新工作，等待真实读取和取消后再释放共享库；错误安全化且其他根资源仍可释放。
  通知中同步关闭先登记 close Future、停止工作，待通知栈退出再 super.dispose，避免 Flutter 生命周期断言。
- Fake 仓库提供同一条目身份/窗口/缺失引用语义，默认读写联动用于回归；未向生产默认空库注入样本。
  未改来源配置状态传播：isAvailable 只反映已持久 Track.availability，不能推断来源配置当前启用/删除状态。

## 验证

- **650/650 Flutter**，新增35项：5模型、11真实SQLite、19会话/生命周期。
  覆盖重复/来源/全部持久可用性、缺失/空/系统保护、窗口/位置损坏、单语句快照与艺人展开预算、
  回滚不暴露临时顺序、同毫秒命令与艺人更新、曲目删除恢复及父删除。
  另覆盖20→200/capped、突发失效合并、旧成功/失败/事件、保留过期数据及重试、
  订阅构造/取消重入、根监听器中同步关闭、真实 SQLite 查询门控和失败后的资源释放。
  原有73张 Golden 全量通过、字节未改；未新增或降低视觉阈值。
- **88/88 Node**，新增2项读取/根生命周期边界门禁；严格 analyze 零问题。
  295个 Dart 文件最终格式零修改；build_runner、make-migrations 重跑，
  生成代码、Schema、迁移、依赖与 lockfile 零差异。五份来源指纹、ZIP24项逐字节、源码许可通过。
- Android Debug 本地预检成功（Gradle21.6秒），48份SVG/字体/许可资产逐字节一致，
  六包及原生许可验证通过，v2单Debug签名有效。APK231,835,013字节，
  SHA256 `9553fda504860ff6e76c152950b242f0097a358be4e9f1e2256de6afa57d7988`。
  `build/app/outputs/flutter-apk/app-debug.apk` 仅本地产物、不入Git、不替代用户要求的GitHub构建交付。
  保留JDK原生访问警告，未升级全局环境或关闭检查。

验证命令：`dart format --output=none --set-exit-if-changed lib test integration_test`、
`flutter analyze --no-pub --fatal-infos`、`flutter test --no-pub --reporter expanded`、
`node --test tools/*.test.mjs`、两个Drift生成命令、指纹/ZIP/许可检查、
`flutter build apk --debug --no-pub`、`verify_android_apk.ps1`及`apksigner verify --verbose`。

## GitHub 与剩余边界

前置H3精确提交 `cbe7bdc1b8c3e11bde293250db82d48162e9693c` 的
[push34198822942](https://github.com/Z-YO-YI/YYMusic/actions/runs/34198822942) 与
[PR34198919253](https://github.com/Z-YO-YI/YYMusic/actions/runs/34198919253)
两组 checks/Android Debug/Windows native 全成功，Draft PR #48仍OPEN，本批回填其报告。
本批审查后推送 stacked Draft PR，base=`codex/playlist-entry-commands`；
精确提交与本次云端结果记录于对应PR。本地或前置成功不代表新提交云端验收。
普通push的Android job不上传APK，Windows Debug artifact为需开发运行环境的14天审查包。
未合并/发布/改写历史，未提交凭据、日志、构建产物或用户数据；Windows继续由GitHub构建，
不把本机缺失C++/Debug CRT的限制当作已经解决，也未重跑专用实机音频测试。

下一增量接三端原生歌单内容管理入口、条目动作与播放，随后继续Local/Settings等主指令阶段。
系统歌单实时入口、超过200条的页面浏览策略、导入/恢复、实时REST、完整播放器/歌词、
平台集成和发行仍未完成；默认新安装仍为空库，尚不是完整可用或上线版本。
完整App.tsx的NEW_ICON_SPRITE/POLISH_CSS及基础HTML保持为设计依据。
既有网页对照安全限制不绕过；Golden/构建不能替代网页对照或设备音频验收。
