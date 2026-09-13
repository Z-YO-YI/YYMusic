# 实施状态

最新Phase7J9：[原生期限报告](phase_7j9_native_expiry_report.md)/ADR140。期限传至NativeBackend，跨准备/load/append/seek等待失效时停止并转换streamUrlExpired；10新通道测试，全量2501 Flutter、161 Node、严格分析和Android Debug通过。分支codex/native-source-expiry，基线c169efc。持续播放定时撤销、网络Adapter及声学/生命周期仍待验收；以下为历史阶段。

最新Phase7J8：[过期恢复报告](phase_7j8_expired_resume_report.md)/ADR139。根保留已加载源期限用于play/replay/repeat-one/seek前刷新，保留位置、原生序列和历史周期；12新根测试，全量2491 Flutter/161 Node及Android Debug通过。分支codex/expired-source-resume，基线b1473ad。完整网络无缝和真机验收仍未完成；以下为历史阶段。

最新Phase7J7：[有效期报告](phase_7j7_source_expiry_report.md)/ADR138。可选UTC expiresAt仅存在瞬时PlayableSource，根有限重取及完整身份/许可复核，引擎执行时预检。12项新测试，全量2479 Flutter、161 Node、严格分析与Android Debug通过。分支codex/source-expiry-guards，基线5489b5c。网络Adapter、暂停后刷新及完整网络无缝尚未实现；以下为历史记录。

最新Phase7J6：[有界提前加载报告](phase_7j6_lookahead_report.md)/ADR137。初始三项、当前位置后两项前瞻；异步解析不占根命令队列，提交追加复核身份/策略，关闭排空解析任务。新增9项测试，全量2467 Flutter与161 Node通过。分支codex/native-sequence-lookahead，基线6448b42。并非完整有界内存窗口或上线验收；以下为历史记录。

最新Phase7J5：[播放根序列报告](phase_7j5_root_native_sequence_report.md)/ADR136。显式playNativeSequence已贯通唯一PlaybackController：顺序解析前缀、一次加载、原生切曲持久化、原子元数据/时钟及有界历史证据，策略/编辑截尾。27项根测试含真实SQLite及加载撤销后禁止play，加1项真实插件通道到根贯通。分支codex/root-native-sequence，base codex/sequence-continuation-boundary。生产UI未开放，无缝/连续窗口预载及原生验收不记完成；以下为历史阶段。

最新Phase7J4：[本曲边界报告](phase_7j4_continuation_boundary_report.md)/ADR135。原生尾部移除经共用引擎串行与身份复核，使用未被SequenceState截断的原始播放事件索引；13新测试覆盖正常保留、旧请求、切曲/回切竞态、失败与关闭。分支codex/sequence-continuation-boundary，base codex/sequence-event-isolation。根策略尚未绑定，不宣称用户无缝播放完成；以下为历史阶段。

最新Phase7J3：[原生事件隔离报告](phase_7j3_event_isolation_report.md)/ADR134。整批替换使用新AudioPlayer与原生事件通道；旧订阅及play Future按generation撤销，音量/速率保留。8项新通道测试，含插件释放错误被吞的明确限制证据；根尚未切换序列，无缝未上线。分支codex/sequence-event-isolation，base codex/sequence-engine-identity；以下为历史阶段。

最新Phase7J2：[序列引擎报告](phase_7j2_sequence_engine_report.md)/ADR133。JustAudioEngine实现可选AudioSequenceEngine，共用原有串行/关闭机制；同一状态携带不含URI/头的批次与entry身份。17新专项＋1真实插件跨层测试，根策略未切换、不宣称无缝已启用。分支codex/sequence-engine-identity，base codex/native-sequence-backend；以下为历史阶段。

最新Phase7J1：[原生序列边界报告](phase_7j1_native_sequence_report.md)/ADR132。可选后端使用真实setAudioSources并投影插件索引，输入快照、整批预检、安全失败；11项通道测试，不增加依赖。生产根仍单曲，不启用无缝开关，标准化与原生验收待完成。分支codex/native-sequence-backend，base codex/queue-skip-feedback；以下为历史阶段。

最新Phase7I2：[可见反馈报告](phase_7i2_queue_feedback_report.md)/ADR131。QueueScreen已接根失败列表，显示安全原因和当前精确匹配元数据，快照确认不影响队列/播放；7新Widget及3新Golden，原223图不变。分支codex/queue-skip-feedback，base codex/queue-skip-unplayable。整体目标尚未完成。

最新Phase7I：[队列失效跳过报告](phase_7i_queue_skip_report.md)/ADR130。复核主指令§20发现此前只尝试一次下一项，现按捕获队列有界跳过曲目失败并保留20项安全会话记录；明确点选不自动替换，错误分类限定音频/解析边界，不吞持久化故障。可见反馈、其他Phase7缺口和Phase8–11仍待完成。分支codex/queue-skip-unplayable，base codex/continuation-settings-ui。

最新Phase7H6C：[设置界面报告](phase_7h6c_continuation_settings_report.md)/ADR129。播放分类、真实自动继续开关、读取/保存/错误重试已接生产路由；保留分类与宽度切换，旧回调/隐藏路由不可操作。3新Golden、7设置分类Golden更新且逐图检查，213旧图不变。分支codex/continuation-settings-ui，base codex/continuation-persistence-binding。以下为历史记录。

最新Phase7H6B2b：[生产持久化报告](phase_7h6b2b_continuation_binding_report.md)/ADR128。AppDataServices拥有专用仓库，根协调器启动恢复、串行保存并关闭排空。真实SQLite三次重开、坏记录保留/显式修复及关闭屏障均有测试；设置UI尚未接入。分支codex/continuation-persistence-binding，base codex/continuation-restore-permit。以下为历史记录。

最新Phase7H6B2a：[恢复保护报告](phase_7h6b2a_continuation_restore_report.md)/ADR127。一次性许可及独立显式意图计数，11项新测试保护用户选择、关闭与重入；没有接通生产持久化协调器。分支codex/continuation-restore-permit，base codex/continuation-preference-storage。以下为历史记录。

最新Phase7H6B1：[继续偏好存储报告](phase_7h6b1_continuation_storage_report.md)/ADR126。专用Repository、version1布尔codec及借用数据库的Drift适配，21新测试；不改schema。启动恢复/保存协调器和设置开关待后续。分支codex/continuation-preference-storage，base codex/playback-auto-continue。以下为历史记录。

最新Phase7H6A：[自动继续根报告](phase_7h6a_auto_continue_report.md)/ADR125。实现continueAfterTrack策略与完成revision撤销，覆盖慢解析/load/seek、循环/随机及睡眠优先；新增17测试，关机恢复后完整2286 Flutter/160 Node通过。UI和持久化下一阶段。分支codex/playback-auto-continue，base codex/audio-output-panel；父f47c5d7双平台云端成功。以下为历史记录。

最新Phase7H5C2：[输出面板报告](phase_7h5c2_output_panel_report.md)/ADR124。生产Presenter借用根观察器，播放/歌词/Inspector既有设置路由显示输出与系统设置入口；输出局部通知、页面许可及安全反馈。11新Widget+3新Golden，旧217图不变；父ab29b7f双平台云端成功。分支codex/audio-output-panel，base codex/output-settings-action。硬件验收和Phase7其他偏好及Phase8–11仍待完成。以下为历史记录。

最新Phase7H5C1：[设置操作报告](phase_7h5c1_settings_action_report.md)/ADR123。根输出控制器显式设置请求等待读取后验证页面许可、能力及关闭状态，busy防重入，关闭排空已接受启动；15操作+1根测试。父b7ffb6f双平台云端成功。本批未接Presenter/界面，分支codex/output-settings-action，base codex/root-audio-output。以下为历史记录。

最新Phase7H5B2c：[根输出报告](phase_7h5b2c_root_output_report.md)/ADR122。双平台生产Gateway已由Bootstrap交根所有，非阻塞初始化、前台转换刷新、关闭排空与安全失败清理；修复观察器事件Timer残留。新增9项Flutter测试并增强既有启动测试；Presenter/界面入口下一阶段。父6345f49双平台云端成功。分支codex/root-audio-output，base codex/audio-output-observer。以下为历史记录。

最新Phase7H5B2b：[输出协调报告](phase_7h5b2b_output_observer_report.md)/ADR121。独立AudioOutputController借用Gateway，串行合并读取、流修订隔离和安全关闭；13新单测，完整2230 Flutter/160 Node通过。父8f3b992云端源码/Android/Windows成功。根、Presenter、UI和前台刷新绑定仍待下一批，不把独立模块标为可见功能。分支codex/audio-output-observer，base codex/windows-default-audio-output。以下为历史记录。

最新Phase7H5B2a：[Windows默认输出报告](phase_7h5b2a_windows_output_report.md)/ADR120。getState只读MMDevice活动eRender/eMultimedia默认端点、类型校验名称及资源释放；返回systemDefault而非playerRoute。新增1项CI原生读取测试和1项Node门禁；本机Windows环境限制保持，编译/原生结果待本SHA云端。Android仍unknown，无根/Presenter/UI绑定。分支codex/windows-default-audio-output，base codex/native-sound-settings。以下为历史记录。

最新Phase7H5B1：[原生设置报告](phase_7h5b1_native_settings_report.md)/ADR119。双宿主注册固定声音设置目标与Dart串行适配，21项通道测试、1项源文件门禁。路由仍unknown，尚无根/Presenter/UI绑定；Windows本地编译前因Developer Mode/symlink限制失败，待GitHub本SHA验证。分支codex/native-sound-settings，base codex/audio-output-contract。以下为历史记录。

最新Phase7H5A：[输出契约报告及H5B计划](phase_7h5a_audio_output_contract_report.md)/ADR118。AudioOutputGateway区分未知、系统默认和实际路由；设置启动结果不等同切换；标签校验/日志脱敏、安全不可用实现及22项测试。尚无原生或UI绑定，下一批按锁定平台代码和一手API落实读取/启动。分支codex/audio-output-contract，base codex/root-sleep-fade。以下为历史记录。

最新Phase7H4C2b2：[生产根淡出报告](phase_7h4c2b2_root_fade_report.md)/ADR117。分钟到期已绑定SleepFadeRunner，临时振幅与用户音量隔离，用户中断/切曲前恢复、关闭清理通道排空，恢复失败可观察且不掩盖先前播放错误。17项新根测试，旧截止/恢复/持久化断言明确加入音量命令，无Golden改动。分支codex/root-sleep-fade，base codex/sleep-fade-runner。代码启用不等同实机听感或Phase7整体完成。以下为历史记录。

