# Phase 7J12B：独立 Windows 原生序列诊断

## 基线、目标与范围

2026-09-19，仓库 Z-YO-YI/YYMusic，沿用 codex/native-repeat-window，基线 bd0c374。先 fetch 核对工作区干净且与远程一致；此前 workflow 权限问题已通过用户明确授权的设备流程解决，bd0c374 已推送，同一 Draft PR #136 保持未合并。

按[J12计划](phase_7j12_native_sequence_probe_plan.md)继续 Windows Profile 入口及严格结果验证。读取总指令、阶段记录、现有序列/单源探针和工具；不重新实现循环、随机或前缀清理，不改变生产 UI、音频逻辑、数据库、依赖或设计参考。NEW_ICON_SPRITE/POLISH_CSS 的原有合成与指纹保持不变，不使用 WebView。

## 实现与风险控制

- 独立 `integration_test/windows_sequence_probe.dart` 只接受 Windows Profile、显式开关及相同的 40 位 source/native SHA；拒绝覆盖已有结果。运行 J12A 的真实序列测试，在全部测试及 teardown 完成后输出独立 `native-sequence-poc-result.json`，超时/运行器失败使用固定诊断 ID，不保存插件原文。
- `support/native_sequence_probe_result.dart` 要求恰有一项成功测试、精确源码身份、索引和轮次恰为 0/1/2、每项实际时钟进度 100–10000ms、追加/清理/截尾/结束/关闭均完成。只投影白名单，不回传未知字段；仍明确 `acousticGapMeasured=false`。
- 原有序列测试增加三个 `waitFor` 返回状态的真实 `progressMs`，不是人工计时/emit。旧 Windows 单源/HTTPS 入口与 1/2 项测试合同不修改。
- 显式 Windows Profile 模式可单独选择 `include_sequence_audio_poc=true`，与 HTTPS、Android 模式互斥。默认 false，独立 artifact 名称、purpose 与结果文件，不能把旧 WAV/HTTPS/Debug 包当作序列诊断包。
- 复用原有 ZIP 路径、SHA256、SDK 引擎、原生清单、AOT/Debug CRT、全文件哈希、真实音频端点及服务检查。新的 `tools/native_sequence_result.ps1` 在进程退出码为零后再次验证 JSON 类型/身份/进度/生命周期；不调整系统设置，只运行专用子进程，超时只终止该子进程。

风险仍是实际插件事件顺序、Windows 音频端点与 CI 环境。代码/静态门禁通过并非设备运行通过；声音连续性、原生内存和生命周期继续单独验收。

## 使用方式

只使用对应提交的 GitHub Actions Profile 诊断产物；以下操作不发布应用，不修改已安装程序：

```powershell
gh workflow run foundation.yml --repo Z-YO-YI/YYMusic --ref codex/native-repeat-window -f run_just_audio_poc=false -f build_windows_audio_probe=true -f include_https_audio_poc=false -f include_sequence_audio_poc=true
```

下载并核对该次运行的 `YYMusic-windows-sequence-probe-<SHA>` 归档后，向 `tools/windows_audio_probe.ps1` 提供 `-RuntimeMode Profile -IncludeSequence -NativeCommit <完整SHA>` 和精确归档 SHA256。先 `-Mode ValidateArchive`，再 `-Mode PrepareProfile` 到 checkout/build 下全新目录，最后 `-Mode Run` 指向同一目录；每次重跑使用新目录，不覆盖旧证据。不能使用旧 Debug 默认指纹，不能将本次探针作为用户应用发布。

## 验证记录

新增 Dart 结果合同 6 项，与旧合同共 12 项专项通过；严格分析零问题（10秒），612 个 Dart 文件格式检查零修改。全量 Flutter 2526 项通过（131秒），Node 工具门禁 168 项通过（43.58秒、无跳过）。新增静态门禁初次有产品名大小写笔误，修正后通过；没有关闭或放宽旧测试。

默认 `lib/main.dart` Android Debug 构建通过（32.3秒），48项包内资产、6项音频许可和完整原生声明核验通过；保留既有Java/SDK工具版本警告。不上传本地APK，不把默认包替换成诊断入口。生产lib/平台源码/依赖/参考素材及226张Golden未改；差异空白和待提交文件凭据模式扫描通过。

J12A 的 bd0c374 显式 [Android运行35412218776](https://github.com/Z-YO-YI/YYMusic/actions/runs/35412218776) 已success：先保留原有local/content两项成功，再执行独立序列1项成功（31秒）。日志中sourceCommit精确匹配bd0c374，platform=android，observedIndices/observedCycles均为[0,1,2]，append/prune/retain/disposed=true，completedAtIndex=2，acousticGapMeasured=false。这是模拟器原生执行证据，不是真机听感。Linux普通回归2294通过、226个固定Windows宿主Golden跳过，不能把它单独称为2520全部执行。

父提交普通 push 35412215872、PR 35412218036 的Android构建已成功，Windows仍在核验；新 J12B 提交必须另行构建，不能使用父提交结果替代。只读检查本机Audiosrv/AudioEndpointBuilder均Running、活跃输出端点2个且Profile SDK运行库存在，但新Windows序列探针尚未执行。平台构建与设备结果在完成后补记，未完成前不记为成功。

## 限制与下一步

Phase 7 整体、生产无缝设置、音量标准化、真机听感/生命周期和 Phase 8–11 尚未完成。本批新增的是可执行验证路径，不是正式上线或新音乐导入功能。下一步取得新 SHA 的 Windows Profile 产物，在实际音频端点机器运行，并核对 Android 序列结果；失败必须优先处理，不放宽生产安全检查来迎合探针。
