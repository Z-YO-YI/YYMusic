# Phase 7H2B：共享原生睡眠设置面板

2026-09-13；基线1998157，fetch/ff-only pull且干净，分支codex/native-sleep-settings，Draft base codex/sleep-settings-projection。H2A双CI开发开始仍运行。

先ADR100，再复用YYDialog/YYBottomSheet、YYButton、YYTheme/Token和原始关闭图标，实现共享SleepSettingsPanel。Figma技能已完整读取；没有线上节点，沿用本地完整导出审计，核对App.tsx NEW_ICON_SPRITE、POLISH_CSS的30px对话框圆角，以及HTML1328–1333的选项卡和2541–2560的五个睡眠选项。不照搬HTML模拟设备。

现有组件无匹配的双行选项卡，新增YYOptionCard作为纯受控原语：74px最小高度、13px内边距、16px圆角、10px间隔、11/9px字体及原生键盘/语义选中；字体放大时允许增高。手机/短Android窗口用底部面板，平板/Windows对话框；窄布局单列，宽布局双列，正文复用可滚动容器。

面板借PlaybackPresenter，不拥有计时器或持久化。每次构建获取最新一次性动作；旧构建、页面许可、隐藏/遮罩、零尺寸、关闭/卸载撤销。显示真实off/armed/pausing/expired/failed，不伪造逐秒倒计时或声称已经暂停空库；选择立即生效，完成只关闭，取消不自动重播。

本批先验证可复用面板及原语（Widget、键盘/关闭/过期动作、三布局/深浅色/130%/短窗Golden），生产播放/歌词/底栏/Inspector入口在H2C分批接入，不声称本批已有正式入口。全量检查、构建和敏感扫描后提交push/Draft，188旧Golden不得无关修改。
