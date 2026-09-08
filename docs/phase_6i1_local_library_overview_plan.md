# Phase 6I1 开始 — 本地音乐数据概览

2026-09-09，`codex/local-library-overview`，基于 fetch/pull 后的 `2b756d18c45af2ff7a7def2082ddbb72ccf5113e`。
前置 Phase6H14 本地984 Flutter/108 Node及Android通过，Draft PR #59精确云端检查仍在运行；若失败先处理，不冒称成功。

## 本阶段目标

- 为 Phase6 Local Music 页面提供真实本地曲目计数/总时长、已保存文件夹计数和有界文件夹列表。
- 单一SQL快照同时读取统计和分页，空库返回真实零值；本地和在线来源严格分开，保留所有本地不可用状态。
- 只读目录摘要包含标识、显示名、平台、启用标记和历史扫描时间，不把文件路径、Content URI或授权引用送入概览。
- 文件夹存在、启用和历史扫描时间不代表当前已授权；不扫描、不调用平台文件系统、不创建或删除用户数据。
- 提供轻量变化通知、协作取消和安全错误，复用已有数据库连接及生命周期；暂不接UI或新增Schema。

## 已读取的来源

已复验主指令、App.tsx、HTML、ZIP固定指纹；主指令17/21/29/33/36、HTML libraryLocal统计/文件夹区及已有本地分类。
已读LibraryRepository、CatalogBrowseRepository、DriftLibraryRepository/查询实现、现有LocalFolderRecords表和生命周期/测试。
本批是只读数据合同，不创建新Figma节点、页面、图标或视觉基线；App.tsx覆盖仍是后续界面的优先来源。

## 文件与合同

新增domain/models/local_library_overview.dart、domain/repositories/local_library_repository.dart、data/repositories/drift_local_library.dart及隔离SQLite/模型测试。
修改DriftLibraryRepository以实现同连接接口；共享API先记录ADR-071，更新README/实施状态/矩阵/完成报告。

## 风险与出口

风险：跨来源计数、重复关联放大计数、空分页丢统计、授权含义误报、私有路径泄露、读取失败原文、取消后返回旧结果。
出口：真实SQLite空/多来源/全部可用性/同名分页/末页/更新通知/取消/错误测试，格式/分析/全量Flutter/Node、生成与指纹/许可、本地APK预检及精确GitHub双平台。
下一步Phase6I本地音乐原生页面；真实Windows/Android选择器、导入、扫描、权限恢复仍归Phase8。无下载/Release/自动合并。
