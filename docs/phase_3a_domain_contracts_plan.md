# Phase 3A 开始 — Domain 模型与数据合同

日期：2026-09-01。开始前已fetch并确认`feat/cross-platform-queue-lyrics-primitives@3c09ed7`与远端0/0同步、工作树干净；从该提交创建`feat/domain-model-contracts`，不在main/master开发。

## 本阶段目标

- 建立与平台、数据库、HTTP和Flutter UI无关的核心Domain模型：Track/TrackRef、Album、Artist、Playlist/Entry、QueueEntry/Snapshot、Favorite、History、Lyrics、MusicSourceConfig。
- 建立显式`idle/loading/data/empty/error`状态、分页模型、脱敏失败分类、Library/Collection/MusicSource Repository合同和SecureCredentialGateway合同。
- 用测试Fake证明Repository/Gateway可替换，并保持根`DependencyGraph`只依赖自有接口。

## 已读取与校验的来源

- 主指令第10节核心模型、第11节核心接口、第12节状态边界、第29节持久化、第30节错误分类及Phase3任务/出口。
- 完整App.tsx及基础HTML的catalog规范化、favorite/recent/playlist/queue持久状态、来源默认结构和同步/翻译歌词Fixture；App.tsx的`NEW_ICON_SPRITE`与`POLISH_CSS`不属于本批数据合同，仍保持Phase2成果不变。
- Phase0 ADR中的稳定TrackRef/QueueEntry ID、来源删除后不可用引用、普通配置与安全凭据分离、禁止下载/明文秘密边界。

## 风险与边界

- 本批不安装Drift，不创建表、数据库文件或Migration；Schema/Migration作为下一独立批次。
- 不接UI、不替换Phase4前的PlaybackState/AudioEngine，不执行HTTP、文件扫描、安全存储或平台调用。
- `MusicSourceConfig`只允许公开Header并拒绝Authorization/API Key/Cookie等敏感名称；秘密只通过`SecureCredentialGateway`的内存值传递，`toString`必须脱敏。
- HTML的随机/时间生成ID、object URL、默认在线成功和示例Token不进入正式Domain或Fixture。

## 出口条件

- 模型不变量、不可变集合、歌词时序、稳定队列entryId、来源公开字段校验和脱敏失败有单元测试。
- Library/Collection/Source Repository及Credential Gateway均可用Fake替换；UI与Domain不导入数据库/HTTP/平台插件类型。
- 全量format、strict analyze、Flutter/Node/ZIP/指纹门禁通过；独立提交、Draft PR与GitHub Android/Windows Debug通过。
