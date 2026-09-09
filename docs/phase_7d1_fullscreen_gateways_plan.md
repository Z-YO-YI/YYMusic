# Phase 7D1 — 原生全屏通道与恢复保护

2026-09-09；`Z-YO-YI/YYMusic`；`codex/native-fullscreen-gateways`；干净基线`0a9e6d0`，fetch/pull已同步。前置C2云端仍在运行，继续独立核对，不冒称成功。

本批先实现操作系统能力，不一次性接入UI：扩展已有FullscreenGateway为异步握手、原生模式快照/事件、幂等进入/恢复及有序关闭；不把Flutter尺寸作为真实全屏依据。单个跨平台MethodChannel适配器复用同一受限协议，与已有Windows窗口通道相互独立，不占用其事件处理器。

Windows只控制当前Runner HWND：进入保存WINDOWPLACEMENT、样式/扩展样式；移除非客户边框并占当前显示器完整矩形，退出还原保存状态；失败保留恢复凭据，重复进入不覆盖快照。detach、销毁、最小化和显示器配置改变时安全恢复，不修改全局显示模式/分辨率，不授予任意窗口句柄或坐标参数。

Android使用已有AndroidX WindowInsetsControllerCompat（不增加依赖/权限），保存各系统栏可见性与行为；仅设置隐藏/手势临时显示，恢复先前状态。onPause/失去窗口焦点/引擎解绑/销毁均恢复，不挂接或消费Flutter的Insets监听，不关闭edge-to-edge或伪装分屏caption可隐藏。

纯Dart合同、通道解码、拒绝参数、序列化/晚到命令/关闭排空/错误脱敏覆盖；扩展既有Windows真实原生集成用例核对普通与最大化进入前后位置/样式一致及系统恢复。不触发独立音频诊断；默认GitHub CI继续在测试后重建正式入口。

本批不将新通道注入正式页面，不启用F/按钮或自动沉浸；下一增量以根生命周期协调器接歌词/播放页、Esc先退出全屏及标题栏隐藏。现有138张Golden预计不变。完整格式/分析/测试/Node/生成/迁移/Android包预检后提交push、Draft PR base=`codex/native-lyrics-route`。本地Windows和Android真机验收分别记录，不冒用构建成功。

依据主指令19.5/Phase7和既有Phase0审计；本次非视觉迁移，不改原App.tsx/HTML/图标/样式。
参考[Android官方沉浸模式](https://developer.android.com/develop/ui/views/layout/immersive)、[微软全屏窗口切换](https://devblogs.microsoft.com/oldnewthing/20100412-00/?p=14353)、[WINDOWPLACEMENT](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowplacement)。Android桌面窗口caption可能始终显示，enabled表示已进入本应用请求的原生模式，不表示系统临时栏永远不可见。
