# Phase 6H10 — 系统歌单只读数据计划

2026-09-08，从已pull且干净的243299c755f9e0c11b6fd15a073eba1aae11faa6开始，
分支codex/system-playlist-projections。前置PR #54两组常规源码/Android/Windows均成功。
五份原始指纹、ZIP24项、44图标/52产物再次校验，沿用完整App.tsx/NEW_ICON_SPRITE/POLISH_CSS审计。
按主指令17.4、23及Phase6顺序，先交付可独立验证的数据层，不把系统视图伪装成自定义歌单。

- 先记录ADR-066。以SystemPlaylistType枚举读取喜欢/最近/队列，不分配或持久化伪Playlist父记录。
- 新只读模型保留完整TrackRef、缺失/失效引用、类型相关条目ID、时间及一致计数/窗口。
  喜欢以完整TrackRef标识；最近使用历史ID，最新20首；队列使用真实QueueEntry ID，重复曲目仍是不同条目。
- 一个绑定SQL在同一快照中读取计数、页、曲目与艺人；先限页后展开署名，无逐项getTrack或跨版本分页拼接。
  喜欢按addedAt DESC/完整引用ASC；最近按startedAt DESC/historyId ASC；队列按position。
  当前队列ID同语句读取，可在页外；队列位置不连续、状态缺失/悬空和坏曲目数据安全失败，不默默显示部分内容。
- 按类型提供无初始查询的失效通知；收藏/历史/队列及对应曲目/艺人变化可刷新，非对应集合不触发。
  Fake与真实SQLite合同一致；本批不新增任何写API、数据迁移、历史记录行为、页面、播放器或平台能力。
- 测试模型、三类型空/页尾/稳定排序、来源隔离/重复/失效、1003条限页再署名展开、真实变更通知/取消、持久化重开与损坏数据。
  全量格式/分析/Flutter/Node、生成/Schema/lock/指纹/许可门禁、本地Android预检和精确GitHub双平台构建。
  清晰提交并推送stacked Draft PR，不自动合并/Release，不提交凭据、用户数据或构建产物。

下一批再接系统歌单会话/原生入口及根播放动作；最近播放“真正开始才记录”的生产写入也要单独验收。
本批不宣称系统页面已可用，不跳到Phase8扫描/授权，不代替Phase7独立队列页；无需Figma或其他UI技能操作。
