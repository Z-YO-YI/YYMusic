# Phase 4O — 应用内完整许可查看入口

2026-09-05。基于已推送并pull的`f324ed2`，分支`codex/audio-license-viewer`。
Phase4N云端构建仍在运行，本批同属Phase4并行准备；若前置校验失败，先修复，不宣布出口通过。

目标：设置可打开原生Flutter许可页面，读取SDK LicenseRegistry和已审Android原生材料，支持
搜索、完整原文、返回、加载/失败重试，不使用Material默认页面、WebView或外部许可网站。
已读取总指令、App.tsx/HTML最终合成审计、设置层级、现有主题/控件/路由、SDK许可接口。

新增Domain许可模型/Repository、app层SDK/资产适配器、Settings共用许可页与单元/Widget测试；
修改AppRouter/Navigation/Graph、设置入口及开发文档。公共合同先由ADR-043记录。
不新增依赖、音乐源、播放状态副本、网络请求、媒体、权限或Schema。

风险：完整许可证较长，必须按需加载和虚拟列表；错误不能展示内部路径；离开页面后异步完成
不能更新销毁的Widget；长组件名、暗色、130%文字与手机窄屏要测试。
出口：源码/全文完整与负向测试、导航/搜索/重试/模态返回测试、格式/分析/完整回归和双平台构建。
本批完成后继续生产播放器接线，不将许可查看页称为完整Settings业务页。
