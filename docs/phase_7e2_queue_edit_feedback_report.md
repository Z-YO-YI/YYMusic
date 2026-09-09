# Phase 7E2 阶段报告 — 根队列编辑反馈

2026-09-09；GitHub `Z-YO-YI/YYMusic`；分支`codex/queue-edit-feedback`；基线`3d89cc85b183fd524972c42a6ed3f733e20e943f`，Stacked Draft PR base=`codex/queue-edit-intents`。开始前核对远程/工作区并fetch/pull最新，[计划](phase_7e2_queue_edit_feedback_plan.md)及ADR082先于共享API变更。

## 实际新增与修改

- QueueEditResult区分applied/cancelled/busy/failed，每次返回自己的失败身份。QueueEditFailure仅保留原始不可变意图和固定安全DomainFailure/提示，不保存原异常或私有路径。
- 现有根QueueController新增submitEdit、editBusy、editFailure、retryEdit/canRetryEdit及dismissEditFailure；队列仍唯一存于PlaybackController。没有新的数据缓存、Repository、计时器或音频对象。
- 同步busy阻止重复提交；过期快照、no-op或撤销的页面许可返回正常取消，不生成伪失败。SQL一旦接受，离页依照E1提交语义，失败留在根状态，重新订阅即可知悉。
- 重试必须匹配当前失败对象和原根快照；同值/同时间替换、当前项切换或其他成功编辑后不可把旧确认重绑新队列。其他成功不抹未处理失败；同失败身份成功重试或显式知悉才清除，失败再次发生生成新身份，旧回调无效。
- 待处理Future先于通知/依赖调用登记；结果结算清busy后通知，监听者可立即再提交或关闭。QueueController.close排空结果/失败处理，DependencyGraph在释放播放器、引擎和存储前等待该屏障；旧edit及程序化API保持兼容。

对应HTML renderQueue的真实队列操作反馈，不复制模拟Toast、DOM或localStorage。原始指纹审计仍覆盖App.tsx完整NEW_ICON_SPRITE/POLISH_CSS；本批没有新UI、WebView、图标、字体、Golden、Schema、依赖或平台修改。失败提示尚未接正式队列页面，不把状态接口称为可见UI完成。

## 测试与构建证据

- 新增**25项Flutter**：22模型/反馈单元及3实际SQLite；目标25/25通过。覆盖四结果、同步busy/双提交、旧快照/无变化/离页取消、安全失败、跨订阅保留、明确重试/再失败新身份、无关成功、同值替换/当前项变化、旧知悉与同值伪造失败、重试中知悉/取消，以及开始/终态监听重入关闭或再次提交。
- 实际SQLite在DELETE暂停时移除页面订阅，故障回滚后新的订阅者仍获得同一失败；移除测试故障后显式重试成功且数据库队列正确。成功和失败两种关闭测试证明根等待实际SQL及反馈结算，再各释放引擎/数据库一次；失败结果安全返回而非未观察Future异常。没有Widget或实机出声的新证据。
- 最终`flutter test --no-pub --reporter expanded`：**1350/1350通过**，约97秒；含146张Windows宿主Golden，全部旧图字节不变。450→454个Dart文件，格式零修改；严格`flutter analyze --no-pub --fatal-infos --fatal-warnings`零问题（14.4秒）。
- Node **126/126通过**（约18.1秒），新增根保留/身份授权/先登记工作/关库顺序门禁。两处旧精确关闭顺序断言添加queue.close，原lyrics→playback→engine/data先后约束保留；修正一处新测试缺失花括号后重跑，没有关闭Lint或删测试。
- `build_runner build`成功（约19秒），`drift_dev make-migrations`成功；生成代码/Schema/lock/原始assets/Golden零差异。原始指纹、ZIP24条目、44SVG/52确定输出、六音频包LICENSE及完整原生法律材料通过。
- 本地Android Debug预检构建成功（66.1秒），48原始资产/六音频包/完整原生许可一致，v2签名验证成功、单签名者。APK **232,134,517 bytes**，SHA256 `324276139f2cf4b70a81348399ce64be092bf35a8249f18b0f6d3b7720aebbe4`；包/日志仅在忽略的build目录。正式Android/Windows按本批新SHA由GitHub Actions构建；本机未运行本批Windows构建或设备安装。

## GitHub同步与边界

前置E1实现3d89cc8的[push34300327819](https://github.com/Z-YO-YI/YYMusic/actions/runs/34300327819)与[PR34300332649](https://github.com/Z-YO-YI/YYMusic/actions/runs/34300332649)均SUCCESS，源码/Android/Windows通过；Windows146Golden、2实际Runner及正式入口65文件Debug包/许可成功，Android51原生坐标/3完整法律文本、48资产/v2单签名者通过。[PR #71](https://github.com/Z-YO-YI/YYMusic/pull/71)及[E1报告](phase_7e1_queue_edit_intents_report.md)已回填，不替代E2新SHA验收。

本批审查/敏感候选检查后提交push并创建Stacked Draft PR，精确SHA及push/PR链接记录在对应PR；未完成的新云端验证不记成功。不自动合并、改默认分支、发布Release、触发手动媒体诊断或操作付费服务。不提交凭据、环境文件、用户媒体或构建产物。
15个文本文件/候选路径敏感检查零命中，`git diff --check`通过。文档链接更新后再次运行126项Node全部通过（约15.8秒），没有原始资产、生成文件或截图基线改动。

主要文件：`lib/playback/queue_controller.dart`、`queue_edit_feedback.dart`、`queue_edit_result.dart`和`lib/app/dependency_graph.dart`；新增两份反馈测试，更新Node门禁及README/ADR082/计划/报告/状态/矩阵和E1精确验收回填。

## 下一阶段

接独立队列的有界显示/根快照映射、确认和键鼠/拖拽UI，再继续Phase7其余能力；真实导入/扫描/授权、来源、后台/系统媒体和发行验收仍按Phase8–11推进。新安装仍为空库，普通AndroidCI没有APK artifact，Windows开发Debug依赖Debug CRT；本批不代表日常可用发行版或上线。
