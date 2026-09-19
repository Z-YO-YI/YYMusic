# Phase 7J13D：Windows 删除前缀后回传真实状态

## 开始与范围

2026-09-19，Z-YO-YI/YYMusic、codex/native-repeat-window，基线3e34aa90012f60f8f3efcd64098aade8e3f732fe；Draft PR #136。J13C精确源码双平台构建和Android原生通过，Windows原样运行失败轨迹确认删除后1秒未回传原始归零，见[C报告](phase_7j13c_windows_prefix_report.md)。这是修复前真实失败证据，不重写既有循环/随机算法。

目标：保持锁定just_audio_windows0.2.3，仅在成功删除范围后、方法确认前调用既有broadcastState，读取WinRT的实际当前索引/位置/播放状态，不伪造0，不seek/pause/reload。用户无需改设备、重启或释放其他应用。按总指令§38/39及ADR150实施。

已新增仓库内最小本地插件副本（完整原发布源码与MIT许可、来源指纹/补丁说明）、完整性门禁与边界回归；修改pubspec路径及锁文件、音频许可源码解析以仅接受这一明确本地依赖，相关文档同步。所有其他包保持原锁定；不编辑Pub缓存，不拉取未锁定上游开发版本，不更换播放引擎。设计依据仍为既有基础HTML+App.tsx NEW_ICON_SPRITE/POLISH_CSS合成审计，无UI/图标变更。

风险：本地副本漂移、许可证漏打包、广播先后顺序和WinRT异步事件竞争。出口：官方发布归档匹配原锁文件SHA；副本的唯一行为差异可审计，许可和原生CMake保持字节指纹；测试仍拒绝未归零/前进/迟到/错误；本地格式/分析/全量回归后GitHub构建精确SHA并在本机原样复测同一探针。设备未通过前不得宣称修复成功，不通过则继续定位，不放宽失败判据或自动上线。

## 验证记录

### 精确4380386：双平台构建与Windows本机实测通过

2026-09-19，修复提交 `4380386c5c229d1e82ea48e5fbdc1f6cf0d53483` 的 [push 35450858997](https://github.com/Z-YO-YI/YYMusic/actions/runs/35450858997)、[PR 35450861486](https://github.com/Z-YO-YI/YYMusic/actions/runs/35450861486)、[Windows Profile 35450881237](https://github.com/Z-YO-YI/YYMusic/actions/runs/35450881237)、[Android原生 35450882711](https://github.com/Z-YO-YI/YYMusic/actions/runs/35450882711) 四条Actions均success。云端完整`pub get --enforce-lockfile`、生成/迁移无漂移、严格分析与179 Node通过；Linux2354普通回归通过/226宿主Golden跳过，Windows另行226 Golden及3项原生窗口/关闭握手通过。Android Debug的48项资产/签名/完整音频许可与Windows65文件开发包及包内许可通过。不产生正式发布。

Android原生保留WAV/content两项通过，另有序列1项30秒通过：indices/cycles=[0,1,2]，progressMs=[302,115,100]，追加/前缀清理/截尾/释放均true，completedAtIndex=2。前缀rawIndex在4ms从2变0，6ms接受，playing保持true。模拟器-noaudio、acousticGapMeasured=false，不计真机声学证据。

Windows使用上述Profile的artifact `10586059602`，24729889字节；官方与下载ZIP SHA-256均为 `d31f56567cd88e0c9b7b315389ec12c4af5e0e2cfc951e46acee51868ef1fc88`。新隔离目录原样解包，路径、SDK运行库、source=native=4380386身份检查通过；没有本机原生构建、DLL/内核替换或系统音频改动。

本机结果：**退出0、31865ms、单项严格结果passed=true**。三轮原生indices/cycles=[0,1,2]，progressMs=[114,100,103]；appendAccepted/pruneAccepted/retainAccepted/disposed均true，completedAtIndex=2。前缀前rawIndex=2、position=103ms；**38ms收到并接受真实rawIndex=0，position=141ms、ready/playing保持不变**，droppedSamples=0。执行后运行库逐文件指纹仍一致，仅新增指定结果文件。原始日志和产物保留在忽略的 `build/native-sequence-4380386-20260919`，不提交用户设备信息或构建二进制。

与3e34aa9相同场景下“超过1秒仍为2、退出1”的失败相比，最小广播补丁已关闭该Windows前缀确认缺口；没有放宽1秒、用Dart裁剪索引或人为跳过操作。**关闭的是Windows引擎级序列状态/时钟与该故障出口，不是无缝听感、根队列/历史整合或完整Phase7。** 下一批按[Windows根验证计划](phase_7j13e_windows_root_validation_plan.md)复用已有Android场景，不重写循环/随机；声学、长时资源、后台生命周期、标准化、Phase8–11及发布仍保留。

实测后补记仅改8份文档（含下一批计划），应用、依赖和测试源码与4380386一致。提交前179 Node再次通过（22.26秒）、626文件格式零修改、严格分析零问题（21.1秒），593处本地文档链接及UTF-8检查通过。文档提交触发的普通CI另行跟踪，不用上述应用提交的成功结果冒充新文档SHA已完成构建。

以下为修复提交前的本地实现和验证记录；当时“待构建”状态已由上面的精确SHA结果补齐。

官方发布归档 `https://pub.dev/api/archives/just_audio_windows-0.2.3.tar.gz` 的SHA-256为 `7d80dfa02a2189f1c26673a56f4d8584a306d3f22735302be6111e9578a40318`，与原锁文件一致。全部12份发布文件保留；`windows/player.hpp` 唯一行为差异是RemoveAt循环成功后调用一次既有broadcastState，再确认方法。另有CHANGELOG末尾补LF，逐文件重建原始字节的门禁明确扣除此差异。MIT许可与CMake指纹未变，详见[来源说明](../third_party/just_audio_windows/UPSTREAM.md)和机器清单。

本地结果：

- 80项序列后端/引擎/轨迹专项通过；新增事件先于方法确认的回归，保留同一batch/绝对entry e2、不load/play/seek。
- 全量Flutter 2580项通过（119秒，含226既有Windows Golden）；626文件格式零修改，严格analyze零问题。
- 全量Node 179项通过（22.57秒，无跳过/失败）。新源码门禁在原实现缺广播时失败，补丁后通过；既有hosted依赖断言同步改为精确本地路径/来源/锁定版本检查后全量重跑通过。
- Source音频许可校验：6份LICENSE与2份原生构建源码全部匹配，许可解析只允许此准确仓库路径，拒绝其他本地根/远程URI/查询片段/链接路径。
- 本机`flutter pub get --offline`完成解析和锁文件更新，但后续Windows插件链接步骤因宿主缺symlink权限退出1；**整条pub get不计通过**。没有修改系统设置，以上Dart验证均显式`--no-pub`；完整解析、原生编译与包内许可继续由GitHub Actions验证。

提交时修复版实际构建和设备结果尚待独立记录，现已在文首补齐。J13C的失败不是本补丁执行结果；不将通道模拟、源码门禁或已通过的旧包构建计作新Windows实机通过。
