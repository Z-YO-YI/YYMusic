# Phase 7H5B1：双平台原生声音设置入口

## 实现与未完成边界

Android Activity和Windows Runner已注册audio-output只读/启动通道，Dart NativeAudioOutputGateway负责串行调用、严格解析、未知降级和关闭排空。**原生入口代码已加入应用构建，但尚未注册到根/Presenter或UI，因此目前应用界面没有新增按钮。** 路由读取继续unknown，未伪造系统默认或播放器实际设备。没有直接切换设备、枚举已连接设备或修改音量。

Android固定Intent(Settings.ACTION_SOUND_SETTINGS)，manifest只新增对应intent可见性query，不添加QUERY_ALL_PACKAGES或设备权限。查询可解析Activity，失焦/结束时拒绝启动，ActivityNotFound与SecurityException区分unavailable/failed。Activity重新配置、清理和销毁解除通道handler。

Windows固定ms-settings:sound，ShellExecuteW返回值大于32才opened；失去前台/窗口已销毁返回unavailable，启动失败返回failed。CMake加入独立源文件和shell32.lib；窗口销毁先释放通道。所有原生方法拒绝非空参数，不接受任意URI、路径、设备ID或媒体数据。opened仅表示OS接受启动，不等于设备切换或用户实际修改设置。

## 一手依据

- [Android ACTION_SOUND_SETTINGS](https://developer.android.com/reference/android/provider/Settings#ACTION_SOUND_SETTINGS)：声音设置Activity动作；设备实现可能没有匹配Activity，因此检查与失败处理必需。
- [Windows设置URI](https://learn.microsoft.com/en-us/windows/apps/develop/launch/launch-settings)：Sound对应ms-settings:sound。
- [ShellExecuteW返回语义](https://learn.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-shellexecutew)：大于32表示成功，小于等于32为失败，不把返回句柄当可用进程句柄。

本轮未启动电脑设置窗口或进行设备音频诊断。系统默认和播放器实际路由的读取协议保留H5A区分，后续按真实平台API证据逐项接入。

## Dart调用生命周期

initialize幂等，refresh重新读并发出观察；坏数据/原生错误/缺宿主都撤回旧已知状态与设置能力，不把旧名称继续标成当前。输出标签沿用H5A安全校验，错误不回显原生载荷。关闭拒绝尚未执行的启动、等待已经接受的调用，之后不再返回旧初始化能力。已被OS接受的启动不能伪称撤回。没有原生事件订阅，本批states来自显式读取，返回设置后的刷新仍待后续生命周期/UI绑定。

## 验证

21项MethodChannel mock测试覆盖幂等与能力、两类路由来源、六类坏数据、五类启动结果、未初始化、读取失败撤旧、缺宿主重连、启动异常、关闭队列/在途结果及通知重入。新增1项Node固定目标/生命周期/构建注册源文件约束。它们不是系统设置真的显示或Windows原生运行测试。

初版泛型尾链类型推断错误已改为显式then<T>；审查补强通知中关闭后的返回值保护。最终完整2217 Flutter通过（101秒，首轮117秒），159 Node通过（38.54秒），574 Dart格式零修改、严格分析0问题（14.1秒）。217旧Golden不变，无依赖/生成输入/schema/UI变化，未重复生成迁移。设计ZIP 24文件逐字节、秘密扫描及diff检查通过。

Android原生编译最终20.6秒（首轮13.5秒），48资产/完整音频许可/v2单签名者通过；APK232305161 bytes，SHA256 6777938608f556dadd9be1ede1008dcebc8a3c5d20a3196befb8cbff746d8b1e。保留Java原生访问警告。无实际设置窗口启动或设备验收，不提交APK/日志。

Windows本地flutter build windows --debug --no-pub在编译前因未启用Developer Mode、缺少symlink support失败。本轮没有擅自开启系统设置或绕过限制；**不记本地Windows编译通过**。C++编译和原生Runner回归仍需本SHA GitHub Actions验证。

## Git与后续

基线f8b37df，分支codex/native-sound-settings，Draft base codex/audio-output-contract。开始前fetch/ff-only pull且工作区干净；父34739784945/34739798511最终已SUCCESS。新SHA独立核验，保持Draft，不自动合并/发布，不提交构建产物。

H5B2继续真实路由观察与根/Presenter生命周期，再接既有设置UI；开设置仅由仍有效的用户动作触发，返回前台刷新，未知/失败诚实反馈。Windows CI若失败优先修复。整体Phase7和Phase8–11未完成。
