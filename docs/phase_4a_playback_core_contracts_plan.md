# Phase 4A 开始 — 播放核心合同与唯一状态源

日期：2026-09-04。开始前已 fetch，并确认
`feat/dev-fixture-bootstrap@e5072a0` 与远端同步、工作树干净；从该提交创建
`feat/playback-core-contracts`，不在 main/master 开发。

## 本阶段目标

- 把 Phase 1 的 play/pause 占位接口升级为项目自有的正式音频合同：可播放来源、
  引擎状态流、load/play/pause/stop/seek/volume/rate 与安全错误。
- 由根级 `PlaybackController` 合成当前曲目、位置、缓冲、时长、音量、随机、循环、
  队列、输出设备和失败；插件状态不得直接成为 UI 状态。
- `QueueController` 只委托给 `PlaybackController`，不保存第二份队列；队列项 ID 与
  TrackRef 分离，重复曲目仍可独立排序、移除和播放。
- 定义 Android MediaSession 与 Windows SMTC 共用的项目接口及回调，不在 UI 或
  Shell 中出现平台/插件类型。
- 为后续真实后端 POC 建立同一套 Fake 合同矩阵，并保持生产默认后端明确不可用。

## 安全与生命周期边界

- 本地来源只接受绝对文件路径或 Android `content://`；网络来源只接受无 user-info
  的 HTTPS。临时流 URL 和 Header 可交给音频适配器，但 `toString` 必须全部脱敏，
  不写入数据库、日志或 Fixture。
- 未识别异常映射为只含固定 diagnostic ID 的 `DomainFailure`，不得把底层异常、
  URL、路径或 Header 放入公开状态。
- 根依赖图只创建一个 Controller/Engine/MediaSession；Shell 切换、路由切换和
  Android 599↔600 断点切换均不得重建。
- 依赖图初始化时恢复正式 CollectionRepository 中的队列；释放时按队列门面、
  Controller、Engine、MediaSession、数据作用域的顺序幂等清理。

## 队列与播放语义

- 支持替换、末尾添加、下一首插入、移动、移除、清空、指定项播放、上一首与下一首。
- 随机播放使用可注入的索引选择器生成一次遍历顺序；关闭循环时一轮内不重复，列表
  循环才开启下一轮，单曲循环只影响自然播放完成，不阻止用户手动切歌。
- 删除当前项或清空队列时停止引擎并清除当前曲目；只删除非当前项不得中断播放。
- Seek 拒绝负值，并在已知时长时夹紧到曲末；未知时长不写入示例常量。
- 引擎 `completed` 是自动下一首的唯一触发，不能用 UI Timer 推进队列。

## 不在本批

- 不选择或添加真实音频插件，不宣称 Windows/Android 音频 POC 通过。
- 不提交音频二进制、用户路径、在线密钥、可播放 URL、下载缓存或离线文件。
- 不接正式播放器 UI、歌词路由、历史写入、音频焦点、耳机/蓝牙、通知或 SMTC 原生实现。
- 不增加 Shell 专属控制器，不修改视觉 Token、Golden 或已审计 SVG。

## 出口条件

- 状态模型覆盖主指令规定的八个播放阶段与全部字段，并对边界值做运行时验证。
- Fake Engine/Resolver/MediaSession 覆盖 load、状态流、Seek、队列重复项、随机一轮、
  repeat off/all/one、错误脱敏、媒体按键与幂等释放。
- 架构门禁证明 Shell/UI 不依赖音频插件或创建播放真相，工程中不存在下载/离线 API。
- format、严格 analyze、Flutter 全量测试、Node 门禁、ZIP 审计和 Android Debug 构建通过；
  GitHub Windows/Android Debug 在实现提交上通过。
