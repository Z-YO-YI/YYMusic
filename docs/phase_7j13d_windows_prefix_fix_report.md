# Phase 7J13D：Windows 删除前缀后回传真实状态

## 开始与范围

2026-09-19，Z-YO-YI/YYMusic、codex/native-repeat-window，基线3e34aa90012f60f8f3efcd64098aade8e3f732fe；Draft PR #136。J13C精确源码双平台构建和Android原生通过，Windows原样运行失败轨迹确认删除后1秒未回传原始归零，见[C报告](phase_7j13c_windows_prefix_report.md)。这是修复前真实失败证据，不重写既有循环/随机算法。

目标：保持锁定just_audio_windows0.2.3，仅在成功删除范围后、方法确认前调用既有broadcastState，读取WinRT的实际当前索引/位置/播放状态，不伪造0，不seek/pause/reload。用户无需改设备、重启或释放其他应用。按总指令§38/39及ADR150实施。

已新增仓库内最小本地插件副本（完整原发布源码与MIT许可、来源指纹/补丁说明）、完整性门禁与边界回归；修改pubspec路径及锁文件、音频许可源码解析以仅接受这一明确本地依赖，相关文档同步。所有其他包保持原锁定；不编辑Pub缓存，不拉取未锁定上游开发版本，不更换播放引擎。设计依据仍为既有基础HTML+App.tsx NEW_ICON_SPRITE/POLISH_CSS合成审计，无UI/图标变更。

风险：本地副本漂移、许可证漏打包、广播先后顺序和WinRT异步事件竞争。出口：官方发布归档匹配原锁文件SHA；副本的唯一行为差异可审计，许可和原生CMake保持字节指纹；测试仍拒绝未归零/前进/迟到/错误；本地格式/分析/全量回归后GitHub构建精确SHA并在本机原样复测同一探针。设备未通过前不得宣称修复成功，不通过则继续定位，不放宽失败判据或自动上线。

## 验证记录

官方发布归档 `https://pub.dev/api/archives/just_audio_windows-0.2.3.tar.gz` 的SHA-256为 `7d80dfa02a2189f1c26673a56f4d8584a306d3f22735302be6111e9578a40318`，与原锁文件一致。全部12份发布文件保留；`windows/player.hpp` 唯一行为差异是RemoveAt循环成功后调用一次既有broadcastState，再确认方法。另有CHANGELOG末尾补LF，逐文件重建原始字节的门禁明确扣除此差异。MIT许可与CMake指纹未变，详见[来源说明](../third_party/just_audio_windows/UPSTREAM.md)和机器清单。

本地结果：

- 80项序列后端/引擎/轨迹专项通过；新增事件先于方法确认的回归，保留同一batch/绝对entry e2、不load/play/seek。
- 全量Flutter 2580项通过（119秒，含226既有Windows Golden）；626文件格式零修改，严格analyze零问题。
- 全量Node 179项通过（22.57秒，无跳过/失败）。新源码门禁在原实现缺广播时失败，补丁后通过；既有hosted依赖断言同步改为精确本地路径/来源/锁定版本检查后全量重跑通过。
- Source音频许可校验：6份LICENSE与2份原生构建源码全部匹配，许可解析只允许此准确仓库路径，拒绝其他本地根/远程URI/查询片段/链接路径。
- 本机`flutter pub get --offline`完成解析和锁文件更新，但后续Windows插件链接步骤因宿主缺symlink权限退出1；**整条pub get不计通过**。没有修改系统设置，以上Dart验证均显式`--no-pub`；完整解析、原生编译与包内许可继续由GitHub Actions验证。

修复版实际构建和设备结果尚待本批提交后独立记录。J13C的失败不是本补丁执行结果；不将通道模拟、源码门禁或已通过的旧包构建计作新Windows实机通过。
