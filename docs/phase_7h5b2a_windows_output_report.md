# Phase 7H5B2a：Windows系统默认输出读取

## 实现范围

Windows getState不再恒定返回unknown：每次只读查询eRender/eMultimedia默认端点，确认DEVICE_STATE_ACTIVE，用STGM_READ属性存储取得PKEY_Device_FriendlyName。成功才返回systemDefault与label；无设备、COM/属性失败、错误类型或非法名称返回unknown，系统设置能力保持独立。**不是playerRoute，不保证就是just_audio当前实际输出**，不枚举所有设备、不读取设备ID、不切换输出或修改音量。

Main现有UI线程已初始化COM；读取借用该apartment，不调用CoUninitialize。ComPtr释放枚举器/端点/属性接口，局部PROPVARIANT作用域退出必清理。名称限制128个Unicode标量、最多256个UTF-16单元，拒绝控制字符/孤立代理项并严格转UTF-8，无打印、持久化或上传设备名称。

本批只扩展Windows宿主和验证，Android保持unknown。Gateway已支持systemDefault解析，但根/Presenter/UI仍未绑定，不能宣称应用已有可见设备信息。热插拔目前通过显式refresh重读，不声称已注册系统通知或自动前台刷新。

## 官方依据

- [GetDefaultAudioEndpoint](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdeviceenumerator-getdefaultaudioendpoint)按数据流与角色取得默认端点，无设备可返回E_NOTFOUND；调用者释放接口。
- [GetState](https://learn.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdevice-getstate)区分active、disabled、not present及unplugged。
- [Device Properties](https://learn.microsoft.com/en-us/windows/win32/coreaudio/device-properties)说明只读属性存储和FriendlyName；GetValue可成功但VT_EMPTY，所以不能只检查HRESULT。

## 验证与限制

现有Windows CI原生Runner测试文件增加1项只读输出协议检查：无mock，校验实际宿主返回unknown或systemDefault、能力字段、任意参数拒绝及Gateway读取/关闭；不播放、不打开设置、不打印端点名称或ID。无音频端点的Runner允许unknown，因而不能把该测试当作已在真机验证命名设备、热插拔或实际播放路由。

Node新增1项原生源码门禁，核验活动默认端点、只读属性、类型/UTF校验、RAII清理、ole32链接及不枚举/不读ID；旧门禁由“永远unknown”改为“不得冒称playerRoute”。本地完整2217 Flutter通过（95秒），160 Node通过，574 Dart格式零修改、严格分析0问题（9秒）；217旧Golden不变。新增Windows原生测试不在本地2217项内，仍待云端运行。无依赖/生成输入/schema变化，未重复生成迁移；24ZIP条目指纹、秘密扫描和diff检查通过。

Android Debug预检6.5秒，48资产/完整音频许可/v2单签名者通过；APK232305161 bytes，SHA256 6777938608f556dadd9be1ede1008dcebc8a3c5d20a3196befb8cbff746d8b1e，与父阶段一致，符合Windows专属改动。保留Java原生访问警告，无新增设备安装或听感验证。

本机Windows编译已知受Developer Mode/symlink支持限制，未再次要求或修改系统配置。**本轮C++编译及新增原生测试待新SHA GitHub结果，不标记已通过。** 无新设备听感验收。

## 同步与后续

基线4be1344，分支codex/windows-default-audio-output，Draft base codex/native-sound-settings。开始前fetch/ff-only pull且干净；父34740841491源码检查已SUCCESS，Android/Windows任务仍运行，父双运行34740841491/34740862274总体in_progress。保持新SHA单独验收，不自动合并或发布。

下一步优先处理Windows云端编译/原生测试结果，再接根输出观察协调和返回前台刷新；Android实际可观察范围按平台一手API审计，未知时继续显示未知。Phase7其他播放偏好和Phase8–11仍待完成。
