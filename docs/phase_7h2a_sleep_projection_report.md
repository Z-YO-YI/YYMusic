# Phase 7H2A：睡眠设置投影与动作保护

2026-09-13，基线bac9405；fetch/ff-only pull且干净后创建codex/sleep-settings-projection，Draft base codex/sleep-current-entry。先[计划](phase_7h2a_sleep_projection_plan.md)与ADR099，再接口和测试。

## 本批范围调整与实现

原计划开始原生设置界面；读取Figma设计转代码技能、App.tsx的替换图标/完整POLISH_CSS、HTML optionsOverlay和现有YYDialog/YYBottomSheet后，发现两个UI前置缺口：根只存截止时间，不能准确显示原选中分钟；旧弹层回调也不能直接调用“设置当前曲终”而误指向新歌曲。因此本批独立补投影和动作接口，**没有Widget、新入口或Golden更新**。无线上Figma节点，未调用或冒称线上get_design_context成功；继续已审计本地导出流程，模拟音频设备不得照搬。

- armed分钟状态记录原PlaybackSleepDuration；非armed不显示活动分钟选中。本曲可用性与根设置方法共用同一判定，UI不复制引擎加载/准确条目规则。
- 现有PlaybackPresenter借根sleepState和选择映射；新增五个选项与accepted/rejected/failed结果，未增加控制器、播放器、Timer、存储、依赖或平台协议。
- 动作捕获播放/睡眠快照对象及通知版本；执行前后校验页面许可与根/Presenter生命周期。消费在外部许可和根通知前，重复或递归执行明确拒绝。许可抛错安全拒绝；根错误返回安全failed，原始异常不暴露。
- 先失败复现const off在关闭/重复取消时对象身份不变：增加根isClosed及Presenter通知版本，旧关闭状态不能绕过保护。任意播放通知会撤销旧动作，后续UI从最新构建获取新动作，不缓存旧闭包。

## 验证

20新增Flutter测试，67相关通过；完整Flutter **1813通过，101秒**。Node **144通过，18.9秒**（新增1），188旧Golden不变。静态分析发现一处大括号风格问题，修正后严格分析**0问题，8.1秒**；最终**523文件格式零改动**。

原无Timer门禁误将PlaybackSleepTimerState名称视为独立定时器；改为精确禁止Timer标识符，扩大检查到新part文件，并新增Timer构造、periodic、new tear-off及变量类型的断言，未关闭架构检查。build_runner **32秒**和Drift迁移通过，无生成/Schema Git差异；ZIP24条目和原音频许可/原生源指纹通过。

Android Debug **17.9秒**通过，48资产、完整音频许可及v2单签名者通过。APK **232247203 bytes**，SHA256 `df884edae17c4179ecb66702f59463766c24bf7aaff66aadd2cb3d79821780cd`。Java native-access警告保留，构建产物不入Git。无新增实机安装/出声、UI-SQLite或本地Windows构建。

## 同步与下一步

前置bac9405的[push34716728571](https://github.com/Z-YO-YI/YYMusic/actions/runs/34716728571)/[PR34716743445](https://github.com/Z-YO-YI/YYMusic/actions/runs/34716743445)已SUCCESS；本批精确SHA和云端运行在提交后PR信息单独记录，不以本地成功代替双平台云端通过。保持Draft，不自动合并、修改默认分支或发布Release。

主要文件：playback_presenter.dart、playback_sleep_action.dart、playback_sleep_projection.dart、根sleep状态/能力、投影单元测试及foundation_architecture.test.mjs。下一步H2B复用已审计YYDialog/YYBottomSheet做共享原生睡眠设置，必须实时借根投影、每次构建新动作、页面/弹层许可及关闭焦点恢复，随后分批接播放/歌词/底栏/Inspector入口和三布局Golden。设备列表/无缝/标准化等仍按真实能力矩阵单独实现；Phase7整体及Phase8–11未完成。
