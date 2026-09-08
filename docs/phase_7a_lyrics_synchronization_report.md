# Phase 7A 阶段报告 — 共享歌词时间轴与同步核心

2026-09-09；仓库 Z-YO-YI/YYMusic；分支 `codex/lyrics-synchronization-core`。
基于 fetch/pull 后的干净 `1d24bdc`，独立增量，Draft PR base=`codex/native-settings-surfaces`；不修改 main、不自动合并或发布。

## 实际新增与修改

- 新增 `lib/domain/models/lyrics_timeline.dart`：纯 Domain 二分时间轴，无计时器、插件或 UI 依赖。
- 新增 `lib/playback/lyrics_controller.dart`：根拥有的活动歌词同步器，只借用已有仓储和唯一播放器。
- 修改 `lib/app/dependency_graph.dart`：生产同范围注入与先停止、后排空、最后关资源的顺序。
- 修改 `lib/playback/playback_controller.dart`：可选 `canSeek` 在根串行命令开始时检查；通知中关闭延迟最终 ChangeNotifier 释放。
- 新增测试工具、17 项时间轴、25 项控制器、2 项真实 SQLite 测试；FakeAudioEngine 增加默认关闭的暂停/Seek 闸门和 Seek 错误注入。
- 新增 Node 根唯一同步器/无第二时钟门禁，扩展既有精确关闭顺序；ADR-075 与计划先于共享 API 修改。
- 更新 README、实施状态、测试矩阵，并回填前置 J2 云端成功报告与 PR #63。

## 实现结果与来源对应

同步歌词使用 [start,end) 区间，正 offset 延迟显示与 Seek，负值提前；按微秒保护整数溢出。同 start 取最后一行，最新候选已结束或区间间隙不高亮，不回退到更早重叠行。
纯文本/实际翻译原样保留，不高亮或 Seek；无当前歌曲为空闲、无文档为空态、缺仓储/读取失败为安全错误。错误不带原始异常、路径或来源私密字段，显式刷新可重试。
歌词按完整 TrackRef 和实际队列 entryId 读取，默认不活动；播放位置只更新行号，不重复查库，不复制播放进度或生成标题匹配歌词。
最多一个读取 worker；切歌、刷新、隐藏合并为最新需求，晚返回不能覆盖新会话。隐藏取消结果授权，不声称底层 SQLite 查询已被物理中断。
点击带当前 LoadState 快照；刷新即使返回同一 LyricsDocument 实例，旧回调仍失效。已排队 Seek 在执行前重新验证快照、活动代次、完整身份、引擎状态和最新时长；不乐观改变高亮。
根关闭等待已接受歌词读取和原生 Seek，随后释放引擎与共享数据库；通知/仓储调用中重入关闭安全，借用仓储不由同步器销毁。

设计源 5 指纹/44 NEW_ICON_SPRITE/52 确定产物和 ZIP 24 文件复验通过，已有 App.tsx 的 POLISH_CSS 合成仍为视觉真相。本批没有 UI/Token/SVG/Golden 修改，不需要新增视觉技能或在线设计读取。
基础 HTML 的 renderFullscreenLyrics / updateLyricsUI 对应真实仓储 + 根播放位置 + 同步行索引；不迁移网页 title-keyed Fixture、自动生成歌词、DOM 时钟、浏览器 audio 或全屏 API。

## 测试命令与真实结果

