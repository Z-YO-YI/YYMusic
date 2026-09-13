# Phase 7H6B1：自动继续偏好持久化契约与SQLite适配

## 本批范围

为H6A根continueAfterTrack策略新增PlaybackContinuationRepository与Drift实现，单独存储playbackContinueAfterTrack设置。只保存布尔偏好，不保存播放状态、队列或音频数据；没有新增无缝/响度标准化假开关。使用已有AppSettingRecords，schema版本不变，无迁移/生成输入变化。

PlaybackContinuationCodec使用version=1、continueAfterTrack布尔字段，限制输入128字符，验证版本整数、字段数量和布尔类型；未知版本、多余字段、缺失/错误类型、无效JSON等抛固定FormatException，异常不带原记录。缺失才返回null；坏记录与I/O失败不能冒充缺失，不在读取时写默认或清理数据。

SQLite适配器只读写专用key，单语句upsert原子替换。调用即登记Future尾链，读写按接受顺序执行；单次失败对原调用者可见，尾链吸收失败后继续下一项。无效记录映射schemaMismatch，其余存储错误为安全databaseCorrupted，保留可重试标记。dispose同步拒绝新工作并排空已接受操作，幂等、不关闭借用数据库。

此阶段仅是实际存储适配，**尚未注册AppDataServices、启动恢复协调或设置页开关**。不能因为SQLite单测可重开就声称应用重启恢复已经接通。

## 验证

新增21项测试：两种布尔往返、11类非法输入/安全错误、缺失不写默认、保存/读取顺序、未知版本保留且显式保存恢复、无关设置隔离、关闭拒绝/排空且DB仍可用、依赖失败后继续、阻塞写入及后续替换先于关闭完成，以及真实临时SQLite文件三次打开验证false/true保留。临时文件测试只清理自身创建并验证处于系统临时目录内的目录。

首批20专项通过，追加阻塞写入测试后全量2307 Flutter通过（136秒）。589 Dart格式零修改，严格分析0问题（16.2秒），160 Node通过（44.61秒）。Android Debug预检10.3秒通过，48资产及完整音频许可验证通过，既有Java原生访问警告保持；无新增设备安装/听感验收。本机Windows symlink限制未变，GitHub Actions负责本提交双平台构建。

ZIP/主指令/App.tsx/基础HTML四个SHA256匹配Phase0基线，24个解压条目逐字节验证通过；未改变NEW_ICON_SPRITE/POLISH_CSS或HTML。220张Golden不变，无依赖升级或不必要构建产物提交。

## Git与后续计划

开始前fetch/ff-only pull，基线79d613e，独立分支codex/continuation-preference-storage，Draft目标codex/playback-auto-continue。父运行34746525781仍在执行，不记为已通过；本提交另验，不自动合并或发布。

H6B2接生产数据范围及受保护恢复/保存协调器：读取晚到不能覆盖用户新选择（包括选择与当前默认相同的值），缺失保留默认，坏记录保留并反馈；仅用户显式新选择允许覆盖。恢复只改变策略，不调用play，不让旧完成事件复活。保存按最新意图串行，退出先冻结观察和排空写入再关闭存储。之后H6C接设置页开关和重试状态，完成三端布局/回归；Phase7其余能力和Phase8–11仍待完成。
