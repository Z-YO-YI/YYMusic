# Phase 7J13E：Windows真实播放根与持久化验证

2026-09-19，仓库Z-YO-YI/YYMusic、codex/native-repeat-window、基线9b408108c6d26f3fe4328bd356f2f867e6bd2152、Draft PR #136。fetch后本地/远程一致且工作区干净；父应用4380386的双平台及Windows引擎实测已成功，父文档push35452323718/PR35452326829也已全部success。遵循[E计划](phase_7j13e_windows_root_validation_plan.md)与ADR151，不重做已完成的循环/随机或前缀修复。

范围：从Android A提取共享原生顺序根场景和指标投影，保持旧Android协议；新增Windows独立Profile入口、结果/身份门禁、默认关闭且互斥的Actions模式、归档/宿主校验和反例测试。生产lib、插件补丁、依赖、UI、设计合成参考与Golden不改。仅用生成低幅WAV和探针临时SQLite，不访问用户媒体、不改系统音频设置。

目标：真实根/插件/SQLite自然q0→q1→q0，元数据/持久化当前项一致，历史去重更新，关闭继续后自然结束无重启，关闭/重开数据库不自动播放。风险是共享提取破坏Android已验收合同、平台/产物混用、异步历史及清理被提前算成功。每项通过需有同SHA原生证据；构建、模拟协议及实际运行分开计数，声学/长时资源/后台和Phase7完整出口不在本次关闭范围。

## 实现与本地验证

- 共享`root_native_repeat_scenario.dart`的真实播放/SQLite测试主体与FixtureResolver经对比和换行归一后与原Android场景完全一致；平台由各入口固定枚举，实际平台必须匹配。旧Android输出标记、测试计数与宿主日志门禁不变。
- Windows独立`windows_root_repeat_probe.dart`只接受显式启用的Windows Profile、精确source=native SHA与不存在的结果文件。等待测试和teardown完成再写`root-native-repeat-poc-result.json`，失败不输出成功指标。
- `windows_root_repeat_result.ps1`白名单校验完整原生/根/持久化顺序、时钟、历史、停止及释放事实；错平台/身份、数组伪装字符串、缺项/错类型、跳过/多测、失败和错误声学宣称均拒绝。独立`native-root-repeat-build.json`防止混用旧单曲/HTTPS/序列包。
- Actions新增默认false的`include_windows_root_repeat_poc`，仅允许单独Windows Profile；老Android/其他Windows模式、权限、标准开发包路径不变。共享归档工具新增`-IncludeRootRepeat`，保留官方digest、SDK、路径、原样文件和运行前后清单门禁。
- 本地16专项与2586完整Flutter（144秒，含原226 Windows Golden）通过；631文件格式零改动，严格分析零问题；24设计ZIP条目与6音频许可/2原生来源指纹一致。初次格式命令误用了两个不存在的工具文件名，已按实际两份verify_root工具重跑成功，没有修改参考资产。
- 首轮完整Node 184/185通过，失败为旧CI目标选择断言仍限定两分支；已更新为新根/旧序列/旧单曲三分支及三种产物名的精确匹配，未删除旧隔离门禁。最终完整185/185通过（47.07秒），无失败/跳过。

## 可复现的云端与设备步骤

本批提交后，Windows dispatch只开启`build_windows_audio_probe`和`include_windows_root_repeat_poc`；Android回归只开启`run_just_audio_poc`、平台android和既有`include_root_repeat_poc`。其余诊断布尔项保持false。标准push/PR分别构建Android/Windows Debug；诊断Profile不是发行包。

从精确SHA的官方Actions产物读取artifact ID与digest，下载后用`tools/windows_audio_probe.ps1`的ValidateArchive及PrepareProfile，指定RuntimeMode Profile、IncludeRootRepeat、精确NativeCommit、官方ExpectedArchiveSha256及新建build子目录；随后以同组参数执行Run。不得覆盖旧结果、混用Debug/kernel或在本地重编译、替换app.so。实际结果与云端状态待该SHA执行后回填，当前不计设备通过。

本批即使全过也只关闭Windows最小顺序根与持久化出口；Windows随机根、长时资源、声学/后台、标准化与Phase8–11仍待后续，不自动合并或发布。
