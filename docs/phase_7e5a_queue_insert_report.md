# Phase 7E5A 阶段报告 — 添加/下一首根编辑

2026-09-12；GitHub `Z-YO-YI/YYMusic`；分支 `codex/queue-insert-intents`；fetch/pull 后基线 `8d9b4da7c838a0f222014f66b029a69b22fbc9be`；Stacked Draft PR base=`codex/queue-drag-sorting`。[计划](phase_7e5a_queue_insert_plan.md)及 ADR085 先于共享 API 修改。

## 交付与边界

- QueueEdit 新增 addToEnd/playNext：捕获不可变根与新 QueueEntry，拒绝重复 entry ID；同完整 TrackRef 可多次入队，保留 addedAt/current，位置归一化。末尾/当前项之后/无current时头部插入均为纯变换，空队列不选中、不自动播放。
- 复用根 submitEdit 的同步 busy、旧快照/页面许可取消、安全失败、同请求显式重试及关闭排空。成功插入不停止或重载正在播放的音频；失败不改原队列或播放状态，不把原始异常暴露给页面。
- 修复随机模式下显式下一首被重新洗牌的问题。插入仅扩展既有根随机序列、保留已访问游标与待播放次序；显式下一首位于当前随机游标之后，连续指定按最近一次优先，随后末尾添加不抹掉优先项。旧低层 add/playNext 复用相同顺序策略。三种循环的既有语义不变：单曲循环自动完成仍重播当前项，手动下一首可切换。
- 顺序只在 SQL 成功后更新，失败保留此前指定的下一首；写入等待期间开启随机也正确。仅复用原有 _shuffleOrder，不增加第二份队列/播放器/数据库或新后台任务。运行时随机顺序仍不跨启动保存，真实持久化队列及current可恢复；普通排序/移除/替换仍采用既有策略。

本批是 E5A 核心能力，尚未新增三端菜单按钮；E5B 将接入添加/下一首入口与页面反馈。无 UI、Golden、Schema、依赖、原生通道或原始资产变化。Figma转代码技能用于检查本地审计来源与可复用组件；没有在线node URL，未虚构线上设计读取或重绘图标。

## 验证

- 新增 **10 纯模型、18 核心、4 真实 SQLite** 测试；最终新旧队列目标集 **92/92** 通过。覆盖顺序/随机与旧新接口、重复完整引用/冲突ID、空/无current、连续下一首、追加、已访问游标、自动完成/循环、失败重试/原优先序保留、SQL期间切换随机、busy、过期取消及已接受写入关闭排空。
- 四组真实文件 SQLite 验证末尾/下一首的成功或 INSERT 触发器失败：DELETE后失败回滚全部原队列，显式同ID重试不重复；关闭并新建根后恢复条目順序、连续位置、完整来源引用、addedAt/current与收藏。Fake音频不计设备出声。
- 完整 Flutter **1445/1445 通过**（77秒）；Node **129/129 通过**（约29.8秒）。**473 Dart 文件**最终格式零修改，严格分析零问题（8.3秒）；build_runner成功（17秒），Drift迁移成功。161旧Golden全部通过且字节不变，生成文件/Schema/锁/平台/原始资产零差异。
- 严格检查曾发现测试导入排序和未使用导入，修正后重跑通过；不把首次失败计为成功。Node原门禁精确接纳新增提交参数，并新增仅成功持久化后扩展随机顺序的检查，未删除授权/单一根门禁。
- 再次核对 ZIP、App.tsx、基础HTML与主指令四源指纹无变化。ZIP全24条目一致，NEW_ICON_SPRITE/POLISH_CSS与原始SVG设计门禁通过，六音频包许可与完整原生材料通过。无凭据、用户媒体或环境文件入库；测试临时数据库限定系统临时目录内新建的专属子目录，关闭后只清理该验证过的路径。

## 构建与同步

本地 Android Debug仅预检，**18.5秒成功**；48原始资产、六包许可/完整原生法律材料、APK v2签名/单签名者通过。232,172,542 bytes；SHA256 `0be844ad37d9ffd44e716e010cf25424ef4058797b35365bc7602e592bbb6ec5`。构建与签名仍有 Java native-access警告，未掩盖为无警告；包/日志只在忽略的build目录。没有本批本机Windows运行或真机安装/出声验收。

前置 E4 精确 `8d9b4da` 的 [push34686488776](https://github.com/Z-YO-YI/YYMusic/actions/runs/34686488776) 和 [PR34686499064](https://github.com/Z-YO-YI/YYMusic/actions/runs/34686499064) 均 SUCCESS，已回填[PR #74](https://github.com/Z-YO-YI/YYMusic/pull/74)和E4报告。PR日志：Linux1252通过/161平台Golden跳过，Windows161Golden、2真实Runner、正式入口Debug重建/65文件包，Android48资产/许可/签名通过。手动音频诊断跳过，无Release操作。

本批审查提交并push后在Stacked Draft PR记录新SHA和两组常规CI链接，Android/Windows由GitHub独立构建，不用E4成功或本地APK预检代替新SHA云端通过。主要文件：`lib/domain/models/queue_edit.dart`、`lib/playback/queue_editing.dart`、`playback_controller.dart`，三份插入单元/SQLite测试与共享测试Fixture、`tools/queue_editing.test.mjs`，README/ADR/计划/报告/状态/矩阵。

未合并、改默认分支、发布Release、触发手动原生音频诊断或使用付费服务。Phase7菜单及其他剩余能力、Phase8导入/扫描/授权、Phase9来源、Phase10后台/系统媒体、Phase11签名/安装/发行仍待完成；新安装仍为空库，Debug不是日常可用发行版。
