# Phase 7J12C：Windows 旧式原生错误兼容

## 基线、范围与风险

2026-09-19，Z-YO-YI/YYMusic，codex/native-repeat-window，基线d0c96a6。开始前fetch核对本地/远程一致及工作区干净；沿用Draft PR #136，不切换分支、重置或重做J11循环/随机实现。设计参考、NEW_ICON_SPRITE/POLISH_CSS、UI与Golden保持不变，不使用WebView。

本批处理Windows设备验证中发现的独立错误传播缺口，见ADR-144。范围是平台协议兼容、既有后端的Windows注册入口、错误/恢复测试与文档；不升级音频库、不改Pub缓存或原生插件、不添加第二个播放器、不改变Android协议。风险为平台注册影响范围、重复事件订阅、旧播放器错误污染新批次，以及把失败及时可见误写成实际播放恢复。

## 设备环境与授权操作

父提交d0c96a6的[push 35433237373](https://github.com/Z-YO-YI/YYMusic/actions/runs/35433237373)与[PR 35433239355](https://github.com/Z-YO-YI/YYMusic/actions/runs/35433239355)均success，属于本批改动前的双平台构建记录，不借作新源码通过证明。

只读检查确认默认输出已经是实体端点而非虚拟端点；共享会话快照没有Active项，但不能据此认定无独占占用。与Flutter无关的WASAPI共享初始化在48000Hz/2声道混音格式下返回0x8889000A，未调用Start。微软的[Initialize契约](https://learn.microsoft.com/en-us/windows/win32/api/audioclient/nf-audioclient-iaudioclient-initialize)将DEVICE_IN_USE定义为设备已被占用，不能因服务Running或端点Active而假定可播放。

用户明确允许仅重启一次Windows Audio（Audiosrv）。普通进程操作被系统拒绝后，走标准UAC管理员确认，隐藏助手退出0；只重启该服务，没有重启AudioEndpointBuilder/电脑、关闭其他程序或修改输出、驱动及独占设置。随后在两个全新build目录复测，旧失败目录保留：

| 未修改的GitHub Profile包 | 实测结果 | elapsedMs |
|---|---|---:|
| 25747bc旧单曲对照 | exit=1，20秒进度超时，testCount=1、passed=false | 21876 |
| 2828d38独立序列 | exit=1，首项25秒进度超时，testCount=1、passed=false | 26769 |

两者仍报告设备正在使用中，归档指纹与[J12B报告](phase_7j12b_windows_sequence_report.md)完全相同。没有再次重启或扩大系统权限操作；原始日志、设备信息与临时管理员助手仅留本机忽略目录，不提交仓库。设备恢复仍待解决，以下软件修复不是声卡修复。

## 根因与实现

核对锁定源码：just_audio_windows0.2.3的player.hpp在MediaFailed/ItemFailed中发送EventChannel错误包；just_audio0.10.6的subscribeToEvents忽略该平台流的onError，公开errorStream仅由PlaybackEventMessage.errorCode构建。既有应用虽然监听errorStream及快照错误，仍接不到这种旧式原生错误。修复前新增的单源/序列两项通道回归均得到ready而不是预期error，明确复现软件缺口。

- `windows_just_audio_error_compatibility.dart`：通过公开MethodChannelJustAudio/MethodChannelAudioPlayer继承点兼容，不复制命令实现；仅Windows创建后端时幂等替换原始默认平台，其他插件或测试注入保持原样。
- 每个原生player ID缓存一个broadcast事件流；普通/已有结构化错误事件不变，旧式错误或格式异常转换为固定errorCode=-1及固定安全文案，不转发原始message/details/stack。只保留上一事件的索引、位置、时长；无前序则未知索引/时长、零位置，不虚构推进。idle错误态让上游释放失败连接，应用仍使用既有DomainFailure及generation隔离。
- `just_audio_platform_interface 4.6.0`从既有传递依赖提升为精确直接依赖；lock仅分类变化，版本和归档SHA不变，许可材料不增加。Android继续默认实现，未启用生产无缝开关。

## 验证与剩余事项

修复前两项回归按错误状态断言失败（首轮测试代码的可空ID编译问题先已修正，未将编译失败冒充复现）。修复后51项专项通过，覆盖活动单源/序列错误、恢复后旧错误隔离、真实方法通道序列命令、首事件错误、脱敏、正常/结构化事件、多个ID隔离、单一订阅和最后订阅取消、非Windows不干预及保留自定义平台。

最终614个Dart文件格式零变更，严格分析零问题（7.6秒）；全量Flutter2536项通过（108秒），168项Node门禁通过（27.41秒、无跳过）。严格分析初轮发现测试的两个多余导入，移除后重跑，未关闭lint。全部24项设计归档内容、6份音频包许可及2份原生构建源指纹通过；pubspec.lock仅依赖类别变化。差异空白与待提交文件敏感模式检查通过。

所有新通道测试是自动化协议回归，不是设备播放证明。新提交必须另行获得GitHub Android/Windows构建及Windows Profile产物；旧2828d38的云构建成功不能替代本次。Windows设备占用、实际序列成功、声学/内存/后台生命周期、标准化及Phase8–11仍未验收，不标记Phase7或J12整体完成。本PR仍包含[J11循环/随机](phase_7j11_repeat_window_report.md)、[J12A序列测试](phase_7j12a_native_sequence_probe_report.md)与[J12B隔离Profile](phase_7j12b_windows_sequence_report.md)，没有重做这些功能。
