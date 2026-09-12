# Phase 7G1：底栏队列导航计划

2026-09-13。基线6f9552a，已fetch/ff-only pull，工作区干净；分支codex/shell-queue-navigation，Draft base codex/shell-favorite-overlay-guard。前置双CI仍运行。

先ADR094，再给ShellPlayer增加可选onOpenQueue，AdaptiveRoot委托既有AppNavigation.openSystemPlaylist(queue)。复用原导出i-queue及YYDesktopPlayerBar，不新增页面/路由/播放器/存储；手机与Inspector不扩张入口。空队列也允许进入已有空态。路由/尺寸/活动/内联遮罩许可复用F3，并在调用后撤销旧闭包，避免保留回调在返回后重复导航。

四项设计指纹与已审计记录一致，核对App.tsx NEW_ICON_SPRITE/POLISH_CSS及基础HTML队列入口。设计转代码技能使用完整本地导出回退（无在线node），沿用现有组件，不手绘资产。验证两平台真实点击/空队列/重复及过期回调/菜单遮罩，确保根队列与音频不变；完整Flutter/Node、格式/严格分析/Android构建，Golden不应因仅接线而变化。若改变渲染则先审计差异，禁止盲目更新。

不涵盖全屏和Inspector剩余接线，不声称Phase7整体完成或实机/正式发行通过。验证后提交推送并创建Draft；本次云端按新SHA独立核验。
