# Phase 6A 增量 — 首页最近添加数据基础

2026-09-05，`codex/home-recent-catalog`，基于已fetch/pull的`db7998e`（Draft PR #35）。
前置两组GitHub checks/Android/Windows全部成功，真实窗口测试与六份许可日志已核对。

已重读主指令17.1/29/36，原HTML首页2144–2229和完整合成规则中App.tsx Hero/字重/阴影覆盖。
首页将保留问候、Hero、继续聆听、最近添加、音乐源、最近播放层级；三端独立组合、数据共用。
检查发现v1仅有文件modifiedAt，没有首次加入曲库时间，现有listTracks按标题分页，不能冒充最近添加。

先完成独立可验的数据增量，再组合首页UI：v2增加nullable tracks.added_at_ms及有序复合索引；
旧记录保持NULL（未知），不伪造导入日期；新upsert由Repository UTC时钟赋值，冲突更新保留首次时间。
LibraryRepository增加有起止时间、稳定排序、offset/limit/hasMore的最近添加分页查询，不拉取整库到UI。
使用原生SQLite迁移验证旧数据、引用、索引、重开、失败回滚，不删库、不重置用户数据。
v1快照保持原字节，新增v2快照和生成迁移/测试助手；不改依赖、不读写用户真实数据库。

出口：新增/重复扫描/并发写入/时间边界/同时间排序/分页/未知旧记录/坏窗口和生命周期测试；
v1→v2结构及数据完整迁移、重复打开无重复审计、失败保持v1可恢复；完整测试/静态分析/Golden、
源码指纹/许可、Android默认APK和GitHub Windows原生/双端构建。首页视图与聚合Controller另批继续，
本批不能宣称Home或Phase6全部完成。

依据：[Drift迁移助手](https://drift.simonbinder.eu/migrations/step_by_step/)、
[Drift写入与冲突更新](https://drift.simonbinder.eu/dart_api/writes/)。
