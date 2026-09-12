# Phase 7H2C1：正式播放页睡眠设置入口

2026-09-13；基线d039bb0，fetch/ff-only pull且干净，分支codex/player-sleep-settings，Draft base codex/native-sleep-settings。先ADR101，再正式入口和路由集成。

完整读取Figma设计转代码技能，无线上节点，继续本地导出审计；基础HTML nowOverlay header使用原i-more打开播放设置，App.tsx替换sprite和POLISH_CSS优先。PlayerScreen复用YYButton/YYGlyph.more加可选入口，真实AppRouter传入根modal动作；孤立未接入预览保留默认空回调。

AppRouter唯一拥有RawDialogRoute与打开状态，借现有PlaybackPresenter和H2B面板；重复点击拒绝。面板只在拥有者/player路径及自身当前route有效时操作；离开拥有者或router关闭同步撤销，帧后按准确route实例移除，绝不无条件pop别人的页面。显式返回先关闭当前设置，遮罩/完成/Esc均不取消根睡眠意图；继承应用主题、字号和尺寸，不创建控制器或平台实例。非控件上的Space不能透传到播放快捷键。

测试真实App包含三平台点击/五选项/重复打开、旧入口/旧选择/旧关闭、遮罩/完成/Esc/返回、导航离页/切歌、卸载和根状态不变；审核新增/受影响Golden。此批只接播放页，歌词/底栏/Inspector入口下一增量，不宣称全套播放设置完成。完整验证、生成、Android预检及敏感扫描后push/Draft，新SHA云端另验。
