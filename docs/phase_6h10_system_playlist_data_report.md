# Phase 6H10 — 系统歌单只读数据报告

2026-09-08，仓库`Z-YO-YI/YYMusic`，分支`codex/system-playlist-projections`。
从fetch/pull后干净的`243299c755f9e0c11b6fd15a073eba1aae11faa6`开始；前置PR #54两组常规检查成功。
复核五份设计指纹、ZIP24项及完整App.tsx/HTML审计产物，重读主指令17.4/23/Phase6顺序，先记录计划/ADR-066。

## 交付与主要文件

- `system_playlist_content.dart`：与自定义歌单分离的不可变只读窗口，包含枚举类型、计数/页、完整TrackRef、
  类型相关身份、UTC时间、可选曲目和页外也可保留的当前队列ID。喜欢没有伪条目ID，历史/队列使用真实记录ID。
- `collection_repository.dart`与`drift_system_playlist_content.dart`：枚举选择固定SQL片段，分页参数绑定；
  一个语句完成计数/页/曲目/艺人/队列状态读取，先限页后署名展开，不N+1、不拼版本不同的分页。
  喜欢addedAt DESC/完整身份ASC，最近startedAt DESC/historyId ASC且最多20，队列原position顺序。
  引用缺失或不可用仍保留；队列全局位置不连续、负数位置、状态缺失/悬空及可见坏曲目安全失败。
- 新失效流只监听对应集合及曲目/署名表，没有初始内容查询；当前ID变化也能刷新队列，自定义歌单变更不误触发。
  不把通知视为成功提交日志。后续会话必须先订阅后查询，并负责接受工作/取消/关闭排空。
- Fake以同一合同投影；收藏时间使用注入时钟，历史写入按完整TrackRef去重/排序/限20，修正原测试替身与SQLite差异。
  生产历史写入逻辑没有改变，根播放器也未新增recordHistory调用。
- README、实施状态、测试矩阵和前置H9精确云端证据同步更新；本批没有页面、主题、图标、Schema、迁移或新依赖。

## 验证

- **837/837 Flutter通过**（57秒），新增25项：3模型、10 Fake/SQLite共用合同、11 SQL/通知/损坏边界、1文件库重开。
  1003队列三署名的两条页仅六展开行，1003收藏两署名的三条页也仅六行，每次只一个绑定查询、无写事务。
  同时间稳定排序、新收藏置顶、最近20/同曲置顶/清空不删曲库、重复队列、完整来源及所有可用性验证。
  旧快照不会混入随后写入；实际artist/queue_state变更通知，无初始SQL、无无关自定义歌单事件，取消后停止。
  重开真实SQLite文件后喜欢/历史/重复队列/当前项和曲库来源不变，父歌单仍为空；仅精确清理测试临时文件，不递归删除。
- **100/100 Node通过**；严格分析零问题、342 Dart文件format零修改；build_runner/make-migrations后生成/Schema/迁移测试/lock零差异。
  84张Windows宿主Golden通过且全部字节未改，不宣称新系统UI或网页对照完成。
- 五指纹、44图标/52确定产物、ZIP24项逐字节、六音频包LICENSE/完整原生材料通过。
- Android本地Debug预检成功（Gradle21.4秒），231,919,321字节，SHA256
  `4dd00db72ef9b017d13cf417c164bdc8a037214fac484d2a181fed44d15144ca`；48包内资产、NOTICES.Z、完整原生材料、v2单签名通过。
  JDK native-access警告未隐藏，APK/日志只在忽略的build目录；正式双平台结果以GitHub精确head为准。
- 开发中新增测试两处多行if的Lint失败已修正并全量重跑，没有关闭Lint/删测试/放宽生产Schema或Golden阈值。
  损坏数据注入仅在测试内短暂关闭约束，读取前恢复；生产约束不变。

## GitHub与后续

本批完成审查后清晰提交、推送到独立分支，创建base为`codex/playlist-play-all`的stacked Draft PR。
由该PR补精确实现提交的push/PR双组源码/Android/Windows日志和附件元数据，不以前置成功冒充本批结果。
不自动合并、不force、不发布Release，不提交凭据、用户数据或构建产物。

下一批是系统歌单会话/原生入口和根播放动作，再验收真正开始播放后才写入历史。
Phase6仍有Local Music/Settings；Phase7完整播放器/歌词/队列、Phase8真实扫描/权限、Phase9来源、Phase10–11系统媒体/QA/发布均未完成。
本批只读数据层未改变用户当前UI，不代表系统歌单已经可点击使用；默认新安装为空库，没有实际导入入口，Debug不是发行安装程序。
