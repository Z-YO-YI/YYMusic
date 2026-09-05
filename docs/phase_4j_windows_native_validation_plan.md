# Phase 4J — Windows 原生播放的本地诊断路径

2026-09-05。已fetch/pull，基于与GitHub同步的
`fix/playback-session-consistency@4db58997ffe16a62da204344578a5f4b7fd9c320`
创建`codex/windows-native-audio-validation`；ZIP 24个entry再次逐字节验证通过。

## 目标与已读依据

总指令第35—39节、Phase4F原生本地WAV测试/报告、ADR-035/037/038，以及当前Flutter SDK
`BuildBundleCommand`/`BundleBuilder`和IntegrationTestWidgetsFlutterBinding源码。
依据仍是完整App.tsx合成审计，不修改NEW_ICON_SPRITE、POLISH_CSS或UI。

本机已有播放端点，但无法构建C++ runner；GitHub能构建runner，却无音频输出端点。
本批把“原生编译”与“有真实设备的运行”分开，不把构建成功当作播放成功。

## 实施范围

- 从已成功的GitHub运行33949369478取得Windows Debug artifact 9964422701，只下载到Git忽略的build目录。
- ZIP必须先匹配API SHA-256，再安全检查路径、链接、重复项；保留原归档，解压到新的独立诊断目录。
- Windows runner和插件沿用上述精确提交，不编辑其EXE/DLL。本批若改变原生代码、插件注册或依赖，
  此路径即不适用，必须重新取得匹配原生包。
- 使用同一Flutter 3.47.2 SDK的`flutter build bundle --debug --target-platform=windows-x64`
  编译隔离测试入口和开发资产。替换只发生在新建的诊断副本中，不改用户正在使用的应用。
- 入口复用原来的本地WAV集成测试，不复制音频实现；设置编译期开关和精确Commit身份。
- 结果只输出成功/失败、测试数量、平台、Commit身份和已有脱敏计时。临时音频仍由测试生成并清理。
- 工具负责限定工作目录、限时运行、读取本次结果及核验；不安装驱动/软件、不修改注册表、权限或系统服务。
- 标准CI增加`codex/**`分支覆盖。原来默认关闭的原生工作流保持无artifact/Release。
  本批不新建发布模式，不上传本地诊断包，不更改生产UnavailableAudioEngine。

## 风险与出口

Dart kernel与原生Flutter运行时必须匹配；在替换前核验GitHub包中的flutter_windows.dll与本机SDK文件强哈希。
替换前后原生EXE/DLL指纹必须不变，并记录基础原生提交和测试入口提交两种身份，不能称整个诊断副本是原封GitHub包。
窗口/音频初始化或插件不兼容必须失败关闭；不注入假时钟、无头sink或跳过原来的断言。

出口：新工具及安全回归通过、原始WAV测试在真实Windows进程执行并有可复核结果、完整format/analyze/test、
GitHub双平台Debug通过、提交推送及PR。即使本地WAV成功，也只补小批A的Windows证据；
无Header HTTPS和Android content URI、后台/媒体会话、正式接线仍按后续小批验证，不进入Phase5。

官方说明：[Flutter集成测试](https://docs.flutter.dev/testing/integration-tests)、
[IntegrationTestWidgetsFlutterBinding](https://api.flutter.dev/flutter/package-integration_test_integration_test/IntegrationTestWidgetsFlutterBinding-class.html)。
拆分构建/运行是依据当前SDK源码制定的诊断方案，不声称官方完整桌面构建已在本机通过。

## 本机运行方式

使用PowerShell 7。归档SHA-256已在脚本中固定；SDK是本机Flutter 3.47.2路径。
先完成回归并提交，Prepare拒绝脏工作区和原生/依赖漂移，输出必须是checkout/build中的新目录。
以下`run-01`仅为示例，新一次诊断使用新目录，禁止覆盖旧证据：

```powershell
./tools/windows_audio_probe.ps1 -Mode ValidateArchive -ArchivePath build/github-artifacts/phase4j-4db5899/YYMusic-windows-debug.zip -FlutterRoot 'D:\Flutter sdk\flutter'
./tools/windows_audio_probe.ps1 -Mode Prepare -ArchivePath build/github-artifacts/phase4j-4db5899/YYMusic-windows-debug.zip -FlutterRoot 'D:\Flutter sdk\flutter' -OutputDirectory "$PWD/build/windows-audio-probe/run-01"
./tools/windows_audio_probe.ps1 -Mode Run -OutputDirectory "$PWD/build/windows-audio-probe/run-01"
```

Prepare保留原EXE/DLL，只重新编译隔离入口的flutter_assets，manifest记录所有运行文件SHA-256。
Run只启动该副本，核对启动前与结束后的完整清单和本次结果，210秒超时只结束自己创建的进程。
运行时会播放极短、低音量的生成测试音；不证明用户实际听感。诊断目录含manifest、结果及本机日志，
均被Git忽略，不提交/上传原生日志、WAV、ZIP或运行副本；终端仅显示白名单结果。