最新Phase7H4C2b1：[执行器报告与根接线清单](phase_7h4c2b1_fade_runner_report.md)/ADR116。SleepFadeRunner独立实现可取消等待、单调渐降、一次暂停、在途排空及finally恢复，20项时序单测。生产根尚未绑定，下一批H4C2b2处理逐步串行与关闭恢复的防自等待。分支codex/sleep-fade-runner，base codex/playback-volume-intent。以下为历史记录。

最新Phase7H4C2a：[根音量报告](phase_7h4c2a_volume_intent_report.md)/ADR115。3项先失败回归确认问题，修复为有效请求前锁定原确认值、成功后确认新值，两条引擎投影不再覆盖应用意图；23项新根单测通过。无淡出调度或UI变化，H4C2b继续逐步写入/撤销恢复；不标记平滑暂停已完成。分支codex/playback-volume-intent，base codex/sleep-fade-envelope。以下为历史记录。

最新Phase7H4C1：[淡出契约/接入审计](phase_7h4c1_sleep_fade_contract.md)、ADR114。新增SleepFadeEnvelope及17项单测，纯计算不创建计时器或调用引擎；2秒线性振幅/50ms建议间隔。根引擎音量回报直写UI、整段串行等待阻塞用户操作的问题已识别，下一步H4C2隔离并验证；**实际平滑暂停尚未接通**。基线86f75b1，分支codex/sleep-fade-envelope。以下为历史记录。

最新Phase7H4B3b：[计划](phase_7h4b3b_persistence_plan.md)/ADR113/[报告](phase_7h4b3b_persistence_report.md)。分钟定时存储、启动恢复、关闭排空和Presenter/面板反馈已生产绑定，SQLite三次重开验证原截止/取消保留；无自动播放。22协调器+4Graph+6Widget+3新Golden，完整2097 Flutter/158 Node、217截图（214原图不变）、563格式/严格分析/生成迁移及Android Debug49.8秒通过。分支codex/sleep-persistence-coordinator，base codex/sleep-restore-root；父154df75双CI34734305847/34734318067 SUCCESS，新SHA另验。分钟恢复完成，本曲结束仅会话；[H4C平滑暂停](phase_7h4c_sleep_fade_plan.md)及其余Phase7–11仍待验收。以下为历史记录。

最新Phase7H4B3a：[计划](phase_7h4b3a_root_restore_plan.md)/ADR112/[报告](phase_7h4b3a_root_restore_report.md)。captureSleepRestore提供一次性调用和非消费isCurrent检查，按原deadline/选项恢复；晚到结果不能覆盖用户取消/新设。修复调度器返回旧Timer及唤醒时钟重入覆盖新意图。24新单测+1Node，完整2062 Flutter/157 Node、214旧Golden不变、556格式/严格分析/生成迁移及Android Debug51.6秒通过。分支codex/sleep-restore-root，base codex/sleep-timer-storage；父ff55750双CI34733155015/34733165114 SUCCESS，新SHA另验。尚未启动绑定，B3b继续存储协调；Phase7整体及Phase8–11未完成。以下为历史记录。

最新Phase7H4B2：[计划](phase_7h4b2_storage_plan.md)/ADR111/[报告](phase_7h4b2_storage_report.md)。DriftSleepTimerRepository只访问playbackSleepTimer，按调用顺序串行read/save/clear，错误不回显原文，dispose排空且不关闭借用数据库。真实SQLite重开/清理持久化已验证；尚未注册AppDataServices或根恢复，session-only提示不变。20新单测+1新Node，完整2038 Flutter/156 Node、214原Golden不变、553格式/严格分析/生成迁移及Android Debug17.9秒通过。分支codex/sleep-timer-storage，base codex/sleep-restore-snapshot；父push34732285509 SUCCESS，PR34732312781核验时进行中，新SHA另验。下一批B3，Phase7整体及Phase8–11未完成。以下为历史记录。

最新Phase7H4B1：[计划](phase_7h4b1_snapshot_plan.md)/ADR110/[报告](phase_7h4b1_snapshot_report.md)。领域快照仅原15/30/60分钟和UTC deadline；data编码严格校验版本/类型/规范UTC/长度，安全错误不回显记录；Repository定义按调用顺序串行及关闭排空，尚无适配器/启动绑定。29新单测，完整2018 Flutter/155 Node、214原Golden不变、551格式/严格分析和Android Debug41.4秒通过，APK与A2b字节一致。分支codex/sleep-restore-snapshot，base codex/sleep-countdown-panel；父CI34731476534/34731489397核验时仍进行中，本SHA另验。下一批B2真实存储；Phase7整体及Phase8–11仍未完成。以下为历史记录。

最新Phase7H4A2b：[报告](phase_7h4a2b_countdown_panel_report.md)。正式共享面板绑定剩余时间子组件，播放页/歌词页/底栏/Inspector沿用唯一根弹层。6新Widget+3新Golden+1新Node；完整1989 Flutter/154 Node、214截图（12旧图审核更新、199旧图不变）、547格式/严格分析/生成迁移和Android Debug18.3秒通过。分支codex/sleep-countdown-panel，base codex/sleep-countdown-ui。父提交2b57143双CI34730407355/34730418800均SUCCESS；本提交云端另验。§26剩余时间显示已绑定，未到期恢复和平滑暂停尚未完成，下一批[H4B计划](phase_7h4b_sleep_restore_plan.md)。Phase7整体及Phase8–11未完成。以下为历史记录。

最新Phase7H4A1：[计划](phase_7h4a1_remaining_projection_plan.md)/ADR108/[报告](phase_7h4a1_remaining_projection_report.md)。根sleepRemaining与Presenter.sleepRemainingSeconds只读投影，保留原截止/意图，无Timer/通知/音频副作用；18新单测覆盖取整/时钟跳变/延迟/关闭。完整1972 Flutter/153 Node、211原Golden不变、543格式/严格分析/生成迁移及Android Debug18.6秒通过。分支codex/sleep-remaining-projection，base codex/playback-capability-audit。前置push34728554610 SUCCESS、PR34728571947核验时进行中；新SHA另验。尚无界面倒计时，H4A2继续生命周期刷新和绑定；Phase7整体及Phase8–11未完成。以下为历史记录。

当前Phase7H4：[能力审计](phase_7h4_capability_audit.md)/ADR107/[验证](phase_7h4_capability_report.md)。补回§26的剩余时间/未过期恢复/平滑暂停缺口；输出设备与标准化等不得从插件声明或空成功返回推断已接入。下一批[H4A](phase_7h4a_sleep_remaining_plan.md)，之后恢复/淡出及真实设备/偏好。本轮文档与1项Node检查，1954 Flutter/152 Node、211原Golden不变、542格式/严格分析及Android Debug17.5秒复验通过，APK与H3B相同；无应用/依赖/schema变化。分支codex/playback-capability-audit，base codex/inspector-queue-access，前置6d1bb50双CI34727705634/34727730305 SUCCESS，新SHA另验。Phase7整体及Phase8–11未完成。以下为历史记录。

最新Phase7H3B：[计划](phase_7h3b_inspector_queue_plan.md)/ADR106/[报告](phase_7h3b_inspector_queue_report.md)。Inspector绑定H3A根摘要与既有受保护队列入口，移除“队列详情正在开发”提示；以列表序号而非预测随机次序呈现。14新Widget+3新Golden，完整1954 Flutter/151 Node、211 Golden、542文件格式零修改、严格分析/生成迁移及Android Debug18.4秒通过。22旧图审核更新（侧栏页脚/滚动位置及相关绘制），186旧图不变。分支codex/inspector-queue-access，base codex/inspector-queue-summary；前置6d357ad双CI34726594415/34726626442 SUCCESS，确认排序修复。新SHA另验，Phase7整体及Phase8–11未完成。以下为历史记录。

最新Phase7H3A：[计划](phase_7h3a_queue_summary_plan.md)/ADR105/[报告](phase_7h3a_queue_summary_report.md)。新增准确只读队列摘要与根身份缓存，10单测，不预测随机次序；尚未绑定Inspector UI。优先修复父阶段两次Windows截图失败：测试同名曲目逐次系统时间造成排序差异，固定导入批次时间并补1独立回归，未修改任何PNG。最终1937 Flutter/150 Node、208原Golden、540格式零改动、严格分析/生成迁移及Android Debug48秒通过。分支codex/inspector-queue-summary，base codex/inspector-sleep-settings；父SHA失败不冒称成功，新SHA另验。H3B继续侧栏摘要/入口，Phase7整体及Phase8–11未完成。以下为历史记录。

最新Phase7H2C4：[计划](phase_7h2c4_inspector_sleep_plan.md)/ADR104/[报告](phase_7h2c4_inspector_sleep_report.md)。Inspector两个既有按钮绑定根URI动作，沿用Shell生命周期撤销和唯一modal；窄屏通过既有曲目信息/播放页路径实际点击验收。18新Widget+3新Golden，完整1926 Flutter/149 Node、208 Golden、537文件格式零修改、严格分析/生成/迁移及Android Debug预检通过。24旧截图审核更新启用态，181旧图不变；新增图挂载前固定阴影策略，避免缓存绘制差异，未放宽阈值。分支codex/inspector-sleep-settings，Draft base codex/shell-sleep-settings。前置4784cba双CI34724213791/34724254216 SUCCESS；本批新SHA另验。Phase7整体及Phase8–11尚未完成，无新增设备安装/出声或发行验收。以下为历史记录。

最新Phase7H2C3：[计划](phase_7h2c3_shell_sleep_plan.md)/ADR103/[报告](phase_7h2c3_shell_sleep_report.md)。宽底栏既有i-device绑定唯一根modal；全部5个生产frame捕获完整URI，使用GoRouter.state.uri核对push后的栈顶，同路径参数变化撤销旧弹层。22新Widget+3新Golden，完整1905 Flutter/148 Node、535文件格式/严格分析/生成迁移及Android Debug17.7秒与资产许可签名通过；23旧图各100像素图标启用变化审核更新，179不变，共205。分支codex/shell-sleep-settings，Draft base codex/lyrics-sleep-settings；前置81a93c4双CI34722713534/34722770925 SUCCESS，本批新SHA另验。未改手机/窄栏可见性，Inspector及其余设置后续；无新增设备安装/出声或发行验收。以下为历史记录。

