# Phase 7J2：共用序列引擎身份

## 基线与范围

基线f38e8f4，Z-YO-YI/YYMusic，确认工作区干净、fetch及ff-only pull后建立codex/sequence-engine-identity。上一阶段原生序列加载为有效进展，本批按主指令唯一播放根要求及ADR133，将序列能力接至共用音频引擎，不另建队列控制器。参考文件沿用已核实基线，无设计改版或替换App.tsx合成覆盖。

## 实现

- AudioSequence复制有序输入，每批新identity；entryId必须唯一，同一TrackRef允许多次。解析后的PlayableSource只留在瞬时加载请求；引擎存储的cursor仅有批次identity、索引、entryId、TrackRef，无URI/headers，也无序列请求回引用。
- AudioSequenceEngine是可选AudioEngine能力；JustAudioEngine调用真实JustAudioSequenceBackend，共用现有operation tail与dispose drain，不自动play，不改变现有单曲接口。能力不足、初始索引不合法或任一不支持头在替换前拒绝，保留旧状态。
- 加载中清除旧cursor；完成后同一AudioEngineState报告插件状态与映射身份。异步加载错误不能被成功完成覆盖。失败、单曲替换及stop不继续投影旧身份。
- 成功加载后的空/负数/越界索引不猜曲目，清除loaded与cursor并发布安全failure，经同一串行队列请求stop。更新load可撤销旧fault的stop；stop失败仍保留脱敏错误，关闭仍排空工作。系统失败可能阻止实际停止，不能承诺原生一定静音。
- 生产PlaybackController尚未使用序列协议，本批不是无缝开关或实机声学验收。批次身份只证明当前映射，不解决插件内部迟到事件的来源辨认；下一阶段必须结合根队列修订和策略以及原生事件边界。

## 测试与验证

17项新模型/引擎测试：输入不可变/空与重复entry拒绝/重复TrackRef合法，索引与完整身份原子投影，不主动播放，替换期间旧身份不可见，初始越界/不支持能力/请求头保留旧状态，加载失败恢复，异步错误，三种无效原生索引及安全停止、已接受替换不被旧停止伤害、stop失败关闭排空、初始索引缺失、单曲/stop清理、play串行、关闭排空/抑制通知/拒绝新任务。

另1项跨层测试通过真实锁定just_audio插件的MethodChannel/EventChannel，经过NativeJustAudioPlayerBackend及生产JustAudioEngine，将重复曲目索引变化映射为正确entry及批次，验证只加载一次且不发play。没有播放测试声音或假设通道测试即原生播放。

初轮新测试遗漏dart:async导入导致编译失败，补齐后17项通过；跨层及原11项共12通过。最终2409 Flutter测试通过（120秒），161 Node门禁通过（32.80秒），严格分析0问题（6.7秒），606 Dart文件格式零修改，所有测试/构建进程退出0。226张Golden未变，无新依赖、数据库变化或UI变更。

Android Debug构建通过（36.2秒）；48资产字节一致、六项音频许可与完整原生声明通过。四个参考SHA256与既有基线一致，24个解压文件与原ZIP逐字节匹配。既有Java native-access警告不变。差异及变更文本凭据/私钥扫描在提交前复核，不提交构建产物。父运行34759133900复核时仍in_progress，不记为通过。

## 交付与后续

GitHub Draft基于codex/native-sequence-backend，提交推送而不自动合并/发布。本地Windows仍受既有Developer Mode/symlink限制，依赖正常GitHub Windows构建；不打开可选音频探针。继续根队列修订/身份接入、自动继续及睡眠优先、重复随机与失效来源整合，再验证两平台曲间边界。主指令各Phase与发布要求仍完整保留，整体目标未完成。
