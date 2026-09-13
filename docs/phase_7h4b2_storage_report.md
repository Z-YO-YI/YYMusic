# Phase 7H4B2：真实睡眠定时存储适配器

2026-09-13；基线db4375d4f9454456714963519728170c833c531c，fetch/pull --ff-only且工作区干净后建立codex/sleep-timer-storage，Draft base codex/sleep-restore-snapshot。先[计划](phase_7h4b2_storage_plan.md)/ADR111，再实现适配器与真实SQLite测试。

DriftSleepTimerRepository借用已有AppDatabase，只访问playbackSleepTimer键，保存用单语句upsert，清理用带精确键条件的单语句delete，原子更新且不改schema/其他设置。读取仅缺失返回null；B1 codec的非法记录通过私有标记映射安全schemaMismatch，不自动删除或重写未知版本。数据库/时钟异常映射databaseCorrupted并允许重试，原始SQL/记录不进入错误消息。

read/save/clear按调用时登记的Future尾链执行，前序失败不会阻断后续清理，错误仍可在操作Future观察。dispose返回稳定Future，立即拒绝新操作、等待已接受工作，包括延迟/失败的操作；不关闭借用数据库。同步依赖回调触发dispose时，当前写入已登记且必须等待完成。

新增20项测试：空读/重复清理、三种分钟选项精确upsert、无关损坏JSON隔离、save/read/clear/read无await调用顺序、分别阻塞SELECT/INSERT后排队写入和清理再关闭、五类坏记录不重写、SQL保存/清理失败回滚与重试、读取失败不伪装missing、关闭等待失败工作且原调用者仍见错误、时钟异常、重入关闭，以及真实SQLite文件三次打开验证保存和清理都持久化。测试临时目录仅包含新建测试数据，关闭连接后校验其位于systemTemp范围再清理。

完整2038 Flutter通过（114秒），156 Node通过（32.4秒），553 Dart文件格式零修改，严格分析0问题（16.1秒）；build_runner29秒、Drift迁移通过，生成/schema无差异。214既有Golden字节不变。四份设计原文件指纹一致，24ZIP条目逐字节一致，沿用App.tsx NEW_ICON_SPRITE/POLISH_CSS审计，本批无UI改动。

Android Debug17.9秒；48打包资产、完整音频许可、v2单签名者通过。APK232270343 bytes，SHA256 `866e1582dbd4d3fa8050902d0d64267b3d01e2dc4421faff6ec707c4c6fac8a5`，仍与A2b/B1相同，因为尚未被生产入口引用。Java native-access警告保留。不提交APK/测试临时数据；无新增实机安装/出声或本地Windows编译验收。

前置a4ca54e双CI34731476534/34731489397已SUCCESS；直接父db4375d的push34732285509已SUCCESS，PR34732312781核验时仍in_progress。新提交云端另行核实，不以父成功代替。

主要文件：drift_sleep_timer_repository.dart、存储单测/Node检查、ADR/README/状态/矩阵/计划。**真实存储适配器完成不等于应用已支持重启恢复。** 本批不注册AppDataServices，不修改session-only提示；B3继续根恢复、启动读写竞态、关闭排空和诚实失败反馈。平滑暂停及其余Phase7–11仍待验收，不自动合并或发布。