最新Phase7H2C2：[计划](phase_7h2c2_lyrics_sleep_plan.md)/ADR102/[报告](phase_7h2c2_lyrics_sleep_report.md)。歌词i-more入口复用唯一睡眠modal，两页显式owner阻止旧入口跨页借权；覆盖/恢复沿用歌词停用与seek撤销，关闭保留根睡眠意图。窄屏翻译第二行防元信息挤没，稳定header结构保留焦点。17新Widget+4新Golden，完整1880 Flutter/147 Node、533文件格式、严格分析、生成迁移与Android Debug34.3秒及资产许可签名通过；19旧图审核更新、179不变，共202。分支codex/lyrics-sleep-settings，Draft base codex/player-sleep-settings；前置61585ef双CI34721259771/34721287029已SUCCESS，本批新SHA另验。底栏/Inspector及Phase7其余设置和Phase8–11仍待，无新增设备安装/出声或发行验收。以下为历史记录。

最新Phase7H2C1：[计划](phase_7h2c1_player_sleep_plan.md)/ADR101/[报告](phase_7h2c1_player_sleep_report.md)。正式播放页i-more入口接根唯一睡眠设置路由，支持五选项、重复打开拦截、旧动作撤销、精准离页移除、键盘/返回/焦点及实时主题尺寸。17新Widget+4新Golden，1859 Flutter/146 Node、531文件格式、严格分析、生成迁移与Android Debug17.1秒及资产许可签名通过。15旧标题栏Golden审核更新、179旧图不变，合计198。分支codex/player-sleep-settings，Draft base codex/native-sleep-settings；前置d039bb0双CI34719698577/34719716804已SUCCESS。本批新SHA云端另验；歌词/底栏/Inspector与其他播放设置尚未完成，无新增设备安装或发行验收。以下为历史记录。

最新Phase7H2B：[计划](phase_7h2b_native_sleep_plan.md)/ADR100/[报告](phase_7h2b_native_sleep_report.md)。新增纯受控YYOptionCard与借根动作的SleepSettingsPanel，复用YYDialog/YYBottomSheet、主题字体、原始关闭图标；真实五选项、状态失败、单/双列、短窗滚动、Tab/Enter/Esc、焦点恢复及路由覆盖/恢复/隐藏/零面积/旧许可保护。19新Widget、6新Golden逐张审核，25相关及完整1838 Flutter/145 Node、528文件格式/严格分析、生成迁移通过；188旧Golden未改。Android Debug16.3秒及资产许可签名通过，与H2A APK相同，因生产入口仍待H2C。分支codex/native-sleep-settings，Draft base codex/sleep-settings-projection；前置1998157双CI34718048011/34718070381 SUCCESS，本批新SHA云端另验。

最新Phase7H2A：[计划](phase_7h2a_sleep_projection_plan.md)/ADR099/[报告](phase_7h2a_sleep_projection_report.md)。本地导出弹层审计后先补真实分钟选中投影及旧动作保护，复用PlaybackPresenter；双快照+通知版本+根关闭判定，不创建UI Timer。20新Flutter/1新Node，67相关及完整1813 Flutter/144 Node、188 Golden不变、523文件格式/严格分析/生成迁移、Android Debug17.9秒及资产许可v2签名通过。无Widget或原生入口变更，H2B继续共享弹层；Phase7及Phase8–11未完成。分支codex/sleep-settings-projection，Draft base codex/sleep-current-entry；前置bac9405双CI34716728571/34716743445已SUCCESS，本批新SHA云端另验。

最新Phase7H1B：[计划](phase_7h1b_current_entry_plan.md)/ADR098/[报告](phase_7h1b_current_entry_report.md)。本曲结束准确entry绑定与根完成事件前消费已实现；分钟与本曲模式互斥，重复歌曲按entry区分，暂停/seek/恢复保留，切歌/重载/停止/清空/错误撤销。24新增、47相关及完整1793 Flutter/143 Node通过，188 Golden不变；520文件格式/严格分析、生成迁移及Android Debug17.8秒、资产许可v2签名通过。分支codex/sleep-current-entry，Draft base codex/sleep-deadline-core；H1A云端在开发中核验仍运行，不借用本地通过。下一步H2原生睡眠设置界面；Phase7整体和Phase8–11仍未完成。

最新Phase7H1A：[计划](phase_7h1a_sleep_deadline_plan.md)/ADR097/[报告](phase_7h1a_sleep_deadline_report.md)。已实现根截止定时核心（关闭/15/30/60分钟），23新测试含到期后completed错误推进的先失败复现，完整1769 Flutter/143 Node、188 Golden不变、519文件格式及严格分析通过，生成/Schema无漂移；Android Debug18.2秒及资产许可v2签名通过。无新UI，本曲结束与设置界面尚未接入；Phase7及真实导入/来源/后台/发行仍待完成。前置2fb29ec和7d5385e的四组云端运行现均SUCCESS；本批codex/sleep-deadline-core按新SHA另验，不以本地预检替代GitHub结果。以下为历史记录。

当前检查点：[Phase7出口审计](phase_7_exit_audit.md)。五项核心出口有源码/自动化证据，但§18播放设置（设备/睡眠定时/播放偏好）仍缺失，侧栏队列摘要仍预留，设备QA也未被Fake/Golden覆盖；**不标记Phase7整体完成、不跳Phase8**。下一项按[7H计划](phase_7h_playback_settings_plan.md)先审查根完成事件与暂停串行化，再实现真实睡眠定时核心，之后接原生界面。此批仅文档，无新增应用功能/测试/基线。复验1746 Flutter/143 Node、516文件格式/严格分析、Android Debug21.5秒及资产许可签名通过，30本地证据链接可解析。基线7d5385e的双CI核验时仍运行；审计分支codex/phase7-exit-audit，Draft base codex/shell-metadata-navigation-guard，新SHA云端另验。以下为历史记录。

当前Phase7G4：[计划](phase_7g4_metadata_guard_plan.md)/[报告](phase_7g4_metadata_guard_report.md)。先4项真实复现：手机/桌面的旧onOpen/onOpenLyrics在主导航切换后仍能打开页面。改用现有_navigationAction保护，两处onOpen和两处歌词入口不再直接转发。22新Widget（含真实点击/长按），67相关与完整1746 Flutter/143 Node通过，188旧Golden不变；516文件格式/严格分析/生成迁移、Android Debug19.2秒与资产许可签名通过。分支codex/shell-metadata-navigation-guard，Draft base codex/inspector-playback-navigation；前置3be2863双CI34712365647/34712380763 SUCCESS，本批新SHA独立核验。设置/队列摘要及Phase7出口、Phase8–11仍待完成，无新增设备安装/出声或本地Windows编译。

当前Phase7G3：[计划](phase_7g3_inspector_navigation_plan.md)/ADR096/[报告](phase_7g3_inspector_navigation_report.md)。侧栏全屏/歌词按钮借根导航，绑定路由事件与页面/布局/尺寸身份，隐藏/遮罩/离页撤销旧回调，无新增播放或原生真值。20新Widget，45相关及完整1724 Flutter/142 Node、188 Golden、515文件格式/严格分析/生成迁移、Android Debug27.4秒及资产许可签名通过。21旧图精确审核更新、167不变；基线仍逐像素比较，合成取整差异单独量化。分支codex/inspector-playback-navigation，Draft base codex/shell-fullscreen-navigation；前置ea2f3a9双CI34711115530/34711133249 SUCCESS。本批云端按新SHA核验；设置/队列摘要与Phase7出口、Phase8–11仍待完成，无新增实机安装/出声或本地Windows构建。

当前Phase7G2：[计划](phase_7g2_shell_fullscreen_plan.md)/ADR095/[报告](phase_7g2_shell_fullscreen_report.md)。五处AppRouter frame传同一全屏意图闭包，AdaptiveRoot/ShellPlayer接现有按钮；复用FullscreenPresenter.enterOnNextPlayer及G1导航许可，系统不支持时仅打开原生播放页。13新Widget、1新Node，完整1704 Flutter/141 Node、188 Golden、514文件格式/严格分析/生成迁移、Android Debug44.9秒及资产许可签名通过。65旧图只改全屏图标62像素，123不变。分支codex/shell-fullscreen-navigation，Draft base codex/shell-queue-navigation；前置a5dc821双CI34709946561/34709964739 SUCCESS。本批云端新SHA独立核验；后续Inspector剩余入口、Phase7出口和Phase8–11，未新增实机安装/出声或本地Windows构建。

当前Phase7G1：[计划](phase_7g1_shell_queue_plan.md)/ADR094/[报告](phase_7g1_shell_queue_report.md)。AdaptiveRoot与ShellPlayer接既有队列导航，复用F3页面交互许可并在接受导航前撤销旧闭包。12新Widget覆盖两平台空/非空队列点击、返回/重复、内联遮罩及离页/尺寸/卸载；完整1691 Flutter/140 Node、188 Golden、513文件格式/严格分析/生成迁移、Android Debug38.5秒及资产许可签名通过。65旧图每张仅67队列图标像素改变，123旧图不变。分支codex/shell-queue-navigation，Draft base codex/shell-favorite-overlay-guard；前置6f9552a双CI34708712276/34708730171均SUCCESS，本批新SHA另验。下一步底栏全屏/Inspector剩余入口及Phase7出口，Phase8–11未完成，未新增实机出声/安装或本地Windows编译。以下为历史记录。

当前Phase7F3：[计划](phase_7f3_overlay_guard_plan.md)/[报告](phase_7f3_overlay_guard_report.md)。真实复现Windows/平板内联菜单旧收藏回调仍写入，Shell许可现遵循祖先ExcludeFocus并在覆盖变化撤销旧代数；关闭后新按钮仍可用，不新设全局锁。8 Widget覆盖两平台×菜单/历史确认×覆盖/关闭，22相关和完整1679 Flutter/139 Node通过；188旧Golden不变、512文件格式/严格分析/生成迁移和Android Debug校验通过。分支codex/shell-favorite-overlay-guard，base codex/shell-current-favorite-ui；前置344ea0d双CI34707400406/34707403440均SUCCESS，新SHA独立验收。下一步Shell队列/全屏/Inspector剩余导航与Phase7出口；Phase8–11仍未完成。以下为历史记录。

