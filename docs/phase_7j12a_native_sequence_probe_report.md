# Phase 7J12A：独立原生循环序列探针

## 2026-09-19 Android原生执行补记

bd0c374已推送，显式[Actions 35412218776](https://github.com/Z-YO-YI/YYMusic/actions/runs/35412218776)完成success。原local/content两项先通过，随后本序列测试实际执行1项、31秒通过，日志sourceCommit=bd0c37460a0b1372a99317ef4f8d25c04ec4a881、platform=android、observedIndices/observedCycles=[0,1,2]，append/prune/retain/disposed=true，completedAtIndex=2，acousticGapMeasured=false。下文“尚未执行”为本批最初提交时记录，现已补模拟器原生执行证据，仍不代表Windows、真机声学或Phase7整体验收。Windows独立Profile接线继续见[J12B](phase_7j12b_windows_sequence_report.md)。

## 范围与基线

2026-09-18，基线174d873，沿用codex/native-repeat-window。开始前fetch/ff-only pull，工作区干净；不切换分支，不重做J11的生产代码。按[J12计划](phase_7j12_native_sequence_probe_plan.md)先实现独立测试及Android显式诊断接线，Windows独立Profile封装和结果验证器留下一增量，旧Windows探针的1/2项测试合同不改变。

目标：用真实JustAudioEngine与原生插件验证加载、追加播放、跨cycle、前缀清理、截尾、完成和关闭。准备新增独立集成测试及工具门禁，修改已有工作流的显式诊断选项与阶段文档。风险为真实事件延迟、CI设备环境及诊断入口与生产包混淆；出口区分源码/编译通过与设备真正执行通过。

## 实现

- `integration_test/just_audio_native_sequence_poc_test.dart`：只生成临时低幅PCM WAV（10秒），低音量0.05；加载同一entry的cycle0/1不自动播放，一次play后追加cycle2/3。必须观察cycle1与追加的cycle2真实时钟进度；在cycle2清理两项前缀，绝对index/cycle保持2，再截去cycle3，最终于index2完成。观察集合必须恰为0/1/2，不能发生error；stop归idle且dispose完成才生成成功指标。
- 等待使用真实状态流与25秒上限，命令有10/20秒上限，整项2分钟；没有人工emit或固定sleep。输出仅含平台、构建时注入的40位SHA、观测索引/轮次与通过事实，不输出媒体路径/URI。明确`acousticGapMeasured=false`，不把时钟/状态当声学测量。
- `.github/workflows/foundation.yml`：新增默认false的include_sequence_audio_poc；只允许显式Android诊断且不混合HTTPS/Windows Profile选项。保留既有Android本地/content测试，再执行独立sequence测试；失败即退出。不改变默认生产入口、普通双平台构建或旧Windows探针。
- `tools/native_sequence_probe.test.mjs`：两项静态门禁检查真实后端/事件监听、生产隔离、显式选项范围、保留旧来源测试和Windows计数合同。这是源码保护，不冒充设备测试。

## 验证记录

初轮严格分析发现多余dart:async导入，已删除，未关闭lint。最终格式609文件零修改，严格分析零问题（19.5秒）；2520项普通Flutter回归通过（129秒），163项Node门禁通过（17.78秒）。独立Android探针入口编译通过（73.5秒），并不代表设备执行通过。既有226张Golden与运行时代码未修改。

诊断编译后已用lib/main.dart重建默认Android Debug（32.1秒），48项包内资源、6项音频许可与完整原生声明核验通过。最终工作流条件改为单行shell分支以兼容逐行执行器，2项新增门禁重跑通过。diff空白及待提交文件凭据模式扫描通过；不上传本地APK。

前序J11实现与双平台构建证据保留在[J11报告](https://github.com/Z-YO-YI/YYMusic/blob/codex/native-repeat-window/docs/phase_7j11_repeat_window_report.md)。本次继续更新同一Draft PR #136，不自动合并。新提交的普通CI与显式Android设备诊断须分别核对，不能引用前序通过代替。

本机adb设备列表为空，原生集成测试本地未运行。独立入口的Android编译只证明可编译，不能算设备通过；诊断编译后必须重建默认main入口，避免默认app-debug.apk残留诊断程序。最终设备结果以对应提交的显式GitHub Android运行日志为准，尚未执行时不标记J12验收完成。

## 限制与下一步

不启用生产无缝设置，不修改播放器运行时代码/数据库/UI/设计参考。NEW_ICON_SPRITE和POLISH_CSS仍沿用已审计最终合成，不使用WebView。Windows需后续隔离Profile入口、严格结果/产物身份校验及有音频端点机器实测；Android模拟器执行通过也不替代真机听感、内存或后台生命周期验收。Phase7其余缺口及Phase8–11仍保留。
