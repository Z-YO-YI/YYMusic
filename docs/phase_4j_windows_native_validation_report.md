# Phase 4J — Windows 原生验证

## 本批范围

基于远端`4db5899`创建`codex/windows-native-audio-validation`，
[Draft PR #26](https://github.com/Z-YO-YI/YYMusic/pull/26)以`fix/playback-session-consistency`为base。
未在main/master开发，未改动原生Runner、音频插件版本、生产Bootstrap、设计Token或Golden。
原始ZIP 24项逐字节一致；App.tsx的完整Sprite/POLISH_CSS合成仍是设计依据。

- `bd35da1`：隔离Windows测试入口、白名单结果、归档/SDK/运行清单校验。
- `25747bc`：基于实际Debug启动失败，加入显式Profile AOT诊断构建及安全回归。

## 已确认的Debug启动失败

GitHub运行33949369478的artifact 9964422701为66,408,938字节，SHA-256：
`de1a70bc15352cd8699a928eebb261913753e68a8c75dbe1f065733caba54290`。
其`flutter_windows.dll`与本机Flutter 3.47.2 Debug引擎完全匹配。
在新建Git忽略目录中，仅编译`bd35da1`的Dart测试资产，所有原生文件仍为`4db5899`原字节。

本机两项有效播放输出端点可见，Audiosrv/AudioEndpointBuilder运行；但启动退出码为
`-1073741515 / 0xC0000135`，尚未进入Dart测试，无metrics。
LLVM PE导入检查确认EXE需要MSVCP140D.dll、VCRUNTIME140D.dll、VCRUNTIME140_1D.dll、ucrtbased.dll，
本机系统及既有C++安装目标均未找到这些Debug库。普通Release CRT存在，不能代替Debug CRT。
因此旧“portable Debug”表述已改为开发Debug文件包，不再承诺任意电脑免安装可运行。

## Profile诊断路径

采用同一`just_audio_native_local_poc_test.dart`，不删断言、不替换为Fake、不注入无头音频sink。
显式开启入口且拒绝Release；GitHub按精确Commit编译整个Profile包，核对AOT、所有EXE/DLL无Debug CRT导入。
只读手动诊断模式生成保留1天的artifact，Android交付job跳过，不创建Release。
旧`run_just_audio_poc`的双平台只读、无artifact约束保留；两个模式互斥且均默认关闭。

本机PrepareProfile先核对API SHA-256、SDK Profile引擎、归档路径/链接/重复/大小、精确身份和AOT元数据，
然后完整解压到新目录，不替换任何资产。Run核验完整运行清单、新结果和退出码，并限制210秒；
只允许一次真实case和受控计时，禁止复用旧日志/结果，结束后再次比对运行文件。
异常详情、本机路径和VM日志只留在Git忽略目录；GitHub不接收本机运行日志。

## 验证记录

`25747bc`本地：248/248 Flutter测试、43/43 Node检查、156个Dart文件格式零变化、严格analyze零问题；
build_runner与Drift v1快照零差异。Android Debug构建成功，48项SVG/字体/许可包内字节匹配，
APK SHA-256仍为`38fda801f85cbba7cbf4544bb92ae91b22de7796b4e147ad81c76852cf394c0f`。
不提交APK，不把本地APK当成GitHub交付。

精确实现提交的[标准PR运行33951027905](https://github.com/Z-YO-YI/YYMusic/actions/runs/33951027905)
与[Profile诊断构建33951039057](https://github.com/Z-YO-YI/YYMusic/actions/runs/33951039057)均已成功。
标准PR的checks、Windows Debug、Android Debug三个job成功；Profile运行的checks与Windows成功，
Android交付与旧双平台POC按设计跳过。Profile运行恰好1项诊断artifact、匹配Release为0。
最终文档提交的自动CI在PR检查中单独记录，不能与实现提交的运行身份混为一谈。

## Windows本机原生结果：两次通过

artifact `9964953552`，24,658,878字节，SHA-256：
`c78d00de299072d4da2da7ce7325abafec63b62733f86e2cc2a2125a84277c0a`，到期时间为2026-09-06 07:02:42 UTC。
两次均完整使用GitHub的`25747bc94bd192f73b442eb82b47f72aee574840`，source/native身份相同，
没有替换Dart资产、EXE或DLL。两个独立的新目录中，各运行1个原始WAV case，测试passed=true、
进程退出码0；全部64项运行文件启动前后SHA-256一致。

| 本机运行 | load | 首次进度 | seek | duration |
| --- | --- | --- | --- | --- |
| Profile 01 | 333 ms | 158 ms | 2 ms | 3000 ms |
| Profile 02 | 301 ms | 160 ms | 2 ms | 3000 ms |

原始断言均通过：load不自动播放、真实position推进、音量0.2/速率1.25、Seek到1秒、pause、
Seek近尾并play到completed、stop回idle/position零、没有error状态、测试后释放和临时文件清理。
Header与代理均关闭。不是Fake、不是无头sink，也不据此声称用户听到声音、音质或后台体验通过。

本机详细证据保存在Git忽略的`build/windows-audio-probe/profile-run-01/`与`profile-run-02/`，
包括manifest、process-result和runtime/native-audio-poc-result；stdout/stderr不上传。
先前Debug失败目录保留供复核，不删除用户文件或更改系统设置。

这补齐Phase4F小批A的Windows本地WAV证据。Android既有真实WAV证据仍属于
`037db44`的运行33942090875，不能冒称在本次Profile运行中执行了Android native case。
下一小批先在当前提交复跑Android候选，再验证无Header HTTPS与Android content URI，
之后才讨论最终候选及生产接线；不把media_kit历史结果继承给just_audio。

本批仍属于Phase4；真实本地WAV成功也不代替无Header HTTPS、Android content URI、后台/媒体会话、
候选最终决策或生产接线。Phase5业务页面不提前开始。
