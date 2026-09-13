# Phase 7H5A：输出设备事实与系统设置契约

## 阶段边界

接续已生产绑定的H4C睡眠淡出，推进总指令§26输出设备要求。本批只新增平台边界与安全不可用实现，**没有原生设备读取、设置页启动或UI绑定，不声称现在能显示/切换设备**。不把连接的蓝牙设备列表当成正在播放的输出。

## 契约

- AudioOutputRoute明确unknown、systemDefault、playerRoute三类来源。未知没有label；系统默认并不保证是当前播放器的实际路由，未来界面必须保留该区别。
- 已知名称trim后非空、最多128个Unicode标量值且无内部控制字符。校验错误与toString均不包含设备名称，避免设备名称中的人名进入普通日志；当前没有持久化或上传。
- AudioOutputSnapshot把路由观察与canOpenSettings分离：可打开设置时路由也可能未知，反之亦然。值相等性同时比较来源、标签和能力。
- AudioOutputGateway定义initialize/refresh/观察事件/openSystemSettings/close。opened只表示系统接受启动设置，并不表示路由变化；返回应用后重新读取。close约束撤销、排空、退订，不拥有或操作音频引擎。
- UnavailableAudioOutputGateway返回未知和不可打开，事件为空；绝不返回opened或伪造设备。不提供直接设备切换API，待后端实际支持并验收后再独立扩展。

PlaybackState中原有outputDevice目前无生产填充。下一批须把实际Gateway观察投影到唯一根/Presenter并保留来源语义，不能并列维护两个可写“当前设备”；本批不修改该旧模型，也不把新不可用实现提前装成已完成的设备功能。

## 测试与验证

22项单测覆盖未知、来源区别、两类已知标签规范化/Unicode长度/六类坏输入、隐私输出、设置能力独立、相等性以及不可用生命周期与启动结果。完整2196 Flutter通过（115秒），158 Node通过（31.46秒）；572 Dart文件格式零修改、严格分析0问题（18.5秒）。217旧Golden不变，无依赖/生成输入/schema变化，未重复生成迁移。24ZIP条目逐字节校验、秘密扫描与diff检查通过。

Android Debug预检17.2秒，48资产/完整音频许可/v2单签名者通过，保留Java原生访问警告。APK232305161 bytes，SHA256 eab3d7e0278044c792d97e6f1059ab6c0a615a530e319f25230e8421dba4d4f7，与父阶段相同，符合本批新契约尚无生产绑定的事实。无新增本地Windows编译或设备验证。云端双平台结果按新SHA独立核验。

基线1776de5，分支codex/audio-output-contract，Draft base codex/root-sleep-fade。开始前fetch/ff-only pull，工作区干净。前置34739035941/34739066688核验时in_progress；不以父运行状态代替本SHA结果。

## H5B下一步

先阅读已锁定Android/Windows原生项目、插件与一手平台API资料，明确能读到系统默认还是播放器实际路由，再逐平台实现最小Gateway/设置启动与受控通道测试。Android已连接设备不是路由证明；Windows默认终端不一定等于应用独立输出。未知或读取失败明确降级，设置启动失败可观察；无演示成功消息。之后接UI并验收返回刷新、设备热插拔、关闭/后台、无设备/无权限和真实设备听感。保持Phase7与Phase10设备验收边界，不提前宣称上线。
