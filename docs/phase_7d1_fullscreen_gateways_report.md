# Phase 7D1 阶段报告 — 原生全屏通道与恢复

2026-09-09；GitHub `Z-YO-YI/YYMusic`；分支 `codex/native-fullscreen-gateways`；干净基线 `0a9e6d0cee9b01e3beef26bb011247dd455bbb61`；Draft PR base=`codex/native-lyrics-route`。
开始前已核对远程、分支与工作区，fetch/pull为最新；创建独立分支，未在main/master修改。[计划](phase_7d1_fullscreen_gateways_plan.md)与ADR079先于共享合同变更。

## 本批实现

- 将尚未接线的FullscreenGateway桩扩展为异步握手、原生会话快照/事件、进入/恢复与关闭。NativeFullscreenGateway只发送无参数白名单方法，严格解析enabled，错误固定脱敏；未知平台握手返回不支持。
- 单根通道与旧Windows窗口通道独立；操作串行，关闭先撤销排队操作，等待已接受命令完成，再detach恢复并释放事件监听。命令8秒超时后仍可请求恢复；不派生周期定时器或媒体时钟。
- Windows只访问当前Runner HWND。首次进入保存完整WINDOWPLACEMENT、窗口样式及扩展样式，使用当前显示器完整矩形；重复进入不覆盖原快照，退出恢复保存值。部分原生失败保留恢复记录，detach、销毁、最小化、显示配置改变和切换窗口边框前尝试恢复。不会更改全局分辨率或接收任意窗口/坐标参数。
- Android使用已有AndroidX Insets Controller，保存状态栏/导航栏/caption的可见性、行为及旧系统UI标志。临时系统栏允许手势显示；退出、onPause、失焦、引擎解绑和销毁恢复先前记录，失败保留供下次重试。没有消费Flutter Insets监听或改动edge-to-edge、权限、依赖和全局设置。
- enabled表示本应用持有的原生全屏会话，不承诺Android临时栏或桌面caption永远不可见。Windows额外返回自身窗口和显示器的只读几何/样式，供真实集成断言使用，不开放写入参数。

本批只交付平台能力，不注入生产依赖图或YYMusicApp，不新增UI/快捷键/自动沉浸；应用仍按7C2页面行为运行。没有WebView，未改设计资产、字体、图标或POLISH_CSS映射。

## 验证结果

- 新增16项Dart通道回归：单次握手、不支持/未初始化、四类畸形响应、异常脱敏、事件生命周期、串行恢复、关闭期间握手/排队/已接受命令、超时与detach失败。最终全部通过。
- `flutter test --no-pub --reporter expanded`：**1245/1245通过**，约70秒；包含138张原有Golden，本批未更新任何基线。
- 123项Node检查全部通过，约19.9秒；新增3项通道/Windows/Android边界检查。原始5指纹、44SVG、52确定产物及ZIP全部24条目核验通过；六音频包LICENSE/两个原生构建来源及完整原生许可材料通过。
- `build_runner build`成功，约13秒；`drift_dev make-migrations`成功。生成代码/Schema/lock/原始assets/Golden零差异。437个Dart文件格式零修改；严格`flutter analyze --no-pub --fatal-infos --fatal-warnings`零问题，6.3秒。
- `flutter build apk --debug --no-pub`成功，23.3秒，包括本批Kotlin原生代码。48原始资产、六音频包与完整原生许可、v2单签名者核验通过。APK为232,104,274 bytes，SHA-256 `41305c058d23b54ae89cd81f9e20a86d46d1d16ba68393b6c41edb80cb265c2f`。仅为本地预检，APK与日志留在忽略的build目录；正式Android构建按GitHub新提交另行验证。
- 既有Windows真实Runner集成文件增加1项全屏用例，与旧1项窗口握手用例一并由默认CI执行：普通/最大化、完整显示器边界、精确位置/样式恢复、幂等进入、最小化恢复、detach与拒绝任意HWND。**本地未执行新Windows原生用例，本批云端结果尚待提交后核对**；没有把源码检查当作Win32通过。

## GitHub与交付边界

前置7C2的精确提交`0a9e6d0`已核对push34291806866和PR34291810669，源码/Android/Windows两组均SUCCESS，报告与[Draft PR #67](https://github.com/Z-YO-YI/YYMusic/pull/67)已回填。该Windows开发包仍依赖Debug CRT，不代表发行版；普通AndroidCI没有上传APK artifact。前置证据不证明本批新增Win32代码正确。

本批源码/测试/文档在完整本地回归与敏感文件检查后提交push，创建Stacked Draft PR；实现SHA与两条精确CI链接写入PR，尚未通过的状态不得记为成功。没有自动合并、创建Release、触发手动音频诊断或上传构建包/用户数据。
提交候选为19个文本文件；路径/敏感模式扫描零命中，`git diff --check`通过，没有凭据、环境文件、原始媒体或构建产物。未改动依赖锁、Schema、设计资产或截图基线。

## 未完成与下一步

下一增量接根生命周期协调器、歌词/播放页入口、Windows F与Esc先退出全屏及标题栏隐藏。Android实际系统栏动画、不同版本/分屏/切后台及Windows真实多显示器/DPI变化仍需设备验收；本批不声称真机安装、实机出声或完整端到端全屏已完成。
Phase7真实封面/收藏及独立队列管理、Phase8本地导入/扫描/授权、Phase9来源、Phase10后台与系统媒体、Phase11 Release/AAB/Windows发行和设备验收仍待后续。默认新安装为空库，不以测试数或阶段号换算“日常可用”完成百分比。
