# Phase 7J13A：Android 唯一播放根的真实循环验证入口

## 开始、范围与来源

2026-09-19，Z-YO-YI/YYMusic，codex/native-repeat-window，基线c8dc13e34cdc776e1644cb0e936b94fb07d8f23b。开始前fetch确认远程一致、工作区干净；基线[push 35442571138](https://github.com/Z-YO-YI/YYMusic/actions/runs/35442571138)与[PR 35442574148](https://github.com/Z-YO-YI/YYMusic/actions/runs/35442574148)均success。沿用Draft PR #136，不切分支、不重新实现J11循环/随机或J12错误保护。

复核开发总指令§20/23/25/29/34/38/39、[7J13计划](phase_7j13_root_native_validation_plan.md)、生产PlaybackController/JustAudioEngine/Drift仓库与既有真实序列探针。设计基准继续是基础HTML与App.tsx的NEW_ICON_SPRITE/POLISH_CSS合成结果；本批无视觉修改，引用原审计和指纹门禁，不重新生成设计资产或Golden。

本阶段目标是增加唯一根到真实插件及文件SQLite的设备验证，不替换旧引擎级测试。新增独立集成测试、脱敏结果合同、可取消观察等待、十项单测、宿主结果校验和三项Node门禁；仅修改工作流显式选项与阶段文档。ADR147先于实现记录。风险为把原生事件当根持久化已完成、重复历史错误计数、超时订阅泄漏、清理未完成即报告成功和诊断污染普通包。出口是本地回归、精确新SHA双平台构建及显式Android原生执行分别取证，不能互相代替。

## 已实现的验证逻辑

- `integration_test/root_native_repeat_poc_test.dart`只在Android运行，生成两份10秒低幅PCM WAV；通过真实Drift LibraryRepository建立曲目，生产PlaybackController与真实JustAudioEngine负责播放。自有解析器只能返回本次两份生成文件，不读取用户曲库或默认数据库。
- 使用文件SQLite而非内存库。根设置RepeatMode.all并调用playNativeSequence，自然观察同批次q0→q1→q0、绝对索引0/1/2和cycle0/0/1；三段各自核对原生与根正进度、完整TrackRef/标题、持久化currentEntryId和未被改写的两项队列。无人工原生事件、seek或手动下一曲。
- 历史由生产记录器根据真实位置变化写入。新轮q0应替换原记录ID并更新时间、移至顶部；最近播放仍恰有两首，不把去重误判为未记录新轮。原始历史ID、路径与数据库内容不输出。
- 第三段关闭自动继续，等待本曲自然completed且根历史写入排空，观察至少1秒无重启；随后分别等待根close、借用引擎dispose及数据库dispose。重新打开同一临时数据库和全新根/引擎，验证队列与历史保留、无源解析/自动播放，再观察至少1秒。该有界窗口不声称证明无限期行为。
- 观察等待使用专用订阅与Timer，成功、超时、源关闭、流错误和断言条件异常均在finally取消订阅；截止时间只产生失败，不能代替播放进度。每测试teardown兜底释放自身资源并删除自身临时目录。
- allTestsPassed完成后才输出唯一白名单结果，要求完整小写40位源码SHA、Android、恰好一个成功测试、所有身份/时钟/持久化/历史/停止/恢复/关闭指标。宿主必须先看到flutter test成功退出，再校验唯一最终记录；缺失、重复、额外字段、失败、跳过和旧SHA均拒绝。明确acousticGapMeasured=false。

## 工作流与运行方式

新增默认false的include_root_repeat_poc。仅在workflow_dispatch、run_just_audio_poc=true、just_audio_poc_platform=android且Windows Profile/HTTPS/旧序列选项均false时允许。保持原WAV/content两项先执行，再独立执行根测试与宿主结果校验；旧序列、Windows Profile和生产main不引用新入口，不创建Release，不在本地构建原生包。

推送后使用同一分支显式运行：

```powershell
gh workflow run foundation.yml --repo Z-YO-YI/YYMusic --ref codex/native-repeat-window -f run_just_audio_poc=true -f just_audio_poc_platform=android -f build_windows_audio_probe=false -f include_https_audio_poc=false -f include_sequence_audio_poc=false -f include_root_repeat_poc=true
```

## 本地验证与当前边界

新增Dart合同6项及观察资源生命周期4项全部通过；三个新Node门禁与旧三个序列门禁共同通过。严格分析首次发现新增代码的两处大括号与两处多余类型转换，修正后零问题。首轮完整Flutter为2565通过、1项CI配置测试失败：将宿主工具加入原格式命令破坏了旧命令的精确断言。改为保留原命令并独立检查新工具，没有修改原测试、关闭lint或放宽断言。

最终提交前验证：16项相关Dart专项、完整2566项Flutter全部通过（测试138秒、命令146.06秒，含226项既有Windows Golden）；171项Node全部通过（46.17秒，无失败/跳过）；620个Dart文件格式零修改、严格分析零问题（25.5秒）；14份待提交文件UTF-8与敏感模式检查、300个本地文档链接、差异空白检查通过。没有改动lib、Android/Windows宿主、pubspec/lock、设计参考或既有Golden。完整Flutter不包含本批尚未执行的Android原生集成测试。

### 同SHA云端与Android实测补记

精确源码7b28a166bb5a308d2a806a5ccde88f665487cef5的[push 35445546018](https://github.com/Z-YO-YI/YYMusic/actions/runs/35445546018)、[PR 35445548388](https://github.com/Z-YO-YI/YYMusic/actions/runs/35445548388)与[Android原生 35445563113](https://github.com/Z-YO-YI/YYMusic/actions/runs/35445563113)均success。Linux普通测试2340通过/226 Windows Golden按平台跳过，Windows另行226 Golden及3原生窗口握手通过；Android Debug及Windows Debug构建通过。Android签名v2和51项原生音频坐标/3份法律文本校验通过。常规push/PR未发布Release，不把Debug包称为上线。

Android API36 x86_64模拟器实际执行既有WAV/content两项（6秒）及本批独立根测试一项（34秒）。宿主校验唯一完整SHA、purpose、testCount=1、passed=true的最终记录通过：native/root/persistedEntries均[q0,q1,q0]，nativeIndices=[0,1,2]、nativeCycles=[0,0,1]，nativeProgressMs与rootProgressMs均[302,111,101]；同一批次、元数据对齐、历史替换、重开无播放和资源关闭均true；historyCount=2，完成项q0/index2/cycle1；完成无重启观察1206ms，重开无播放观察1201ms。acousticGapMeasured=false，模拟器使用-noaudio，不能声称实际听感或真机后台通过。该根测试不混入普通Flutter数量。

本阶段最小Android顺序根链路已取得真实通过，后续按[7J13B](phase_7j13b_root_native_shuffle_report.md)独立补随机与策略变更。Windows实际播放仍未通过，本批不重复服务重启、不自动更换输出或指责用户电脑；系统设置与生产代码均未改变。

顺序原生验证通过后再独立补原生随机跨轮及显式策略变更；声学、资源字节、真机后台/生命周期、标准化、Phase7其他出口及Phase8–11仍未验收。PR保持Draft，不自动合并，不将Debug或诊断包称为上线。
