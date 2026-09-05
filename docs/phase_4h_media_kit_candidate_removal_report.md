# Phase 4H — 移除被拒绝的 media_kit 活动候选报告

2026-09-05。基于已同步远端的
`feat/media-kit-license-closure@ad1774c95c1760fabb23488f61be9f352fad5674`创建
`refactor/remove-media-kit-candidate`，未在main/master开发。计划提交为`ccfadd6`，实现提交为
`629ef1491d3735028648dc65a7355f07494f48e8`；`0b18a94`补齐refactor/docs分支的push CI覆盖，
`2ec37ef`把Windows portable bundle的候选排除检查放在上传前执行。

## 结果

Phase4G的失败关闭已经落实为当前工程状态。`media_kit 1.2.6`与
`media_kit_libs_audio 1.0.7`两个直接依赖，以及archive、image、五个平台native wrapper、posix、
safe_local_storage、universal_platform和uri_parser共11个专用传递包均已从lockfile移除。
`just_audio 0.10.6`、`just_audio_windows 0.2.3`及其共享依赖不变。

活动工程同时删除：

- `MediaKitAudioEngine`和插件backend两个适配文件；
- 5项候选Fake单元测试、原生本地WAV与来源两个历史集成测试；
- `run_native_audio_poc`、`run_native_audio_source_poc`输入及四个media_kit专用Windows/Android job；
- Windows生成插件注册中的media_kit插件。

Phase4B—4D旧实现和POC可由Git历史复核，Phase4G报告、JAR/SO/DLL指纹与阻断清单继续保留。
机器manifest现在固定`status=blocked`、`decision=rejected`和`activeDependency=false`；审计器要求历史证据
完整，同时拒绝依赖、活动文件、生成注册、CI入口或生产接线回流。生产`DependencyGraph`仍创建
`UnavailableAudioEngine`，没有把just_audio提前选为正式backend。

## Android干净打包证据

第一次增量构建准确暴露了忽略目录中陈旧的Android生成注册；清除该派生注册后编译通过。随后执行项目内
Gradle `clean`消除增量APK的旧ZIP空洞，再从当前依赖图干净构建。最终
`build/app/outputs/flutter-apk/app-debug.apk`结果：

| 项目 | 结果 |
| --- | --- |
| 字节数 | 194,098,216 |
| SHA-256 | `4f36802c6807371c383d91e9a69d320ada0f0857caa4da45f1637ba005241e69` |
| Phase4G候选基线 | 279,085,047字节 |
| 减少 | 84,986,831字节（约30.45%） |
| native entry | 10项；`libmpv.so`、`libmediakitandroidhelper.so`与media_kit路径均为0 |
| 资源边界 | 48项SVG/字体/许可证逐字节匹配；参考源、私有/凭据文件为0 |
| 签名 | apksigner通过；v2，单一Android Debug证书 |

APK排除逻辑已进入`tools/verify_android_apk.ps1`和架构回归，不依赖人工查看。体积下降只证明候选已退出
当前包，不证明正式音频、实体设备体验或Phase4出口完成。

## 本地验证

| 门禁 | 结果 |
| --- | --- |
| Node | 35/35通过 |
| Flutter | 227/227通过；相较Phase4G只减少已删除候选的5项Fake测试 |
| Dart format | 152文件，0变化 |
| 严格analyze | 0问题 |
| build_runner / Drift | 生成成功，`app_database.g.dart`与`drift_schemas/`零差异 |
| 原始设计ZIP | 24/24逐字节一致 |
| Android Debug | 干净构建、资源/原生库/签名门禁通过 |
| Windows Debug本机 | 未完成：系统Developer Mode关闭，Flutter无法创建插件symlink |

本机Windows限制不以Android或旧bundle替代；目标提交必须由GitHub Windows 2025干净构建。工作流现于
上传前运行`tools/verify_windows_bundle.ps1`，要求完整可执行/Flutter资产存在，并检查portable bundle中
`libmpv-2.dll`、media_kit插件DLL和目录痕迹为0。

## GitHub目标提交证据

目标提交`2ec37ef02a37254d290cb084d200d5f4eacaf0c2`的
[push运行33946021637](https://github.com/Z-YO-YI/YYMusic/actions/runs/33946021637)与
[PR运行33946023102](https://github.com/Z-YO-YI/YYMusic/actions/runs/33946023102)均完成checks、
Windows Debug和Android Debug三项成功；just_audio专用手动作业按预期skipped。PR artifact为0，匹配该
提交的新Release为0。

push产生一个14天Windows审查artifact：ID `9963448349`，名称
`YYMusic-windows-debug-2ec37ef02a37254d290cb084d200d5f4eacaf0c2`，API大小66,407,581字节，
到期时间2026-09-19。下载ZIP的SHA-256
`e2e0acff719ec63a84861db2bc7582ff25c86bbd65c04f72ca414fa4caecc4826`与GitHub digest一致；独立读取
64个文件后，`yymusic.exe`、`flutter_windows.dll`、`data/flutter_assets/AssetManifest.bin`均存在，
`libmpv-2.dll`、media_kit插件/目录条目均为0。该结果同时验证新增上传前脚本确实在干净runner通过。

## CI与发布边界

工作流现覆盖`feat/**`、`fix/**`、`refactor/**`和`docs/**`的push，防止合规分支漏掉Windows artifact。
标准push/PR运行checks、Windows Debug与Android Debug；PR不上传artifact，普通push只上传14天Windows
portable bundle。Android Release步骤仅workflow_dispatch可运行，本批不触发手动运行，不创建Release。

Phase4保持未关闭：just_audio Android真实本地WAV已通过，Windows仍缺真实播放端点。后续不得在没有该
端点证据时接生产，也不得增加WebView、下载、缓存、离线保存、新权限或第三方真实来源。
