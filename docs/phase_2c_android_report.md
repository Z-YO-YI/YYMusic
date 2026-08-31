# Phase 2C — 实现与本地验证报告

2026-08-31。用户要求“现在什么进度，APK要在GitHub上构建，继续开发”。先fetch/pull确认2f35cf5已同步，创建feat/android-ci-and-form-controls；本批分两次阶段提交，不在main/master开发。云端APK流程已先提交为7458a28，UI阶段提交与同步以最终交付消息为准。

## 当前实际进度

Phase0设计身份/完整App.tsx+基础HTML审计已保留；Phase1的Android基础可用，Windows原生构建仍待验收。Phase2A主题/字体/44SVG、Phase2B导航/Slider/七种Artwork已有，本次推进Phase2C输入与选择组件。整个Phase2尚未结束；数据库、真实音频、正式首页/曲库/搜索结果/歌词等尚未实现，不能称为完整音乐客户端。

## GitHub APK流程（独立阶段7458a28）

- 原工作流已有编译但没有下载产物；现在Android job在checks之后编译，依次验签、逐字节核验48份SVG/字体/许可证，再上传APK、SHA256SUMS、构建metadata。
- 输出关联完整commit/run/attempt；上传仅三文件白名单。原artifact方案因账户额度耗尽，后经用户允许改为仅手动运行创建私有草稿Release；其他任务保持只读，个人令牌不进入runner。
- 本机打包脚本默认拒绝执行；本轮没有运行flutter build apk，也没有把旧Phase2B APK上传冒充云端构建。仅以旧包只读运行资产校验脚本来验证脚本兼容性，该结果不代表新版本构建通过。
- 阶段结束时尚无可核验的云端下载；后续已恢复用户授权并确认云端Android/Windows编译通过，但artifact额度已满。新的私有草稿Release仍须按目标commit复验下载、metadata和SHA256SUMS，最新状态见[说明](github_apk_build.md)。

## Phase2C实现

1. YYToggle：46×28轨道、22圆钮、18行程、160/180ms；受控value，>=44触控，开关语义、键盘/RTL/Hover/Pressed/Focus、Disabled/Loading及ReduceMotion。白色等低对比原色保留，补外轮廓及thumb边界。
2. YYSegmentedControl：外14/内11圆角，11/650文字，elevated选中面；按钮组单选语义、Tab/Enter/Space，长标签横向滚动、焦点自动滚入可视区；重复点选当前项不重复通知，禁用项与Loading阻止动作。34px旧触控提高到44，填充可用宽度以适配Android窄窗。
3. YYSearchField：使用Flutter EditableText和平台选择手势，保留中文IME组合区、光标/选择；支持搜索提交、清空、复制/剪切/粘贴/全选菜单，整个搜索表面可触控；常规58/20、Phone52/18、15/460，130%时适度增高。独立错误live region、只读禁用/加载与低对比选择高亮。
4. YYControlAction是开关和分段共用的内部动作/语义层，不取代旧组件或更改根业务状态；SearchField不释放调用方Controller/FocusNode。剪贴板正文只由用户编辑动作访问，测试使用替身。
5. Gallery新增本页文本/筛选/加载示例，没有网络请求、搜索历史、结果Fixture或假音乐；原减少动态/透明按钮改为YYToggle并实际更新根外观。ScrollNotificationObserver协调原生文字选择与滚动。

设计依据：重新核验5份源指纹和24个ZIP entry；读取App.tsx完整相关POLISH与基础HTML669–756、1084、1153。Search字重采用App.tsx的460覆盖旧530；开关/分段继承未被覆盖的基础HTML。按Figma转代码技能复用原始SVG/字体/已有YY组件，无手绘替代图标、WebView或Material默认外观。没有远端Figma节点时不虚构设计上下文。

## 验证结果

| 检查 | 实际结果 |
| --- | --- |
| 代码格式 / 分析 | 53个Dart文件无格式差异；fatal-infos严格分析通过 |
| Flutter完整回归 | 74项通过：旧59 + CI合同1 + 新Widget11 + 新Golden3；非更新模式，无本地跳过 |
| 输入/控件 | IME composing不被改写、单次搜索提交/清空、长按选词与显式复制粘贴、只读状态/错误公告、外部状态所有权、键盘焦点可见、130%/360/600/键盘insets通过 |
| 原生Golden | 新3张390×1080/130%浅珊瑚/深翡翠/自定义白，逐张查看；原8张未改，共11张精确像素比较通过 |
| 资产/源码/CI测试 | 23项Node通过；5份指纹/44SVG/52确定性产物不变，ZIP24entry逐字节一致；原型13文件完整 |
| 依赖/平台边界 | 无新包、无权限或机器环境改动；原始参考、字体/许可证、SVG、lockfile不变；Windows runner/CI保留 |
| APK | 工作流已推送；本地未重建；远端构建/产物尚未核验，不报告为通过 |

初测发现测试Harness缺少文字选择所需Overlay，已与正式路由环境对齐；没有用禁用选择或丢弃异常解决。错误消息增加独立语义边界；输入框空白padding也可聚焦，分段键盘焦点自动可见。旧Golden未因Harness增加Overlay而变动，不放宽容差。

11张Golden在Flutter3.47.2/Windows宿主比较，Linux明确跳过这11张并运行63项非Golden测试；远程结果须另行核验。本地输入法消息测试不等于安卓真机IME/TalkBack验证；仍无网页参考截图、设备Profile或真实播放证据。

## 主要文件与下一步

新增`lib/design_system/yy_search_field.dart`、`yy_toggle.dart`、`yy_segmented_control.dart`、`src/yy_control_action.dart`；Gallery输入示例和真实外观开关；form_controls_test、form_controls_golden_test与3份PNG；更新Harness/资产检查和README/CHANGELOG/ADR/状态文档。CI阶段文件见github_apk_build.md。

下一批仍在Phase2：业务卡片/列表项、更多表单与弹层、MiniPlayer等，随后再进入Domain/数据库与音频。云端APK及PR验收需要为现有GitHub连接器授予本仓库访问；不扩大到其他仓库、不公开仓库、不改计费或Actions权限来绕过问题。
