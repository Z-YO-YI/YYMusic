# Phase 6I2 开始 — 本地音乐原生概览

2026-09-09，`codex/local-music-surfaces`，fetch/pull后基于干净`79540d0b0dd99c0024277457b3d39da951be727d`。
前置PR #60源码/Android已成功，Windows仍在运行；先处理任何失败，不借用前置CI验收本批。

## 目标、来源与文件

本地分类接入真实统计、文件夹20条分页、启用配置/历史扫描标记和空/加载/错误重试；不提供尚未接入的导入/扫描/授权操作。
主指令17/21/29/36、HTML libraryLocal、完整506行App.tsx（44最终SVG、两项品牌替换及全部POLISH_CSS）与现有Library布局已读取。
复验5指纹/44图标/52产物。使用figma-design-to-code技能复用现有YY组件/精确SVG；只有本地导出，无在线节点，不虚构get_design_context。
修改AppDataServices/DatabaseAppDataServices/DependencyGraph与Library接线；新增LocalMusicController、受控Sections/Panel及Phone/Tablet/Windows组合布局。
更新ADR-072、测试/Golden、README/实施状态/矩阵/报告。共享API先决策再改动，不新增Schema或依赖。

## 风险与出口

根只持有一份本地概览；页面/布局切换不复制数据库或播放器，隐藏/覆盖/零尺寸拒绝旧回调、丢弃待返回结果。
订阅先于读取，失效合并为单一读取通道，页尾删除回退有效页，错误保留安全提示而不假装零值；关闭排空实际读取与订阅取消。
单元/SQLite/三端Widget/130%字体/键盘/断点/旧回调/关闭测试；新增Golden逐张检查，旧基线不得无理由更新。
出口：格式/严格分析/全量Flutter与Node、生成/指纹/许可、Android本地预检、精确GitHub双平台及推送/Draft PR。
下一步按Phase6继续Settings；导入和授权扫描仍属Phase8，Phase7–11和正式发行未完成。
