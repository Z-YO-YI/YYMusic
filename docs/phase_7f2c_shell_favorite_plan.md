# Phase 7F2C 开始：底栏收藏

2026-09-12，基线a4faf905af6c65f077fe230a664291c9c50c844f；已fetch/ff-only pull且干净，分支codex/shell-current-favorite-ui，Draft base codex/player-current-favorite-ui。前置34706094820/34706097249仍运行。

目标：桌面/平板宽底栏借同一根收藏，独立busy和安全反馈；窄底栏/手机保持原布局省略心形。已读总指令及当前实施记录、ShellPlayer/AdaptiveRoot/AppRouter/桌面组件/两端Shell；原App.tsx NEW_ICON_SPRITE/POLISH_CSS及HTML2431心形已审计，24导出文件重新逐字节验证。沿用设计转代码技能本地导出路径，无在线节点，不新画图标。

先ADR093，再修改ShellPlayer/独立生命周期part、AdaptiveRoot和五处AppRouter frame注入、桌面组件独立收藏忙态/未知语义；新增Widget/Golden/Node并更新文档。底栏跨主导航保留：监听路由配置变化永久撤销旧代数，尺寸/布局/选中页面身份变化亦撤销；ModalRoute/活动/面积即时检查，根仍复核原投影。失败根保留，反馈有界滚动，收藏不禁用音频。手机/Inspector无新增收藏入口，不创造额外订阅或存储。

出口：跨主导航/独立路由/尺寸/零面积/卸载/快照撤销、接受后排空、重试与多个Shell根共享等Widget验证；精确更新真正受状态接线影响的Golden逐张看，完整回归/格式/分析/生成与Android预检通过后commit/push/Draft。云端新SHA独立验收，不把Debug当作上线。
