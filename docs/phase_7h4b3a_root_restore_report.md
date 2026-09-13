# Phase 7H4B3a：根恢复许可与重入保护

2026-09-13；基线ff55750d9f21977681060790a7495d9c91906041，fetch/pull --ff-only且工作区干净后建立codex/sleep-restore-root，Draft base codex/sleep-timer-storage。先[计划](phase_7h4b3a_root_restore_plan.md)/ADR112，再根API与测试。父提交双CI34733155015/34733165114已确认success，新SHA单独验收。

captureSleepRestore只在未关闭且sleep off时提供一次性许可，捕获根既有sleep generation。执行前与外部依赖/通知之后复核；用户新设、取消（即使仍off）、关闭或先接受另一恢复均撤销旧许可。isCurrent是非消费只读查询，不读时钟，供后续存储missing/失败处理使用。结果明确restored/expired/superseded/unavailable/failed，不泄露底层异常。

接受快照后保留原UTC deadline与15/30/60原选项；调度延迟为原截止减根时钟，不调用setSleepTimer重新开始计时，不调用play或重建队列。复用根已有one-shot和_sleepWoke；到期测试通过FakeAudioEngine确认pause一次，重复旧回调无效，不是新实机出声验收。

审计发现调度器依赖重入时，旧调用返回的Timer可能覆盖新意图Timer；现将返回值暂存，generation失效则立即取消，不覆盖当前Timer。唤醒读取时钟后也再次验证generation，避免时钟回调中设置的新意图被旧截止消费。新增相关回归，不改变正常用户定时语义。

24新增单测覆盖三选项保留原七分钟剩余、-1/0/1微秒边界、用户取消/重设/重设后取消/关闭、重复与并发许可、时钟回拨、时钟失败/重入、调度失败/重入新设/关闭、通知重入取消、不可用引擎、初始化不自动播放、恢复到期暂停一次、本曲结束保护、isCurrent重复检查及off取消。1新Node约束原截止和无存储/自动播放路径。

最终2062 Flutter通过（104秒）、157 Node通过（38.4秒），556 Dart格式零修改、严格分析0问题（8秒）；214旧Golden字节不变。生成40秒及14秒复验、Drift迁移通过，生成/schema无差异。两轮严格分析曾提示测试if括号和构造器初始化风格，均按规则修正；最终全量测试/分析/构建重跑，不把修正前结果当最终通过。

四份设计源文件SHA256一致，24ZIP条目逐字节匹配，App.tsx NEW_ICON_SPRITE/POLISH_CSS审计继续有效，无UI或资产变更。Android Debug最终51.6秒，48资产/完整音频许可/v2单签名者通过。APK232276017 bytes，SHA256 `7cb27e1dc0ca56d928bc35301ef4906b34e3fae5561cc9993095e14cfa75295c`；Java native-access警告保留，不提交APK。无新增设备安装/出声或本地Windows编译验收。

主要文件：playback_controller.dart、playback_sleep_restore.dart、sleep_restore_actions.dart、sleep_deadline_actions.dart、根单测/Node及README/ADR/状态/矩阵/计划。**存储适配器尚未与此根API接通，应用重启恢复仍未可用。** B3b继续初始化/关闭/存储竞争与反馈，session-only提示未变。平滑暂停和其余Phase7–11仍待验收，不自动合并或发布。
