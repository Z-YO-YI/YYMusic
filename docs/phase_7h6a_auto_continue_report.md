# Phase 7H6A：播放结束后继续的根策略

## 语义与实现

基础HTML2394的autoplayToggle帮助文案明确为“从当前队列自动播放下一首”，不是来源推荐或启动时自动播放。新增根continueAfterTrack和setContinueAfterTrack，默认true以保留原行为。本批只实现生产根行为和测试，尚无设置页开关或持久化，不能宣称偏好已完整可用。

关闭时自然完成不自动推进，普通、随机、列表循环及单曲自动重播都停在当前曲结束；显式播放/上一首/下一首保持可用。修改偏好本身不暂停当前曲、不启动播放，完成后再开启不会追溯触发旧完成事件。睡眠定时优先级保留，本曲结束定时在关闭自动继续时仍会被消费。

每次实际偏好变化增加revision，完成事件保存它；关→开也使已排队的旧完成失效。读取曲目、解析来源、已接受的load之后和最终play提交前沿用canPlay许可复核；慢load期间关闭则停止已加载源，不再play；单曲循环慢seek之后也复核。已经交给原生的seek/load/队列提交不能假称未发生，不回滚已提交选择，已提交的play不是此策略可撤销的命令。

随机下一条选择改为只读候选索引，真正加载/选中时由既有_syncShuffleCursor定位。此前取候选就预增游标，异步解析被撤销后手动下一首可能跳过候选；新增测试覆盖这一情况。没有重建播放引擎、复制队列或修改随机顺序算法。

## 剩余播放能力复核

本机package_config与lock定位just_audio0.10.6/just_audio_windows0.2.3，使用其已安装一手源码而非最新版推断。应用NativeJustAudioPlayerBackend仍只用AudioSource.uri，未接setAudioSources列表预加载，因而不宣称无缝播放；Windows player.hpp441–444的audioEffectSetEnabled/androidLoudnessEnhancerSetTargetGain仅返回空Map成功，不能当作响度标准化实际生效。无跨曲目响度测量/削波保护策略，本批不增加这些无效开关，也没有升级依赖。

## 关机恢复及验证

用户电脑意外关机后，确认两份未提交源码/测试仍在codex/playback-auto-continue，父HEAD f47c5d7。旧全量日志出现连接关闭且没有完成，不计为通过；重新fetch，因新分支尚无tracking，明确对父origin/codex/audio-output-panel执行ff-only pull并确认最新，未覆盖任何未提交修改。

17项新根单测覆盖默认一次推进、3循环模式×随机开关、手动下一首、重新开启、旧完成revision、监听重入关闭、慢解析/加载/seek、随机候选撤销、睡眠优先、幂等与关闭根。关机前专项17通过；恢复后最终全量2286 Flutter通过（123秒），160 Node通过（41.01秒），585 Dart格式零修改，严格分析0问题（15.4秒）。220张Golden无修改，无依赖/schema/生成输入变化。

ZIP/主指令/App.tsx/基础HTML四个SHA256仍匹配Phase0基线，24个解压条目逐字节匹配。没有忽略NEW_ICON_SPRITE/POLISH_CSS，也未修改参考输入。Android Debug预检52.5秒通过，48资产与完整音频许可验证通过，APK SHA256 20ce10e9156dae767031db08f8c09e269c055dfe0d71c6b31f7713ae39d465c5。保留Java原生访问和SDK XML版本3/4兼容警告，未自动升级工具链。本提交双平台打包由GitHub Actions另验，本机Windows symlink限制未变，无新增真机安装/听感验收。

## 同步与下一步

基线f47c5d7，分支codex/playback-auto-continue，Draft目标codex/audio-output-panel。父GitHub运行34745557593源码/Android/Windows均SUCCESS。本阶段完成验证后单独提交推送，不自动合并/发布。

下一步实现自动继续偏好的持久化契约与严格解析，再接受保护启动恢复和设置页开关；恢复只改变策略，绝不自动播放。无缝/响度标准化仍独立按实际后端验收，Phase7及Phase8–11尚未完成。
