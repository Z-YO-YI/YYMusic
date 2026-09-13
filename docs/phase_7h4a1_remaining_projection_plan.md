# Phase 7H4A1：剩余时间根投影

2026-09-13，基线8e84f9a，fetch/ff-only pull且干净；分支codex/sleep-remaining-projection，Draft base codex/playback-capability-audit。前置CI进行中，无失败。先ADR108，再只读根API/Presenter/可控时钟测试；H4A2随后接可见刷新和原界面。

剩余量由原注入时钟与UTC截止直接相减，过期夹零，不按tick累计、不提前暂停，不改变选中项。无分钟意图返回null，秒数向上取整，关闭后不读时钟。覆盖边界、时钟前后跳、暂停、重设取消、失败、关闭及零业务副作用。完整验证、文档与commit/push/Draft后进入H4A2；当前没有UI变化，不能称已完成§26剩余显示。
