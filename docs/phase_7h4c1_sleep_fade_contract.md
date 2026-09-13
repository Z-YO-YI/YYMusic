# Phase 7H4C1：淡出曲线契约与接入审计

本批是H4C的第一步，**尚未接入到期路径，不能声称应用已经平滑暂停**。不改变界面、依赖、schema或既有截图。来源为总指令§26，继续使用已审计的App.tsx（含NEW_ICON_SPRITE/POLISH_CSS）与基础HTML，不重新解释为WebView。

## 已实现

`SleepFadeEnvelope`为无状态纯计算：2秒线性振幅淡出，建议50ms采样；负时间钳制起点，超过终点为零，最后一次等待缩短到实际剩余值。逐次传入最新用户音量，拒绝非有限值/越界值，不缓存旧音量，不产生Timer、引擎命令、持久化或播放状态。线性振幅不是等感知响度；时长是初版工程决定而非用户原文规定，实际听感待设备验收。

17项测试覆盖端点、微秒、全区间单调有界、静音/最新音量、非法输入及慢唤醒跳过过时采样。独立计算通过不代表引擎淡出、取消或恢复已完成。

## 接入前源码结论

- PlaybackController.setVolume与睡眠暂停均通过_operationTail串行化；不能把等待整个2秒淡出放入同一个operation，否则用户暂停/切曲被排在后面。下一步每次音量写独立排队，在等待前后核验许可。
- _acceptEngineState两条路径直接copyWith(volume:value.volume)。临时增益必须与用户音量真值分开，否则UI滑块会随淡出下降。接入必须覆盖延迟音量回报，不能只在setVolume调用处掩盖。
- 现有_sleepGeneration、_sessionRevision与_loadedEntryId可用于撤销，根仍独占到期和暂停；不在Widget新增业务计时器。淡出用单调经过时间，分钟截止继续UTC；避免系统时钟回拨重新放大已淡出的音量。
- just_audio 0.10.6的Android AudioPlayer.java:setVolume实际调用player.setVolume；just_audio_windows 0.2.3的windows/player.hpp:setVolume实际调用mediaPlayer.Volume，事件回报也读取Volume。这是已锁定本机缓存源码证据，非硬件听感证据。

## 后续H4C2验收边界

根用户音量与临时增益隔离；最新用户音量/暂停优先；切曲、新定时、取消、失败及关闭撤销旧采样；迟到命令不得遗留静音；恢复最新用户音量但不自动播放；一次性到期不推进下一曲。FakeAudioEngine可控阻塞/重入验证全部路径，再做真实后端验收。暂不改变“本曲结束”的completed事件策略：它已经自然结束，无剩余声音可在完成事件后淡出。

## 同步与验证

基线86f75b1，开发分支codex/sleep-fade-envelope，Draft PR基于codex/sleep-persistence-coordinator。开始前fetch与ff-only pull，工作区干净；父push34736236724/PR34736248193核验时仍运行，新SHA独立核验。

本轮完整2114 Flutter通过（146秒），158 Node通过（42.45秒）；565 Dart文件格式零修改，严格分析0问题（15秒）。217旧Golden不变，无新增UI/生成输入/数据库schema。原ZIP 24文件逐字节校验通过，总指令SHA256仍为5f024c778be878afc6fcdcc2d3051b1aec5d3357b2fd01d2ea23b1a71066cfcf。

Android Debug预检9.6秒，48打包资产/完整音频许可/v2单签名者通过，保留Java原生访问警告。APK232291229 bytes，SHA256 f1e7266f7b83f446c90e002a10053d7b8eeebdeeb1e19f527907c942346bf84a，与基线一致，符合新契约尚未生产绑定的事实。没有新本地Windows构建、设备安装/听感或发布验收。源码秘密扫描和diff检查通过；构建产物不提交。
