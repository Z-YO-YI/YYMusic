# Phase 4I — 播放会话与队列一致性

2026-09-05。已 fetch/pull，基于与远端同步的
`refactor/remove-media-kit-candidate@58398eadb94190b9eefe40fb73097af2f2c96df3`
创建 `fix/playback-session-consistency`。原设计 ZIP 的 24 个 entry 再次逐字节验证通过。

## 目标与依据

依据总指令第 20、25、36、39 节以及 Phase 0 已审计的 HTML 队列/Transport 行为，
修复共用 PlaybackController 的会话一致性，不改 App.tsx 的最终图标、POLISH_CSS 或三套 Shell。
本批仍属 Phase 4；生产继续 UnavailableAudioEngine，不宣布双平台原生 POC 完成。

本轮代码审计发现：stop 后仍凭 currentTrack 直接 play；load 失败后也可能绕过重新解析；
replaceQueue 丢弃当前引用但没有停止旧音频；重复 completed 会排入多个自动下一首；
错误状态下队列修改清除 failure 却保留 error phase，违反模型约束。

## 文件与风险

- 修改 `lib/playback/playback_controller.dart`，保持公共接口不变。
- 增强 `test/support/fake_audio_engine.dart`，新增会话一致性回归测试。
- 同步 ADR、README、implementation_status 与本批报告。
- 重点风险是异步命令、完成事件与持久化失败的顺序；不能为让测试通过伪造成功状态。
- 不升级依赖、不修改数据库、CI 发布权限、不添加音频文件、代理、下载或 WebView。

## 出口

1. stop/load 失败后的 play 重新解析并加载；暂停恢复不重复加载。
2. 替换/清除/移除当前队列身份时先停止旧音频；保留身份/引用的重排不中断播放。
3. 单次完成只自动推进一次，排队期间过期的完成操作不能跳过用户选择的新曲。
4. 保留失败状态的一致性，dispose 后不继续启动音频。
5. 回归测试先复现，再通过；format、严格 analyze、完整 Flutter/Node 测试及 GitHub 双平台 Debug 构建通过。
6. 独立提交、推送并建立 Draft PR；本地 Windows 原生运行限制如实保留。

## 本机环境复核

只读提升权限检查确认音频服务运行、两个 render 端点可见。此前“当前本机无端点”的结论不再适用；
GitHub 托管 Windows runner 的无端点失败仍是历史真实结果。本机未发现可用的 Visual Studio C++ 安装，
Developer Mode/符号链接权限也未就绪，本轮不修改系统权限或安装驱动，因此不声称已经运行原生播放 POC。
