# Phase 7F2A 开始：歌词 Dock 收藏

2026-09-12。基线4302cbbb7ee98f5ef5df8ba6c62f55123e7df5de，fetch/ff-only pull成功且干净；独立分支codex/lyrics-current-favorite-ui，Draft基于codex/current-track-favorite-core。前置PR构建34703282153成功，push34703279070仍运行，不能混为双成功。

## 目标、来源与范围

先接独立歌词页的共用根收藏状态、显式写入、busy和安全读写失败反馈；后续另批接播放页/Shell。已核对四源SHA256及24个解压文件逐字节一致，读取总指令Phase7–11/阶段格式/代码规则，审查App.tsx的NEW_ICON_SPRITE心形与POLISH_CSS合成和基础HTML 1937–2035/2483歌词Dock。使用设计转代码技能的本地导出路径，无在线节点；复用YYLyricsPlayerDock/YYButton/YYErrorBanner/原心形SVG，手机按原CSS隐藏Dock收藏，不擅自塞新图标。

## 文件、风险与出口

先记录ADR091，修改AppRouter/YYMusicApp/LyricsScreen及Dock独立收藏忙态；新增收藏反馈组件、歌词动作part、Widget/Golden及Node门禁，更新进度文档。仅存在CollectionRepository时注入可选收藏能力，无存储的独立预览保留原样。未知收藏不宣称未收藏，按钮隐藏至读到真值；读失败显示重试。

操作捕获原投影和页面代数，路由覆盖/离页/零面积/resize/切歌/卸载撤销未接受写入，已接受写入由根排空。失败与读重试绑定原失败身份，不自动重试；busy不递增页面代数、不禁用播放导航。根真值驱动显示，不做乐观翻转。补原生交互、同ID跨来源、失败/重试/过期回调/关闭、三端布局与Golden；全量格式/严格分析/Flutter/Node/Android预检后提交push/Draft PR，新SHA双平台CI另验。无Schema/依赖/平台/原资产变更，不宣称Phase7或上线完成。
