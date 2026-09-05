# Phase 4L — 无 Header HTTPS 原生验证

2026-09-05，基于已 fetch/pull 的 `862f88ef3b138186134e5fc83bf24bc601f78472`，
分支 `codex/native-https-validation`。总指令副本 SHA-256 和原 ZIP 24 个 entry 再次一致。
已读总指令相关阶段/安全/验证条款、Phase4F/4J/4K 计划与报告、候选引擎、CI、Windows 诊断工具。
App.tsx 最终 Sprite/POLISH_CSS 合成审计保持不变；不改 UI。

## 目标与范围

补当前 just_audio 的 Android 和 Windows 无 Header HTTPS 实际播放。保留原来的本地 WAV
和 Android content URI 用例；不替换原断言、不接生产、不增加权限/依赖/下载功能。

HTTPS 不使用旧自签名服务器、代理、测试 CA 安装或证书绕过。新增固定提交的 AndroidX Media
公开测试夹具（见 ADR-040），只在测试内存中核验长度/SHA-256/Range，然后由原生插件直接读取
相同 HTTPS URL。此方式替代 Phase4F 计划中 HTTPS 也必须运行时生成的限制；本地 WAV 仍生成。
不会把该 WAV、其 Base64 或字节数组提交、打包或持久化，也不访问用户曲库。

## 文件计划

- 新增 `integration_test/support/pinned_https_audio_fixture.dart` 与单元校验测试。
- 新增 `integration_test/just_audio_native_https_poc_test.dart` 和组合来源测试入口。
- 扩展 Windows 诊断入口/结果白名单/工具：显式 `includeHttps`，默认行为仍是一项本地 WAV；
  HTTPS 模式必须同时有本地与 HTTPS 两项成功结果，验证模式、提交和全包指纹。
- CI 新增默认 false 的 `include_https_audio_poc`；只能与显式原生运行或 Profile 诊断组合。
  Android 原生模式无 artifact/Release；Windows Profile 沿用一天诊断包，不变为应用发行。
  并发组按 standard/native/profile 区分，同一模式新运行仍取消旧运行，两个平台的独立验证可并行。
- 更新 CI/Node 门禁、ADR、README、状态、测试矩阵与本批报告。

## 风险和出口

公网服务不可用、字节漂移、Range 不符、TLS 或原生播放失败均真实失败，不自动退回 HTTP/本地文件。
上游测试 WAV 为1秒，与3秒本地夹具分别计时；不是放宽原基线。Windows 必须在真实端点进程运行。
固定上游提交不保证公网永远可用，不能声称已完成离线、任意第三方来源或后台播放。

运行格式、严格分析、完整 Flutter/Node、ZIP、生成代码/Drift 零差异、本地 Android Debug、
GitHub PR 双平台 Debug、Android 组合原生测试，以及同一实现提交的 Windows Profile 原生运行。
记录精确提交、测试数量、计时、哈希和发布边界。测试失败不关闭本批；即使通过，最终选型/许可
展示和生产接线仍须下一批明确完成，不进入 Phase5。
