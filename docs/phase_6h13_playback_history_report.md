# Phase 6H13 — 播放历史自动记录完成报告

2026-09-08，Z-YO-YI/YYMusic，分支`codex/playback-history-recording`。
从远程最新`07ee2dbe579456b24c96e80e6b262fa0fdfeb8c1`开始，提交前fetch/pull复核无前置变化；不在main开发。
本批为stacked Draft PR，base=`codex/system-playlist-surfaces`；不合并、不改写历史、不创建Release或手动音频诊断。
本文件记录本地验证，精确实现提交的push/PR结果在对应PR回填，不能用父分支CI替代。

## 实际新增与修改

- 新增`lib/playback/playback_history_recorder.dart`，由唯一PlaybackController拥有，借用同一CollectionRepository。
  有效加载身份下，playing样本后位置确实前进才确认；短曲完成时携带位置前进也可确认。
  play命令返回、load成功、静止playing、缓冲和seek本身不计入历史；pause/resume与普通seek不重复，新加载/明确重放另建周期。
- 完整TrackRef、随机历史ID、确认UTC时间和位置被冻结后串行保存；同曲去重且最多20首。
  同毫秒/时钟回拨/重启时使用已存和已分配的最大排序时间加1毫秒，不新增Schema；这可能是逻辑排序时间而非精确墙钟。
- 保存工作先登记再调用可能重入关闭的clock/idFactory；不占用音频命令队列，关闭先排空再释放SQLite。
  CollectionRepository事务内先拒绝属于另一完整来源的历史ID，再执行同曲删除与插入；同ID/同引用可幂等重试。
- PlaybackPresenter提供与音频错误分离的安全保存反馈；最近播放页复用YYErrorBanner，最新失败可重试。
  更早失败只允许知悉或重新播放，不让旧重试重新排列后来的聆听；过期/覆盖路由回调不能操作新失败。
- 复查发现已有首页清除与新后台写入有竞争，因此既有确认动作改走同一Recorder串行通道。
  旧写入先完成再清除，新聆听排在清除之后；成功清除撤销旧重试，当前已确认聆听不自动复活。
  清除失败安全返回首页原提示，关闭也等待已接受清除。没有新增最近页清除UI。
- 同步README、实施状态、测试矩阵、计划和ADR-069，并补齐前置H12精确云端记录。

## 测试命令与结果

- `dart format lib test integration_test`与最终只读格式检查：374个Dart文件最终零修改。
- `flutter analyze --no-pub --fatal-infos`：通过，零问题。
- `flutter test --no-pub --reporter expanded`：951/951通过，51秒，包含93张Golden。
- `node --test tools/*.test.mjs`：106/106通过，包括新增3项架构/顺序门禁。
- `dart run build_runner build`、`dart run drift_dev make-migrations`：通过，生成/Schema/lockfile/平台/资产零差异。
- `node tools/design_audit.mjs --check`、`tools/verify_reference_archive.ps1`：5指纹、44最终图标、52确定产物与ZIP24项逐字节通过。
- `tools/verify_audio_licenses.ps1 -Mode Source`、`tools/verify_native_audio_notices.ps1 -Mode Source`：六音频包及完整原生材料通过。

新增44项Flutter：28播放/Recorder/生命周期、6真实SQLite、5三端页面、2生产JustAudioEngine适配器接线、1真实SQLite页面实时更新、2 Golden。
覆盖失败曲目不写、短曲/暂停/seek/重放、同毫秒20首及完整来源身份、时钟回拨/Recorder重建、序列化/关闭重入、安全重试/过期回调、SQL碰撞与事务回滚。
已有首页清除回归及新增4项写入/清除竞争测试通过。真实SQLite空最近页在根确认播放后直接更新，无需重开路由。
生产音频适配器测试使用Fake原生后端，不能称为本批实际设备出声测试。
初轮新增测试的import/字段断言及严格lint已修正；未删除测试、降低Golden阈值或关闭Lint。

## Android预检与提交检查

本机Android Debug预检：`flutter build apk --debug --no-pub`通过（19.5秒）；231,966,175字节，SHA256
`81af555c722faebf094e487eeac0996903fd30bf3cdf6bc8618886cad1b10b90`。
`tools/verify_android_apk.ps1`核对48项原始资源、六音频许可和完整原生材料；apksigner验证v2单签名通过。
JDK native-access警告如实保留；本机预检不代替本次实现提交的GitHub构建，也未生成Windows本机新安装器。

提交前25份变更文本常见秘密模式扫描零命中，无.env/私钥/安装包候选，diff无空白错误；模式扫描不等于完整安全审计。

## HTML与设计对应


基础HTML的setRecent/最近集合提供20首、同曲置顶和历史入口语义；原预览在play请求前写历史，正式实现按主指令23改为播放事实确认。
完整App.tsx的NEW_ICON_SPRITE、品牌替换和POLISH_CSS保持最终视觉依据，不只读取旧HTML。
本批使用figma-design-to-code技能的组件/Token/精确导出图标复用规则；仅有本地Make导出，未提供在线节点，不虚构get_design_context。
Phone浅色和Windows深色保存失败两张新基线已逐张查看，原有91张字节未改；没有WebView、手绘替代图标或新主题。
没有宣称完成浏览器像素对照、无障碍全验收或实机性能验收。

## 已知限制与下一阶段

### 精确GitHub验收补记

实现`891a9f1fdf0da3dd8d2ba8920658452fe9931593`的[push运行34253476324](https://github.com/Z-YO-YI/YYMusic/actions/runs/34253476324)与[PR运行34253548784](https://github.com/Z-YO-YI/YYMusic/actions/runs/34253548784)均首次成功。
两组各三项常规源码/Android/Windows检查成功，四项显式音频诊断按预期跳过；Draft PR #58未合并。
两份完整日志均核对：Linux858通过/93 Golden按宿主跳过、106 Node通过、374文件格式零修改及严格分析零问题；Windows93 Golden和1真实窗口集成通过。
Android51个音频坐标/3组完整原生法律文本/6包许可/48项资产/v2单签名通过；Windows65项运行文件校验通过。
Windows artifact `10067397763`，67,396,077字节，SHA256 `dc59081c7ebd31f47dd2fedb634c25cdf2428f16c48feab36749973a9c9c862e`，UTC到期2026-09-22T17:03:18Z。
只核对API身份/摘要与日志，没有下载或手动运行该新Debug包；普通push/PR未创建APK Release，不把诊断跳过当作本批实机出声证据。
本地25项历史生命周期/Recorder/SQLite另连续4轮通过，重复轮数不计入951个独立测试总数。

### 剩余范围

历史依据引擎状态和位置前进，不保证外部扬声器实际可听；两次快照间过短且无前进证据的曲目保守不记录。
待写任务串行且最终存储20条，但未新增挂起写入队列的数量上限或跨进程恢复日志；极端存储故障仍显示安全失败。
系统最近页清空入口、收藏/队列管理动作仍待后续，Phase6的Local Music/Settings尚未完成。
Phase7完整播放器/歌词/队列、Phase8导入授权扫描、Phase9在线来源、Phase10媒体能力、Phase11性能/安全/Release仍须独立验收。
默认新安装仍为空库，无真实导入入口；Debug通过不等于日常可用。Windows Debug依赖Debug CRT，不是通用安装器。
APK和日志只保留在忽略的build目录，不提交构建产物或任何凭据。