当前Phase7F2C：[计划](phase_7f2c_shell_favorite_plan.md)/ADR093/[报告](phase_7f2c_shell_favorite_report.md)。五处AdaptiveRoot接根收藏与路由事件；底栏组件跨主导航存活时用事件代数/选中页面/布局尺寸撤销旧收藏，另有实时ModalRoute/活动/面积检查。独立busy、未知语义及有界滚动反馈，不新增I/O/真值；手机/窄栏/Inspector不加心形。14新Widget/3 Golden/1 Node，最终1671 Flutter/138 Node、188 Golden（17旧图心形状态精确更新、168旧图不变，20变更逐张查看）、511文件格式/严格分析/生成迁移及Android预检通过。分支codex/shell-current-favorite-ui，base codex/player-current-favorite-ui；前置a4faf90双CI34706094820/34706097249均SUCCESS，本批新SHA另验。下一步Shell剩余入口与内联遮罩许可/Phase7出口核查；Phase8–11未完成，非上线。以下为历史记录。

当前Phase7F2B：[计划](phase_7f2b_player_favorite_plan.md)/ADR092/[报告](phase_7f2b_player_favorite_report.md)。独立播放页三端借同一根收藏，复用F2A反馈；已知值才展示、保存与播放busy独立、原投影/目标/页面代数许可，不新增真值。新增14 Widget/4 Golden/1 Node，完整1654 Flutter/137 Node、185 Golden（181旧图不变）、508文件格式/严格分析、生成零漂移及Android Debug资产许可v2签名通过。分支codex/player-current-favorite-ui，base codex/lyrics-current-favorite-ui；本批新SHA云端另验。前置d29356c双CI34704863898/34704867239已SUCCESS。下一批底栏收藏；Phase7整体/8–11未完成，新安装仍空库，非正式上线。以下为历史记录。

当前Phase7F2A：[计划](phase_7f2a_lyrics_favorite_plan.md)/ADR091/[报告](phase_7f2a_lyrics_favorite_report.md)。AppRouter借根收藏，歌词Dock按已知状态显示，独立保存忙态不锁播放/返回；捕获原投影/目标/页面代数，过期操作和失败回调不重解释。手机遵守原CSS隐藏心形，无存储预览保持原样。新增12 Widget、3 Golden、1 Node；1636 Flutter/136 Node、181 Golden（178旧图不变）、505文件格式/严格分析和Android Debug资产许可v2签名通过。分支codex/lyrics-current-favorite-ui，base codex/current-track-favorite-core；新提交云端另验。前置4302cbb的push34703279070/PR34703282153均SUCCESS。下一批播放页/Shell收藏，Phase7整体及Phase8–11尚未完成，不是已上线。以下为历史记录。

当前增量Phase7F1：根PlaybackFavoriteController/State/Actions借现有播放与CollectionRepository，跟随准确QueueSnapshot/current entry完整TrackRef；未知状态不默认false，空当前项不查询，首次选中条目再启动，位置变化不重读。显式目标/busy/页面许可前后复核，旧快照/失败不能重用；接受后切歌或关闭仍排空原引用写入，只有Repository流更新显示，无乐观翻转。
分支`codex/current-track-favorite-core`，基线449b1ff，Stacked Draft base=`codex/system-playlist-queue-actions`；[计划](phase_7f1_current_favorite_plan.md)、ADR090与[报告](phase_7f1_current_favorite_report.md)。新增27单元/4真实SQLite/2Node；最终1621 Flutter/135 Node/501文件格式/严格分析、生成迁移与Android35.9秒Debug资产许可v2签名通过，178旧Golden及Schema/依赖/平台/原资产均未改。初次6旧回归因过早订阅失败，修复空库惰性启动后原查询数量/关闭断言保持并通过；两处Node顺序精确新增根屏障。
前置#79的449b1ff双CI SUCCESS，Linux1412、Windows178Golden/2Runner/65文件Debug包与Android资产许可签名通过，已回填。当前批核心尚未接三端按钮，下一批7F2做播放区/歌词Dock收藏与页面许可/反馈；Phase7其余和Phase8–11仍待完成，新安装空库，无本批设备安装/出声或发行验收。以下为历史记录。

当前增量Phase7E5E：我喜欢/最近播放三端菜单接下一首/添加队列及E5B共享反馈，准确窗口/条目/读取意图与根快照授权；失效/未解析引用可入队但不可播放，独立新队列ID不复用历史ID。刷新/换组/根替换/路由/尺寸/零面积/关闭后旧菜单和遮罩无效；正常尺寸重发请求，历史清除确认独立且旧确认不可复用。入队不改收藏/历史/当前音频，busy和接受后SQL排空、跨页显式同ID重试均覆盖。
分支`codex/system-playlist-queue-actions`，基线`a2a8b41`，Stacked Draft base=`codex/playlist-queue-actions`；[计划](phase_7e5e_system_queue_plan.md)、ADR089、[总进度及报告](phase_7e5e_system_queue_report.md)。新增12单元/21Widget/8真实SQLite/5Golden和1Node，最终1590 Flutter、133 Node、178Golden、496文件格式、严格分析、生成/迁移及Android Debug资产/许可/v2签名通过。8旧图精确更新/165旧图不变，13变更逐张查看，保留SDK XML/Java警告。
前置#78 head a2a8b41双CI SUCCESS，Linux1371/Windows173Golden和2Runner/65文件正式入口包、Android资产许可签名通过，报告和PR已回填；本批新SHA云端另验。仍在Phase7，播放区剩余入口/收藏接线及整体出口继续核查；Phase8导入/扫描/授权与Phase9–11未完成。没有本批设备安装/出声或正式发行，新安装仍为空库。以下为历史记录。

当前增量Phase7E5D：自建歌单的Phone/Tablet/Windows菜单接下一首/添加队列；许可捕获准确PlaylistContent窗口/条目及读取意图，根分配独立队列ID，保留重复与未解析/失效软引用，不改歌单顺序/内容或自动播放。跨尺寸重发菜单请求，刷新/换组/根替换/覆盖/零面积/关闭撤销旧回调；dispose清空旧菜单和返回焦点，修复旧关闭回调的setState-after-dispose。共享busy/安全失败/显式同ID重试与成功提示沿用E5B组件。
分支`codex/playlist-queue-actions`，基线`5ec9d63`，Stacked Draft base=`codex/catalog-queue-actions`；[计划](phase_7e5d_playlist_queue_plan.md)、ADR088及[报告](phase_7e5d_playlist_queue_report.md)。新增9单元、17Widget、4真实SQLite、4Golden和1Node；完整1544 Flutter/132 Node、491文件格式、严格分析、生成/迁移通过；173Golden仅1旧菜单图更新、168旧图不变，五张变更逐张查看。原资产/依赖/平台/Schema零变化，Android Debug预检通过。
前置#77精确5ec9d63的push34690651343/PR34690666913均SUCCESS，Linux1341/Windows169Golden及2Runner/65文件正式入口包、Android资产/许可/签名通过，已回填。新SHA云端另验；系统歌单等入口及Phase7其余、Phase8–11仍未完成，无本批实机安装/出声或正式发行。

当前增量Phase7E5C：专辑/艺人详情三端歌曲菜单已接下一首/添加队列，AppRouter注入同一根QueueController；准确Track/读取意图许可和页面代数防止旧动作，跨尺寸保留菜单但重新捕获许可；艺人Tab切换、刷新、隐藏/覆盖/零面积、关闭撤销旧回调。借E5B成功提示/busy/安全失败/显式重试与查看队列，不自动播放、不打断当前音频；歌单选择器返回和旧提示身份覆盖。
分支`codex/catalog-queue-actions`，基线`4f50819`，Stacked Draft base=`codex/library-queue-actions`；[计划](phase_7e5c_catalog_queue_plan.md)、ADR087及[报告](phase_7e5c_catalog_queue_report.md)。新增8单元、19Widget、4真实SQLite和3Golden；完整1510 Flutter/131 Node、486文件格式、严格分析、生成/迁移通过；169Golden中仅3旧菜单图精确更新，其余163旧图不变。原资产/依赖/平台/Schema无变化。
前置E5B精确4f50819的push34689627222与PR34689643919均SUCCESS，Android/Windows真实构建完成，#76及报告回填；本批新SHA云端另验。尚未完成其他歌单入口、Phase7其余与Phase8–11，无本批实机安装/音频出声或正式发行验收。

当前增量 Phase7E5B：三端音乐库歌曲菜单已接入下一首/添加队列，根QueueController准备唯一entry ID及不可变编辑；菜单绑定准确Track对象/源读取意图/根快照。根变化、刷新、离页、零面积、尺寸、关闭菜单撤销旧回调；已接受写入排空，缺失文件可添加软引用但不会变可播放。成功页内提示、共享busy/安全失败、跨页显式重试/知悉与打开队列均接线；返回歌单选择器后恢复菜单权限，焦点不抢后台。
分支`codex/library-queue-actions`，基线`f9590f2`，Stacked Draft PR base=`codex/queue-insert-intents`，[计划](phase_7e5b_library_queue_plan.md)、ADR086与[报告](phase_7e5b_library_queue_report.md)。新增3工厂/6源许可单元、15Widget、2真实SQLite菜单、5Golden和1Node；完整1476 Flutter/130 Node、481文件格式、严格分析、生成/迁移通过。166Golden通过，仅1旧菜单图精确更新、160旧图不变；原资产/Schema/依赖/平台无改动。
E5A精确`f9590f2`两组源码/Android/Windows CI SUCCESS，#75已回填；本批新SHA云端另验。本批不是全站菜单完成，专辑/艺人详情、自建/系统歌单等歌曲入口后续复用，Phase7其余与Phase8–11仍待完成，无本批真机安装/出声/发行验收。

当前增量 Phase 7E5A：QueueEdit.addToEnd/playNext 复用唯一根授权、busy、同快照显式重试与关闭排空；拒绝重复 entry ID，保留重复完整 TrackRef/addedAt/current，空队列不自动选中/播放。成功持久化后扩展而不重排原随机序列，最近指定下一首优先，后续末尾添加保持该优先序；旧低层接口复用同一顺序策略。
分支 `codex/queue-insert-intents`，基线 `8d9b4da`，Stacked Draft PR base=`codex/queue-drag-sorting`；[计划](phase_7e5a_queue_insert_plan.md)、ADR085 与[报告](phase_7e5a_queue_insert_report.md)先后记录。新增10模型、18核心、4实际SQLite测试与1Node；完整1445 Flutter/129 Node、473文件格式、严格分析、生成/迁移通过；161旧Golden与原始资产/Schema/依赖/平台未改。
E4 `8d9b4da` 双组云端源码/Android/Windows SUCCESS，#74与报告回填；新SHA云端单独验证。本批尚未增加按钮，下一批E5B接“添加到队列/下一首播放”菜单及安全反馈。随机顺序沿用非持久化边界，物理队列/current跨启动恢复；Phase7其余与Phase8–11仍未完成，不是日常可用发行版。

