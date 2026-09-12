# Phase 7F3 开始：内联遮罩收藏许可

2026-09-13。基线344ea0d41846689fb3f34187cf170df3d36a08e5，fetch/ff-only pull成功、干净；分支codex/shell-favorite-overlay-guard，Draft base codex/shell-current-favorite-ui。前置CI34707400406/34707403440仍运行。

目标：检查并修复实际被内联菜单/确认框ExcludeFocus覆盖的底栏旧收藏回调，不把内联遮罩误当作路由变化。先加实际系统歌单菜单回归复现，再在Shell收藏许可中遵循祖先焦点排除；未被遮罩覆盖的其他区域不强行禁用。已读总指令Phase7/既有报告、SystemPlaylistScreen/QueueScreen/PlaylistEditorHost及Flutter本地Focus/ExcludeFocus实现，不改视觉、图标或设计源。

风险：打开再关闭后旧许可不能复活；只因用户把焦点移到另一个正常按钮不应撤销；已接受Repository保存仍排空，不改播放器。拟修改shell_player.dart/shell_favorite_actions.dart，新增真实内联菜单/确认测试与Node门禁，更新报告文档。出口：先失败复现，再相关/全量Flutter/Node、格式/严格分析、生成与Android预检通过；Golden预计不变。提交push/Draft并按新SHA独立验收，不声称Phase7整体或发行完成。
