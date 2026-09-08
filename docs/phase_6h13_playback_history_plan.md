# Phase 6H13 — 真实播放确认与历史持久化计划

2026-09-08，Z-YO-YI/YYMusic，codex/playback-history-recording。
从fetch/pull后的干净07ee2dbe579456b24c96e80e6b262fa0fdfeb8c1开始；PR #57两组常规检查成功，push第二次运行恢复上传。
复验五指纹/44图标/52产物、ZIP24项；复读主指令23及Phase6–11，保留H12完整App.tsx/HTML审计，重核最终Sprite/POLISH_CSS。

目标：单根PlaybackController确认实际播放时钟前进后写入同一CollectionRepository，最近20首、同曲置顶、完整来源身份保留。
不是按按钮点击、load完成、play请求ack或playing布尔值直接写历史；不额外增加试听时长门槛。

- 新增playback_history_recorder.dart；PlaybackController拥有并关闭，UI/音频插件均不直接写库。
- begin只在新加载/明确重放周期建立；play启动确认观察，暂停恢复/缓冲/seek不重复记录同次聆听。
  新周期中至少看到playing样本与后续更大的播放位置才确认；已playing的短曲在completed携带位置前进时也可确认。
  seek/pause/stop/错误/加载边界隔离，迟到的无已加载身份事件不写。真实听觉/设备语义不以Fake替代。
- 冻结完整TrackRef、独立随机ID、确认时间和首次确认位置；串行写任务先注册，再调用可重入clock/idFactory与存储，根关闭等待排空。
- 同毫秒与时钟回退时，排序时间至少为最新存储/本会话已分配时间+1毫秒；保留到毫秒的稳定置顶语义，不新增Schema。
- 失败独立于音频phase；最近播放页复用现有YYErrorBanner，最新失败可重试，过期失败只能知悉，旧回调不能操作后来的失败。
  ID碰撞不得覆盖其他完整来源；补真实SQLite事务保护及Fake等价行为。
- 文件涉及播放根/Recorder、PlaybackPresenter、系统最近页提示、CollectionRepository实现与测试、README/状态/矩阵/ADR/报告。
  共享合同变更先记ADR-069；复用Figma设计转代码技能的YY组件/Token/原始图标，输入仍仅本地导出，无在线节点，不虚构get_design_context。

风险：ack误当播放、暂停/seek重复、跨曲旧事件归属、同毫秒排序、写入阻塞音频、写失败被吞掉、关闭提前释放SQLite、重试把旧历史置顶。
出口：单元/真实SQLite/根与三端页面/失败Golden、全量格式分析Flutter/Node/指纹/生成/许可、本地Android预检、精确GitHub双平台通过并推送Draft PR。
本批不新增清历史确认/系统收藏写菜单/队列编辑、导入/第三方来源/后台媒体/Release；这些依主Phase6–11继续独立验收。

复查补充：已有首页清除必须与新自动保存共用串行通道，避免用户确认清除后旧待写记录复活。
仅接线现有确认入口，不新增清除UI；清除前的写入先排空，清除后的新聆听正常记录，失败安全返回现有首页提示。
