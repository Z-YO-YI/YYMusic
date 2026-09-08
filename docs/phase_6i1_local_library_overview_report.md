# Phase 6I1 — 本地音乐数据概览完成报告

2026-09-09，Z-YO-YI/YYMusic，`codex/local-library-overview`。
基于fetch/pull后的`2b756d18c45af2ff7a7def2082ddbb72ccf5113e`，独立stacked Draft PR以`codex/system-playlist-management`为base。
前置H14两组精确源码/Android/Windows已成功；本报告仅记录新批次本地验收，不借用前置CI宣称当前提交已通过。

## 实际新增与修改

- `local_library_overview.dart`：不可变LocalTrackSummary、LocalFolderSummary、LocalLibraryOverview；全五类可用性、总时长、文件夹总数/启用数与有界窗口。
  校验非负数、总数/窗口长度、唯一ID及可见启用/禁用数与总体一致；错误不回显输入，目录/概览调试字符串脱敏。
- `local_library_repository.dart`：只读概览及变化流合同，沿用SearchCancellation。消费者先订阅再读、撤销旧结果、取消订阅并排空读取后关闭存储。
- `drift_local_library.dart`与DriftLibraryRepository：在原数据库连接上新增接口实现，单一SQL组合仅本地曲目统计与文件夹窗口。
  SQL不连艺人表避免重复计数；分页参数绑定，按lower(display_name)/display_name/folder_id稳定排序，空库或越过末尾仍保留统计。
  仅选择文件夹ID/显示名/平台/enabled/lastScannedAt，不读取local_path、content_uri、grant_ref，未知平台保留unknown。
  tableUpdates只通知tracks/local_folders变更，不读取全曲库；沿用安全DomainFailure及读前/读后取消检查，不承诺中断原生SQL。
- `fake_local_library_repository.dart`与`local_library_overview_test.dart`：可替换隔离Fake、真实SQLite、模型校验测试。
- `tools/local_library.test.mjs`、ADR-071、阶段计划、README、实施状态、测试矩阵和报告；回填H14精确成功云端日志与Windows产物。

## 实现结果与设计对应

对应主指令17/21/29/33/36及HTML libraryLocal的曲目统计和文件夹记录；从既有本地分类继续，没有跳过Local Music去实现其他页面。
本批是数据层，尚未接入新的本地音乐UI/根Controller；没有新增页面占位、图标、主题值或手绘近似Figma元素。
App.tsx最终NEW_ICON_SPRITE/POLISH_CSS、品牌替换与基础HTML合成参考保持原样，不把网页session/模拟目录用作生产记录。
enabled只表示保存配置；lastScannedAt只表示已有历史记录；统计的available是已保存可用性，不代表刚刚验证文件可读或系统授权。
不执行文件扫描、不申请权限、不修改或删除任何用户文件/授权/曲库数据。测试全部使用内存SQLite和隔离夹具。

## 测试与构建

- 针对性16项通过：13真实SQLite、2模型、1Fake；覆盖多来源同ID、全部可用性、双艺人不放大计数、真实零值、稳定分页/末页。
- 425文件夹测试只返回200行；SQL统计/窗口在查询返回前又发生写入时仍保持同一旧快照，下次读取才见新记录。
- 变更通知不执行SELECT；插入与更新会使消费者失效，取消订阅后不再收到事件。预取消零SQL/晚取消丢弃结果，初始化和关闭后拒绝读取。
- 数据库错误及非法目录名称输出安全Failure；概览不解析无关损坏track metadata，不把私有路径/授权字段送出。
- `dart format lib test integration_test`及最终只读检查：385文件零修改。
- `flutter analyze --no-pub --fatal-infos`：零问题。
- `flutter test --no-pub --reporter expanded`：最终1000/1000通过，51秒；98张Golden全部通过且字节未改。
- `node --test tools/*.test.mjs`：111/111通过，含新增3项只读/隐私/同连接合同门禁。
- `dart run build_runner build`、`dart run drift_dev make-migrations`：通过；生成代码/Schema/lockfile/平台/资产/Golden均零差异。
- `node tools/design_audit.mjs --check`：5指纹/44图标/52确定产物通过；`tools/verify_reference_archive.ps1`：24ZIP条目逐字节一致。
- `tools/verify_audio_licenses.ps1 -Mode Source`与`tools/verify_native_audio_notices.ps1 -Mode Source`独立执行通过。
- `flutter build apk --debug --no-pub`：通过；`tools/verify_android_apk.ps1`独立执行，48资产及六音频包/完整原生许可通过。
- `apksigner verify --verbose`：v2签名、单签名者通过；本地APK231,987,139 bytes，SHA-256 `d454c343f36f5016c07a5fb1cbed0d1e7e41ff863699b283a23df3dd4cc3d1b5`。

未删除测试、降低Golden阈值、关闭Lint或新增依赖。日志/APK留在忽略的build目录，不作为源码提交。
提交前14个变更文本文件敏感模式扫描零命中，未包含.env、密钥或不必要构建产物；`git diff --check`通过。
本机未运行Windows构建/本批Android实机安装；用户要求的双平台GitHub构建以本提交的push/PR实际结果为准。

## 已知限制与下一阶段

数据合同完成不等于本地音乐页面、导入或授权已实现。后续接同一根数据范围与原生Phone/Tablet/Windows页面，再按顺序推进Settings和Phase7–11。
当前已有曲目分类仍是此前界面，默认新安装为空库。没有读取真实个人音乐目录、没有长期保存在线音频、没有发布Release或自动合并。
完整播放器/歌词/队列、Phase8扫描与失效恢复、第三方来源、后台/系统媒体、设备性能/网页视觉对照和正式发行仍未完成。

## 精确 GitHub 验收回填（2026-09-09）

提交`79540d0b0dd99c0024277457b3d39da951be727d`，Draft [PR #60](https://github.com/Z-YO-YI/YYMusic/pull/60)仍OPEN、未合并。
[push 34261549723](https://github.com/Z-YO-YI/YYMusic/actions/runs/34261549723)与[PR 34261554903](https://github.com/Z-YO-YI/YYMusic/actions/runs/34261554903)均completed/success，完成日志已逐项核对：

- 两组Linux各902通过、98张Windows宿主Golden按平台跳过；111 Node、严格分析、生成/迁移/24条ZIP一致性通过。
- 两组Windows各98 Golden与1项真实窗口状态/关闭握手通过；Debug构建及65文件完整包/六音频许可/原生完整许可校验通过。
- 两组Android Debug及v2签名通过；51实际音频坐标/3完整法律文本/48原始资产校验通过。常规运行未创建Release或启动手动音频诊断。
- push的[Windows Debug产物10070752389](https://github.com/Z-YO-YI/YYMusic/actions/runs/34261549723/artifacts/10070752389)：67,420,874 bytes，SHA-256 `b8b2cade2ee56a9be98795ce66a9cb57a63e55616c6ff61f28b76ea8f1e41551`，API复查未过期，UTC到期2026-09-22T18:29:01Z。

上述仅证明I1精确提交的开发构建，不作为后续I2提交的验收，也不代表Windows通用安装包或Android日常可用发行版。
