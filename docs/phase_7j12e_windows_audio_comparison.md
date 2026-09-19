# Phase 7J12E：Windows 音频路径对照与结论修正

## 范围与当前结论

2026-09-19，基线42ad95e，仓库Z-YO-YI/YYMusic，分支codex/native-repeat-window，沿用Draft PR #136。用户已明确反馈这台电脑的其他软件均能正常出声。不能再将YYMusic的失败概括为“电脑音频故障”，也不把重启电脑、关闭其他程序或更换设备作为继续开发的前置条件。本次补记此前会话中已执行的独立对照，不重复运行已确认的失败探针，不更改应用、依赖、系统设置或既有循环/随机实现。

可确认的是：YYMusic当前Windows Profile包未通过播放验收；同一会话中的独立WinRT默认输出路径也加载失败，而WinMM自动映射与明确指定默认端点的打开结果不同。尚不能确定差异来自进程路由、调用方式、端点兼容性或其他因素，更不能确认独占占用者或硬件故障。独立对照不使用YYMusic/Flutter/just_audio，因此失败不只在YYMusic队列代码中出现；这不免除应用的兼容性责任，也不证明换后端即可解决。

## 已执行的无声对照

以下为2026-09-19前序诊断的实际结果，不计入Flutter/Node测试数或原生播放通过数。只打开并释放诊断自身资源；没有调用Play、IAudioClient.Start或waveOutWrite，没有采集用户音频，也没有修改音量、输出设备、独占设置或驱动。

| 路径 | 输入及调用边界 | 观察结果 | 不能据此证明 |
|---|---|---|---|
| WASAPI默认多媒体输出 | GetMixFormat所得48kHz、双声道、32bit扩展格式；Initialize使用共享模式、flags=0、100ms缓冲、period=0 | 0x8889000A（DEVICE_IN_USE）；未Start | 电脑所有音频接口均不可用，或某个已确定程序独占 |
| WinMM自动映射 | WAVE_MAPPER，48kHz双声道PCM16；格式查询与实际打开分别执行 | 查询0、打开0、关闭0 | 实际出声、持续播放或最终使用哪一个物理端点 |
| WinMM明确指定默认输出 | 枚举waveOut设备，以不公开的端点ID与IMMDevice默认多媒体端点精确匹配；相同PCM格式 | 匹配到设备索引0；打开返回4（MMSYSERR_ALLOCATED） | 自动映射成功的输出就是该端点；不据此切换到其他输出 |
| 独立WinRT单源 | Windows PowerShell 5.1投影MediaPlayer；内存生成3秒16kHz单声道PCM16静音WAV，经原生InMemoryRandomAccessStream加载；AutoPlay=false、默认AudioDevice、AudioCategory=Media | MediaFailed，ExtendedErrorCode=C00D4E85，221ms，state=None，未请求播放 | YYMusic序列推进成功、声学结果或失败根因已完全定位 |

WinMM使用[官方端点ID映射方法](https://learn.microsoft.com/en-us/windows/win32/coreaudio/device-roles-for-legacy-windows-multimedia-applications)进行进程内比较，不提交端点标识。对WAVE_MAPPER句柄直接查询时，waveOutGetID仍返回0xffffffff且实例ID为空；因此没有识别出自动映射最终选择的端点，空字符串比较不得算作“确定使用另一设备”。[waveOutOpen契约](https://learn.microsoft.com/en-us/windows/win32/api/mmeapi/nf-mmeapi-waveoutopen)区分格式查询、自动映射与实际打开；三者均不等于声学验收。[IAudioClient.Initialize契约](https://learn.microsoft.com/en-us/windows/win32/api/audioclient/nf-audioclient-iaudioclient-initialize)支持上述共享初始化和错误含义，但不提供占用进程归属证明。

会话与资源快照：诊断、桌面及Codex位于同一交互会话，WTS协议值0；两个音频服务运行、两个活跃输出端点，三个默认角色指向同一端点。采样时共享会话未见Active项，只代表采样时刻，不能否定用户其他软件能出声，也不能排除第三方远程软件或未被共享会话枚举覆盖的情况。不保存其他应用名称、进程ID或设备ID到仓库。

## 排除诊断脚本自身的误报

- 初版COM集合接口GUID错误导致E_NOINTERFACE；修正后才取得快照，不将此错误归因于应用或Windows。
- PowerShell直接Register-ObjectEvent不能订阅该WinRT事件；改用C#线程安全队列、反射委托与注册令牌，退出时解除自身订阅并Dispose。订阅工具限制不是播放失败证据。
- 初版.NET MemoryStream适配器返回80004001（E_NOTIMPL）；最终有效对照改用原生InMemoryRandomAccessStream和DataWriter，完成StoreAsync后Seek(0)。表中C00D4E85来自修正后的原生内存流，不混淆两次结果。
- 所有初始化成功仅表示对应调用成功；独立探针没有播放或听感验证。没有将这批结果包装成新增“测试全部通过”。

## 与现有实现和云构建的关系

J12C修复旧式EventChannel错误被忽略，J12D阻止加载期已知失败被成功确认覆盖；这些已验证的软件修复保留。[J12D报告](phase_7j12d_load_failure_report.md)中e84bda7的Windows失败、Android原生3项通过及精确产物指纹继续有效，不能把独立WinRT对照冒充那个Profile包的新运行。

文档基线42ad95e的[push 35436490247](https://github.com/Z-YO-YI/YYMusic/actions/runs/35436490247)和[PR 35436492958](https://github.com/Z-YO-YI/YYMusic/actions/runs/35436492958)已完成且均success，包含源码验证和Android/Windows Debug构建。它们不是本次文档提交的CI，也不是新的Windows音频成功记录。未改设计参考、NEW_ICON_SPRITE/POLISH_CSS、Golden、原生插件、Pub缓存或生产无缝开关。

## 后续可验证步骤

本次文档提交前验证：168项Node门禁通过（27.85秒、无失败/跳过），614个Dart文件格式零修改，严格分析零问题（10.8秒）；五份文档的270个本地链接、UTF-8有效性、敏感模式与差异空白检查通过。未重新实现或修改应用测试，未把此前2540项Flutter结果称为本轮新运行；提交后的全量回归及双平台构建由现有GitHub Actions按新SHA执行并单独跟踪。

1. 优先只读核对应用/诊断进程实际使用的输出选择及WinRT默认端点行为，明确区分系统默认、应用路由和自动映射；取不到映射就保留未知，不推断或强制切换。
2. 用相同输入和输出前提设计最小兼容性对照；只在复现出具体实现缺口后补回归并修复。不盲目重写播放器、升级依赖或更换后端。
3. 需要修改应用时先记录设计决定，并通过GitHub Actions生成对应SHA的Windows Profile包。按既有严格身份合同重新验证加载、序列推进、追加/清理/截尾和释放；失败仍记失败。
4. 系统变更需要新的明确授权。已执行的一次Audiosrv重启不重复，不自动重启电脑、关闭应用、修改输出/驱动/独占设置；也不要求用户重复证明其他软件能出声。

Phase7成功播放、声学/资源/生命周期、标准化及Phase8–11出口仍未完成。该诊断记录只修正证据边界和后续路径，不增加项目完成百分比，不自动合并PR或发布。
