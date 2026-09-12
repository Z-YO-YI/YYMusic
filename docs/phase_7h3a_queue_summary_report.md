# Phase 7H3A：只读队列摘要接口与云端截图修复

2026-09-13；基线d3e26cbdfb11b0d89eff987073e1342f1427e3e0，fetch/ff-only pull且工作区干净。分支codex/inspector-queue-summary，Draft base codex/inspector-sleep-settings，先[计划](phase_7h3a_queue_summary_plan.md)/ADR105后实现。

## 实现

PlaybackQueueSummary从唯一根QueueSnapshot派生总数、准确currentEntry与1起始currentOrdinal，无当前项时为null。按entry ID定位而非TrackRef，重复曲目仍区分身份；仅表示保存列表位置，不预测随机播放顺序。不可变快照不持有播放器、订阅、Timer或Repository。

PlaybackPresenter按根QueueSnapshot对象身份缓存投影，音频位置/音量/模式通知不重复遍历，重排/切歌/清空时更新，原快照保持不变。10新增单测覆盖上述边界，读取不会产生音频命令或替换根状态。**本批接口尚未绑定Inspector界面或队列入口**，H3B继续视觉实现。

## 优先修复父阶段CI

开发中父阶段push34725547000与PR34725576246报告Windows截图失败，Android/源码检查成功。立即停止界面扩展并检查日志：分别为Inspector和Shell睡眠弹层Windows图的背景同名曲目行差异。FakeLibraryRepository为每首曲目读取时钟，部分主机精度下时间相同按source排序，其他主机按不同时间倒序，导致当前曲目高亮位置不同。不是生产播放状态故障，也不能通过扩大像素容差解决。

LyricsFixture固定一个导入批次时间；新增独立回归使用每次调用递增的时钟验证只读一次且排序为one/three/two。未改生产排序与任何PNG，云端相同tags命令208图严格通过（47秒），之后完整测试也通过。此证据纠正前批仅归因阴影的判断；旧云端运行仍为failure，新SHA需独立复验。

## 验证

- 最终1937 Flutter通过（94秒），包括10摘要单测、1时钟回归及208原Golden；150 Node通过（31.4秒）。
- 540 Dart文件格式零改动；严格分析0问题（16.4秒）；build_runner38秒与Drift迁移通过，生成/schema无差异。
- 24原ZIP条目逐字节匹配，原音频许可指纹通过；未改App.tsx/HTML/指令或资产。
- Android Debug48秒；48打包资产/完整音频许可、v2单签名者通过。APK232265265 bytes，SHA256 `4e7483ff0fc1a5f4a22d597cabb523066ffcecdf5f2fcdb4945f323ee94d3b1e`。保留Java native-access警告，不提交构建产物。
- 无新增设备安装/出声或本地Windows编译；云端新提交另验，不将Debug或本地测试视为上线。

主要文件：playback_queue_summary.dart、playback_presenter.dart、lyrics_fixture.dart、两份单测、Node门禁及README/状态/矩阵/ADR/计划/报告。修复与接口分别Conventional Commit，推送并维护Draft，不合并或发布Release。精确提交与运行链接在PR记录。

后续H3B把已验证投影绑定原侧栏摘要与受保护队列入口；其余真实播放设置、Phase7整体及Phase8–11尚未完成。
