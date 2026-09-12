# Phase 7G2：底栏全屏播放入口

2026-09-13，基线a5dc821，fetch/ff-only pull成功且干净；分支codex/shell-fullscreen-navigation，Draft base codex/shell-queue-navigation。前置双CI仍运行。

四项设计指纹一致；已复核App.tsx NEW_ICON_SPRITE/POLISH_CSS合成与基础HTML openPlayerFullscreen：打开独立播放界面并请求系统全屏，不只是导航。依设计转代码技能沿用本地完整导出（无在线node），复用原按钮与根FullscreenPresenter.enterOnNextPlayer；不新造原生通道/全屏状态。AppRouter统一闭包注入五处frame，经AdaptiveRoot/ShellPlayer可选回调接线，通用导航许可复用G1，遮罩/离页/尺寸/卸载撤销旧回调。系统不支持时仍打开播放页，既有失败反馈不改。

先ADR095。验证Windows/Android平板真实点击、仅一次enter、返回/恢复、原播放不变、失败与不支持、过期及遮罩回调；完整Flutter/Node、格式/严格分析、生成迁移与Android预检。按钮启用会改变既有Golden透明度，必须逐项精确审查而非降低阈值。手机/Inspector不扩张布局，后续继续Inspector与Phase7出口；非实机/发行验收。
