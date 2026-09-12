# Phase 7H2A：睡眠设置投影与快照动作保护

2026-09-13；基线bac9405，fetch/ff-only pull且干净，独立分支codex/sleep-settings-projection，Draft base codex/sleep-current-entry。前置H1B双CI开发开始时仍运行。

读取Figma设计转代码技能后，无线上节点可调用，按现有本地导出路径检查App.tsx的NEW_ICON_SPRITE、完整POLISH_CSS及HTML optionsOverlay2551–2556：关闭、15/30/60分钟、本曲结束需要真实选中状态。技能要求复用现有组件；已有YYDialog/YYBottomSheet处理原生焦点/Esc，后续界面复用，不搬入HTML模拟设备列表。

接界面前发现分钟截止意图没有保留原选项，不能用剩余时间猜选中卡片；根同步本曲设置也未对UI旧快照提供动作校验。本批先ADR099，根投影保留选中时长、共用本曲可用性判定；扩展现有根PlaybackPresenter借用睡眠状态和创建可撤销的一次性动作，捕获播放及睡眠快照，UI许可须在执行前检查。旧快照、重复执行、页面撤销、根/Presenter关闭都不能更改当前设置。无新播放器、定时器、依赖、存储或Widget。

测试覆盖真实投影/三分钟选项、无源可取消但不能启用、加载/完成本曲不可用、成功/拒绝/安全失败、旧播放/睡眠快照、同步重入许可、一次性、关闭。全量回归、生成和Android预检后push/Draft，H2B再实现共享原生弹层和视觉验收；本批不宣称已经有用户界面。