当前增量 Phase 7E4：独立队列页已支持 Android 手机/平板长按和 Windows 原始手柄鼠标拖动；原生惰性列表、落点间隙、边缘自动滚动及无障碍排序接入根 QueueEdit，不创建第二份队列。归一化索引映射原根锚点，组尾保留未加载内容；拖拽不改变当前项、不重载播放。旧视图/根/尺寸/路由/取消回调失效，Windows 连续键盘上下移焦点保留。
分支 `codex/queue-drag-sorting`，基线 `32edb5b`，Stacked Draft PR base=`codex/native-queue-route`；[计划](phase_7e4_queue_drag_plan.md)、ADR084 与[报告](phase_7e4_queue_drag_report.md)记录范围。新增 8 单元、16 Widget、3 Golden、1 Node；2 既有真实 SQLite 页面测试升级为指针拖拽。完整 1413 Flutter / 128 Node、469 文件格式、严格分析、生成/迁移通过；10 张受影响旧 Golden 精确更新并逐张检查，148 张旧图及原始资产/Schema/依赖未改。
E3 的精确 `32edb5b` 两组云端源码/Android/Windows 均 SUCCESS，#73 已回填。E4 云端按新提交单独核验，不能用 E3 代替。当前新增能力仅队列拖拽；添加/下一首入口及 Phase 7 其余能力、Phase 8–11 仍未完成，新安装仍为空库。没有本批真机安装/出声或签名发行验收。

## 之前的阶段记录

当前增量 Phase 7E3：已实现独立 `/queue` 与三端原生布局，复用根有界系统队列读取和 QueueController 编辑反馈。准确播放重复条目、上下移动/跨组锚点、不可用项移除、当前项/清空确认、忙态、安全失败、跨页重试/知悉及返回均接线；根快照/投影/离页/尺寸变化撤销旧回调，刷新投影不误取消已接受的播放。
分支 `codex/native-queue-route`，基线 `9a05089`，Stacked Draft PR base=`codex/queue-edit-feedback`，[计划](phase_7e3_native_queue_plan.md)与 ADR083 先于实现。新增 7 单元、15 Widget、2 实际 SQLite 页面回归、12 Golden、1 Node；完整 1386 Flutter / 127 Node、464 文件格式、严格分析、生成/迁移通过。构建及新提交云端结果见[报告](phase_7e3_native_queue_report.md)。旧 146 Golden、原始资产、Schema/依赖未改。
前置 E2 两组云端常规任务已 SUCCESS，#72 与报告回填；不以旧结果代替本批验收。本批上下移动已可用，拖拽及更多添加入口未完成；Phase 7 其余与 Phase 8–11 继续开发。新安装仍为空库，尚未做本批真机安装/出声或签名发行。

当前增量 Phase 7E2：现有根QueueController新增submitEdit结果、共享editBusy、跨页面安全失败、同快照retryEdit和按失败身份知悉；重复提交返回busy，旧快照/离页取消，其他成功不抹旧失败。结果Future在通知前注册，监听者可重入提交/关闭，根释放引擎/存储前等待队列反馈结算。
新增22项模型/反馈单元及3项真实SQLite测试、1项Node门禁；最终1350 Flutter（146旧Golden未改）、126 Node、454文件格式、严格分析、生成/迁移及Android Debug资产/许可/v2单签名者预检通过。两处旧关闭顺序门禁准确纳入queue.close，未放宽检查。
分支`codex/queue-edit-feedback`，基线3d89cc8，Draft PR base=`codex/queue-edit-intents`，[计划](phase_7e2_queue_edit_feedback_plan.md)及ADR082先于共享API，[报告](phase_7e2_queue_edit_feedback_report.md)记录证据。本批未新增UI、Schema/依赖/原生能力；下一阶段接独立队列视图与管理操作。
前置3d89cc8的push34300327819及PR34300332649均SUCCESS，#71回填，Windows146Golden、2真实Runner/65文件正式入口Debug包、Android资产/许可/签名通过。本批新SHA云端另验；新安装仍为空库，Phase7剩余与Phase8–11仍未完成。

## 历史阶段记录

当前增量 Phase 7E1：QueueEdit纯模型和根editQueue已接入既有QueueController/PlaybackController，绑定不可变根快照，按entry ID移除、锚点排序及清空；同时间/同值替换与当前项改变仍使旧确认失效。执行前、可能等待的停止后复核授权，已接受SQL排空，Facade通知内关闭安全。
分支`codex/queue-edit-intents`，基线dff7c32，Draft PR base=`codex/fullscreen-page-lifecycle`；[计划](phase_7e1_queue_edit_intents_plan.md)与ADR081先于共享API，[报告](phase_7e1_queue_edit_intents_report.md)记录测试/构建边界。新增12模型、19核心、7真实SQLite回归与1项Node门禁；无UI、Golden、Schema/依赖/平台变化。
最终1325 Flutter（146旧Golden未改）、125 Node、450文件格式、严格分析、生成/迁移及Android Debug资产/许可/v2单签名者预检通过。本批云端结果按新SHA独立核对。
尚未接独立队列管理页及其忙态/失败反馈；当前项移除/清空沿用停止并选择相邻项但不自动播放的策略，停止后保存失败保留旧队列但不自动重播。Phase7其余页面能力及Phase8–11仍待后续，新安装仍为空库。
前置dff7c32的push34297862194及PR34297866163均SUCCESS，#70回填；Windows146Golden、2真实Runner/正式入口重建和Android资产/许可/签名通过。本批新SHA云端另行核对，Android真机系统栏/多显示器DPI仍未验收。

