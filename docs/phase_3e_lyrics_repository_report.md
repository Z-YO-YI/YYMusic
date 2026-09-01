# Phase 3E — Drift LyricsRepository 报告

2026-09-01。开始前已fetch并确认`feat/collection-repository-drift@bc49b38`与远端同步、工作树干净；从该提交创建`feat/lyrics-repository-drift`，未在main/master开发。范围与出口见[计划](phase_3e_lyrics_repository_plan.md)。

## 当前实际进度

本批实现第三个正式数据Repository：`LyricsDocument`与既有`lyrics_cache`之间的严格JSON/row映射，以及`LyricsRepository`的get/save/remove全合同。AppBootstrap/DependencyGraph仍未构造它，启动应用不会打开数据库、写入歌词或生成Fixture。MusicSource正式Repository、安全存储、Dev Fixture和Controller仍待后续小批次。

## 映射与持久化

1. 缓存主键使用完整MusicSourceType/sourceId/trackId；相同trackId在不同来源或来源类型间不冲突，也不要求catalog Track或MusicSource row存在。
2. plain与synchronized统一编码为确定性的四字段行数组：`startMs`、`endMs`、`text`、`translation`；language、translationLanguage和offset保存在既有独立列。
3. save使用复合主键`insertOnConflictUpdate`原子替换单份文档并记录注入时钟的UTC毫秒；remove不存在行幂等成功。
4. 解码拒绝非数组、未知/缺失字段、错误类型、空行集、kind/时间不一致、同步顺序错误、翻译语言不一致和不可解析更新时间，再重走LyricsLine/LyricsDocument与TrackRef构造。
5. JSON、row或SQLite异常不泄露歌词、翻译、TrackRef、SQL或路径，只返回日志安全`DomainFailure(databaseCorrupted)`。默认Repository不关闭共享AppDatabase，只有`.owned`在幂等dispose时关闭。

## 本地验证

| 检查 | 当前结果 |
| --- | --- |
| Lyrics定向 | 6项真实内存SQLite通过：plain upsert/remove、同步双语/规范JSON、完整TrackRef隔离、损坏JSON/时间脱敏、SQLite失败脱敏、shared/owned生命周期 |
| 架构边界 | Node定向通过：只有data导入Drift，正式实现只覆盖Lyrics合同，AppBootstrap不打开DB，v1表集不变 |
| 全量门禁 | lockfile严格复现；122文件format零改动、严格分析0问题；181项Flutter含32 Golden、29项Node、ZIP24项全部通过；代码生成/make-migrations后v1 g.dart/快照零差异 |

## 云端与限制

实现提交`1e45532`已推送；[Draft PR #13](https://github.com/Z-YO-YI/YYMusic/pull/13)以`feat/collection-repository-drift`为base并保持未合并。目标提交的push[运行33499761224](https://github.com/Z-YO-YI/YYMusic/actions/runs/33499761224)、PR[运行33499787210](https://github.com/Z-YO-YI/YYMusic/actions/runs/33499787210)和唯一一次手动[运行33500756816](https://github.com/Z-YO-YI/YYMusic/actions/runs/33500756816)均为三job success，分别通过源码/分析/测试、Windows Debug与Android Debug构建。

手动运行创建了标签字段`ci-debug-33500756816-1`的[私有草稿/prerelease](https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-3cd11bdc85a947cb77c1)，target_commitish精确等于完整实现提交，且只有`build-metadata.json`、`SHA256SUMS`和`YYMusic-debug.apk`三资产。下载后独立复核APK为183604101字节，metadata、SHA256SUMS、本地计算与API digest均为`fd71936ef590dc18b1e851572c21cbf6d10f157a495298022dec3f2dd384020a`；48份打包SVG/字体/许可逐字节匹配，apksigner显示v2单签名有效，v1/v3/v3.1/v4为false。首次清理因白名单排序预期错误安全停止，文件未改动；修正精确三文件检查后临时副本已删除，草稿Release保留可恢复。

本机Windows C++/Developer Mode仍受远程/UAC限制，不声称本机Windows构建或安装成功；GitHub Windows runner成功也不替代目标电脑安装、辅助技术/GPU或Android真机验收。APK继续使用临时Debug签名，不是正式发布包或稳定升级密钥。

## 主要文件

- `lib/data/repositories/lyrics_row_mapper.dart`
- `lib/data/repositories/drift_lyrics_repository.dart`
- `test/unit/drift_lyrics_repository_test.dart`
- 架构边界、ADR、依赖、状态与验证文档

下一批应单独实现MusicSourceRepository的公开配置持久化，再以独立安全存储批次实现SecureCredentialGateway；不把credential值、Controller、网络适配器或UI混入本提交。
