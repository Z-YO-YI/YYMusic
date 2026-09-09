# Phase 7E1 阶段报告 — 队列编辑意图与根串行写入

2026-09-09；GitHub `Z-YO-YI/YYMusic`；分支`codex/queue-edit-intents`；干净基线`dff7c3233b6be5731d2e8392fe83422787ef67c9`；Stacked Draft PR base=`codex/fullscreen-page-lifecycle`。已核对远程并fetch/pull最新，[计划](phase_7e1_queue_edit_intents_plan.md)与ADR081先于共享API变更。

## 实际实现

- 新增纯Domain QueueEdit：不可变QueueSnapshot身份绑定、独立entry ID移除/清空、beforeEntryId锚点移动（null为末尾）。不使用旧可见行索引，保留完整来源引用、addedAt和重复条目；输出连续位置，原快照不变。无变化移动/空清空返回no-op，不写库；缺失目标/锚点构造时拒绝。
- PlaybackController新增editQueue，仍走原有单串行命令队列和CollectionRepository事务；执行前及可能等待的停止后检查根快照/页面许可，旧快照、当前项改变、已释放Facade/根或离页取消未开始编辑。同值同时间的新快照也不接受旧确认。
- 一旦SQL开始，离页不回滚已接受的持久化，成功后应用完整快照；根关闭等待已接受SQL后再释放引擎和数据库。监听回调中关闭Facade/根使用通知深度保护，避免ChangeNotifier在通知内直接销毁的断言。
- 非当前项编辑保留音频和播放相位，不重载、停止或更换当前曲目；保存失败返回固定脱敏DomainFailure，允许显式重试，不伪装音频故障。移除当前项/清空沿用既有“先停止，选择相邻项但不自动播放”策略；停止后授权取消或保存失败不擅自重播，失败时旧队列保留。
- QueueController仅转发和生命周期许可，没有第二份队列、SQL或媒体时钟；旧程序化API兼容。当前阶段没有新增忙态/失败反馈界面、菜单或独立队列路由。

HTML renderQueue的上移/下移/移除/清空转成原生业务意图，浏览器queueIds索引、DOM与localStorage不复制。源审计仍覆盖App.tsx完整NEW_ICON_SPRITE和POLISH_CSS；本批无视觉改动、不使用WebView、没有改原始图标或字体。

## 测试与构建

- 新增**38项Flutter**：12纯模型、19播放核心、7实际SQLite；目标测试38/38通过。模型涵盖正反向锚点、末尾/self/相邻no-op、完整来源/addedAt、当前项相邻选择、空态、错误参数和1003条完整队列。
- 核心涵盖一次写入/无音频重载、随机/循环保留、精确重复条目、当前移除停止一次、同值替换/当前项变更/竞争编辑、离页/Facade/根关闭、停止后取消、SQL开始后离页、写入/停止失败、重试、监听者/许可回调重入关闭及排空。
- 实际SQLite验证DELETE后INSERT故障与最终queue_state UPDATE故障全事务回滚，原始当前位置/条目/时间恢复；1003条可完整移动、没有tracks SELECT或截断；收藏/历史不误改。成功和失败各一条实际磁盘测试在DELETE暂停时关闭根，证实数据库/引擎仍存活，释放后才关闭，再重开核对提交或回滚后的完整队列。临时测试目录先校验位于系统临时目录且名称前缀匹配才清理，无用户数据操作。
- 最终`flutter test --no-pub --reporter expanded`：**1325/1325通过**，约74秒；包含146张Windows宿主Golden，全部旧基线未改。未放宽阈值、跳过测试或关闭Lint。测试失败路径加入gate清理，磁盘重开前显式关闭其他测试数据库，不静音Drift警告。
- Node **125/125通过**，包含新增根快照/串行/不直接音频或SQL/安全失败门禁。450个Dart文件格式零修改；严格`flutter analyze --no-pub --fatal-infos --fatal-warnings`零问题（11.0秒）。`build_runner build`成功（约15秒），`drift_dev make-migrations`成功；生成/Schema/lock/原始assets/Golden零差异。
- 原始指纹、ZIP24条目、44SVG/52确定输出、源码六音频包许可/完整原生法律材料复核通过。
- 本地`flutter build apk --debug --no-pub`预检成功（51.8秒），48资产/六音频包/完整原生许可一致，v2签名验证成功、单签名者。APK **232,130,785 bytes**，SHA256 `ce20d38f5237b532cace4c1a9e19926365e0de14b6f71f25ad2b78202963f37b`；包与日志留在忽略的build目录。正式Android/Windows按新提交由GitHub Actions构建，本机未构建本批Windows或进行设备安装/出声验收。

