# Phase 5B 增量 — 正在播放 Inspector 报告

2026-09-05，`codex/now-playing-inspector`，基于已 fetch/pull 的 `05f818d`（Draft PR #33）。
本仓库批次编号覆盖主指令 Phase5 Windows/Tablet 的详情能力，不表示主指令5B Phone已全面验收。
前置05f818d的push33961128767和PR33961146824均completed/success，checks、Android Debug、
Windows Debug全部通过；两项原生POC按设计skipped，不计新设备运行。

## 实现

新增受控 `YYNowPlayingInspector`：原稿18padding/26radius不透明面板、player角色封面占位、
真实标题/艺人/来源类型/播放状态/队列总数，3dp/14dp进度、56dp主Transport、38dp次要视觉按钮，
命中保持至少44dp，使用App.tsx覆盖后的阴影/hover与原SVG。260dp布局将模式控件放到下一行，
所有内容独立纵向滚动，短窗口与130%长中英文不会溢出。没有模糊整页或默认Material。

Windows>=1440的320dp、Android横屏>=1200的260dp详情位替换原占位；由AdaptiveRoot注入
ShellPlayer.inspector模式，与底栏复用相同Presenter和手势实现。只新增安全的来源类型/状态与
真实队列总数投影，不显示地址、路径或凭据，也不把物理队列顺序说成随机后的下一首。

两个表面可独立预览，提交后从根状态收敛；禁用时同时清除Widget预览，修复同条目重载后可能
残留旧进度的问题。换曲的entryId保护沿用5A；隐藏/恢复详情不重载或释放音频。
原稿的完整歌词/设备/收藏/队列业务与真实Artwork尚未接入，相关入口保持禁用并注明剩余工作。
本批不新增网络、依赖、Schema、文件权限或音频实例。

## 验证

- 严格 analyze 0；最终 Flutter 308/308，41张Windows宿主Golden；Node59/59。
- 新增5个Widget场景：Windows/Android两表面play/pause/next/modes/seek状态收敛、宽窄隐藏恢复，
  空/加载/固定错误/重试、同条目重载清除预览、260×240短视口独立滚动。
- 同条目重载测试最初只pump一帧、尚未进入load即断言loading导致失败；等待布局中间帧稳定后
  在仍被Completer阻塞的load中断言，再完成load验证预览消失。没有放松生产行为或丢弃Future。
- 首次非更新Golden只出现2张预期整页差异：Windows expanded空态和White播放态；确认后更新。
  新增320浅色播放、260深色播放、320白强调错误三张完整面板，逐张检查；其余36张基线不变，
  最终全量非更新比较通过。尚缺网页参考截图，不能宣称与网页逐像素完全一致。
- 182文件format零差异；build_runner71项内部缓存输出；跟踪的生成代码/Drift快照/lockfile零差异；
  ZIP24/24和六包源码许可指纹通过。

- Android默认Debug成功（19.1秒）：48设计资产、六包Dart许可和原生许可资产均匹配，v2签名有效、
  一个Debug签名者。APK231,546,250字节，SHA256
  `c3735dc6fa6d061bb1c09c8cbe88dee6613510c1a9f7ff619a4faf43188fbae5`。
  原生Java警告保留，未更改工具链或全局权限来压制。

实现提交`a39d306435738cc24a8ac23540ae092bafecb056`，Draft PR #34保持未合并。
GitHub push33961718376与PR33961733794均completed/success：两组checks、Android Debug、
Windows Debug全部通过，原生音频POC两项均skipped（不计新原生设备运行）。没有新原生POC、Release或
真实歌曲导入；这些Widget/Fake合同不替代Phase4L的设备播放证据。Phase5窗口能力和Phase6—11
继续分批开发，不能作为完成版音乐应用或上线成果交付。
