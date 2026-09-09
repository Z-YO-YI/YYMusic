# Phase 7D2 阶段报告 — 原生全屏页面与生命周期

2026-09-09；GitHub `Z-YO-YI/YYMusic`；开发分支`codex/fullscreen-page-lifecycle`；最终基线`e68fffab81a7e787f31d6a24bc6136410d4bc3af`，Stacked Draft PR base=`codex/fullscreen-maximized-restore`。
开始前已核对远程、工作区并fetch/pull同步；[计划](phase_7d2_fullscreen_pages_plan.md)及ADR080先于共享API改动，不在main/master开发。

## 本批实现

- 根FullscreenPresenter拥有唯一原生通道、当前会话和单worker；页面只提供有效路由身份，不直接调用平台API。原生事件优先于更早命令/握手的晚返回，离页与生命周期撤销未执行意图，已接受进入若晚到则恢复。
- 使用实际Navigator顶层观察器，包括imperative RawDialogRoute。播放/歌词直接切换延续当前全屏；队列和弹层覆盖恢复，弹层期间F不穿透。页面保留的旧按钮在覆盖后不能执行。
- Windows顶部按钮和F切换全屏；非输入框且无弹层时F可打开播放页并发出一次进入请求。Esc先退出全屏，再返回；页面关闭仍直接返回并恢复。标题栏隐藏但保留相同Overlay/Column/Expanded/Navigator祖先，不因全屏重建播放器或歌词状态。
- Android进播放/歌词页请求沉浸，支持按钮退出/再次进入；系统返回离页恢复。切后台、失焦、零尺寸和原生退出取消旧进入意图，恢复前台不自动重进。系统手势临时显示栏不等于丢失应用的原生会话。
- 失败显示固定安全提示及可用时的恢复按钮，不展示异常、路径或凭据，不停止音乐；失败进入最多自动恢复一次，恢复失败不忙循环。错误条有界且可滚动，窄屏/放大字体可达；失败时标题栏重新可见。
- 根关闭先撤销并等待全屏清理，再finally关闭业务图，最后由既有WindowPresenter完成原生窗口关闭。没有新的媒体时钟、后台服务、依赖、Schema或权限。

设计遵循figma-design-to-code的组件/资产复用流程：依据本地完整导出而非不存在的在线Figma节点，使用App.tsx最终NEW_ICON_SPRITE的fullscreen/fullscreen-exit、YYButton及已有字体/Token；POLISH_CSS映射与44个原始SVG不改。没有WebView、替代图标或新位图资产。

## 前置失败与隔离修正

开发中发现前置D1 `ba68cdd`的两组Windows CI在最大化退出后精确左边界断言失败（期望-7，实际0），源码/Android及138Golden成功。暂停新增页面行为，在隔离worktree/分支修正最大化恢复顺序，保留原始断言；本地页面仅做QA。

修正提交`e68fffab81a7e787f31d6a24bc6136410d4bc3af`与[Draft PR #69](https://github.com/Z-YO-YI/YYMusic/pull/69)的[push34295775225](https://github.com/Z-YO-YI/YYMusic/actions/runs/34295775225)、[PR34295846524](https://github.com/Z-YO-YI/YYMusic/actions/runs/34295846524)均SUCCESS：Windows138Golden、2项真实Runner（`restoration=true minimize=true detach=true`）、正式入口重建/65文件包成功，Android资产/许可/签名通过。成功后安全快进页面分支，未覆盖历史。完整失败和修复证据见[D1报告](phase_7d1_fullscreen_gateways_report.md)；初始#68本身仍失败，不能用修复SHA冒充原提交成功。

## 验证结果

- 新增42项Flutter：18协调器单元、16真实根Widget、8Golden；目标回归42/42通过。覆盖晚到响应/握手、事件优先、前后台和尺寸、旧回调、RawDialogRoute、F输入隔离、分层Esc、同一Player State、音频加载不增加及关闭顺序。
- 完整`flutter test --no-pub --reporter expanded`：**1287/1287通过**，约65秒；包含146张Windows宿主Golden。8张新图逐张查看，138张旧图字节不变，不放宽阈值或跳过旧测试。
- 新Golden为Windows播放1440×900、歌词1024×720、窗口态/恢复错误840×640；手机歌词390×844、短横屏播放590×360；平板横歌词1280×800、竖播放800×1280。Widget另验证Windows500×640和130%字体、Android四尺寸及旋转。错误条初版布局预留空白，修正后仅重生成该新基线并重新查看。
- 最终Node **124/124通过**，约15.7秒，已包含接回的最大化修复门禁。原关闭顺序断言随共享API改为“先fullscreen.close，finally graph.close”，后续原生关闭断言不变。原始指纹/44SVG/52确定产物和ZIP24条目、源码音频许可/完整原生法律材料通过。
- **445个Dart文件格式零修改**，严格`flutter analyze --no-pub --fatal-infos --fatal-warnings`零问题（5.9秒）。`build_runner build`成功（约13秒），`drift_dev make-migrations`成功；生成代码/Schema/lock/原始assets无差异。
- `flutter build apk --debug --no-pub`成功（24.3秒），48原始资产、六音频包和完整原生许可一致，v2签名验证成功、单签名者。APK **232,124,537 bytes**，SHA256 `87717a8dd017b7b243407cd9e3e2a49e0286fcf795a917546aa2830e0f4197ca`。仅本地预检，正式Android按GitHub新提交构建；APK和日志留在忽略的build目录。
- 本机未运行本批Flutter Windows构建；本机隔离worktree解析依赖后因开发者模式/符号链接限制退出，未改系统设置。新D2提交的GitHub Windows编译/146Golden/2项原生Runner按精确SHA另行核对，不能借前置D1成功宣称D2云端已通过。

测试基础设施明确为普通Widget/Golden模拟“没有原生通道”，实际适配器测试另设mock，真实Runner集成不走此配置。修复测试清理阶段的等待方式为有界排空并断言确实释放，避免在FakeAsync外死等；Golden画布调试标记在测试体finally恢复，未跳过框架不变量或隐藏悬挂计时器。

## GitHub与交付边界

本批实现、测试、8张基线和文档经diff与敏感候选检查后提交push，创建Stacked Draft PR；实现SHA、精确push/PR CI链接及当前状态写入对应PR。前置修复PR的成功已回填，不以旧成功替代本批结果。不自动合并、改默认分支、创建Release、触发手动音频诊断或提交构建包/用户数据。
提交候选31个文件（23个文本、8张新Golden）；文本敏感模式和所有候选路径检查零命中，`git diff --check`通过。没有凭据、环境文件、私有媒体或不必要的构建产物。

主要文件：`lib/app/fullscreen_presenter.dart`、`fullscreen_route_observer.dart`、`fullscreen_button.dart`、`yy_music_app.dart`、`window_chrome.dart`及两正式页面；新增单元/Widget/Golden和Fake/harness；更新路由、门禁、README、架构决策、状态与矩阵。

本批只完成Phase7D2页面接线，不是整个Phase7或可日常使用的发行版。Android实际系统栏/分屏/切后台、Windows多显示器/DPI与设备安装仍须单列验收；Fake和截图不代表实机系统行为或出声。
后续按主指令分批推进Phase7真实封面/收藏及独立队列，Phase8真实本地导入/扫描/授权，Phase9来源，Phase10后台/系统媒体与Phase11发行/设备验收。默认新安装为空库；Windows开发Debug依赖Debug CRT，普通Android CI尚不上传APK artifact，不以测试数量换算虚假完成百分比。
