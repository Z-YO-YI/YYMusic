# Phase 7I：队列失效项有界跳过与安全记录

## 审计与目标

开始前确认Z-YO-YI/YYMusic、干净分支codex/continuation-settings-ui与f03b332基线，fetch/ff-only pull无变化，新建codex/queue-skip-unplayable。上一目标轮完成H6C并提交，是有效进展。本轮从主指令Phase7与§18–20重新检查当前源码，而非沿用旧审计结论。

H4睡眠、H5输出及H6自动继续闭环已有实现；实际发现§20“无法播放项跳过并记录错误”此前缺失：_advanceInternal只获取_nextEntry并尝试一次，异常即中断。更新phase_7_exit_audit.md而不宣布Phase7通过。本批目标为有界推进与根诊断记录；风险为循环无限重试、吞数据库故障和用户撤销后继续播放。

## 实现

新增queue_advance.dart作为既有PlaybackController的part，不创建第二个播放控制器。沿用_nextEntry的原随机换轮规则，捕获此轮候选顺序；最多尝试每个队列项一次，repeat-all也不能无限循环。成功即返回，全部失败则保留error并报告最后失败。失效引用不删除，成功后当前项按既有原子队列写入路径更新。

_playEntryInternal只在曲目可用性、来源resolve和音频load边界标记可跳过失败；缺失曲目、本地失效、格式不支持、来源停用/移除、流过期、明确打开失败和notFound才允许继续。库读取、队列保存、stop/play命令不在该边界；认证、离线、未知、安全和schema错误仍停止。显式playEntry依旧准确报告指定项失败，不擅自播放别的歌曲。自动repeat-one继续使用已有精确重播路径，失败不无限重播。

每次候选和已有load/play异步边界复核关闭与自动继续许可，监听者关闭自动继续会阻止下一次尝试；手动下一首不受自动继续开关限制。新增QueuePlaybackFailure仅包含稳定条目ID、TrackRef和错误枚举，不保留URI、原始异常或凭据；根仅保留最近20项不可变记录，成功推进不清除这些记录。当前为会话内记录，尚未接队列页面可见反馈或长期诊断存储，不夸大为完整错误UI。

## 验证

新增19项测试。首批14项加H6A既有17项共31专项通过；随后补四种不可用曲目availability及stop错误不吞测试，共追加5项（此前进度消息误计为6项，以实际测试结果为准）。格式修复一处测试多行if括号，未关Lint。

第一轮2365 Flutter通过（120秒），追加后的最终全量2370通过（99秒）。161 Node通过（33.40秒），600 Dart文件格式零修改，严格分析0问题（10.0秒）。Android Debug构建通过（50.9秒），48资产逐字节一致，六项音频许可与完整原生声明通过。git diff --check通过，变更文本凭据/私钥扫描未命中。已有Java native-access警告保持。223张Golden未改，24个解压源与ZIP字节一致；不改App.tsx的NEW_ICON_SPRITE/POLISH_CSS或基础HTML，不引入WebView或新依赖。

本地Windows未运行：既有Developer Mode/symlink限制未变，由GitHub Actions验证本提交。父运行34757452442源码检查success，Android/Windows最后查询仍in_progress，可选音频探测跳过；不记为双平台完成。不新增真机听感、手势、后台或发行验收结论。

## 交付与下一步

独立commit/push及基于codex/continuation-settings-ui的Draft PR，不自动合并或发布。下一步把诊断接到队列可见反馈，继续核查剩余Phase7出口；无缝/标准化、真实封面/LRC来源、设备QA仍是缺口，随后按序推进Phase8–11。整体目标保持完整，不因本批有限范围或测试数量标记完成。
