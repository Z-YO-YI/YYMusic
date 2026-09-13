# Phase 7J8：过期源恢复播放

## 基线与范围

Z-YO-YI/YYMusic，基线b1473ad，fetch/ff-only确认最新后建立codex/expired-source-resume。上一轮已提交有效期模型和加载前保护，本轮继续解决暂停后恢复、seek和重复播放使用旧地址的问题，不缩减最终Android/Windows和Phase0–11要求。

## 实现

- 根保留已加载源的期限而非URI/headers；stop及采用下一个原生条目清理期限。J7不会预载明确带期限的未来项，因此原生切到下一条目时不存在需要继承的旧期限。
- play、完成重播、自动repeat-one和seek通过同一刷新方法：暂停旧引擎、复核当前完整TrackRef与库中可用性、有限解析、加载，再seek到原位置或明确目标；最后才按意图play。未过期路径不重新解析或load。
- 原生批次刷新重新解析当前允许的前缀并建立新身份；加载期间策略撤销仍截尾，拒绝迟到批次。刷新不调用新的playEntry，不改队列currentEntryId或制造一次新的普通暂停恢复历史。原历史suspend后activate，显式重播才begin新周期。
- 播放中seek刷新后恢复playing，暂停时seek仍paused。自动重复的canAdvance在解析期间继续有效，不提前递增会自行撤销它的sessionRevision。
- 每个异步边界复核关闭/许可。解析、加载或seek失败清理已加载身份并请求stop，安全错误保留，不播放尚未完成位置恢复的源。关闭等待已接受任务，禁止迟到load/play。

## 验证

新增12项根测试，覆盖位置、确实已有一条历史后的不重复记录、无过期无重取、两种seek状态、完成重播、自动单曲循环、原生批次及切曲、解析/seek失败、关闭、意图撤销。全量2491 Flutter测试通过（119秒），161 Node门禁通过（28.67秒），608 Dart文件格式零修改，226 Golden未变。初轮3处多行if规范已修复并复查，不忽略Lint。

Android Debug构建通过（36.9秒）；48资产、六项音频许可和完整原生声明验证通过。现有Java native-access警告不变。四个参考SHA256匹配既有基线，24解压文件与ZIP逐字节一致；App.tsx的NEW_ICON_SPRITE/POLISH_CSS、基础HTML、依赖/schema/UI未变。

## 剩余和交付

测试使用替身及既有插件边界测试，不是真机声学证明。网络Adapter尚未接入；无明确期限但服务端已失效的源、定时刷新、原生内部等待跨期限、未来网络项预载刷新、前缀修剪与循环窗口仍需继续实现。生产无缝开关仍未开放，Phase8–11和双平台验收保留。

当前阶段以codex/source-expiry-guards为base建立Draft PR，不合并/发行。父J7运行34763991767与J6运行34763488905本轮检查仍in_progress，新提交推送后独立触发GitHub双平台构建，状态须另行确认。未绕过本地Windows Developer Mode/symlink限制，未启用可选音频设备探针，构建产物和凭据不提交。