## GitHub同步与前置验收

前置dff7c32的[push34297862194](https://github.com/Z-YO-YI/YYMusic/actions/runs/34297862194)与[PR34297866163](https://github.com/Z-YO-YI/YYMusic/actions/runs/34297866163)均SUCCESS：Windows146Golden、2真实Runner、正式入口重建/65文件包及Android资产/许可/签名通过。[PR #70](https://github.com/Z-YO-YI/YYMusic/pull/70)和[D2报告](phase_7d2_fullscreen_pages_report.md)已回填；Android系统栏/Windows多显示器DPI仍未做设备验收。

本批代码/测试/文档审查后清晰提交push并创建Stacked Draft PR，新SHA及精确push/PR链接在对应PR核对，不借前置成功表示新CI通过。不自动合并、修改默认分支、发布Release、触发手动音频诊断或操作付费服务；不提交凭据、环境文件、用户媒体或构建包。
15个文本候选文件的敏感模式及全部候选路径检查零命中，`git diff --check`通过；没有新增截图、原始资产或不必要构建产物。最终Node125项在文档链接更新后再次通过（17.7秒）。

主要文件：`lib/domain/models/queue_edit.dart`、`lib/playback/queue_editing.dart`、`playback_controller.dart`、`queue_controller.dart`；新增三份queue_edit单元/SQLite测试与Node门禁；README、ADR081、计划/报告/状态/矩阵及D2精确验收回填。

## 限制与下一步

本批只是Phase7E1核心能力；后续接根编辑反馈、当前队列只读投影到独立管理界面、确认和键鼠/拖拽操作。不可播放项自动跳过及错误记录、真实封面/收藏等Phase7剩余能力继续分批验证。Phase8导入/扫描/授权、Phase9来源、Phase10后台/系统媒体、Phase11发行/设备验收未完成，新安装仍为空库。普通AndroidCI无APK artifact，Windows开发Debug依赖Debug CRT；不将Debug或接口完成宣称上线。

## 精确云端验收回填

实现`3d89cc85b183fd524972c42a6ed3f733e20e943f`，[Draft PR #71](https://github.com/Z-YO-YI/YYMusic/pull/71)；[push34300327819](https://github.com/Z-YO-YI/YYMusic/actions/runs/34300327819)及[PR34300332649](https://github.com/Z-YO-YI/YYMusic/actions/runs/34300332649)均SUCCESS，head SHA一致。Linux1179通过/146Windows宿主Golden预期跳过；Windows146Golden和2真实Runner（restoration/minimize/detach均true）通过，正式入口重建/65文件Debug包及完整许可通过；Android51原生坐标/3完整法律文本、48资产及v2单签名者通过。
[本SHA Windows开发Debug包](https://github.com/Z-YO-YI/YYMusic/actions/runs/34300327819/artifacts/10085019844)：67,590,554 bytes，SHA256 `fdf1160ab45531d33a1997febca46dfbe5359dc53ba16bdc5f3fe1fe16dde466`，到期UTC`2026-09-23T01:58:26Z`。仍依赖Debug CRT；普通Android无APK artifact，没有Release/手动媒体诊断或设备安装验收，不代替E2新SHA验证。