当前增量 Phase 7D2：正式播放/歌词页接入唯一根全屏协调器，使用原始fullscreen/fullscreen-exit SVG及YYButton；Windows F/分层Esc、隐藏且保留状态的标题栏，Android进页自动沉浸请求均已接线。真实Navigator顶层含弹层、后台/零尺寸、原生中断和关闭撤销旧意图，不重建播放器或歌词状态。
新增18项单元、16项Widget、8张Golden与1项Node检查；最终1287 Flutter（146 Golden，138旧图未改）、124 Node、445文件格式、严格分析、生成/迁移及Android Debug资产/许可/v2签名预检通过。
分支`codex/fullscreen-page-lifecycle`，最终基线`e68fffab81a7e787f31d6a24bc6136410d4bc3af`，Stacked Draft PR base=`codex/fullscreen-maximized-restore`；[计划](phase_7d2_fullscreen_pages_plan.md)与ADR080先于共享改动，[报告](phase_7d2_fullscreen_pages_report.md)记录本批边界，新提交GitHub云端状态见对应PR。
开发中发现前置D1 `ba68cdd`最大化退出几何失败，隔离修复后才接回页面分支。[PR #69](https://github.com/Z-YO-YI/YYMusic/pull/69)的e68fffa两组源码/Android/Windows已SUCCESS，2项真实Runner通过；初始#68失败不改写为成功，不以D1原生证据代替D2页面或Android实机验收。
尚非完整Phase7：真实封面/收藏、独立队列管理仍待后续；Phase8导入/扫描/授权、Phase9来源及Phase10–11后台/系统媒体/发行未完成。默认新安装仍为空库，Debug不是日常可用发行版。

当前增量 Phase 7D1：已实现受限的原生全屏协议与Dart串行适配器，Windows保存/恢复原始WINDOWPLACEMENT及样式，Android保存/恢复系统栏；原生生命周期可自行恢复，不依赖页面仍然存活。
新增16项Dart通道回归、3项Node检查与1项真实Windows全屏集成用例；最终1245 Flutter（138旧Golden未改）、123 Node、437文件格式、严格分析、生成/迁移零漂移及Android Debug包/许可/v2签名预检通过。
分支`codex/native-fullscreen-gateways`，[计划](phase_7d1_fullscreen_gateways_plan.md)、ADR079先于合同变更，[报告](phase_7d1_fullscreen_gateways_report.md)记录实现及验证边界。新Windows编译/原生测试等待本批精确GitHub CI，Android只验证了编译/打包，未运行真机沉浸恢复。
正式页面尚未注入本批通道，没有启用F/全屏按钮或自动沉浸；下一增量接根生命周期与页面入口。Phase7完整队列、Phase8导入/扫描、Phase9来源和Phase10–11后台/发行仍未完成，默认新安装仍为空库。
前置7C2实现`0a9e6d0`两组源码/Android/Windows已SUCCESS，#67与报告回填；不借其成功替代本批平台变更验收。

当前增量 Phase 7C2：正式 `/lyrics` 已从占位页替换为三套原生布局，复用唯一根歌词/播放状态与惰性正文。同步/纯文本/翻译开关、真实 Dock、读取/无歌词/空库/安全失败重试和返回关系已接线；元数据长按及 Windows L 入口不改变普通单击或 Ctrl+L。
根跳转增加可撤销页面意图检查；处理重复打开尚未构建的 Navigator 页面、十轮来回/跨队列恢复、覆盖/零面积/卸载与晚到读取；不停止音频或新建媒体时钟。
新增30项Widget、11张完整页面Golden和1项Node架构检查；最终验证与精确GitHub结果见[7C2报告](phase_7c2_native_lyrics_report.md)，分支`codex/native-lyrics-route`，计划及ADR-078先于实现。
最终1229 Flutter（138 Golden）、120 Node、435文件格式与严格分析通过；Android Debug/48资产/完整许可/v2单签名者预检通过。本轮没有实机安装或出声验证。
本批固定深色兜底，不含真实封面提色、OS全屏/Android沉浸、收藏或独立队列管理；Phase8–11仍待实施。前置`aad2d06`双组源码/Android/Windows全部SUCCESS，已回填#66，不借用其结果表示本批云端通过。

当前增量 Phase 7C1：原生歌词正文组件使用双向惰性 Sliver、真实根行号/位置与快照回调，按实际高度居中；一万行远跳和手动滚动一万像素后的恢复均验证。触摸/滚轮/焦点浏览暂停跟随，停止五秒或显式恢复后继续，时序间隙不跳回开头。
新增 21 Widget、7 Golden 与 1 Node 门禁；减少动态禁用行缩放，纯文本有真实只读语义；仅 3 张受修正影响的旧歌词基线精确更新，其余 117 旧图不变。无 Schema/依赖/平台/原始资产变化。
最终 1188 Flutter（127 Golden）、119 Node、428 文件格式与严格分析通过；Android Debug/48 资产/完整许可/v2 单签名者预检通过，实机安装/出声及本批云端结果独立记录。
分支 `codex/lyrics-follow-viewport`，[计划](phase_7c1_lyrics_viewport_plan.md)与[报告](phase_7c1_lyrics_viewport_report.md)。前置 `af1b07b` 双组源码/Android/Windows 均 SUCCESS 并已回填 #65；本批按新 SHA 独立验收。
正式 `/lyrics` 路由尚未接线；本批不是完整歌词页或整体 Phase 7 完成。下一批接三套页面、顶部/Dock、翻译入口及加载/空/错/返回关系；平台沉浸和独立队列管理继续分批。以下为历史记录。

当前增量 Phase 7B1：`/player` 已替换工程占位页，三端独立布局借用同一根播放投影，底栏元数据打开；播放/切歌/随机/循环/进度/音量和已有当前队列浏览均已接线。
切歌、覆盖/隐藏/零面积、卸载及同类布局内尺寸变化撤销旧回调；排队 Seek 执行前再次授权。修复 imperative push 时路由活动判断、快速重复打开与直接路由系统返回；不停止根音频。
1160 Flutter（新增 25 Widget、8 Golden）、118 Node、120 Golden、425 文件格式、严格分析及 Android Debug/48 原始资产/完整许可/v2 签名通过；112 旧图、Schema/锁/平台/原始资产未改。
分支 `codex/native-player-route`，[计划](phase_7b1_native_player_plan.md)与[报告](phase_7b1_native_player_report.md)。前置 7A `ffb83e6` 两组 GitHub 源码/Android/Windows 均 SUCCESS；本批新提交云端验证独立核对，不自动合并。
本批不是完整 Phase 7：封面仍为明确兜底，系统沉浸/原生歌词与独立队列管理待开发。真实导入/扫描、后台媒体、实机验收与正式发行仍未完成，新安装没有可导入歌曲的入口。以下为历史记录。

当前增量 Phase 7A：纯 Domain 偏移时间轴与根 LyricsController 已接入依赖图，按完整来源/队列身份单通道读真实歌词；位置不重读，隐藏/刷新/切歌撤销旧快照 Seek，根关闭排空读取与跳转。
1127 Flutter（新增 44）、117 Node、112 旧 Golden、418 文件格式和严格分析通过；Android Debug/48 资产/六音频包完整许可/v2 签名预检成功，Schema/锁/平台/原始资产不变。
分支 `codex/lyrics-synchronization-core`，[计划](phase_7a_lyrics_synchronization_plan.md)与[报告](phase_7a_lyrics_synchronization_report.md)；本批精确 GitHub 构建在 push/PR 后核对。前置 J2 `1d24bdc` 两组源码/Android/Windows已 SUCCESS，#63 保持 Draft 未合并。
下一步原生独立播放器/歌词/队列接线；尚无歌词自动滚动或沉浸 UI，真实导入/扫描/后台与正式发行仍未完成。以下为历史记录。

当前增量 Phase 6J2：正式设置页提供原生外观/关于，三端布局共用根主题和持久化状态，真实保存/读取失败重试；颜色草稿、选区与滚动跨布局保留，失效页面不接受旧操作。
最终 1083 Flutter（新增 19 Widget/8 Golden）、116 Node、112 Golden、412 文件格式和严格分析通过；104 旧图不变，Schema/锁文件/平台不变，最终 Android Debug/包内许可/资产/v2 签名预检通过。
本批分支 `codex/native-settings-surfaces`，[计划](phase_6j2_native_settings_plan.md)与[报告](phase_6j2_native_settings_report.md)。GitHub 精确新提交构建在 push/PR 后核对；前置 #62 两组 Android/Windows 已成功且回填。
没有真实文件扫描、后台媒体或正式发行；下一步 Phase 7。以下为保留的历史阶段记录。

## 历史阶段记录

当前增量Phase6J1：外观设置以五键白名单和单事务保存于既有app_settings表，同一数据范围/唯一YYAppearanceController；显示模式、预设/自定义色、glassEnabled/reduceMotion已真实持久化。
根启动先恢复，不回写默认；早到用户变更优先，连续修改单worker合并，读取失败不覆盖，保存失败安全保留/可重试，根关闭排空并保护通知栈内重入退出。
最终1056 Flutter（新增27：15 Controller/9 SQLite/1模型/2启动Widget）、115 Node、404文件格式、严格分析通过；104旧Golden字节不变，Schema/依赖/平台无变化，Android Debug预检通过。
见[Phase6J1报告](phase_6j1_appearance_persistence_report.md)，分支`codex/appearance-settings-persistence`。对应精确提交云端验收另行核对；前置I2 `b1adbce` 的push/PR源码、Android、Windows已全部SUCCESS并回填。
本批是外观存储/根状态，不是完整原生设置页面；下一批Phase6J2接设置界面，之后仍有Phase7–11。无新的扫描、授权、后台或假播放开关。下方是历史记录。

当前增量Phase6I2：音乐库“本地”已接入原生统计/20条目录分页、配置/历史标记及加载/空/错误重试；Phone/Tablet/Windows独立布局，共用同一LocalMusicController和数据库。
先监听再读、单一查询通道、旧回调隔离、末页删除回退，隐藏/覆盖/零尺寸撤销读取，根关闭排空查询与订阅取消。
真实路由回归发现并修复布局替换时旧Panel误停新状态，稳定GlobalKey迁移唯一Element；不复制播放器或数据库。
最终1029 Flutter（104 Golden：新增6/更新1/原97不变）、113 Node、397文件格式、严格分析零问题；生成/迁移/指纹/许可与本地Android Debug资产/签名通过。
见[Phase6I2报告](phase_6i2_local_music_surfaces_report.md)，分支`codex/local-music-surfaces`；对应精确提交的GitHub双平台另行验收，不借用前置结果。
前置I1 `79540d0` / Draft PR #60 的push/PR源码、Android、Windows已全部SUCCESS，完成日志和Windows产物已回填。
本阶段只读已保存索引，不获取系统权限或验证文件，默认新安装为空；下一步Settings，之后Phase7–11，真实导入扫描仍属Phase8。以下均为历史阶段记录。

当前增量Phase6I1：LocalLibraryRepository由现有DriftLibraryRepository实现，同一SQL读取本地五类可用性计数/总时长、全部文件夹计数及最多200行窗口。
同名稳定排序，超出末页仍保留真实统计；摘要不读取路径/Content URI/grantRef，启用配置与历史扫描记录不代表当前系统授权。
轻量表变更流不执行曲库查询，支持协作取消及安全错误；没有新增Schema、平台操作、UI接线或生产Fixture。
新增16 Flutter（13 SQLite/2模型/1Fake），最终1000 Flutter/111 Node、严格分析零问题；385文件格式零差异、98旧Golden未改、Android Debug预检通过。
见[Phase6I1报告](phase_6i1_local_library_overview_report.md)，分支`codex/local-library-overview`。下一步本地音乐原生页面；真实导入/授权/扫描仍属于Phase8。
前置H14 `2b756d1` / Draft PR #59 两组精确源码、Android、Windows均SUCCESS，报告已回填。下方旧阶段记录保留历史归属。

当前增量Phase6H14：喜欢菜单可取消完整来源引用（含失效/未解析）；最近页原生确认清除，三端共用根SystemPlaylistWriter和H13有序历史通道。
只改收藏/历史，不删除歌曲文件、其他收藏、队列或自定义歌单；失效/旧快照/遮挡/最小化拒绝旧动作。
写入先登记后调用依赖，重复提交保护、离页失败保留、返回可见，根关闭等待真实SQLite删除排空。
984 Flutter（98 Golden，新5/改4/原89不变）、108 Node与严格分析通过；新增33项回归，另扩展2条实际SQLite页面用例。
分支`codex/system-playlist-management`，结果见[Phase6H14报告](phase_6h14_system_playlist_management_report.md)。
下一步继续Phase6 Local Music/Settings；系统批量播放及队列详细管理仍待后续，不代表Phase6–11或正式上线完成。
默认新安装仍为空库，无导入流程；前置H13 `891a9f1` 已核对两组精确源码/Android/Windows成功。
以下旧阶段文字保留历史归属。

当前增量Phase6H13：根播放器按playing位置前进确认后自动记录历史；最近20首、完整来源去重、同毫秒/回拨置顶。
暂停恢复/缓冲/普通seek不重复；保存失败与音频独立，最近页可重试最新失败或知悉旧失败。
首页已有确认清除进入同一串行通道，避免旧待写记录清除后复活；关闭等待历史读写及清除排空。
951 Flutter（93 Golden，新增2/原91不变）、106 Node、严格分析通过；新增44项回归。
分支`codex/playback-history-recording`，本机预检与精确GitHub结果见[Phase6H13报告](phase_6h13_playback_history_report.md)。
Phase6仍在Playlists收尾，随后Local Music/Settings；Phase7–11、真实导入、设备/网页对照和发行仍未完成。
默认新安装为空库，不能以Fake后端测试或Debug构建声称可日常听歌。以下旧阶段描述保留历史归属。

当前增量Phase6H12：音乐库三系统入口、闭合枚举路由、Phone/Tablet/Windows独立原生布局，共用H11会话与唯一根播放器。
20→200条窗口、上下组、空/加载/错误重试、保留不可用引用；没有复制队列、伪造计数或创建系统父记录。
收藏/最近通过完整TrackRef复用或追加根队列，队列通过真实entry ID与完整引用校验播放，重复项不会归并到第一项。
离页/覆盖/零尺寸/刷新/失败撤销待开始播放，已开始音频继续；自己的current ID写入触发刷新不自取消。
907 Flutter（91 Golden：新7、受影响更新3、原81未改）/103 Node通过，严格分析零问题；新增39项动作/界面/SQLite/视觉测试。
分支`codex/system-playlist-surfaces`，Android预检/精确云端结果见[Phase6H12报告](phase_6h12_system_playlist_surfaces_report.md)。
前置Phase6H11 `428a49f`、Draft PR #56两组GitHub源码/Android/Windows成功，未合并。
下一步接真正开始播放后的历史记录和剩余系统动作；本批只读已有最近记录，不以测试Fixture冒充自动历史。
之后仍有Local Music/Settings，不代表整个Phase6完成；运行时失效的完整跳过策略仍待Phase7。
详情真实封面、实时REST、导入/恢复、完整播放器、网页对照和上线仍未完成，默认新安装仍是无Fixture的空库。
下方旧阶段记录保留历史归属。

更新：2026-09-05。当前在 Phase 5 三套 Shell 接线；Phase 0—4 已有实现与审计产物，Phase 2 仍欠网页截图对照。Phase4L 已在同一实现提交验证 Android WAV/content URI/HTTPS 与 Windows WAV/HTTPS。Phase4G 的 `media_kit` 分发审计未通过，Phase4H 已移除该活动候选。许可材料、查看入口及 ADR-044 工程选型已完成，默认入口不再使用 UnavailableAudioEngine；独立测试 Graph/main_dev 仍保留不可用后端。正式 Shell 底栏已可控制根播放器，业务曲库/导入、完整播放页面与 Phase5 其余部分/Phase6—11 未完成，不能作为可用音乐应用交付。下文旧阶段的未接线描述保留历史归属。

Phase4J最新增量：`25747bc`的GitHub Profile完整诊断包已在本机Windows进程连续两次通过原始本地WAV测试，
此前Windows小批A运行证据已补齐；本机缺Debug CRT导致的`0xC0000135`没有被掩盖。
该提交的GitHub Android/Windows Debug均成功，对应 Draft PR #26；最后文档提交 `ca7b69d` 的两组 CI 也已成功。
Phase4K 实现 `33a0b3c` 已通过 Android WAV/content URI 两项测试和标准双平台 Debug，Draft PR #27 未合并。
前一批为 `codex/native-https-validation` 的 Phase4L：实现 `8c4aa6e` 的 Android API36 三来源原生、标准 push/PR 双平台 Debug、完整 Windows Profile 构建四条运行均成功。同一 Profile 包在本机两个新目录各执行本地 WAV/HTTPS 两项测试，均退出0，64项运行文件前后指纹不变。完整本地255项 Flutter、46项 Node 通过；Draft PR #28 未合并。Phase4F 的无Header HTTPS 运行缺口已补齐，最终选型/NOTICE 和正式接线仍待完成。
下文无端点/旧分支描述保留历史归属；原生证据见[Phase4L报告](phase_4l_native_https_report.md)，当前进度以下面的Phase4M为准。

Phase4M本批已完成：`codex/audio-license-foundation`、实现`2143ecf`/参数修正`c0e3706`、Draft PR #29，增加六个音频Dart包的
完整许可原文清单与源码/双平台打包门禁。本地255项Flutter、51项Node、Android Debug/48资产/六包许可/
v2签名通过；Windows既有真实Profile包只做新增许可复核。初始实现和最终修正版各两组GitHub三job均通过，最终修正的源码/两端包内许可日志已复核，
原生Maven传递NOTICE、用户可见许可页和生产接线仍未完成，详见[Phase4M报告](phase_4m_audio_license_report.md)。

| 阶段/能力 | 状态 |
| --- | --- |
| Phase 6H8 大歌单分组 | 同一有界SQL快照按200条组前后浏览、范围/末组删除恢复、原生分页与关闭/过期保护；774 Flutter/84 Golden/96 Node，旧81张不变；无Schema/依赖变化 |
| Phase 6H7 新建并添加 | 一个事务/根命令创建父歌单与首条引用，三端独立名称表单、IME/旧回调保护、失败回滚/关闭排空；754 Flutter/81 Golden/94 Node；无Schema/依赖变化 |
| Phase 6H6 添加到已有歌单 | 原生元数据选择器、显式名称筛选、根原子追加/排空、当前快照/覆盖路由/IME保护；718 Flutter/81 Golden/92 Node；不提供选择器内创建，200个匹配上限需缩小筛选 |
| Phase 6H5 原生歌单内容管理 | 三套布局/原生路由与菜单、单首根播放、原子移除/上下移动、过期快照保护及离页写入反馈；680 Flutter/78 Golden/90 Node；前200条上限明确，添加/播放全部/随机/系统歌单待开发 |
| Phase 6H4 歌单内容会话 | 单SQL一致窗口、实时失效刷新、缺失引用保留、旧响应隔离/根排空；650 Flutter/73 Golden未改/88 Node；不新增UI，最多200条可见前缀明确标记上限 |
| Phase 6H3 歌单条目命令 | 原子追加/移除/锚点移动、ID/系统/来源保护、回滚与根关闭排空；615 Flutter/73 Golden未改/86 Node，本机Android通过；歌曲管理界面仍待接线 |
| Phase 6H2 原生歌单编辑 | 三端创建/改名/确认删除、原生文本/IME、草稿代次/跨断点、关闭后失败反馈；572 Flutter/73 Golden/84 Node，本机Android通过；条目管理待开发 |
| Phase 6H1 歌单写入基础 | 原子create-only/rename-existing、系统保护、名称校验、共享根命令和关闭排空；551 Flutter/70 Golden未改/82 Node，本机Android通过；尚无编辑界面 |
| Phase 6G4 详情曲目菜单 | 三端受控原生菜单、不可用曲目收藏、按需读取/独立重试、离页写入排空及键鼠/返回/焦点；531 Flutter/70 Golden/80 Node，本机Android通过；无下载或第二收藏存储 |
| Phase 6G3 搜索详情入口 | 明确原生按钮、完整来源引用、连续返回/搜索滚动/条件/键盘焦点保持、无隐式历史/播放；512 Flutter/67 Golden/78 Node，本机Android通过；未扩展搜索/来源合同 |
| Phase 6G2 原生详情 | 音乐库入口、三端布局、完整来源返回栈、分页/重试及根播放；506 Flutter/67 Golden/77 Node，本机Android通过；搜索入口/收藏菜单/封面和后续业务待完成 |
| Phase 6G1 详情状态层 | 固定来源身份摘要、独立有界分页、刷新取消、根会话排空；479 Flutter/61 Golden未改/75 Node，修复三个目录投影的短页容量；路由/三端详情页面下一批接入 |
| Phase 6F 原生音乐库 | 五分类/三布局、排序/来源类型/状态筛选、分页/惰性构建、根播放/收藏/菜单；452 Flutter/61 Golden/73 Node，b72413e双组云端成功；详情、歌单编辑/系统歌单与导入/恢复未完成 |
| Phase 6E 音乐库浏览数据 | 类型化排序/组合筛选、来源隔离详情、一条只读SQL先分页再展开关联；423 Flutter/55 Golden未改/71 Node；音乐库UI与导入/恢复仍待后续 |
| Phase 6D 原生搜索 | 三端布局、根数据/播放器接线、防抖/IME、六筛选、独立分页/错误、历史与安全取消；407 Flutter/55 Golden/69 Node；实时在线搜索、导入、详情与网页对照仍未完成 |
| Phase 6C 搜索数据层 | 正式SQLite单语句分页/源筛选、合作式取消、20条持久历史及安全错误；该批379 Flutter/67 Node，49张Golden不变；Phase6D已接原生UI，REST仍待后续 |
| Phase 6A/B 首页 | v2首次入库时间与保留旧数据迁移；三套原生布局、真实投影、单根播放、确认清除历史和关闭排空已实现；359 Flutter/49 Golden/65 Node，本批报告记录精确构建状态；导入/来源配置、真实封面与网页对照未完成 |
| Phase 0 输入身份、源码审计、合成与映射 | 已形成可复核产物，结果见 phase_0_report.md |
| Phase 1 Flutter 工程骨架 | 已实现路由/DI/三个Shell/runner/测试/CI；GitHub Android/Windows Debug已通过，本机Windows仍待UAC，见phase_1_report.md及ci_reference_audit_fix.md |
| Phase 2A Android设计基础 | 已接入主题/字体/44SVG/首批控件及原生预览，见phase_2_android_report.md |
| Phase 2B Android导航与控件 | 手机/平板导航已驱动路由，Slider和七种Artwork占位已加入Gallery；见phase_2b_android_report.md |
| Phase 2C Android输入与选择 | SearchField、SegmentedControl、Toggle及Gallery已实现/测试；见phase_2c_android_report.md |
| Phase 2D Android内容组件 | AlbumCard、TrackTile及Gallery Fixture已实现/测试；见phase_2d_android_report.md |
| Phase 2E Windows导航基础 | 42工具区、240/72侧栏、1440/1024/840布局、跨平台Gallery及Windows Chrome Fixture已实现/测试；见phase_2e_cross_platform_report.md |
| Phase 2F 跨平台播放器表面 | Mini64与Desktop88/76受控组件、Android/Windows Gallery Fixture已实现；真实音频和正式Shell接线不在本阶段，见phase_2f_player_surfaces_report.md |
| Phase 2G 跨平台弹层原语 | ContextMenu/Dialog/BottomSheet/Toast及Android/Windows Gallery Fixture已实现；业务Overlay编排、路由、锚定、计时器和真实动作不在本阶段，见phase_2g_overlay_primitives_report.md |
| Phase 2H 跨平台状态原语 | ThemeSwatch/EmptyState/ErrorBanner/Skeleton及Gallery Fixture已实现；真实异步状态、重试、Repository和假数据均不在本阶段，见phase_2h_state_surfaces_report.md |
| Phase 2I 跨平台集合卡片 | SourceCard/PlaylistCard及Gallery Fixture已实现；来源连接、真实计数、歌单Repository/Create流程和持久化均不在本阶段，见phase_2i_collection_cards_report.md |
| Phase 2J 跨平台队列与歌词原语 | QueueTile/LyricsLine/LyricsPlayerDock及Gallery Fixture已实现；队列算法、Seek、LRC、自动滚动、持久化和正式歌词页均不在本阶段，见phase_2j_queue_lyrics_primitives_report.md |
| Phase 2 后续组合及视觉对照 | 通用组件清单已完成；正式业务页组合、网页对照和设备性能待验 |
| Phase 3A Domain合同 | Track/Collection/Lyrics/Source模型、显式LoadState/错误分类、四类Repository及安全凭据Gateway已实现；无数据库或生产接线，见phase_3a_domain_contracts_report.md |
| Phase 3B Drift Schema/Migration | 17张表、10索引、v1创建/审计/空队列状态、外键/约束、Schema快照和后台文件打开已实现；不接App启动，见phase_3b_database_schema_report.md |
| Phase 3C LibraryRepository | Track/Album/Artist双向映射、事务upsert、分页/watch/可用性及脱敏失败已实现；不接App启动，见phase_3c_library_repository_report.md |
| Phase 3D CollectionRepository | 歌单/条目、收藏、最近20首历史和可重复TrackRef队列已用Drift事务持久化；不接App启动，见phase_3d_collection_repository_report.md |
| Phase 3E LyricsRepository | 完整TrackRef歌词缓存、plain/synchronized双语严格JSON、upsert/remove与脱敏失败已实现；不解析LRC/联网/接App启动，见phase_3e_lyrics_repository_report.md |
| Phase 3F MusicSourceRepository | 公开配置/credentialRef严格JSON、确定watch、稳定身份/内置删除保护与引用保留已实现；不接安全存储/网络/App启动，见phase_3f_music_source_repository_report.md |
| Phase 3G 安全凭据Gateway | Android/Windows安全存储适配器、192位随机引用、规范载荷、碰撞保护、限额和日志脱敏已实现；不接数据库、网络、UI或App启动，见phase_3g_secure_credential_gateway_report.md |
| Phase 3H 数据引导与Dev Fixture | Android/Windows生产空库组合、四Repository/安全Gateway根接线、独立内存HTML Fixture及脱敏Bootstrap状态已实现；默认入口无Fixture，见phase_3h_dev_fixture_bootstrap_report.md |
| Phase 3 后续来源/状态 | 主指令Phase3本地出口已满足；REST Adapter、来源凭据事务与业务Controller按后续阶段分批交付 |
| Phase 4A 播放核心合同 | 完整八阶段Engine/Playback状态、脱敏PlayableSource、唯一Controller、持久队列/随机/循环/自动下一首、MediaSession接口已实现；本地门禁与目标提交GitHub三类三job/草稿APK复核完成，见phase_4a_playback_core_contracts_report.md |
| Phase 4B 候选适配/打包 POC | media_kit 1.2.6 + audio libs已解析；项目适配器、5项Fake测试、完整本地门禁、本机Android native打包及目标提交GitHub push/PR双平台三job通过；生产入口未接候选，native许可证和真实播放未闭合 |
| Phase 4C 双平台原生本地音频 POC | 已关闭：精确提交`622408e`的专用运行33862786766 attempt 2在Windows/Android均成功，覆盖固定WAV的load不自动播放、play/position/seek/pause/volume/rate/completed/stop；不接生产入口、不上传产物/Release |
| Phase 4D Content URI与受控HTTPS音频 POC | 已关闭：实现提交`913f3d75`的标准PR三job与专用运行33878710671成功；Android debug-only Provider、双平台loopback HTTPS、Android content URI、Header与脱敏失败映射均通过；零artifact/Release，不接生产、不提交证书/音频 |
| Phase 4E just_audio + Windows WinRT备用候选 | 已关闭：精确依赖/许可指纹、隔离适配器、7项Fake合同、Header失败关闭、完整门禁与Android Debug通过；`a2b517b`的push/PR两次三job成功，无新Release，不接生产 |
| Phase 4F just_audio双平台原生运行比较 | 原生来源缺口已由 Phase4J/4K/4L 补齐；同一 `8c4aa6e` 的 Android 三来源和 Windows WAV/HTTPS 两轮通过。最终选型/许可展示和正式接线仍未完成，整体保持未关闭；GitHub Windows 托管机无端点，使用实际本机进程证据，不把 skipped 计通过 |
| Phase 4G media_kit原生分发审计 | 审计完成/发布阻断：四个JAR、APK三ABI、Windows归档/DLL均强哈希映射，实际二进制关闭GPL/nonfree；Windows构建变换不可恢复、Android helper未固定，两个归档均缺完整NOTICE/对应源码/重链接材料，机器门禁保持blocked |
| Phase 4H 移除被拒绝的media_kit候选 | 已完成：13个直接/传递包、两个适配器、5项Fake测试、两个历史集成测试、四个POC job及双平台生成注册已移除；历史manifest固定为rejected/inactive。Android干净APK无libmpv/helper；`2ec37ef`的push/PR双平台三job均成功，Windows bundle二次清单为0 |
| 后续页面、歌词、导入、来源、平台集成 | 未开始 |
| Phase 4I 播放会话/队列一致性 | 修复停止后重播、load失败重试、替换当前队列时停止旧音频、completed去重与过期操作、Seek恢复新周期、error/failure一致性、load结束后dispose保护；新增16项回归，完整243项Flutter通过，见phase_4i_playback_consistency_report.md及Draft PR #25 |
| Phase 4J Windows本机原生验证 | GitHub完整Profile包在本机两次真实WAV通过；248项Flutter、43项Node、源码指纹、严格分析和实现提交的GitHub双平台Debug通过。正式入口不变，见phase_4j_windows_native_validation_report.md |
| Phase 4K Android本地来源 | 已完成本批：`33a0b3c` 的 Android API36 本地 WAV/content URI 两项原生测试及 PR 双平台 Debug 全部成功；content 缺失失败、同引擎恢复、播放/释放通过；本地 249 项 Flutter / 44 项 Node 通过；见 phase_4k_android_native_sources_report.md |
| Phase 4L 无Header HTTPS来源 | 已完成本批：`8c4aa6e` 的 Android 三来源原生、标准双平台 Debug、Windows 完整 Profile 构建成功；同包两次本机 WAV/HTTPS 各2项通过。内存验证固定夹具 SHA/Range，默认 TLS、无代理/Header、无媒体提交；本地255 Flutter / 46 Node，见 phase_4l_native_https_report.md |
| Phase 4M 音频许可基础 | 已完成本批：六包完整LICENSE/两个构建源指纹、源码/APK/Windows NOTICES.Z校验、有界解压/UTF-8/全文唯一与参数大小写回归；本地255 Flutter/51 Node，`c0e3706`两组GitHub三job均成功；不代表全部Maven传递NOTICE或生产接线完成 |
| Phase 4N/O/P 原生材料、许可页与根接线 | 51 坐标/三份全文材料、原生许可页、根引擎及有序关闭已完成；各批精确实现两组 GitHub checks/Android/Windows 全部成功，最新 `4a5b32d`；不代表 Release 批准 |
| Phase 5A 共用 Shell 播放器 | 300 Flutter/58 Node、三端状态/动作/拖动取消/跨曲 Seek/键盘焦点已验证，38张 Golden；窗口、Inspector、全屏/歌词/队列和业务页面仍待后续批次 |
| Phase 5B 增量 Inspector | Windows320/Tablet260独立滚动面板与底栏共用状态/操作，308 Flutter/59 Node、41张Golden；本编号不等同于主指令全部Phone子项完成 |
| GitHub APK交付 | Phase4A ec508df的唯一手动运行33848236710创建私有草稿Release；190735487字节APK的三资产、metadata、SHA256SUMS、API digest、48份包内资产、Manifest及v2单签名已独立复核 |
| 浏览器参考截图 / Computed Style | 未运行：file: 导航被安全策略阻止 |
| Flutter format/analyze/test | Phase5B 格式182文件零改动、严格分析0问题、完整308项含41张Windows宿主Golden、59项Node、ZIP24/24与生成代码/Drift零差异通过 |
| Windows / Android Debug构建 | Phase4P `4a5b32d` 标准push/PR均完成双平台Debug；Phase5A结果见本批报告。Windows本机构建仍缺工具链；真实播放证据仍归属于Phase4L，不伪称本批进行了新的原生设备播放 |

## 保留的验收缺口与后续边界

2026-09-05 Phase4I复核更正：本机提升权限的只读检查已发现两个播放输出端点，音频服务运行；
下方Phase4F/4H的“当前远程会话无端点”仅保留为历史环境结果，不再代表当前本机状态。
本机Windows Debug实际重试仍失败于Flutter插件symlink权限；未找到可用Visual Studio C++安装。
Phase4I 当时分支为`fix/playback-session-consistency`，基于远端`58398ea`；当前分支/进度见文首，仍不进入Phase5、不接生产音频。
Phase4I最终严格分析0问题、243项Flutter通过；GitHub目标提交结果见Draft PR #25检查及正文。

1. 已执行安全归档：13个旧原型文件移入archive/sonic_gallery，指纹一致，f96197b保存；根lib是新骨架，不再是旧代码。
2. 用户已批准补足工具链；Android命令行工具/API36/35、NDK及项目要求的CMake已安装，Windows C++安装等待UAC确认。GitHub Windows2025/Android的Phase3H Debug构建均已成功，但云端成功不等于本机Windows构建或安装验收。未批量接受所有Android许可。
3. Phase4G 发现 media_kit 分发材料不完整，Phase4H 已删除该活动候选并用双平台包清单防止回流。Phase4J/4K/4L 已补当前后端双平台本地和无Header HTTPS 运行，Android另有content URI；GitHub Windows 托管机仍缺播放端点。Phase4M/N/O/P 已完成当前后端材料、查看及默认生产接线，不等于全应用签名/安装/发布验收。
4. 已建立实时平台分类、三个Shell和根依赖；Phase5A 正式底栏、Phase5B Inspector已接根播放器，Gallery 仍为独立 Fixture。窗口Gateway、完整队列/歌词/全屏、真实封面和业务页面未实现，不把设计预览当成音乐业务交付。
5. 为后续视觉验证准备获准且可访问的预览环境；遵守 Browser 技能边界，不绕过本轮 file: 拒绝。参考 screenshot 与 Flutter Golden 必须分别记录。

## 仓库边界

Phase4H 历史分支：`refactor/remove-media-kit-candidate`，基于`feat/media-kit-license-closure@ad1774c95c1760fabb23488f61be9f352fad5674`。未在main/master直接开发；旧候选仍可由Git历史和Phase4B—4G报告复核。该批删除已拒绝候选，不改UI、生产Bootstrap、release权限或Drift v1 Schema。当前 Phase5A 的分支、PR 与精确提交见文首和本批报告；没有擅自合并或改写历史。

用户于2026-09-04明确授权将`Z-YO-YI/YYMusic`由private改为public；变更前检查当前已跟踪文件及可见Git历史，未发现常见Token、私钥、`.env`或签名密钥文件。临时API访问令牌不持久化、不进入仓库。Phase3H Draft PR #16与APK证据仍只对应`27dd76c`；Phase4A Draft PR #17与APK证据只对应`ec508df`；Phase4C原生证据只对应`622408e`。
