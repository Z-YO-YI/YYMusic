# Phase 4E — just_audio 候选依赖与许可证清单

2026-09-05。该清单记录本次锁文件、本机Pub缓存和Android解析得到的工程事实，不构成法律意见，
也不表示已经允许发布候选二进制。

## Dart / Flutter 包

| 包 | 锁定版本 | 作用 | 包内许可证文件 SHA-256 |
| --- | --- | --- | --- |
| `just_audio` | 0.10.6 | 跨平台播放器API与Android实现 | `63ce4443e916b27424700d7fe970003add9f54944daf732f2dbcc1d8caf1bbad` |
| `just_audio_windows` | 0.2.3 | Windows WinRT实现 | `5ce607ae5defa5246b2886d696c1b495e8c099fd728421c8ac1bc627b0105d4d` |
| `just_audio_platform_interface` | 4.6.0 | 平台合同 | `2568490c678ba27cc8a405238637c4ba76adc632232f05dc1c36cbf59381dba4` |
| `just_audio_web` | 0.4.16 | `just_audio`传递平台包，生产目标不使用Web | `2568490c678ba27cc8a405238637c4ba76adc632232f05dc1c36cbf59381dba4` |
| `audio_session` | 0.2.4 | Android音频会话传递插件 | `2568490c678ba27cc8a405238637c4ba76adc632232f05dc1c36cbf59381dba4` |
| `rxdart` | 0.28.0 | 状态流传递依赖 | `c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4` |

前五个包的主许可为MIT；`rxdart`为Apache-2.0。`just_audio`的12,644字节LICENSE同时包含
项目MIT文本与ExoPlayer的Apache-2.0全文，因此发行清单不能只写“MIT”。其他四份相同MIT文本均为
1,097字节，`just_audio_windows`的MIT文本为1,099字节，`rxdart`的Apache-2.0文本为11,357字节。

## Android 原生依赖事实

`just_audio 0.10.6`的`android/build.gradle.kts`为1,952字节，SHA-256为
`e568ec02f8bdffabfeba525df3acea4959e07212195591285b1e3fda500cc2c2`。脚本固定
AndroidX Media3 1.4.1；本机`debugRuntimeClasspath`实际解析`media3-exoplayer`、DASH、HLS、
SmoothStreaming及其common/container/datasource/decoder/database/extractor 1.4.1。

本次Android Debug APK没有出现just_audio专属`.so`；其原生播放实现通过Media3/AAR提供。APK仍包含
上一候选引入的三ABI `libmpv.so`、`libmediakitandroidhelper.so`，不能把“just_audio没有新增SO”误写成
“当前APK不含media_kit原生库”。新增合并权限为`ACCESS_NETWORK_STATE`；现有`INTERNET`和生成的
not-exported receiver权限保留，没有存储、媒体库、麦克风、通知或下载权限。

## Windows 原生依赖事实

`just_audio_windows 0.2.3`的`windows/CMakeLists.txt`为2,063字节，SHA-256为
`931796ade3a2a04e40d91e82b4006e783a25e9d214f6e076a1aed5a371cc2643`。它构建一个
`just_audio_windows_plugin`并链接Flutter/plugin wrapper，`just_audio_windows_bundled_libraries`为空；
播放由Windows Runtime MediaPlayer提供。包能力表没有声明直接请求Header支持，因此YYMusic候选要求
创建方显式声明Header能力；未声明时认证Header会在插件调用前失败关闭，不能静默丢弃。

本机因Windows Developer Mode关闭，`flutter pub get`在完成下载/解析后无法创建plugin symlink；
`dart pub get --enforce-lockfile`已成功。Windows编译只能由目标提交的GitHub Windows runner给出证据，
在该证据取得前不能声称Windows Debug已经通过。

## 发布边界

本批不启用`LockCachingAudioSource`、`StreamAudioSource`或清理缓存API，不实现下载/离线保存，也不接
生产入口。即使双平台Debug编译成功，仍需在Phase4F运行本地WAV、无Header HTTPS、Android content URI，
再决定Android直接Header与Windows认证来源策略；同时补齐最终应用的第三方NOTICE/许可展示方案。
