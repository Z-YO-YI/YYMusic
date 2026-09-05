# Phase 5A 开始 — 三套 Shell 的共用播放器接线

2026-09-05，分支 `codex/shared-shell-player`，基于已 fetch/pull 的 `4a5b32d`。
Phase4 POC/唯一控制器/平台来源与许可条件已有证据，4P 本地门禁通过，云端检查仍在运行；
本批先准备接线，前置若失败则先修复，不把构建未完成当成跨平台通过。

目标：把 Phone Mini64、Tablet Compact76、Windows88/76 的已审原生控件接到同一个
PlaybackController，显示真实当前曲目/状态/进度，执行播放暂停、前后切换、随机、循环、Seek、音量。
空队列禁用播放、加载抑制重复命令、错误脱敏显示且可重试。拖动只预览，松开提交，换曲/换 Shell
丢弃旧拖动，不产生跨曲 Seek。增加 Windows Space 快捷键，输入框和其他控件优先消费按键。

已读取：总指令 Shell/Phase4—5/控件/错误/固定格式；基础 HTML 829–858 播放器样式及 Footer；
App.tsx 新 Sprite、Slider/primary 后置阴影与合成顺序；现有 2F 控件、根图、队列合同和关闭测试。
指纹保持主指令指定版本。UI 继续使用最终 44 SVG/YYTheme，无 Material 或 WebView。

新增 app/PlaybackPresenter、features/player/common/ShellPlayer 和单元/Widget/Golden；
修改 Graph、Router/AdaptiveRoot、三个 Shell、状态文档。先以 ADR-045 固定公共边界。
Presenter 只映射并转发，不存第二份播放或队列状态；临时拖动保留在 Widget，不进入数据库。

边界：本批不实现收藏 Repository 接线、实际封面加载、Inspector/队列/全屏业务、窗口 Gateway、
媒体服务或导入/REST。对应工具保持禁用，不放空回调冒充实现。空应用不放演示曲目。
风险：快速重复命令、长中英文、130%文字、手机横屏/平板分屏、错误反馈占高及键盘焦点。
出口：所有操作连到注入的真实合同、重复调用/失败/销毁/Seek取消测试、全量分析/回归/Golden，
源码/ZIP/生成代码/许可门禁与 GitHub Android/Windows 构建。Phase5 其他能力继续分批，不宣布整阶段完成。
