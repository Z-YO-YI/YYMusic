# Phase 7H2B：共享原生睡眠设置面板

2026-09-13；基线1998157，fetch/ff-only pull且干净，分支codex/native-sleep-settings，Draft base codex/sleep-settings-projection。先[计划](phase_7h2b_native_sleep_plan.md)/ADR100，再组件和测试。

## 实现范围

- 共享SleepSettingsPanel借现有PlaybackPresenter，不创建播放器、业务控制器、Timer、数据库或平台访问。五选项实际调用H2A一次性动作；显示真实选择/设置中/已结束/失败，取消不自动恢复播放，完成只关闭。
- 每次构建更新动作代数并订阅路由/TickerMode/Focus状态；对方页面覆盖再返回、外部许可撤销再恢复、隐藏、零尺寸、关闭和卸载均不能让旧操作重获授权。根同帧变化以安全拒绝提示处理，新构建获取新动作。
- 原生手机/短Android窗口使用YYBottomSheet，平板/Windows使用YYDialog；复用原始关闭图标、主题和既有焦点/Esc/滚动处理。新增受控YYOptionCard匹配原HTML双行卡片，键盘Enter/Space、语义selected/enabled、最小74px触控卡片和字体放大增高。
- 正文不足500宽单列，其余双列；标题与完成固定，短窗口正文滚动。不展示HTML模拟设备，也不提供没有后端行为的假开关。
- **本批是共享面板验收，尚未在生产播放页/歌词/底栏/Inspector插入Overlay或绑定入口。** 宿主负责插入、遮罩、路由移除；H2C继续集成。不得将测试宿主等同生产入口或设备验收。

## 设计证据

完整读取Figma设计转代码技能；无线上节点，沿用既有本地完整导出审计，未冒称线上get_design_context成功。复核App.tsx NEW_ICON_SPRITE、POLISH_CSS30px对话框形状与HTML1328–1333/2541–2560五选项，复用YYDialog/YYBottomSheet/YYButton和主题，不用WebView或自绘替代SVG。ZIP、App、基础HTML和总指令四个SHA与Phase0一致，24解压条目逐字节通过。

新增6张基准全部逐张查看：phone、phone_dark、phone_landscape、tablet_dark、windows、windows_failure。130%字号下文字无溢出，深浅色选中/失败可辨；短手机横窗正文自然裁剪并可滚动，后续选项的ensureVisible+点击通过。截图背景来自真实主题，阴影启用；既有188张图未改，合计194，严格逐像素比较未放宽。

## 验证结果

- 新增19 Widget+6 Golden，25相关通过；完整Flutter **1838通过，98秒**。Node **145通过，33.6秒**，含新增面板依赖边界检查。
- 严格分析最初发现大括号风格问题，修正后**0问题，23.2秒**；最终**528文件格式零改动**。build_runner **20秒**、Drift迁移通过，无生成/Schema漂移。
- 首次测试清理卡在真实/模拟异步区的SDK流关闭，按项目既有closeGraph模式显式排空并断言完成，不丢弃close Future。键盘测试改为覆盖实际Scrollable额外焦点站点，仍明确断言Tab到达15分钟卡片并Enter激活、Esc只关闭一次，不跳过验收。
- Android Debug **16.3秒**，48资产、完整音频许可、v2单签名者通过。APK **232247203 bytes**，SHA256 `df884edae17c4179ecb66702f59463766c24bf7aaff66aadd2cb3d79821780cd`，与H2A一致，符合本批尚未接入生产引用链的边界。Java native-access警告保留，包不入库。
- 没有新增设备安装/出声、UI-SQLite验收或本地Windows编译；Windows组件Golden在本地Windows测试环境验证，不等同用户设备运行。当前提交双平台云端按新SHA另验。

## GitHub与下一步

前置1998157的[push34718048011](https://github.com/Z-YO-YI/YYMusic/actions/runs/34718048011)/[PR34718070381](https://github.com/Z-YO-YI/YYMusic/actions/runs/34718070381)已SUCCESS，#92回填；本批精确提交与Actions在提交后Draft信息记录。无自动合并、默认分支变更、付费服务或Release发布。

主要文件：yy_option_card.dart、sleep_settings_panel.dart、测试宿主/Widget/Golden及6基准、sleep_settings_panel.test.mjs和文档。下一步H2C实现借同一根的Overlay宿主与可撤销入口，先播放页，再歌词/底栏/Inspector；实测重复打开、路由覆盖、返回、卸载、主题/尺寸变化和焦点恢复后再更新生产Golden。输出设备和其他播放设置仍需真实能力验证，Phase7整体及Phase8–11尚未完成。
