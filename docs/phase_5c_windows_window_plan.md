# Phase 5C 增量 — Windows 真实标题栏与窗口 Gateway

2026-09-05，`codex/windows-window-gateway`，基于已 fetch/pull 的 `a39d306`。
前置详情面板 push33961718376/PR33961733794 两组 checks/Android/Windows 全部 success。
本仓库增量编号对应总指令 Phase5 Windows Shell，不代表总指令所有5A/5B/5C子项均完成。

范围：WindowsWindowGateway隔离Win32平台通道；正式根UI拥有一个WindowPresenter，原生握手成功
后隐藏系统caption、保留原生resize边框并启用原稿42dp标题栏；非交互标题区可拖动/双击，按钮
实际最小化、最大化/还原与请求关闭。原生WM_CLOSE/Alt+F4经Dart等待Graph.close后才最终销毁。
失败只显示固定提示，通道不可用保留系统标题栏，Android不得调用Windows通道。

所有Win32操作只作用于当前Runner HWND，不枚举/控制其他程序，不申请UAC、不读写全局设置。
窗口尺寸/位置持久化、多显示器恢复、托盘/媒体/无边框全屏留在Phase10，不用半成品声称完成。
组件/Presenter/Gateway合同测试与Windows原生通道测试分开记录；原生测试放在CI默认打包之前，
随后重新构建正式默认入口，防止将测试入口上传成用户Debug包。

新增平台合同和实现、窗口Presenter/Chrome、Runner通道代码与单元/Widget/原生验证；复用现有
YYWindowToolbar、最终SVG/主题/交互，不引入额外插件或许可。修改严格限制在当前窗口与工程。
出口：检查、全量测试、原稿相关Golden、Android打包无退化、GitHub Windows真实状态/关闭握手
以及默认入口构建通过；审核/记录真实限制，提交推送并维护PR，不自动合并或发布。

依据：主指令第27节/Phase5；完整App.tsx+基础HTML；Microsoft官方
[ShowWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-showwindow)、
[SetWindowLongPtr](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowlongptrw)、
[WM_CLOSE](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-close)。
ShowWindow返回的是先前可见性，不能把false当成失败；样式更新用SetWindowPos刷新原生frame。