- `dart format lib test integration_test`：418 文件，最终零修改；提交前另运行只读格式门禁。
- `flutter analyze --no-pub --fatal-infos`：最终零问题，6.4 秒。
- `flutter test --no-pub --reporter expanded`：1127/1127 通过，64 秒；新增 44 项，112 张旧 Golden 均通过且字节未变。
- `node --test tools/*.test.mjs`：最终 117/117 通过，19.4 秒（文档写入后重跑）。
- `dart run build_runner build`、`dart run drift_dev make-migrations`：通过；生成文件、Schema、锁文件、平台配置和原始资产无漂移。
- `node tools/design_audit.mjs --check`、`verify_reference_archive.ps1`：5 指纹、44 图标、52 确定产物与 24 原 ZIP 文件通过。
- `verify_audio_licenses.ps1 -Mode Source`、`verify_native_audio_notices.ps1 -Mode Source`：分别通过。
- `flutter build apk --debug --no-pub`：成功，19.0 秒。`verify_android_apk.ps1`：48 项原始资产、六音频包/完整原生许可与私密/参考文件排除通过；`apksigner verify --verbose`：v2、单签名者通过。
- 本地 APK 232,056,268 bytes，SHA-256 `ccd4690b48da93d3448023b6bf06941b9a5351a1ee98a3d9352bd3b3b66f00cd`；仅位于忽略的 build 目录，不提交产物。

关键测试覆盖一万行二分与线性 oracle 一千次比对、首尾/间隙/重复/零长度/极端偏移、同 ID 不同来源、纯文本双语、最新位置、单查询合并、加载失败重试、隐藏与切离又返回后的旧 Seek、可重入刷新/关闭和真实 SQLite 读取排空。
初轮 SQLite 扩展导入与严格分析提示已修正重跑；未关闭 Lint、跳过失败、修改旧 Golden 或减少旧验证。
提交前 17 个变更文本文件敏感模式扫描零命中，`git diff --check` 通过；没有环境文件、凭据、私钥或构建产物进入提交。

## 限制、同步与下一阶段

这是一批共享核心增量，不是完整 Phase 7。尚未将歌词控制器接到原生路由：独立播放/歌词/队列界面、自动滚动、翻译开关、Esc/返回关系及平台沉浸能力继续按后续批次实现。
本机 Windows 构建、本批 Android 实机安装/出声、性能 Profile、Release/AAB 未运行，不计入通过。GitHub 新提交的 Android/Windows 结果在推送与 Draft PR 后按精确 SHA 核对；前置 J2 双组 SUCCESS 不代替本批验收。
普通 Android CI 构建并验证 APK，但没有上传 APK artifact；Windows Debug 依赖 Debug CRT，不是通用安装发行版。新安装仍为空库，真实导入扫描属 Phase 8，来源/平台后台媒体/QA 发行仍待 Phase 9–11。
不发布 Release、不手动触发诊断、不合并 PR、不提交凭据/私钥/环境文件/构建产物。下一步进入 Phase 7 的原生独立页面接线与交互验证。

## 精确 GitHub 验收回填（Phase 7B1 核对）

实现提交 `ffb83e6dd492eaa6ce1c3c42ac1de407475004cf` 的 Push [34279329106](https://github.com/Z-YO-YI/YYMusic/actions/runs/34279329106) 与 PR [34279334384](https://github.com/Z-YO-YI/YYMusic/actions/runs/34279334384) 均 SUCCESS；[PR #64](https://github.com/Z-YO-YI/YYMusic/pull/64) 为 Draft/OPEN，未合并。
两组 Linux 各 1015 Flutter 通过/112 宿主 Golden 跳过，Windows 各 112 Golden + 1 真实窗口生命周期通过。Android 两组均完成 51 音频坐标/3 完整法律文本、48 原始资产和 v2 签名；Windows 65 文件/六音频包/完整原生许可通过。
Push [Windows Debug artifact](https://github.com/Z-YO-YI/YYMusic/actions/runs/34279329106/artifacts/10077461411) 为 67,489,116 bytes，SHA-256 `b328a5f5b22823ffd2873c22322842d6c508a06cd3821aa0b2f279822c032cf2`，核对时未过期，到期 UTC 2026-09-22 21:27:09。
普通 Android 运行没有上传 APK artifact；Windows 开发包依赖 Debug CRT，不是通用安装版。未发布 Release、未手动运行原生诊断，不把本证据归给后续页面增量。
