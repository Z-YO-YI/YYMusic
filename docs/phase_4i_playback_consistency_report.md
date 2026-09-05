# Phase 4I — 播放会话与队列一致性报告

## 实现结果

- 共用Controller区分曲目元数据与成功加载的音频会话。停止后重播、加载失败重试重新解析与load；暂停恢复不重复加载。
- 替换当前QueueEntry身份或其TrackRef、清除、移除当前项前先stop。重排不打断当前曲；stop失败不提交新队列。
- completed仅为当前会话安排一次自动下一首；排队的过期自动操作不能跳过用户手动选择的新曲或停止操作。
- 重复completed仍能同步控制值，单曲循环的新一轮播放仍可再次完成。列表播放结束后改循环模式不自动重播。
- 队列编辑保留匹配的error/failure；异步load结束时若已dispose，不继续调用play。

主要文件：`lib/playback/playback_controller.dart`、`test/support/fake_audio_engine.dart`、
`test/unit/playback_session_consistency_test.dart`、`test/unit/playback_core_test.dart`、ADR-038、README与阶段状态。
所有行为仅在共用核心，三套Shell没有重复实现。设计对应为基础HTML的队列与Transport语义；
App.tsx最终Sprite/POLISH_CSS、已有Token和Golden基线无修改。

## 回归证据

最初11项新测试在旧实现上2通过/9失败，真实复现重播、替换队列、重复完成及释放竞态问题。
修复后新增15项会话测试与原有7项核心测试共22项通过。原有随机循环测试改为“显式重播后开始新周期”，
保留原全部断言；没有删除测试、放宽Lint或替换原生POC为Fake。Fake现在拒绝无已加载来源的play，stop释放来源。

完整Flutter回归发现两个历史测试未加载任何来源即注入paused/position；现分别在
`dependency_graph_test.dart`和`foundation_app_test.dart`补齐队列、Fake Repository解析和load前置步骤，
原状态共享、42秒进度、手机/平板切换、释放次数断言全部保留。

最终完整Flutter测试 **242/242通过**，含新增15项；严格analyze **0问题**；
format检查153文件零变化；Node结构/指纹/安全边界 **35/35通过**；原始ZIP **24/24一致**。
本地详细测试输出仅保存在Git忽略的`build/phase4i-flutter-tests.log`。
Windows Debug本机实际重试失败于插件symlink权限，不声称构建或原生播放通过。
Android本机`flutter build apk --debug --no-pub`成功（26.1秒）；48项SVG/字体/许可包内字节一致，
被拒绝media_kit原生内容为0，apksigner确认v2单Debug签名。增量APK为230,986,861字节，SHA-256
`fb874c989964e2b0a9a374010ab97dd26b08e08932776340a16253f3668b158a`。
它仅是本地构建验证、不作为GitHub交付或原生播放证据、不提交构建产物。

GitHub精确提交检查与双平台干净构建结果在完成后补录；未通过前不声明本批完全交付。

## 限制与下一步

本批是Phase4共用核心修复，不关闭Phase4F原生POC，不进入Phase5。2026-09-05本机只读复查确认
AudioEndpointBuilder/Audiosrv运行、两个播放输出端点可见；先前“当前远程会话无端点”描述已过时。
本机未发现可用C++安装，且Developer Mode/符号链接权限未就绪，因此没有运行Windows原生测试。
不擅自安装驱动、更改系统安全设置或加入假时钟。本批不创建Release，不改变依赖或生产入口。
