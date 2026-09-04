# Windows + Android 音频 POC 计划

状态：**Phase4A合同已实现，真实POC未运行**。Flutter/Dart、Android工具链与GitHub Windows 2025 runner已经可用；本机Windows C++工具链仍受远程UAC限制。Phase4A只交付共用合同、Fake矩阵和本机Android编译，不把Fake、构建或资产Fixture冒充扬声器播放证据。

## 候选与隔离

A：[media_kit](https://pub.dev/packages/media_kit) + 对应平台audio native libs。B：[just_audio](https://pub.dev/packages/just_audio) + 经核验的Windows backend。当前优先用A做最小POC，因为同一上游明确列出Android/Windows、本地/网络/Header/Seek能力；这只是进入测试的选择，不是正式锁定。B中的`just_audio_windows`不支持请求Header，`just_audio_media_kit`文档说明shuffle order被忽略，必须在比较时记录。两者共享现有AudioEngine合同/测试夹具，后台播放是Android MediaSessionGateway与Windows SMTC Gateway的独立责任。候选证据见dependency_decisions.md。

## 准入与测试材料

- Phase 1骨架可分析且Windows/Android debug构建通过；记录Flutter/Dart/OS/SDK/ABI/backend版本、原生依赖分发说明。
- 使用自制/明确授权的短WAV、MP3、FLAC、AAC测试音频，包含文件缺失/损坏/无封面/Unicode长路径场景；不提交用户真实音乐和路径。
- Windows文件路径、Android MediaStore content URI与可持久授权SAF来源；不能只用asset路径证明本地功能可用。
- 受控HTTPS测试流：正常、鉴权成功/401、404、429、timeout、断网、过期URL刷新；凭据仅测试秘密库注入，日志脱敏。不得调用用户真实在线音乐源来“试播”。

## 双平台相同合同矩阵

| Case | 观察与通过条件 |
| --- | --- |
| load/play/pause/stop | 状态流转换明确，成功后才记录history；失败不是playing |
| seek | 0/中段/近结束可达，position/duration同一来源；测量误差后规定阈值，不预先伪造精度 |
| queue | 添加重复entry、下一首、排序、删除当前/下一项、清空；不会引用错误Track |
| shuffle/repeat | off/all/one、自动结束、空队列、仅一项；不从Fixture catalog重新填队列 |
| duration/buffer | 未知duration不强填228秒；buffering不会停止本地来源或误写失败 |
| volume | 0–1边界、静音恢复；设备无切换能力则只显示系统输出 |
| failure | 404/权限/格式/TLS/过期流分类，单源失败不阻塞其他来源 |
| lifecycle | 前后台/锁屏/耳机拔出/音频焦点/来电/蓝牙按钮；重复连接不重复事件 |
| Shell/route | 599↔600、横竖屏、Windowsresize、player↔lyrics不重建引擎，不丢队列和进度 |
| dispose | Stream/timer/句柄清理，退出停止媒体会话，原生全屏状态恢复 |
| sleep | 15/30/60、trackEnd、恢复/过期策略，平滑暂停不伪造支持 |
| no-download | 没有downloadTrack/saveOffline/batchDownload，网络音频仅技术性缓冲，不形成可离线播放文件 |

Phase4A已用可注入clock/random、FakeAudioEngine/Resolver/MediaSession覆盖合同级场景；下一批必须把相同场景跑在真实Windows/Android backend。性能记录启动/seek时延、内存、CPU、持续播放事件频率；先测基线再设性能阈值，不把浏览器demo计时、编译成功或Fake事件当测试。

## 输出与否决条件

产出docs/audio_poc_results.md：平台/设备/backend版本、测试材料许可、每项结果、脱敏日志/视频、已知格式限制与回退建议。两平台任一关键能力失败不得选为正式后端，不以换成WebView解决。License/原生打包/安全存储问题未解也不能默认上线。
