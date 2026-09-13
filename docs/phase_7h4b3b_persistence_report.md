# Phase 7H4B3b：生产分钟定时恢复与反馈

2026-09-13；基线154df756d70c45b14f109629ef9e6e8fa030a840，fetch/pull --ff-only且工作区干净后建codex/sleep-persistence-coordinator，Draft base codex/sleep-restore-root。先[计划](phase_7h4b3b_persistence_plan.md)/ADR113，再协调器、生产注册、界面与测试。父双CI34734305847/34734318067已确认success，新SHA另验。

SleepPersistenceController构造即捕获一次性恢复许可并订阅根睡眠意图，独立off观察许可识别即使保持off的显式取消；普通播放进度不当作睡眠编辑。单worker读取并保存最新快照，慢读期间用户新设/取消优先，旧失败不覆盖新成功。仅分钟armed写入原选项/UTC deadline；off、本曲结束和到期清理分钟记录。本曲结束仍明确仅本次启动有效。

过期或schemaMismatch坏记录（含未知版本）由协调层安全清理；I/O失败保留记录并允许重试，不假装missing。恢复失败/引擎不可用保留记录、提示重新设置，不自动播放。取消或保存失败明确警告重启可能使用旧设置。关闭冻结最后接受的意图、停止观察、排空写入，再关闭数据库，不把根退出时取消Timer的临时off写成用户取消；失败关闭仍以安全DomainFailure可观察。

AppDataServices/DatabaseAppDataServices拥有真实Repository，DependencyGraph在根初始化之后恢复，先停止持久化观察再停止根，释放数据前等待排空。额外源码核实YYMusicApp的Windows beforeClose会await graph.close，WindowPresenter随后才completeClose；没有新增实机窗口关闭测试，不将源链路核验冒充设备验收。异常关闭仍沿用既有完成资源清理再退出策略，不保证磁盘故障或强制杀进程下未完成写入能保存。

Presenter只读投影状态并转发带当前失败身份的重试，面板继续既有布局/许可保护。无Repository环境保持session-only提示；生产显示分钟截止保留、本曲结束会话边界，以及读取/保存/失败状态。重试被旧失败、重复调用、隐藏和关闭许可保护，倒计时仍不是每秒liveRegion。使用设计转代码技能复用原caption/YYButton，本地已审计导出为参照，无在线Figma节点、无新增图标或WebView。

35新增Flutter：22协调器（恢复/幂等/进度过滤/慢读竞争/用户先改/过期/损坏/读写失败/旧失败/重试/关闭/实际到期及通知重入）、4真实Graph+SQLite（文件三次重开、阻塞写入关闭、过期/无效清理）、6安卓/Windows面板交互、3新截图。真实重开验证设置15分钟，正常关闭后两分钟再开仍原截止、剩余13分钟，再取消/关闭/重开记录为空，FakeAudioEngine没有play调用。

最终完整2097 Flutter通过（123秒），158 Node通过；563文件格式零修改，严格分析0问题（6.5秒），生成21秒/Drift通过且无生成schema差异。217截图：214旧图字节不变，3新图逐张检查手机恢复、深色平板保存失败和短Windows读取失败，130%字号与重试可用。初次3项源码检查因旧相邻顺序/构造器形状失败，更新为新的明确顺序并保持唯一Presenter与所有权约束；静态风格提示修正后最终全量复验。

四份设计SHA256一致、24ZIP条目逐字节匹配，App.tsx NEW_ICON_SPRITE/POLISH_CSS审计继续有效。Android Debug最终49.8秒，48资产/完整音频许可/v2单签名者通过。APK232291229 bytes，SHA256 `f1e7266f7b83f446c90e002a10053d7b8eeebdeeb1e19f527907c942346bf84a`；Java native-access警告保留，APK不提交。无新增安装/听感或本地Windows编译验收。

主要文件：sleep_persistence_controller.dart、数据范围/DependencyGraph、Presenter与sleep_settings_panel.dart、测试假存储/实际Graph/Widget/Golden、源码门禁、README/ADR/状态/矩阵。分钟恢复已生产接通，仍需GitHub新SHA构建验证及设备验收；下一批H4C平滑暂停，真实输出设备等其余Phase7–11仍未完成，不自动合并或发布。
