# Phase 4E — just_audio + Windows WinRT 备用候选报告

2026-09-05。开始前已fetch并确认
`feat/native-audio-content-network-poc@3da2f618ea6de79ece0c885c9bc7a435b509b24f`
与远端同步；从该提交创建`feat/just-audio-native-poc`，未在main/master开发。范围与出口见
[计划](phase_4e_just_audio_candidate_plan.md)，依赖证据见
[许可证清单](phase_4e_dependency_license_inventory.md)。

## 已实现边界

本批精确锁定`just_audio 0.10.6`与`just_audio_windows 0.2.3`。只有
`lib/playback/just_audio_backend.dart`导入插件；它把playing、processing、position、duration、buffered、
volume和speed压成项目快照，并直接丢弃原始插件错误。`JustAudioEngine`只依赖该快照与现有
`AudioEngine`合同，映射Windows file URI、Android content URI及HTTPS瞬时来源，不自动播放。

Header能力由backend显式声明：Android直接Header和任何代理策略在native验证前都不会被默认启用；
Windows实现未声明直接Header能力时，带Header来源在插件调用前产生固定脱敏
`audio.just-audio.open`失败。候选不把URL、query、Header或插件异常写入状态、日志、数据库或Fixture。

命令继续串行，非法Seek/音量/速率先拒绝；dispose等待已接收操作、拒绝新操作并且只释放一次。
生产`main.dart`、AppBootstrap、DependencyGraph、Shell和UI均未创建这个候选，默认仍使用
`UnavailableAudioEngine`。没有WebView、缓存、下载、离线保存或Schema变更。

## 本地验证

| 检查 | 结果 |
| --- | --- |
| 候选定向测试 | 7项通过：三类来源且load不自动播放、状态/命令、未知时长与归一化、命令/异步错误脱敏、Header不支持时失败关闭、并发幂等释放、非法输入 |
| 全量门禁 | 152份Dart文件format零变化；严格analyze 0问题；完整232项Flutter含32张Windows宿主Golden、31项Node、24项ZIP全部通过 |
| 依赖 | `dart pub get --enforce-lockfile`成功；六个新增解析包和许可指纹已记录。`flutter pub get`完成下载/解析后仅因本机Developer Mode关闭而不能创建Windows plugin symlink |
| Android Debug | 本机构建成功；279,085,047字节，SHA-256 `bba16856f7cdbc3c909172cafa75ee07c345067cb50f66dcc6cfe21e9adbf601` |
| APK核验 | 包名/YYMusic/SDK24→36；48份字体/许可证/SVG资产存在且设计参考为0；v2单Android Debug签名有效；无存储/媒体/麦克风/通知权限 |
| 原生内容 | 三种Flutter目标ABI仍包含media_kit的libmpv/helper及既有Flutter/SQLite库；没有just_audio专属SO。Android实际解析Media3 1.4.1 |
| Windows本机 | 未构建：远程会话无法开启Developer Mode/创建plugin symlink；不把手工登记文件或Android成功当作Windows编译证据 |

首次Android构建暴露Pub缓存位于C:、工作树位于D:时Kotlin增量缓存无法计算相对根路径；项目只增加
`kotlin.incremental=false`，随后同一Debug构建成功。该设置牺牲增量编译速度，不改变产物功能。

首次push运行33936060829的Windows构建在MSVC 14.51编译C++/WinRT兼容头时失败：新版STL把旧
`experimental/coroutine`提示升级为`STL1011`静态断言。修复只对`just_audio_windows_plugin`目标声明
`_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS`，不降低全项目警告级别、不修改Pub缓存源码；
修复提交的Windows结果必须重新取得，失败运行不计作通过。

## 尚待GitHub证据

实现提交、Draft PR及目标SHA的checks/Android Debug/Windows Debug运行将在推送后补记。本批不会触发
`workflow_dispatch`，不会创建Release或可下载候选APK。标准push可能按既有工作流保存Windows portable
artifact；它只用于Debug审查，不是发行包。

Phase4E只有在目标实现SHA的标准三job全部成功且无新Release后才关闭。即使关闭也只代表备用适配与
打包可行；真实解码/控制链进入Phase4F，实体设备输出、后台/焦点/系统媒体会话和最终许可证展示仍未验收。

## 主要文件

- `lib/playback/just_audio_backend.dart`
- `lib/playback/just_audio_engine.dart`
- `test/unit/just_audio_engine_test.dart`
- `pubspec.yaml`
- `pubspec.lock`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugins.cmake`
- `android/gradle.properties`
- `tools/foundation_architecture.test.mjs`
