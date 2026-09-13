# Phase 7H4B2：睡眠定时专用存储

基线db4375d；实现DriftSleepTimerRepository，借用已有AppDatabase，仅访问playbackSleepTimer键，不改schema。单语句upsert/delete保持原子性，使用B1严格codec，未知/损坏记录读失败而不自动重写或删除。格式失败映射schemaMismatch，其余数据库/时钟失败映射安全databaseCorrupted，不回显原记录。

使用Future尾链在调用时登记，所有read/save/clear按接受顺序执行；失败消化到内部尾链以允许后续操作，错误仍返回原调用者。dispose立即拒绝新调用并返回稳定排空Future，必须等待此前读写清理，不关闭借用数据库；回调重入也不能漏登记。

验证真实SQLite文件关闭重开、专用键隔离、保存/读取/取消顺序、读取阻塞期间新操作、失败后继续/回滚、损坏记录保留、关闭排空/拒绝新调用、时钟重入关闭。不在此批接AppDataServices或根恢复、不改session-only文案。后续B3再实现根与启动/关闭协调，避免接口存在就误称恢复可用。
