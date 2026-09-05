# Phase 4G — media_kit 原生分发清单

2026-09-05。清单以当前`pubspec.lock`、包内构建脚本、上游固定release/tag/commit、实际Android Debug
APK和GitHub Windows Debug bundle为证据；详细字段及全部SHA-256见
[`docs/legal/media_kit/manifest.json`](legal/media_kit/manifest.json)。本文件不构成法律意见，也不表示
候选二进制已获发布许可。

## 直接相关 Flutter 包

| 包 | 锁定版本 | 包许可证 | LICENSE SHA-256 | 构建脚本 SHA-256 |
| --- | --- | --- | --- | --- |
| `media_kit` | 1.2.6 | MIT | `2e3000…a331` | — |
| `media_kit_libs_audio` | 1.0.7 | MIT | `2e3000…a331` | — |
| `media_kit_libs_android_audio` | 1.3.8 | MIT | `2e3000…a331` | `67c64a…c58b` |
| `media_kit_libs_windows_audio` | 1.0.9 | MIT | `a78baa…f2bd` | `4e2174…90f6` |

这些MIT文本只覆盖wrapper/package源码，不能替代JAR、SO或DLL中传递组件的许可证和对应源码义务。

## Android 产物与来源链

包脚本从`libmpv-android-audio-build v1.1.8`下载四个JAR并只校验MD5。本次同时用GitHub release API
给出的SHA-256和本机下载字节复核，四项全部一致：

| JAR | 字节 | SHA-256 | native内容 |
| --- | ---: | --- | --- |
| `default-arm64-v8a.jar` | 2,983,585 | `0481a64b…8bb09` | helper 386,696 / `64025bd7…fa3d`；mpv 6,215,848 / `328ca0ed…b9ee` |
| `default-armeabi-v7a.jar` | 2,865,617 | `1bba852f…ceae9` | helper 286,812 / `290d8aba…95bf`；mpv 5,648,496 / `e42cd8fd…9203` |
| `default-x86.jar` | 3,040,597 | `824deeee…e8b7` | helper 350,252 / `5109232d…38bf`；mpv 6,334,772 / `298292e0…d37d` |
| `default-x86_64.jar` | 3,114,935 | `ddffa046…7106` | helper 367,528 / `8faa3327…77a2`；mpv 6,983,648 / `98456a27…6ad1` |

每个JAR只有上述两个SO，没有LICENSE、NOTICE、源码清单或重新链接材料。当前Android Debug APK
`bba16856…f601`只打包arm64-v8a、armeabi-v7a、x86_64；六个SO的字节数和SHA-256逐项等于对应
JAR entry，x86 JAR已下载但不在本APK中。

构建tag `87744be8b337c50ed54961249b7a97c5e8cc37c9`固定mpv 0.35.1、FFmpeg 6.0、Mbed TLS 3.6.1
和libxml2 2.10.3。SO内嵌的真实FFmpeg参数含`--disable-gpl --disable-nonfree --enable-version3`，
各libav模块报告`LGPL version 3 or later`；mpv内嵌参数为`--enable-lgpl`。这能排除“实际包仍启用GPL/
nonfree”的猜测，但不能替代完整分发材料。

Android仍有一个不可忽略的映射缺口：release脚本从可变`main`克隆
`media-kit-android-helper`。按release时间及仓库历史，唯一可界定的候选是
`42054e5d479f39ccbb0ae604862e2bcaf59b74c2`，但这是时间推断，不是构建输入中的固定commit，因此
清单状态只能是`partial`。

## Windows 产物与来源链

`media_kit_libs_windows_audio 1.0.9`固定下载
`mpv-dev-x86_64-20230924-git-652a1dd.7z`。包脚本MD5为`cd738e…f8c`；本次实际下载得到
5,392,413字节、SHA-256 `583af5a2…eb6a8`。归档只有四个mpv头文件、`libmpv.dll.a`和
`libmpv-2.dll`，没有许可证、NOTICE、源码/patch清单、构建日志或可重新链接对象。

归档内DLL为15,525,902字节、SHA-256 `0a5a0b47…164a4`，与Phase4C提交`622408e`的GitHub
Windows Debug bundle中DLL逐字节一致。release名和说明把mpv映射到
`652a1dd90711839acdccc08004056d25514ef2d8`。

DLL内嵌的真实FFmpeg参数同样关闭GPL/nonfree、启用version3和静态库，各libav模块报告LGPLv3+；
mpv内嵌`-Dgpl=false -Dprefer_static=True`。可见组件至少包括FFmpeg 6.0、libarchive 3.7.3dev、
libjpeg-turbo 3.0.1，以及版本未能精确映射的Mbed TLS、libjxl及静态依赖、mujs、libass、lcms2、
OpenAL Soft、uchardet、zimg、zlib和libarchive静态依赖。

关键阻断不是“DLL是否声明LGPL”，而是“该DLL如何产生”。release前最近的公开构建仓库提交
`f5a6f879c9b8bef6a73e52c8c0f35e51636c96e5`中，FFmpeg脚本仍写着`--enable-gpl`和
`--enable-nonfree`，与DLL字节内配置相反；对应workflow允许`workflow_dispatch`传入任意预构建命令，
并恢复源码/构建cache。2023-09-24的Actions运行记录现已不可取回，所以无法证明当时使用的完整命令、
patch、浮动仓库commit和cache内容。2024年出现的近似audio脚本晚于release且配置仍有差异，不能倒推为
本二进制的对应源码。

## 分发门禁

| 要求 | Android | Windows |
| --- | --- | --- |
| 下载产物强哈希 | 已核对 | 已核对 |
| 实际应用native字节映射 | 三ABI已核对 | DLL已核对 |
| GPL/nonfree实际配置 | 已由二进制排除 | 已由二进制排除 |
| 所有源码revision/patch可重建 | helper未固定 | 未记录命令、浮动依赖与cache |
| 完整逐组件LICENSE/NOTICE | 缺失 | 缺失 |
| 对应源码/重新链接交付方案 | 未批准 | 未批准 |
| 候选应用包内材料逐字节验证 | 未建立 | 未建立 |

因此两个平台都不能解除发布阻断。仓库只保存`inventory-only`机器清单，不把不完整许可集合放进
`assets/`，也不提交审计下载的JAR/SO/DLL/7z或源码归档。
