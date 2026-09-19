# YYMusic 架构决策记录

## ADR-146：命令只确认本次未失败，偏好更新不代表播放恢复

Phase7J12F。16项失败回归确认非加载命令会忽略等待期流错误，音量/倍速还会清除旧错误。JustAudioEngine共用串行命令在完成后检查新失败；偏好命令保留原失败对象，仅新失败或命令异常使本次更新失败，相同错误码的新对象仍拒绝。stop在发布idle前检查，不覆盖等待期失败；现有明确播放控制命令/加载重试和失败后尾链继续保留。没有增加自动重试、平台调用或新播放器；真实方法通道与根历史测试验证错误不冒充成功。本机Windows音频兼容性仍独立未解决，见[J12F报告](phase_7j12f_command_failure_report.md)。

## ADR-145：单源加载确认前的异步失败不得返回成功

Phase7J12D。在J12C云构建等待期间复核加载错误链路，两个失败回归确认：JustAudioEngine.load收到后端异步失败后仍成功返回，根随即play并清除该失败。序列加载已有失败复核，单源缺失。单源在open返回后、提交ready前同样复核本次_failure，走已有playbackOpenFailed/open异常路径并撤销_loaded；禁止根自动开始已失败项，显式重新加载仍可恢复。不新增平台调用、超时策略或公共接口，不改变循环/随机策略；以Fake后端的引擎及根回归和真实插件方法通道回归验证。设备占用及Windows实际序列验收仍独立，不把协议回归称为实机通过。

## ADR-144：Windows旧式错误在平台协议边界转换，不复制事件订阅

Phase7J12C。设备占用复验同时暴露独立的软件兼容缺口：锁定just_audio_windows0.2.3发送EventChannel错误包，而just_audio0.10.6忽略平台流onError，只从PlaybackEventMessage.errorCode生成公开错误流。单曲与序列的活动通道回归均复现ready而非error。采用公开MethodChannelJustAudio/MethodChannelAudioPlayer继承点，在Windows后端创建首个播放器前幂等注册兼容层；仅替换原始默认实现，不覆盖其他插件/测试注入，不修改Pub缓存、原生插件或Android实现。将已有传递依赖just_audio_platform_interface4.6.0提升为精确直接依赖，不升级解析版本。

每个原生播放器仅有一个缓存事件流，正常事件及所有原生命令沿用上游；旧式流错误转换为固定脱敏的errorCode=-1事件，仅保留上一条位置/索引事实，无前序时保持零位置及未知索引。错误状态idle用于释放失败的原生连接，不伪造成功、推进或播放时钟；不复制错误原文/细节/堆栈。既有引擎负责DomainFailure，既有generation负责隔离旧播放器。验证活动单源/序列错误、恢复、迟到事件、取消及非Windows不干预。设备占用仍是独立环境阻碍；软件错误及时可见不等于Windows播放通过，须重新取得同SHA的GitHub构建与设备证据。

## ADR-143：Windows序列诊断使用独立入口和严格证据合同

Phase7J12B。复用已有真实序列测试，不改变旧单源/HTTPS探针的1/2项测试合同。独立Windows Profile入口仅允许显式启用、source/native精确同SHA和非Release环境；结果在allTestsPassed（含teardown）之后生成，必须恰有一项成功测试。白名单校验平台、源码身份、索引/轮次0/1/2、三次真实播放进度、追加/清理/截尾/关闭；缺失、错误类型、超时与旧产物均失败。不会把状态证据标成声学无缝。复用已有归档路径/哈希/SDK/端点保护，仅显式序列模式选择独立入口、purpose和结果文件；默认生产构建及旧诊断仍独立。Profile构建与有端点设备运行分别记录，不能相互替代。

## ADR-142：循环预载以cycle区分同一队列条目的多次播放

Phase7J11。AudioSequenceEntry/cursor新增非负cycle；加载请求与活动窗口的唯一键改为(cycle,entryId)，不保留所有已清理历史的全局去重集合。逻辑索引仍绝对递增，cycle只能保持或递增一。根RepeatMode.all可跨尾部预载下一轮，包括单项队列；绝不新增/修改持久化队列条目。每轮冻结原生顺序，随机新轮沿用既有“当前尾项在首、其余随机、从第二项继续”的规则，仅实际采用新轮时更新根随机游标。存储等待后先比较appliedShuffleOrder引用，不能用旧轮覆盖用户显式重建的顺序。循环顺序随已播窗口清理，仍最多11项/两项前瞻；策略撤销截尾。期限制约/不可用项仍回落既有逐项推进，不冒称所有来源已无缝。用户开关、原生听感与完整生命周期验收仍独立保留。

## ADR-141：原生窗口清理已播前缀，逻辑cursor保持绝对索引

Phase7J10。原生列表索引允许清理后归零，但AudioSequenceCursor.index是批次内绝对逻辑序号，身份不重用。引擎按窗口列表映射原生索引，根按首cursor偏移访问元数据。根最多保留11项、当前位置前积累8项时清理前缀；追加仍保持两项前瞻。删除期间冻结引擎投影，等待原始索引归零（方法完成后最多1秒），旧批次/期望当前不符不提交；观察到非法索引、切曲导致最终非零、错误/关闭则失败停止，不推测当前项。原生本操作不pause/seek/reload/play，保留当前及其后项；根队列与currentEntryId不因内存窗口变化而改写。迟到的旧大索引越界则安全失败，设备事件时序与真正无缝仍须验收，循环窗口未完成。

## ADR-140：原生准备前后及操作完成后复核源期限

Phase7J9。JustAudioPlayerBackend.open传递可选expiresAt，原生后端仅保留UTC期限列表及失效标记，不复制地址到状态。使用可注入时钟，在替换前、旧播放器释放后、native load/append完成后，以及play/seek入口复核。操作等待跨过期限时标记失效、请求stop并抛出无地址的JustAudioSourceExpired，引擎转换为既有streamUrlExpired；停止失败不得覆盖该安全错误。失效标记禁止继续play，只有新成功加载解除。预检拒绝不破坏尚可用旧播放器；已开始替换后的失效可通过新load恢复。批次任一明确期限失效则整批无效，应用根目前不预载带期限未来项。期限检查不证明服务器接受，也不覆盖持续播放中的定时撤销或原生内部已发出的网络请求取消。

## ADR-139：恢复播放时刷新过期源，保留位置与同次历史

Phase7J8。根只保留已加载源的期限，不保留URI/headers；原生采用新条目或stop清除期限。play、完成重播、repeat-one以及seek共用加载期限刷新路径。刷新暂停旧引擎、重新查当前完整TrackRef及可用性、有限解析，加载后seek到调用前位置或明确重播/seek目标，确认后才play。刷新期间不建立新历史周期，只有显式重播仍begin；暂停/加载/seek不能计作有效播放。原生批次刷新重建当前及允许的后续前缀，并继续遵守策略撤销；关闭或许可撤销不迟到play。解析/加载/seek失败清理已加载身份并停止，不假称恢复成功。尚非定时刷新或网络原生声学验收。

## ADR-138：瞬时播放地址携带UTC期限，加载前重新解析

Phase7J7。PlayableSource的可选expiresAt只用于networkStream，不进入Track、队列、持久化或日志。精确到期即失效，调用方提供时间，不在模型中读取系统时钟。唯一播放根在首次解析及调用load之前复核；已经失效的结果只重取一次，第二个结果仍失效则固定streamUrlExpired，不无限重试。异步重取后重验完整TrackRef、关闭和播放许可。引擎也在串行命令实际执行时拒绝已到期输入，拒绝发生在替换现有状态之前。明确有到期时间的未来项暂不加入原生预载，保留队列、待实际推进时解析；未给期限不等于永久有效。此保护不宣称网络无缝、原生内部等待期间期限保证、暂停后刷新、已加载地址定时撤销或Phase9网络Adapter已完成，后续仍须补齐。

## ADR-137：以批次尾部许可追加，根仅保持有限前瞻

Phase7J6。AudioSequenceAppend复制瞬时输入，沿用同一批次身份且从已确认尾部索引继续编号；引擎串行复核完整尾部、重复entry和请求头能力，追加不reload/play。根初始最多三项，随后只为当前位置保持两项前瞻；解析在根命令队列外进行，提交追加仍回到唯一根及引擎队列并再次复核绑定/策略/队列条目。策略撤销或关闭阻止迟到追加，关闭等待已登记解析任务退出。原生新索引可能在追加Future返回前出现，因此先安装已校验的身份映射，失败必须清理并停止；不得把完成后追加变成隐式重播。暂不修剪已播前缀或实现循环窗口，生产UI仍未开放，最终内存/循环/过期源及真机验收保留。

## ADR-136：原生序列仅通过唯一播放根加载及接收切曲

Phase7J5。新增显式playNativeSequence入口供原生序列整合验证，现有生产UI仍走playEntry，不提前开放无缝开关。根解析当前顺序中的可播放前缀并加载一次；后续原生cursor按批次/完整条目身份验证，切曲经根串行队列持久化currentEntryId后才发布曲目信息/时钟及历史，不建立第二状态真相。策略变更先撤销后续接收并排队截尾，尾部解析期间变更则降为当前曲目；队列编辑先截尾，已有待确认切曲时先停止再编辑。正常有限序列末尾回到原有重复/随机/失效跳过逻辑。完整连续预载、用户开关及原生生命周期/听感仍待验收，不将初次根整合宣称全部无缝完成。

## ADR-135：继续策略以受保护的序列尾部移除建立本曲边界

Phase7J4。新增retainSequenceThrough(expectedCursor)，在共用引擎串行队列内复核批次identity、entry/TrackRef及当前索引；过期请求不调用原生。只移除当前索引之后的预载项，不seek/reload/play或修改应用持久化队列。原生使用removeAudioSourceRange，尾部为空不调用Windows拒绝的空范围。执行中暂缓身份投影并记录索引变化；发生切曲、错误或失败时丢弃序列身份、请求停止并返回固定安全failure，不宣称边界成功。该能力为本曲结束睡眠和关闭自动继续的根接入前置；尚未绑定根，成功通道返回不代替原生边界听感或释放验收。

## ADR-134：整批替换隔离原生播放器事件域

Phase7J3。锁定插件的事件通道按播放器ID区分，但索引事件不带应用批次；不能在同一播放器上以新列表解释旧索引。NativeBackend在第二次及后续open/openSequence前撤销旧订阅generation、排空取消、请求pause并dispose旧AudioPlayer，再创建新AudioPlayer及独立通道。保留音量/速率，绝不自动play；同一序列内切歌不重建播放器。旧流、错误和play Future失败全部校验generation。可观察的准备/暂停失败阻止新播放器建立并锁定后续加载。插件stop会吞掉主释放及回退释放错误，dispose成功不能证明资源释放成功；该限制须保留且做设备验收，不虚构可检测性。关闭中不创建新播放器。此变更作用于单曲与序列替换，不据通道隔离声称无缝上线。

## ADR-133：序列引擎状态携带瞬时批次与条目身份

Phase7J2。可选AudioSequenceEngine接入既有JustAudioEngine串行命令/关闭队列，不建立第二播放根。AudioSequence复制有序输入，允许重复TrackRef但拒绝重复entryId；每批拥有独立不持久化identity。AudioEngineState的可选cursor只携带identity/index/entryId/TrackRef，不含PlayableSource、URI或headers。加载中、失败、单曲替换和stop清除cursor；成功后同一状态原子报告插件索引与身份。索引缺失/越界时不猜曲目，报告安全失败并要求重新load。支持能力不足在替换前拒绝。此协议不证明插件旧事件隔离或真实曲间无缝，生产根尚不使用序列，接入前仍须处理完整策略和原生验证。

## ADR-132：先验证原生序列边界，不提前启用应用无缝播放

Phase7J1。增加可选 JustAudioSequenceBackend，仅原生适配器实现；既有 AudioEngine/PlaybackController 单曲协议不变。输入复用不可变、短生命周期 PlayableSource，复制序列后整批检查请求头能力，禁止部分加载。快照提供插件真实 currentIndex，不推断应用队列身份。适配器调用锁定版本 setAudioSources，不实现第二个队列控制器，不自动 play，不持久化 URI/请求头；失败输出固定安全错误。调用者须独占并串行操作同一后端。

此阶段只验证 Dart 到原生通道的序列结构、索引和安全边界；不证明 Android/Windows 实际无缝听感。下一阶段必须处理根队列身份/修订、睡眠本曲结束、自动继续关闭、失败跳过与过期来源，再做显式设备边界验证，最后才允许用户开关。标准化另行处理，不能以用户音量代替。

## ADR-131：队列跳过反馈按记录快照确认，不影响音乐库或播放

Phase7I2。QueueController只投影根最近失败列表，确认必须匹配当前不可变列表身份；旧确认不能清除后来产生的记录。QueueScreen显示本次启动摘要及最多20项详情，只使用当前分页中精确条目/TrackRef匹配的元数据，否则显示队列位置或已移除，不补查库。分类原因固定文案，不显示原始ID/路径/异常；展开与确认复核页面许可和路由可见性。不自动重试、移除歌曲或改变播放。

## ADR-130：队列推进有界跳过曲目级失败，全局失败停止

Phase7I。每次下一首推进按捕获的顺序/随机队列候选最多尝试每项一次；循环不能造成无限重试。只在曲目可用性、来源解析和音频load边界允许分类明确的曲目失败跳过，数据库提交、停止/播放命令、未知/安全失败仍终止。记录最近20项安全队列失败，不保留异常原文、媒体URI或凭据。关闭自动继续/根关闭在每个候选和异步边界复核。记录不删除失效队列引用，成功下一项不丢失诊断。

## ADR-129：播放偏好设置借用根协调器并复核页面可见性

H6C。生产SettingsScreen增加播放分类，三套既有设置布局共用根继续偏好协调器；UI不读写数据库或调用音频插件。开关选择与重试复核页面generation、可见路由和有效面积，存储变化使旧回调失效。读取失败仍允许显式选择；保存中允许更新最新意图。无缝/响度标准化不提供虚假开关，注明未支持。

## ADR-128：自动继续持久化由根范围协调，显式意图与读取分离

H6B2b。AppDataServices拥有继续偏好仓库；根协调器借用仓库与播放器，在I/O前捕获许可。只读意图revision支持相同值选择与重入复核。缺失不写默认，坏记录保留并反馈；只有显式用户意图才允许覆盖。串行保存最新意图，失败显式重试，退出冻结意图并排空写入，最后才关闭数据范围。恢复不得调用音频命令。UI后续通过协调器选择/重试，不自行写库。

## ADR-127：启动自动继续恢复使用一次性意图许可

H6B2a。在存储读取前由 PlaybackController 捕获唯一恢复许可。显式选择（即使与当前值相同）和关闭均撤销许可；恢复应用前消耗许可，通知期间的新选择仍优先。独立意图计数不改变原自动完成策略计数，避免相同值选择意外取消有效推进。不触发播放，不依赖音频设备可用性。本批只提供根接口，数据范围、恢复/保存协调器与设置 UI 尚未接入。

## ADR-126：自动继续布尔偏好独立版本化存储，读取不改数据

H6B1。PlaybackContinuationRepository仅存储continueAfterTrack，Drift使用既有设置表专用key，version1有界codec拒绝错误类型/未知版本。missing为null、损坏为安全错误，不在读取时回填默认或删除。操作按调用顺序登记、失败不毒化尾链；关闭拒绝新工作并等待接受写入，不关闭借用数据库。生产恢复与UI后续接入，恢复不得自动播放或覆盖更晚的用户意图。见[报告](phase_7h6b1_continuation_storage_report.md)。

## ADR-125：自动继续只控制自然完成，变更撤销旧推进而不触发播放

H6A。按HTML队列下一首语义，根策略默认true，关闭优先于自动repeat-one/all，手动导航保持；开关变化递增revision，重新开启也不恢复旧完成。canPlay跨解析/load/seek和最终play提交前复核；已提交副作用不伪称撤销。随机下一条候选不提前增游标，只有既有选中路径同步游标。UI/存储另阶段，恢复策略不能自动播放；无缝/标准化不以开关存储或插件空成功代替实现。见[报告](phase_7h6a_auto_continue_report.md)。

## ADR-124：输出面板借用根观察器并局部重绘，不提供模拟选择

H5C2。既有PlaybackPresenter传递可选根观察器，但不转发它的高频/busy通知；输出区域独立监听，避免自己的启动使父generation失效。生产工厂始终注入，独立无平台契约的旧展示保持可选。只读状态严格区分unknown/systemDefault/playerRoute，设置操作复用H5C1实时许可，反馈再验页面；不改变根观察或宣称设备切换。现有合成设计token与原生Dialog/BottomSheet复用，无WebView或伪设备卡。见[报告](phase_7h5c2_output_panel_report.md)。

## ADR-123：系统设置启动由根控制器以实时页面许可守护

H5C1。先登记单一launch Future以防通知/许可回调重入，等待读操作排空后再复核页面许可与能力；失效许可不调用原生宿主。opened保持OS接受启动语义，不改观察或立即推断路由；反馈由后续Presenter复核页面。根关闭等待已接受启动，但不能撤销已交给OS的副作用。未知路由不意味着系统设置不可用，两类事实独立。见[报告](phase_7h5c1_settings_action_report.md)。

## ADR-122：输出由生产根拥有，前台仅刷新，可选观察不阻塞启动

H5B2c。Bootstrap平台工厂创建NativeAudioOutputGateway交Graph所有；构造失败逐项释放。Graph后台初始化唯一观察器，关闭同步撤销、异步排空后关闭Gateway，保持引擎/数据释放屏障。App既有生命周期监听只在非前台到resumed转换请求刷新，卸载不关闭借用根。独立观察器用微任务登记读/关闭，避免Widget卸载残留事件Timer；状态不持久化、不等同设备切换。见[报告](phase_7h5b2c_root_output_report.md)。

## ADR-121：输出观察独立于播放状态，借用Gateway并排空关闭

H5B2b。AudioOutputController仅协调瞬时观察，初始化/刷新串行，突发刷新合并后续读取，流修订保护迟到结果；错误不能继续确认旧路由。不复用PlaybackState.outputDevice推断系统默认与实际路由，不持久化名称、不打开系统设置、不改变音频引擎。关闭先撤销并排空，再由未来根所有者关闭Gateway。当前为独立可测模块，生产绑定和前台刷新下一阶段实现，见[报告](phase_7h5b2b_output_observer_report.md)。

## ADR-120：Windows只读默认端点并保留系统默认来源

H5B2a。在既有UI COM apartment内用MMDevice查询活动eRender/eMultimedia默认端点，只读FriendlyName；HRESULT/类型/UTF长度校验失败均unknown，设置能力独立。ComPtr与PROPVARIANT作用域负责释放，不记录设备ID或名称。默认端点不能证明播放器实际输出，禁止返回playerRoute。原生测试无端点时允许unknown且不发声/启动设置，测试通过不能替代设备热插拔或听感验收。见[报告与依据](phase_7h5b2a_windows_output_report.md)。

## ADR-119：原生设置入口只接受固定目标，启动结果不推断路由变化

H5B1。Android ACTION_SOUND_SETTINGS、Windows ms-settings:sound分别由Activity/Runner持有只读启动通道；非空参数拒绝，失焦或销毁不启动。不从连接列表猜路由，目前返回unknown。Dart读取失败撤回旧事实，关闭撤销排队启动并排空已接受调用；不能声称已启动的OS窗口被关闭操作撤回。本批无根/UI绑定和原生路由读取，Windows编译另由CI验证。见[报告与一手依据](phase_7h5b1_native_settings_report.md)。

## ADR-118：输出设备观察必须保留来源，设置启动不是切换成功

H5A。平台契约区分unknown/systemDefault/playerRoute，未知不填设备名；系统默认不冒充当前播放器实际路由，已连接设备不构成路由证据。设置入口能力独立，opened仅为OS接受启动；返回后重新读取。设备标签限长且拒绝内部控制字符，异常及调试输出脱敏，无持久化。先提供诚实不可用Gateway，不暴露未实现的切换API；原生适配与唯一根投影后续独立验收。见[报告](phase_7h5a_audio_output_contract_report.md)。

## ADR-117：根淡出作业与命令尾链分开排空

H4C2b2。根持有唯一当前SleepFadeRunner及在途作业集合，逐步写/暂停通过原_operationTail，每次重验generation/entry；间隔在尾链外。临时振幅dirty标记只在实际写前置位，恢复或用户新音量成功才清除。用户播放前恢复，暂停/停止后finally恢复；旧runner让位新runner。关闭先撤销，再等待作业和尾链，只允许私有恢复命令在disposed后执行，借用引擎由Graph最后释放。恢复失败由close返回，音量回报不抹除已有播放错误。生产分钟到期正式启用；本曲结束自然完成策略不变。见[报告](phase_7h4c2b2_root_fade_report.md)。

## ADR-116：淡出等待不占根命令队列，恢复无条件排空已尝试写入

H4C2b1。SleepFadeRunner为根未来持有的单次执行器，借用命令回调而不拥有播放器。Stopwatch/高水位经过时间驱动纯曲线，Timer等待位于写回调之外；根接线必须逐次串行且重验许可。start先登记Future支持重入，取消解除等待但不放弃在途写与恢复。只要尝试过写入，成功/失败/取消都调用恢复；结果记录首个失败操作及次生恢复失败，不泄漏异常文本。恢复不可依赖已失效的播放许可，根关闭队列顺序须防自等待。当前仅独立执行器，未启用根淡出。见[报告](phase_7h4c2b1_fade_runner_report.md)。

## ADR-115：根应用音量在有效请求后独立于引擎回报

H4C2a。PlaybackState.volume表示已确认的应用音量，不是系统音量或瞬时引擎振幅。首个有效请求前沿用引擎种子；调用引擎前锁定原值，成功且未关闭才确认新值。失败保留原值且沿用安全错误，不假称硬件回滚。两条引擎投影均隔离迟到音量，其他状态照常处理；唯一串行队列保证新请求在旧请求之后确认。关闭排空但不发布迟到结果。无新持久化或淡出调度，后者必须在无用户调音量时也显式锁定意图。详见[报告](phase_7h4c2a_volume_intent_report.md)。

## ADR-114：睡眠淡出先定义纯振幅契约，根接入独立验收

H4C1采用2秒线性振幅、50ms建议采样，最后间隔缩短；迟到唤醒按真实单调经过时间采样，不追发过时步骤。纯SleepFadeEnvelope不持有音量、不拥有Timer或引擎。每次使用最新用户音量，拒绝非法值。该曲线不宣称等感知响度或设备听感通过。

根接入不得在串行队列里等待整段淡出；必须隔离用户音量与引擎临时增益回报，并覆盖取消/切曲/暂停/新意图/关闭及迟到命令恢复。H4C1不替换既有到期暂停，下一步H4C2完成生命周期协调后再启用。详见[审计及后续验收](phase_7h4c1_sleep_fade_contract.md)。

ADR-001至008记录Phase 0边界与规划；ADR-009起记录Phase 1迁移及实现选择。实际已存在模块见architecture.md，不把规划当作全部实现。

## ADR-001：原生 Flutter 与设计参考隔离（确定）

唯一正式客户端是Flutter Widget；React/Vite/Tailwind/Blob/iframe只保存在design_reference。构建阶段提取SVG，不在Flutter启动时解析App.tsx/HTML，不加载源JavaScript。所有Fixture通过开发/测试注入，Release不包含参考工程。

## ADR-002：平台优先、窗口宽度实时分类（确定；横屏解释待视觉复核）

Windows先分1440/1024；Android以600决定Phone/Tablet，然后orientation由当前width>height决定。三套Shell不各建一个项目，也不各建播放控制器。844×390横屏在该规则下是TabletLandscape；“Phone横屏”验收指测试设备尺寸，低高度player布局独立于设备命名。若后续要改变这个分类，必须修改ADR并获得范围确认，不能悄悄用设备型号判断。

## ADR-003：业务真相位于根依赖图（确定）

App bootstrap构造唯一PlaybackController、QueueController、Repositories、Theme等Controller。Shell/route创建销毁不重建AudioEngine。队列entryId与trackId分开，允许重复曲目且排序稳定；UI不持有插件类型，不直接HTTP/SQL/文件扫描。Controller状态显式idle/loading/data/empty/error，播放器有独立phase。

模块流向：Shell/Feature → Controller/UseCase → Repository接口 → Data/Platform实现。AudioEngine/MediaSession/Fullscreen/LocalMusic/SecureCredential独立Gateway；平台回调只驱动共用Controller。

## ADR-004：player、lyrics独立路由（确定）

/player与/lyrics可各自从主页面进入；player→lyrics关闭返回player，主页面→lyrics关闭返回原页。全屏OS状态不是route本身：Esc/系统返回先处理最上层菜单/弹层与OS全屏，再按栈返回。保存并恢复窗口/Android系统UI。不能复制HTML对象反序关闭作为正式路由语义。

## ADR-005：分离配置、秘密与媒体引用（确定）

SQLite存TrackRef/来源公共配置/credentialRef，安全存储保存凭据和敏感header；日志脱敏并丢弃敏感query。HTTPS默认。用户映射是受限字段表达式，不执行任意代码；UI不保留持久stream URL。删除来源保留用户歌单/收藏/队列中的不可用引用；不提供音频下载或长期缓存。

## ADR-006：插件条件选择（待POC）

候选以当前维护者文档为证据，具体版本待兼容解析。Audio优先比较media_kit与just_audio+Windows backend；音频/后台会话分层。只有Windows和Android合同测试均通过，才能选正式实现，详见dependency_decisions.md及audio_poc_plan.md。

## ADR-007：旧原型保留、不自动收编（确定）

任务开始本地有未跟踪的Sonic Gallery代码，但没有.git；远程没有任何refs。初始化独立docs/phase-0-design-audit并fetch空远程，不伪称拉取了已有main。原有lib/test/pubspec/analysis_options/album_atlas保留原地、不修改、不纳入本阶段提交；审计产物是本轮GitHub基线。

因此本阶段推送成功不意味着整份工作目录与远程相同。后续Phase 1需明确旧原型迁移/归档方案，保留可恢复历史后再整理，不能覆盖或删除未经授权的本地文件。

## ADR-008：合成事实与原生目标分别记录（确定）

源码哈希不变；完整polish映射带来源行号。CSS高specificity导致的全屏滑条、Artwork、移动端圆角差异保留在审计中。平台和无障碍硬约束优先，但任何视觉主动适配在Golden报告明确写出，不把通用Material外观当设计还原。

## ADR-009：Phase 1 的可恢复原型迁移（2026-08-31）

用户要求继续开发后，选择先原样归档旧原型再建立正式根工程。13 个旧文件移动前后逐字节核验，放入 archive/sonic_gallery 并单独提交。它们不再保持 Phase 0 的“未跟踪、位于根目录”状态；ADR-007 是历史状态，不是当前文件位置。

根分析排除只读 archive 与 design_reference，原因是它们是独立历史/设计资料，不是关闭正式客户端 Lint。旧测试、旧图标和图片完整保留但不代表正式 YYMusic 测试。新测试验证新契约，不以修改旧断言掩盖问题。

## ADR-010：Phase 1 注入与路由选择（已实现）

采用已解析兼容版本的Riverpod 3.4.2与go_router18.0.0。Riverpod仅负责根ProviderScope与依赖图，Controller使用Flutter基础ChangeNotifier；go_router封装在AppRouter，Shell只收到AppNavigation自有接口。StatefulShellRoute保存主导航分支，player/lyrics位于根Navigator。

ProviderScope拥有注入依赖的释放责任，依赖图dispose幂等。默认AudioEngine不可用且不模拟播放；Repository/FullscreenGateway未注入时为null。Phase 3/4扩展合同前先更新ADR，不在Phase 1编造完整模型或虚假实现。

## ADR-011：骨架验证与阶段出口分开（已采用）

本机分析/Widget测试可以用现有SDK执行，但缺少Visual Studio与Android命令行工具/明确许可。提交可验证的骨架与CI不代表双平台构建通过；没有真实构建结果不进入Phase 2。CI只构建Debug，不发布或部署，不读取用户音乐和凭据。

## ADR-012：按用户要求分离 Android 优先验收（2026-08-31）

用户在 Android 工具链/APK 已通过、Windows UAC 无法远程确认后明确要求“先开发安卓平台”。从本批起，允许以 Android 已通过的 Phase1 基础推进 Android Phase2 分批增量；ADR-011 的“等待双平台后再推进”在此范围内被用户的新指示覆盖。

这不是 Windows 构建成功或整个 Phase1/2 完成的声明。保留 Windows runner、平台优先分类、共用 Domain/Controller 和现有测试；不删除 Windows CI，不另开 Android 仓库，不重复实现业务逻辑。Windows 本机安装、原生构建/真机视觉与后续平台能力仍单独待验收。

## ADR-013：Phase 2B 受控输入与可读导航（2026-08-31）

导航的当前项来自路由；Phone使用胶囊选中、不显示3×18左条，Tablet保留左条。保留正常强调色外观；当原始accent相对elevated底色对比不足3时，补派生色边框，选中内容及边框相对实际选中底色对比至少4.5，原HEX/填充不改。标签提升至11dp并随文字缩放，单个触控区不小于44dp。

YYSlider的onChanged只表示预览，只有onChangeEnd可供未来业务提交Seek；系统取消走onChangeCancel，不冒充提交。已接受的Flutter横向Drag在收到原始PointerCancelEvent时仍可能调用onEnd，因此用Listener先清除本次拖动并发取消回调。禁用、零范围、加载或范围改变会使内部拖动失效，不提交；范围/禁用变化时父状态负责决定预览回退。键盘/语义动作走离散开始→更新→结束，滑块不订阅音频流。

几何占位直接实现原始CSS的百分比、旋转及固定px线宽/偏移，区分album20/track10/player26圆角。不使用随机或AI封面，不创建假Track数据；未来真实Artwork应优先。只对kind和local accent变化重绘，模糊仍限定导航区域，ReduceGlass保留几何。

实现依据为本地Flutter3.47.2源码，以及Flutter官方[Semantics](https://api.flutter.dev/flutter/widgets/Semantics/Semantics.html)、[FocusableActionDetector](https://api.flutter.dev/flutter/widgets/FocusableActionDetector-class.html)、[CustomPainter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)。Widget语义与绘制测试不代替设备TalkBack或性能验证。

## ADR-014：云端APK与Phase2C输入边界（2026-08-31）

用户明确要求APK在GitHub构建：交付必须对应目标commit的GitHub运行、私有草稿Release与校验和，不能上传旧本机包冒充云端编译。Actions artifact额度耗尽后，经用户允许改为仅手动workflow_dispatch创建draft/prerelease；普通push/PR只做验证。Actions先验签/比对资产再按三文件白名单上传，元数据不复制环境变量，签名仍为临时Debug；正式发布、Release签名和稳定升级密钥另行授权。

输入控件是设计系统，不是搜索功能。YYSearchField保留原生TextEditingValue/composing/selection，不在onChanged重写IME组合文字，只通过onSubmitted通知调用方。调用方Controller/FocusNode所有权不转移；启用/加载状态阻止输入和提交。剪贴板正文只有用户发出复制/粘贴等编辑动作才访问，测试全用替身；无网络搜索、输入历史或隐藏持久化。

选择手势、工具栏和原生编辑句柄基于Flutter Widgets层；工具栏复用YYButton和主题，不引入Material外观。支持Tab/Enter/Space的分段选择按按钮组语义实现（不是切换页面的选项卡），窄宽横向滚动且键盘焦点自动可见。11px/650字重和14/11圆角保留，34px旧命中高度提升至44；Search15/460、52/18或58/20，随字号适度增高，不截断文字。

参考Flutter官方[EditableText](https://api.flutter.dev/flutter/widgets/EditableText-class.html)、[TextSelectionGestureDetectorBuilder](https://api.flutter.dev/flutter/widgets/TextSelectionGestureDetectorBuilder-class.html)。本地单元测试包含IME消息但不替代安卓真机输入法/TalkBack验收。

## ADR-015：Phase 2D 内容组件的动作与语义边界（2026-09-01）

`YYAlbumCard`与`YYTrackTile`是受控展示组件，不拥有收藏、选择、播放、队列或菜单业务状态。Album的`selected`表示调用方选择，但它不是互斥单选组，因此复用`YYControlAction`时显式关闭`inMutuallyExclusiveGroup`；Track的`playing`同样只用于受控外观及“正在播放”语义，不触发或模拟音频。

Track整行主动作与尾部更多动作必须是两个独立的Semantics/Focus/命中节点。更多按钮不位于主动作的GestureDetector内，不冒泡调用`onPressed`；禁用或加载时两个动作同时不可用。Album与Track只公开回调，Gallery回调仅修改本页Fixture状态，不访问Controller、Repository、网络、文件、数据库或持久化。

Album保留最终POLISH的20圆角与默认/hover双阴影；Track保留14行圆角、10封面圆角、36封面、58最小高度与手机隐藏时长。手机来源标签限制宽度并省略，避免长来源挤压标题或越界；这属于响应式防溢出，不改写来源内容。白色等低对比accent保留原HEX填充，边界和选中文字使用既有可读派生色。

## ADR-016：Phase 2E Windows Chrome 与平台能力分界（2026-09-01）

Windows设计系统先实现受控`YYWindowsSidebar`与`YYWindowToolbar`，但窗口控制不在Widget内直接调用插件。Toolbar只公开最小化、最大化/还原、关闭回调；正式Shell在`WindowsWindowGateway`实现前隐藏这组控制，继续由操作系统原生窗口边框提供真实能力。Gallery可用明确标注的Fixture回调验证视觉与动作，但不能冒充真实窗口操作。

竖向Sidebar需要适配父约束，因此新增`YYGlassPanel`；既有`YYGlassSurface`保留原固定高度、高光线占位和渲染树，不委托新组件。视觉回归曾准确拦截把高光线改为覆盖层造成的Android导航内容约1dp位移，因此恢复旧实现而不更新旧导航基线。Glass仍只覆盖Sidebar等有界区域，不扩展到全屏滚动层；Reduce Glass关闭Blur但保留Fill、Stroke和Shadow。

Sidebar的选中路由来自`AppRouter`，只发出`onSelected`，不持有Controller。展开布局显示顶部`YY Listener / 本地账户`与显式的“音乐源尚未接入”；紧凑布局只保留账户头像和图标导航。HTML中的“128首”“音乐源在线”“2个在线来源”是演示状态，在Phase3 Repository之前不得进入正式Shell。

## ADR-017：Phase 2F 播放器表面只表达受控状态（2026-09-01）

`YYMiniPlayer`与`YYDesktopPlayerBar`属于Phase2设计系统，只接收`YYNowPlayingViewData`及回调。它们不读取`PlaybackController`、`QueueController`、AudioEngine、Repository或插件，也不在Widget内推进进度、循环队列或模拟播放；Gallery Fixture只修改页面局部状态。Phase4确定播放合同后由Feature/Presenter把唯一播放真相映射到该UI模型，Shell不得再创建播放器状态。

曲目信息主动作与播放、下一首、随机、循环、歌词、收藏、队列、音量和进度必须保持独立Semantics/Focus/命中节点。进度`onChanged`仅预览，`onChangeEnd`才提交；系统取消不冒充Seek。Repeat的off/all/one只是受控视觉枚举，不实现循环算法。Loading或空回调使对应动作不可用，组件不以假成功状态回应。

播放器条使用基础HTML的88/76/64高度、24/22/21外圆角、54/50/48封面及14/12封面圆角；新增Artwork role而不改26圆角的全屏Now Playing role。App.tsx的POLISH没有播放器条选择器，因此保留基础HTML播放器规则，同时仍使用最终Sprite的play/pause/prev/next/shuffle/repeat/volume/queue/fullscreen/lyrics等原始SVG。正式Shell在Phase4/5前继续显示明确的未接入结构槽，不把Gallery Fixture接成假播放器。

## ADR-018：Phase 2G 弹层原语与弹层编排分离（2026-09-01）

`YYContextMenu`、`YYDialog`、`YYBottomSheet`与`YYToast`只负责可复用的原生视觉、焦点、键盘和语义，不自行创建业务Overlay、路由、计时器、右键/长按监听或平台触觉。Feature/Shell以后决定何时插入Overlay、如何锚定/避让窗口边缘、Android使用Sheet还是全屏Route以及业务动作；Gallery只以内联Fixture验证组件。

Context Menu沿用基础HTML的224宽、7内边距、30模糊和菜单标题/元信息结构，最终POLISH把圆角从17覆盖为20；HTML的38高菜单项提升为44dp命中以满足主指令。组件接收受控item列表与`onSelected(id)`，不解释“播放/队列/收藏”等业务含义；方向键/Tab在闭环FocusScope内移动，Esc只通知`onDismiss`。右键坐标、窗口边缘限制、长按520ms和外部点击关闭属于后续调用层。

普通Dialog保持680最大宽、30圆角、72头尾与不透明Surface，不误用Liquid Glass；Phone Bottom Sheet是主指令允许的主动平台适配，复用30顶部圆角和同一焦点合同，不冒充基础HTML在599px下的全屏Dialog像素复制。两者打开时可聚焦关闭按钮、Tab闭环、Esc通知关闭，并在销毁时恢复先前焦点。Toast保持42最小高、420最大宽、14圆角与可访问live region，但显示时长由调用方控制，组件不内置2300ms计时或模拟业务成功。

## ADR-019：Phase 2H 状态原语不拥有异步工作（2026-09-01）

`YYThemeSwatch`、`YYEmptyState`、`YYErrorBanner`与`YYSkeleton`只表达调用方状态。Swatch通知选色但不持久化；Error Banner通知可选action但不重试；Skeleton不启动加载、计时或生成假数据。未来Controller显式拥有idle/loading/data/empty/error，Feature只把状态映射到这些组件。

Swatch保留基础HTML的30px视觉，但实际命中提升到44dp并增加键盘、焦点和互斥选择语义；选中内环使用相对色样可读的黑/白色，解决自定义白色上原网页白环不可辨识的问题。Empty State保留28/16内边距、24图标和10px/1.6文字。Error Banner没有App.tsx后置样式，最小化复用基础HTML notice的12/14/15几何以及既有error badge色值。主指令要求Skeleton但设计导出没有对应CSS，因此只用`bg-subtle`、默认边界和10圆角的静态纯色占位；明确禁止臆造渐变shimmer。

## ADR-020：Phase 2I 集合卡片不拥有来源或歌单业务（2026-09-01）

`YYSourceCard`与`YYPlaylistCard`是受控展示组件，只接收调用方给出的文字、图标、状态、选择和动作。来源状态标签及positive/warning/error/neutral色调由调用方映射；组件不测试连接、不读取凭据、不启动网络或计时器。歌单卡片的collection/create变体只通知动作，不创建歌单、不读取曲目、不打开页面或Dialog，也不持久化选择。

Source沿用基础HTML的72最小高、12内边距、42图标、16卡片圆角和6状态点，并应用App.tsx最终`POLISH_CSS`的13图标圆角。Playlist采用最终20卡片圆角、14图标圆角、桌面16内边距/44图标/18标题间距；Phone沿用13内边距和40图标。Create虚线边界由纯色`CustomPainter`绘制，不使用Material默认卡片或渐变。

Gallery只展示明确标注的确定性Fixture，点击只更新本页说明或选择；HTML中的“在线”“128首”等演示内容不得进入正式Shell。未来Phase3由Repository/Controller提供真实来源和歌单状态，Phase2组件不先发明Domain模型。

## ADR-021：Phase 2J 队列与歌词原语不拥有播放真相（2026-09-01）

`YYQueueTile`、`YYLyricsLine`与`YYLyricsPlayerDock`是受控展示组件。Queue主动作与上移、下移、移除分别拥有Semantics/Focus/命中边界；组件不修改列表或实现拖拽排序。Lyrics Line只表达future/past/active和可选动作，不解析LRC、不Seek、不自动滚动。Dock只转发Transport、进度、收藏和返回动作，不订阅AudioEngine、PlaybackController或QueueController，也不推进时间。

Queue沿用基础HTML的50/7/36标准与60/9/42沉浸几何、26视觉动作，并应用App.tsx最终10封面圆角；实际动作命中仍不小于44dp。Lyrics保留future 24%、past 50%、active纯白与1.018缩放，并应用最终780字重、紧字距和6px激活外环。Dock保留82最小高、11/13内边距、50封面、34/44控制和900px两层重排；App.tsx最后的`POLISH_CSS`把各断点外圆角统一覆盖为26。Phone/低高度仅做40/38封面和控制尺寸降级。

Dock歌词背景使用单一纯色Atmosphere，不使用渐变或封面模糊铺满。减少玻璃时只关闭Blur并改用不透明混合面，几何不变；减少动态时歌词缩放即时切换。Gallery只保存确定性Fixture标签与受控数值。正式QueueEntry、LyricsDocument、LRC解析、拖拽、跟随滚动、Seek、持久化及独立歌词页留给后续Domain/Feature阶段。

## ADR-022：Phase 3A 先固定 Domain 合同再选择数据库实现（2026-09-01）

Phase3拆分交付。首批只建立纯Dart Domain模型、Repository/Gateway合同和测试Fake，不安装Drift、不建表、不接UI或Controller。下一批Schema/Migration必须依赖这些项目自有类型并用内存数据库验证，不能让Drift row、SQLite句柄或平台插件类型进入Domain/UI。这样数据库候选或安全存储实现可替换，不改三套Shell。

`TrackRef(trackId, sourceId, sourceType)`是跨来源稳定引用；`QueueEntry.id`与TrackRef分离，允许同一曲目重复入队。所有持久时间先规范为UTC，Queue位置连续且顺序显式。来源删除或本地文件失效只改变`TrackAvailability`，不级联抹除用户歌单、收藏、历史或队列引用。HTML按标题slug、数组trackId和object URL生成的示例状态不迁入正式模型。

`MusicSourceConfig`只保存HTTPS无userinfo/query/fragment的公开base URL、公开Header、受限字段路径和`credentialRef`；Authorization、Cookie、API Key、Token、Secret、Password、换行Header均运行时拒绝。`SensitiveCredential`只为SecureCredentialGateway提供临时内存值，字符串输出固定脱敏，不提供数据库序列化。DomainFailure只保留枚举、来源ID、retryable和日志安全diagnosticId，不携带原始异常、URL或Header。

所有Controller异步状态使用显式idle/loading/data/empty/error，但Repository返回Domain数据/流而不返回UI组件。Phase4前不扩展现有PlaybackState为假播放实现；Phase3后续只负责数据库、Repository和Controller数据真相，音频状态机仍按原阶段执行。

## ADR-023：Drift原生后台数据库与不可变v1快照（2026-09-01）

Android和Windows共用Drift的`NativeDatabase.createInBackground`，SQLite由3.x build hooks打包；不选只支持移动端的sqflite，也不增加已被当前Drift原生路径取代的`sqlite3_flutter_libs`。路径由Flutter官方path_provider提供应用支持目录，测试注入内存executor或临时目录。只有data层可导入Drift/sqlite3/path_provider，UI、Domain和Shell继续只依赖项目接口。

首版包含主指令15张建议表、独立`queue_state`和`schema_migrations`。用户集合里的TrackRef不外键指向tracks/music_sources，避免来源删除时级联丢失歌单、收藏、历史和队列；catalog内部track_artists/album_artists及playlist_entries使用外键级联。Queue位置唯一、entryId与TrackRef分离；连续性仍由Domain QueueSnapshot/Repository事务验证。

schemaVersion1只处理首装`onCreate`并记录审计行，不伪造v1→v2。`make-migrations`生成的v1 JSON一经本批提交即不可覆盖；未来必须升版本、保留旧快照并用官方SchemaVerifier和数据完整性测试验证。生成的g.dart和快照在CI重新生成后要求Git零差异。

普通来源配置仍可能包含公开Header JSON，但数据库没有Authorization/API Key/Token/Password等独立列，只保存`credential_ref`；所有写入必须经过后续Repository对Phase3A MusicSourceConfig的运行时验证。安全凭据永不进入Drift row、迁移Fixture或日志。

## ADR-024：LibraryRepository使用原子catalog事务与脱敏row映射（2026-09-01）

Phase3C只实现`LibraryRepository`，不同时接Collection/Source/安全存储/Controller。Track/Album/Artist从Drift row返回前必须重走Domain构造验证；枚举、URI、JSON、时间或关联损坏统一转成无原始数据的`DomainFailure(databaseCorrupted)`，不将SQLite异常、路径、URI或metadata写入日志安全封装。

TrackRef仍以sourceType/sourceId/trackId为主身份。由于当前Track合同只包含艺术家显示名，data层用`SHA-256(sourceId + NUL + exact UTF-8 name)`生成source范围内可复现的派生artist ID；禁止随机/时间ID。如来源适配器需保留真实artist ID，必须先以独立Domain升级批次解决，不暗中塞进metadata。

upsert在一个Drift transaction中先替换Track关联，再batch conflict-update主表/关联，最后重建Album credits与计数。任一失败整批回滚，外部watch只在提交后看到一致快照。分页在limit/offset前固定标题、来源与ID排序，使用`limit + 1`判定hasMore。

Repository默认不拥有共享`AppDatabase`；显式`.owned`才在dispose关闭。生产initialize只执行user_version/quick_check/foreign_keys，官方`validateDatabaseSchema`留在测试，避免生产导入dev-only `drift_dev`。AppBootstrap在Dev Fixture和其余Repository策略完成前仍不打开DB。

## ADR-025：CollectionRepository保留用户引用并原子替换队列（2026-09-01）

Phase3D只实现`CollectionRepository`，不同时接Lyrics/Source/安全存储/Controller。Playlist、Entry、Favorite、History和Queue从Drift row返回前重走Domain构造；损坏枚举、时间、位置、引用或SQL异常只返回不含用户数据的`DomainFailure(databaseCorrupted)`。

系统歌单的`isSystem/systemType`是不可变身份，同一systemType只能有一个且不允许删除。自定义歌单删除只使用Schema已定义的playlist→entries级联，不触及catalog。歌单条目整体替换前必须验证playlistId、唯一entryId和0起始连续position，之后在单事务内delete+batch insert。

队列在单事务中先清除queue_state.current引用，再整体替换entries并写回current/updated。watch query显式`readsFrom`queue_state与queue_entries，外部只观察提交后快照。QueueEntry.id仍独立于TrackRef，同一曲目可重复。收藏幂等更新addedAt；历史按完整TrackRef删旧插新并裁剪到20条。

用户集合不要求catalog Track存在，来源被删除或文件失效时仍保留TrackRef，由后续Library/Source状态标记不可用。Repository默认共享`AppDatabase`，只有`.owned`在幂等dispose时关闭；AppBootstrap在其余Phase3数据策略完成前仍不接线。

## ADR-026：LyricsRepository只持久化已验证文档，不承担解析与获取（2026-09-01）

Phase3E只实现`LyricsRepository`，不同时实现LRC解析、在线歌词获取、Controller或UI。缓存主键继续使用完整sourceType/sourceId/trackId，歌词无需catalog Track或MusicSource row存在；来源暂时不可用时不会级联删除用户已有歌词缓存。

`lines_json`使用确定性的四字段数组对象：`startMs`、`endMs`、`text`、`translation`。读取必须拒绝非数组、未知/缺失字段、非整数时间及错误文字类型，再交由`LyricsLine/LyricsDocument`验证plain/synchronized时间一致性、同步顺序、非空行和翻译语言一致性。缓存更新时间即使未暴露给当前Domain也必须是可解析UTC毫秒；任何JSON/row/SQLite异常都转成不含歌词、TrackRef或SQL的`DomainFailure(databaseCorrupted)`。

单行upsert使用既有复合主键和`insertOnConflictUpdate`，删除不存在行幂等成功。Repository默认不拥有共享`AppDatabase`，只有`.owned`在幂等dispose时关闭。AppBootstrap在Source、安全存储与Dev Fixture策略完成前仍不接线；未来解析器或来源适配器必须先构造合法LyricsDocument再保存，不能把未验证原始LRC或响应体塞入数据库。

## ADR-027：MusicSourceRepository只保存公开配置与凭据引用（2026-09-01）

Phase3F只实现`MusicSourceRepository`，不同时选择安全存储插件或实现REST Adapter。Drift row保存MusicSourceConfig中的公开base URL、公开Header、相对endpoint、受限字段路径、状态/延迟及`credentialRef`；Repository和mapper不得导入或接收`SensitiveCredential`。凭据引用不是凭据生命周期：替换或删除引用时如何清理安全存储必须由后续Controller协调，data层不能猜测并删除外部秘密。

三个Map使用按key排序的确定性JSON；读取必须拒绝非对象、非字符串值，再重走MusicSourceConfig验证HTTPS无userinfo/query/fragment、敏感Header名、相对路径、受限映射、枚举和UTC时间。损坏JSON/row/SQLite异常只返回不含名称、URL、Header、credentialRef或SQL的`DomainFailure(databaseCorrupted)`。

sourceId是稳定身份；已存sourceType或builtIn不得转换，内置来源不可删除。自定义来源删除只移除配置，Schema刻意没有从用户集合TrackRef指向music_sources的外键，因此收藏、歌单、历史、队列和歌词引用仍保留，后续Library/Controller标记不可用。Repository默认共享数据库，只有`.owned`负责关闭；AppBootstrap继续等待安全存储与Dev Fixture策略。

## ADR-028：凭据只以随机引用跨越平台安全存储边界（2026-09-01）

Phase 3G选择`flutter_secure_storage 10.3.1`：其Android实现与项目现有API 36工具链一致，Windows解析为`flutter_secure_storage_windows 4.2.2`；暂不采用要求compileSdk 37的11.x。插件只能出现在`platform/secure_credentials`边界，Domain、Drift、Repository、Controller和UI不得直接依赖插件，也不得把凭据正文写入数据库、日志、异常或诊断字段。

`SecureCredentialGateway`返回192位`Random.secure()`生成的不可推导引用，存储前检查碰撞且绝不覆盖已有值。正文使用带schemaVersion和kind的确定性JSON，字段按key排序，读取时拒绝未知字段、非规范编码、非法引用及超限载荷，并重新通过`SensitiveCredential`验证。所有插件、随机数和编解码失败只映射为固定的日志安全失败类型；Dart `String`无法可靠原地清零，因此调用方必须缩短凭据驻留时间且禁止缓存。

Android使用独立`yymusic_credentials_v1`命名空间、RSA-OAEP/AES-GCM迁移策略，关闭resetOnError，并在Manifest明确`allowBackup=false`，避免加密数据与设备密钥分离后静默重置。Windows关闭旧版兼容迁移，使用当前Windows安全存储实现；其ATL/原生编译要求必须由GitHub Windows runner实际验证，不能以Android成功代替。

本批只实现Android/Windows Gateway与可注入字符串存储适配器，不在`AppBootstrap`提前接线。后续Controller更新来源凭据时必须按“先保存新秘密、成功更新数据库credentialRef、最后幂等删除旧引用”的顺序协调；任何中间失败都不得覆盖旧秘密或产生虚假的成功状态。

## ADR-029：生产空库与开发样本使用不同入口（2026-09-01）

Phase 3H用`AppDataServices`定义一个明确拥有资源的数据作用域：单一`AppDatabase`供四类Drift Repository共享，Android/Windows各构造对应`SecureCredentialGateway`，根`DependencyGraph`只暴露项目自有合同。`AppBootstrap`不直接导入Drift或插件；它异步请求作用域并负责正常销毁、失败和卸载后晚到完成的关闭。平台初始化错误只显示固定文案，不把异常、路径、URL或秘密带到UI。

默认`main.dart`始终使用生产工厂，在应用支持目录打开空白数据库；禁止为了让骨架“有内容”而自动填充HTML示例。独立`main_dev.dart`才调用内存数据库工厂和`DevFixtureSeeder`。Fixture写入前要求曲目、歌单、队列和来源均为空，进程结束后整体丢弃，不能指向生产文件或平台安全存储。

HTML四首示例曲目、两个歌单、队列和双语歌词通过正式Domain/Repository写入，但统一挂在禁用的`https://fixture.invalid`来源，曲目标记`sourceDisabled`。它不保存credentialRef、用户路径、content URI、artwork URI、可播放URL、收藏/历史或connected状态。这样可验证HTML状态到真实接口的映射，又不把网页假延迟、对象URL、在线状态或秘密冒充为生产能力。

只有`data/database`可以构造Drift内存executor；除`main_dev.dart`外的生产入口不得导入`dev_fixture`，UI/Shell继续不能导入data层。REST Adapter、来源凭据替换事务与Controller仍需后续独立决策；Phase 3H只关闭主指令规定的Domain/Database/Repository/安全存储接口/Dev Fixture出口。

## ADR-030：PlaybackController合成唯一播放与队列真相（2026-09-04）

Phase 4A先锁定项目合同与状态语义，再选择真实音频插件。`AudioEngineState`只报告idle/loading/buffering/ready/playing/paused/completed/error、时间、音量、速率和安全失败；它不知道Track、队列或UI。根级`PlaybackController`是唯一将Library Track、短期PlayableSource、Engine事件、Collection队列和MediaSession组合为完整`PlaybackState`的对象。`QueueController`仍作为主指令列出的业务入口存在，但只委托命令并返回`playback.state.queue`，不得保存第二个QueueSnapshot。

`PlayableSource`是仅在resolve到load之间存活的适配器输入：本地文件必须是绝对路径，Android引用必须是`content://`，网络必须是无userinfo的HTTPS。过期URL可能含短期query，授权Header可能含秘密，因此locator/Header在`toString`中无条件显示`<redacted>`，不得写入Drift、Fixture、公开状态或日志。插件异常由适配器优先分类；Controller对未知异常只产生固定diagnostic ID，不复制异常文字。

播放命令使用单一串行队列，避免快速点击导致load/seek/queue持久化交错。随机模式生成一轮稳定entryId顺序，关闭列表循环时一轮内不重复；repeat all才开始下一轮，repeat one只处理自然completed，用户手动next仍前进。删除当前项/清空队列停止引擎并清除当前Track；删除同TrackRef的另一个重复entry不得中断。持久队列在AppBootstrap期间恢复，但不自动解析或播放，避免启动即访问用户文件/网络。

MediaSessionGateway只把Android MediaSession/Windows SMTC动作转回同一Controller，并接收项目Track/PlaybackState；其失败是辅助能力退化，不能停止正在播放的音频。Phase4A不添加插件或平台实现，默认Engine仍不可用。只有后续Windows+Android对同一合同完成本地授权文件、受控HTTPS流、Seek/状态/错误和打包验证后，才可锁定正式backend并关闭Phase4出口。

## ADR-031：media_kit先作为隔离候选验证，不进入生产组合（2026-09-04）

Phase4B解析`media_kit 1.2.6`与`media_kit_libs_audio 1.0.7`，但它们仍是POC候选而非正式
backend。只有`lib/playback/media_kit_audio_backend.dart`可以导入插件；该文件把Player即时状态和
事件压成项目自有snapshot，并在边界直接丢弃原始error文字。`MediaKitAudioEngine`只依赖这个
可注入backend与现有AudioEngine合同，Windows路径转为file URI，content URI原样传递，HTTPS
Header只交给单次Media构造；所有open/transport/stream失败只暴露固定DomainFailure。

候选Engine串行接受命令，`open`固定`play:false`，0–1项目音量与0–100插件音量在边界换算。
loading、buffering、ready、playing、paused、completed、idle与error从同一backend snapshot组合；
dispose先停止接收新命令、等待已接受工作、取消订阅并幂等释放Player。队列、随机和循环继续由
唯一PlaybackController处理，不启用插件自己的playlist/shuffle/repeat，也不在Shell复制状态。

本批刻意不在`main.dart`、AppBootstrap或DependencyGraph创建候选Player；Fake backend测试不加载
native库。后续Phase4C/4D已在Windows/Android补齐本地WAV、Android content URI、受控HTTPS/Header、
Seek事件和脱敏失败矩阵，因此受控双平台POC已通过；实体扬声器、真机生命周期和许可证仍未通过，
候选继续不得上线。

发布合规也是选型门：已解析的wrapper包带MIT文件，但Android v1.1.8四个固定JAR只含两个`.so`
且没有LICENSE/NOTICE；Windows 1.0.9在构建时下载2023-09-24 libmpv归档。它们包含libmpv/FFmpeg，
不能用wrapper的MIT声明替代传递二进制义务。补齐精确构建配置、LGPL/第三方NOTICE、可替换/源码
提供策略并经发布审核前，不触发包含该候选的手动APK Release，也不正式锁定backend。

## ADR-032：真实本地音频证据使用运行时生成材料与隔离手动作业（2026-09-04）

Phase4C不向仓库加入WAV/MP3等媒体二进制，也不使用用户音乐或下载在线样本。专用测试在运行时生成
固定3秒PCM16单声道WAV，单元测试锁定RIFF结构、长度与SHA-256，再写入测试进程私有临时目录。
测试只把该绝对路径交给候选`MediaKitAudioEngine`，退出时依次取消状态订阅、释放Player并删除临时目录；
日志只记录平台和三项耗时，不输出路径、URI、Header或原生错误。

真实运行复用默认分支已注册的`foundation.yml`，但只有手动输入`run_native_audio_poc=true`时才调度；
该路径只运行checks及Windows/Android两个只读job，带`contents: write`的Android发布job明确跳过。
Windows 2025进程和Android API36 x86_64模拟器执行同一测试，不上传artifact、不创建Release。position推进与completed
可以证明native初始化、解码、时钟和控制链工作，但无头runner不能证明扬声器可听、音质、音频焦点、
后台或设备切换。生产`main.dart`继续使用`UnavailableAudioEngine`；Android `content://`与受控HTTPS
已在Phase4D专用作业通过，但许可证闭环前仍不能正式锁定或发布候选backend。

## ADR-033：受控来源POC使用debug-only Provider与短期loopback TLS（2026-09-04）

Phase4D不访问用户文件或真实第三方源。Android只在debug source set注册不可导出、不可授权给外部应用的
只读Provider，并仅打开cache中的固定运行时WAV；main/profile不注册。Windows/Android共用loopback HTTPS
server，短期证书与私钥运行时生成到Git忽略目录，原始文件立即删除且专用工作流不上传artifact。

POC Header是公开sentinel；网络探针只发HEAD、禁止自动重定向并将HTTP/offline/timeout/TLS映射为脱敏
DomainFailure。自签名TLS绕过与Windows无头sink只存在于名称明确的POC构造入口，生产默认继续验证TLS并
使用真实设备。精确提交`913f3d75`的专用运行33878710671双平台成功且零artifact/Release，关闭来源POC
出口；该证据不授权下载/离线能力，也不替代真实API、实体设备、后台/焦点或发布许可证审核。

## ADR-034：just_audio备用候选显式声明Header能力并保持生产隔离（2026-09-05）

Phase4E精确解析`just_audio 0.10.6`和`just_audio_windows 0.2.3`，但只作为与media_kit比较的
备用候选。`package:just_audio`只能由`lib/playback/just_audio_backend.dart`导入，插件对象和错误
不得越过项目snapshot；`JustAudioEngine`继续实现既有AudioEngine合同。生产main/AppBootstrap/Graph、
Shell、UI、数据库与Fixture均不得创建或引用该候选。

`just_audio_windows`没有声明直接请求Header能力，而just_audio内置代理会引入loopback cleartext及额外
安全审计。本阶段不默认启用两者：backend创建方必须显式声明Header是否支持，若来源带Header但能力为
false，则在调用插件前失败关闭并只暴露固定脱敏DomainFailure。Phase4F可以分别验证Android原生Header
和Windows无Header HTTPS；任何代理方案必须单独审计绑定地址、会话隔离、Range转发、生命周期与日志，
不能通过静默丢弃Header换取表面成功。

候选只映射一次性file/content/HTTPS来源，不使用插件playlist/shuffle/repeat，不启用
LockCachingAudioSource、StreamAudioSource或缓存清理，不实现下载/离线保存。Debug编译和Fake合同通过只
证明适配与打包；真实native运行、实体设备、后台/焦点、系统媒体会话及第三方NOTICE完成前不锁定正式
backend，也不触发包含备用候选的手动APK Release。

## ADR-035：无真实Windows播放端点时原生POC必须失败关闭（2026-09-05）

Phase4F为`just_audio`建立与media_kit合同相同的运行时WAV原生测试，且不启用Header代理、缓存、下载或
插件内部队列。Android API36完成duration、position、seek、pause、completed等链路。Windows适配层修复
WinRT插件在position和natural duration同为0时提前报告completed的问题，但修复后托管机调用play仍不推进
position。

专用Windows job会启动AudioEndpointBuilder与Audiosrv，并用PnP设备事实要求至少一个可用播放端点。
GitHub Windows Server 2025两项服务均Running但播放端点为0，因此测试在端点门失败；当前远程本机同样为
0端点，且Developer Mode关闭阻止Flutter创建plugin symlink。构建通过、服务Running、Android成功、Fake
时钟或media_kit无头sink都不能替代本候选的Windows真实端点证据。

因此Phase4F只关闭Android小批A，Windows与整个阶段保持打开，小批B不扩大。生产继续创建
UnavailableAudioEngine。后续可在有播放端点的Windows runner重跑同一测试；并行可审计media_kit的native
分发许可证，但任何候选都必须在自身剩余门禁关闭后才能接入Bootstrap。

## ADR-036：原生分发来源无法重建时只提交失败关闭清单（2026-09-05）

Phase4G不以Dart wrapper的MIT许可证推断native bundle合规，也不因SO/DLL内嵌配置显示LGPL模式就自动
批准发行。Android四个release JAR、APK三ABI以及Windows release DLL/Phase4C bundle已经用SHA-256逐字节
映射；真实FFmpeg/mpv配置也确认关闭GPL/nonfree。该证据回答“打包了什么”，没有回答“发行者如何交付
对应源码、patch、NOTICE和重新链接能力”。

现有Android脚本从可变main取得helper；Windows实际DLL配置与release前最近历史脚本相反，构建workflow
又允许未记录自定义命令和恢复cache，旧运行记录无法取回。故机器manifest固定为`inventory-only`、
`releaseApproved=false`、`productionWiringApproved=false`。不完整许可证集合不得放入应用assets；测试同时
锁定生产`UnavailableAudioEngine`、native哈希映射和阻断项。只有自行从不可变revision与记录patch重建、
补齐逐组件审查/NOTICE/对应源码/重新链接方案并验证双平台候选包后，才可通过新决策显式改写本门禁。

## ADR-037：失败关闭的native候选必须退出活动依赖图（2026-09-05）

Phase4G已经确定当前media_kit发布链无法满足来源重建、逐组件NOTICE、对应源码和重新链接材料门禁。
继续让候选留在pubspec、生成注册和每次Debug包中不会增加有效证据，只会扩大体积与误发面。因此Phase4H
从活动工程删除media_kit直接/传递包、隔离适配器、对应Fake/集成测试和历史专用CI job；旧代码仍可由
Git历史复核，Phase4B—4G报告与原生哈希manifest不得删除或改写成“从未评估”。

历史manifest新增`decision=rejected`和`activeDependency=false`，审计同时验证历史指纹仍完整、当前依赖与
入口为0。Android交付校验逐ZIP entry拒绝`libmpv.so`、`libmediakitandroidhelper.so`和media_kit路径；
Windows由生成注册门禁及GitHub干净portable bundle清单复核。该删除决定不等价于选择just_audio：后者仍须
在真实Windows播放端点通过自己的原生POC，生产Graph继续构造`UnavailableAudioEngine`。

旧Android debug-only Provider、受控TLS生成器和HEAD探针是与候选无关的受控测试基础设施，可供后续来源
验证复用；它们不接生产、不持久化响应、不加入release Manifest。Phase4H不进入Phase5，也不增加下载、
缓存、离线保存、WebView、后台服务、SMTC/MediaSession或新权限。

## ADR-038：队列元数据不等于已加载的播放会话（2026-09-05）

Phase4I不改公共API。PlaybackController内部单独记录成功load的QueueEntry身份：stop或idle后
保留当前曲目信息供UI显示，但后续play必须重新resolve/load；暂停恢复可复用已加载会话。
load失败不能因为currentTrack非空而绕过重试加载。显式重播已完成项从零开始。

队列替换、清空和移除共用提交路径：丢弃当前Entry身份或完整TrackRef前先stop，stop失败不写入新队列；
保存队列失败保留原快照，已成功停止的音频不自动恢复。只重排且保留当前身份/引用时不中断音频。
同一当前曲目的error phase与failure必须同时保留，不能清除failure却保留error phase。

自动下一首绑定触发时的会话revision和Entry身份；一次完成只入队一次。手动选择、停止、暂停、Seek或
新一轮播放使旧自动操作失效。完成后的重复快照仍可更新控制值，但更改循环模式不应把重复completed
伪造为新播放周期。旧循环测试补显式重播，不移除随机/列表循环/单曲循环断言。

dispose在异步曲目查询、来源解析、load返回后检查，已关闭Controller不再发起play。Controller仍不拥有
Engine的dispose；根依赖释放职责不变。该门禁不宣称能识别一个没有来源身份的Engine流在新load完成后
错误发送的旧曲快照；插件适配器仍须隔离自身过期事件。双平台原生POC和生产接线门禁保持不变。

## ADR-039：把原生编译与有播放端点的运行分开记录（2026-09-05）

Phase4J证实GitHub Debug EXE需要本机缺失的Debug CRT，实际启动为`0xC0000135`，而不是播放失败。
不通过公共artifact补发Debug运行库、不改系统权限或安装驱动。使用明确的Profile诊断入口，
由GitHub编译完整AOT包、核对原生导入和Commit；有真实端点的本机再执行原来的WAV集成测试。
Profile是测试构建，不是Phase11 Release，也不是正式业务应用；默认入口仍使用UnavailableAudioEngine。

手动`build_windows_audio_probe`默认false，只运行checks/Windows job并生成1天诊断artifact，
与原有双平台无产物POC互斥；Android APK/Release交付明确跳过。原有POC无产物门禁不放宽。
运行者必须从API取得精确artifact digest/head SHA，核对SDK引擎与AOT身份、路径安全与全文件清单，
不允许用旧结果或本地改过的资产宣称某个GitHub Commit通过。Debug拆分路径单独记录Dart/native身份。

本方案只解决诊断交付，不把构建成功、时钟推进或自动测试当作主观听感/后台/媒体会话验收。
真实结果和范围记录于[Phase4J报告](phase_4j_windows_native_validation_report.md)。

## ADR-040：HTTPS POC 使用不可变上游测试夹具与默认 TLS（2026-09-05）

旧 Phase4D 自签名服务器依赖测试信任绕过，不能用于当前 just_audio 的原生 TLS 验收。
Phase4L 使用 AndroidX Media 自身 WavExtractorTest 的公开 `media/wav/sample.wav`，固定
提交 `43e3af79dabb43a69badffbbdfa6d421a1cdb36c`、88,278 字节、SHA-256
`1b35cc093f3d56732b19ff936c21b5bca8195135d63708f6c6488eba5803ddce`。
RIFF 为 PCM16、mono、44100Hz、88200 字节/秒、1秒。上游仓库 LICENSE 为 Apache-2.0，
该文件 SHA-256 为 `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30`。
这是公开测试数据的来源记录，不代替最终应用逐组件许可证审计。

此决策只调整 Phase4F 的 HTTPS 夹具策略：HTTPS 内容不再要求由本测试运行时生成，
本地3秒 WAV 仍使用原生成器。测试先以默认 HttpClient 信任、禁重定向、限时/限额在内存核验
完整字节与 Range；随后引擎直接读取固定 HTTPS URL，不把预检字节转换为本地或字节流音源。
没有证书回调、测试 CA 安装、代理、Authorization、用户 URL 配置、文件写入或产品下载接口。
不提交、打包、上传媒体或其 Base64；服务不可用或指纹漂移均失败关闭，不自动换源。

新增显式 `include_https_audio_poc=false` 的 CI 选择；Windows Profile 诊断扩展同名编译模式，
两用例与1秒/3秒计时分别验证，旧一用例模式不放宽。模式进入构建元数据、准备 manifest 和结果，
调用者必须匹配模式，旧单项结果不能被当成 HTTPS 通过。原生产物与真实端点规则沿用 ADR-039。
本批无生产公共接口修改，不接音频/业务页面；HTTPS通过也不自动批准最终选型和应用发布。

来源：[上游测试](https://github.com/androidx/media/blob/43e3af79dabb43a69badffbbdfa6d421a1cdb36c/libraries/extractor/src/test/java/androidx/media3/extractor/wav/WavExtractorTest.java)、
[夹具](https://github.com/androidx/media/blob/43e3af79dabb43a69badffbbdfa6d421a1cdb36c/libraries/test_data/src/test/assets/media/wav/sample.wav)、
[许可](https://github.com/androidx/media/blob/43e3af79dabb43a69badffbbdfa6d421a1cdb36c/LICENSE)。

## ADR-041：验证实际打包的完整许可证，不重复维护原文（2026-09-05）

Phase4M核对 Flutter 3.47.2 的 LicenseCollector 与 ServicesBinding：构建器会收集 Pub 包 LICENSE，
按完整文本去重并保留包名，原生包保存为 GZip `NOTICES.Z`，运行时由 LicenseRegistry 按需读取。
Phase4L Windows 实际包的四个许可组已包含当前音频六个 Dart 包，逐组原文字节/哈希等于 Pub 原件。
因此新增独立副本并不能提高准确性；本批为已打包原文增加不可静默跳过的源码与产物校验。

`docs/legal/just_audio/manifest.json` 固定六个版本、原文长度/SHA-256和两个原生构建源文件指纹。
源码检查必须匹配lockfile和实际Pub缓存。APK/Windows检查必须找到唯一 NOTICES.Z，限4 MiB压缩体积、
16 MiB展开体积、严格UTF-8及最多10000组；每个目标包恰好出现一次，必须完整文本匹配，
不能通过重命名、只保留许可证名称、重复标注或篡改段落让校验通过。原有48项设计资产校验不变。

技术能力仍以Phase4L同提交的真实POC为准：Android file/content/无Header HTTPS，Windows file/无Header HTTPS。
六包原文检查不等于所有Android Maven传递材料、系统组件、完整发行或用户可见许可页面已经验收。
Media3 1.4.1 的注释tag解析到 `c35a9d62baec57118ea898e271ac66819399649b`，根LICENSE为11358字节，
Apache-2.0，SHA为 `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30`；
just_audio包原文本身包含ExoPlayer的Apache全文，但这不能替代其Maven传递NOTICE覆盖检查。
Windows候选没有额外bundled player libraries，实际使用系统WinRT MediaPlayer。

manifest显式保持 `releaseApproved=false`、`productionWiringApproved=false`、
`transitiveNoticeReviewComplete=false`。下一批继续原生传递材料/许可展示与正式接线，
不得把新增校验“通过”解读为整个应用已获发布批准。被拒绝media_kit清单与历史不变。

来源：[just_audio 0.10.6](https://pub.dev/packages/just_audio/versions/0.10.6)、
[Windows 0.2.3](https://pub.dev/packages/just_audio_windows/versions/0.2.3)、
[AndroidX Media精确LICENSE](https://github.com/androidx/media/blob/c35a9d62baec57118ea898e271ac66819399649b/LICENSE)。

## ADR-042：随应用保留 Android 音频闭包的原生许可材料（2026-09-05）

Phase4N以应用真实解析的Media3闭包为范围，共51个坐标，而非仅插件声明的10个Media3模块。
Gradle报告只解析选定外部模块，避免AGP本地插件的多变体歧义；相同文件名且SHA相同的重复
变体归档去重，BOM/重定向坐标保留为空归档列表，不伪造二进制。解析版本和每份实际归档的
长度/SHA均进入可比对清单；开发机绝对缓存路径只存在忽略的build报告中。

生成器读取精确POM及必要父POM，禁用DTD/外部实体；查找AAR/JAR及嵌套classes.jar中的
LICENSE/NOTICE/COPYING/AL2.0/LGPL2.1文本，完整UTF-8原文有界读取并去重。
当前有三份不同原文：固定Media3上游Apache-2.0、ExifInterface归档内Apache原文、
checker-qual归档内包含著作权的MIT原文。Guava/failureaccess/listenablefuture的许可继承
精确父POM；没有用通用MIT模板替换带著作权原文。生成结果为66,604字节JSON，SHA见机器清单。

该数据随两平台应用资产打包，Windows携带的条目明确属于Android能力，不声称其二进制
进入Windows。Android构建后重新解析真实闭包并逐项验证归档及重新生成原文；两平台均对
实际包内资产逐字节校验。新增唯一资产白名单项，原48项设计资产与六个Dart包门禁不变。

额外只读解析Profile与Release：Profile同为51项；Release为48项，恰好不含jsr305、
error_prone_annotations和checker-qual三项注解依赖。机器清单明确记录三个变体的差异，
逐项精确比对，不能允许任意子集缺失。随应用保留51项材料超集；这不是Release构建成功证据。

这关闭当前音频闭包的工程材料缺口，保留releaseApproved=false；整个应用仍须Phase11发行
审核和Release构建，未来依赖版本改变必须重审材料。用户可见许可入口和生产播放器接线尚待
下一批，不在本批翻转已声明的生产状态。没有运行时联网收集许可或媒体下载。

来源：[固定Media3源码](https://github.com/androidx/media/tree/c35a9d62baec57118ea898e271ac66819399649b)、
[Guava精确版本POM](https://central.sonatype.com/artifact/com.google.guava/guava/33.0.0-android)、
[Checker Framework 3.41.0](https://checkerframework.org/releases/3.41.0/manual/)。

## ADR-043：许可查看使用自有合同与原生控件（2026-09-05）

新增纯Dart `SoftwareLicense` 与 `LicenseRepository`，自有app适配器读取Flutter
`LicenseRegistry`和Phase4N已审资产；UI只接收合同，不读取文件或导入第三方插件。
SDK条目保留全部段落内容，Android材料逐文档长度/SHA校验并按同文档聚合组件，不请求网络。
适配器限制数量/文本大小/总时长，失败仅返回固定安全错误，允许用户主动重试。

设置入口推入独立`/settings/licenses`路由，搜索组件名、按需显示全文，使用YYSearchField、
YYButton及自有Dialog/BottomSheet；不是Material LicensePage，不复制完整Settings功能。
模态原文进入导航栈，返回先关原文再离开许可页；长文本在模态内部滚动。依赖由Graph注入，
不在build启动异步请求，不保存第三方许可内容到数据库，不引入全局播放状态或媒体文件。

## ADR-044：当前音频工程选型与根资源所有权（2026-09-05）

选择锁定的 just_audio 0.10.6 + just_audio_windows 0.2.3（Media3/WinRT），
依据 Phase4L 同实现双平台原生运行、Phase4M/N 源码/实际包内全文核验、Phase4O 可见许可入口。
只批准当前无代理/Header 的工程接线；全应用发行仍未批准。更新六包清单的工程能力标志，
但保持其六包覆盖范围和 releaseApproved=false，原生范围仍以独立 manifest 为准。

新增 app 层 AudioEngineFactory，默认 Bootstrap 在数据作用域之后只创建一次后端，再移交 Graph。
Widget 测试注入 Fake，main_dev 显式不可用；不按布局断点创建播放器。平台限定本地解析器只将
已经由 Repository 提供的 Track 转为短期 PlayableSource，不读磁盘、访问网络或取得权限。
Android 优先 content URI，回退绝对 POSIX 路径；Windows 接受驱动器绝对路径或明确 UNC 文件，
拒绝设备命名空间、相对路径和跨平台引用。REST 必须等待 Adapter，不解析 metadata URL。

PlaybackController.close() 同步停止接受命令/状态更新，并等待订阅取消、已有命令和媒体同步；
Graph.close() 共享同一个 Future，逐项释放 engine/media/data，即使一项失败也继续，最后给固定
app.shutdown-failed。dispose() 保留 Flutter 同步接口，安全启动关闭；有验证需求调用 close()。
Bootstrap 获取资源期间的异常或晚到结果都执行清理，不展示原始路径/插件异常；恢复队列不自动播放。

## ADR-045：Shell 播放器只消费根 Presenter（2026-09-05）

新增 app/PlaybackPresenter，订阅根 PlaybackController，只计算只读 YYNowPlayingViewData 与
控件可用性，转发既有播放/队列/随机/循环命令；不复制位置时钟、队列算法、历史或音频实例。
Presenter 仅保留 UI 命令执行中与脱敏动作错误，Graph 在 Controller 前解除其订阅。
三个 Shell 接收已构造的播放器 Widget 插槽，由 AdaptiveRoot 选择 Mini 或 Desktop Compact/Full。
因此宽度/路由变化不重建 Presenter/播放核心，也没有平台专属业务控制器。

ShellPlayer 的短期拖动值由 Widget 持有；Seek 绑定队列条目身份并以该身份重建拖动子树，
换曲/换 Shell 不把旧手势提交到新曲。持久位置、音量仍只来自 Controller，预览不调用引擎。
命令串行期间禁用相应操作，失败使用固定文案；空队列/不可用后端不假装播放。
未实现的收藏、歌词/全屏、队列/设备工具保持空回调即禁用；不打开骨架页冒充业务功能。
当前无封面来源 Gateway，播放器暂用既有纯几何占位，后续真实 Artwork 接口优先替换。
Controller.seek 增加可选 expectedEntryId，并在串行命令真正执行时再次核对；Presenter 的前置核对
不能代替队列内部保护，防止 Seek 排在外部换曲操作之后。系统媒体接口仍可不传此参数。
修正旧播放器主按钮误用 accent 阴影：采用 App.tsx .player-control.primary 的 (0,8)/22/16% 深色，
不影响普通 Primary Button；对应基线只在确认几何与颜色差分后更新。
未开放详情的曲目信息使用静态 Semantics，保留正常文字对比度且没有按钮/onTap 语义；
动作按钮仍按可用性禁用，不修改公共控件的全局禁用样式。

## ADR-046：Inspector 与底栏共享同一个绑定入口（2026-09-05）

设计系统的 YYNowPlayingInspector 仅消费视图与受控回调；ShellPlayer 的 inspector 模式复用
根 Presenter 和相同的手势预览/提交/entryId 保护，不生成新 Controller。多个可见表面只各自持有
短期手势，提交后从根状态收敛。Windows320/Tablet260使用同一内容组件、不同几何容器；
短高度独立滚动，收窄卸载面板不停止或重建音频。来源只显示 local/rest 类型，不暴露路径或URL。
未开发的完整队列/歌词/设备入口禁用，队列仅显示真实总条目数，不把物理顺序冒充随机后的下一首。

## ADR-047：窗口生命周期独立于播放根资源（2026-09-05）

YYMusicApp根作用域拥有WindowPresenter/Gateway，三个Shell只接收已构造Chrome，不调用Win32。
窗口通道只操作本Runner HWND；握手成功前保留系统caption，成功后保留原生resize边界，Flutter
42dp非交互标题区域驱动移动/双击最大化，控件区域不作为拖动区。窗口快照以原生状态为准。
WM_CLOSE/Alt+F4触发closeRequested，Presenter幂等等待业务Graph.close所有释放尝试完成后调用
原生completeClose，才允许WM_CLOSE销毁。窗口Gateway不能作为Graph内的提前释放资源，否则
退出握手会在最终关闭前断开。UI卸载时解除通道/订阅，晚到回调不能更新已销毁状态。
没有新包、全局系统修改、尺寸/位置持久化或全屏能力。本批CI先跑原生窗口测试再重新构建正式
Debug，原生测试不关闭测试进程，只证明关闭请求被Dart接收且批准前窗口仍存在。

## ADR-048：首页“最近添加”使用首次入库时间（2026-09-05）

不能用文件修改时间或标题排序伪造“最近添加”。tracks.added_at_ms由Repository首次插入时记录，
后续upsert保留原值；v1迁移旧行保持NULL而非给全部旧库写“今天”。v2新增排序索引和有界时间/分页
合同，首页不订阅全曲库来做客户端排序。起止时间包含端点、按首次时间倒序及完整TrackRef稳定排序。
迁移保留v1快照、引用、收藏和队列，不删库，审计与新增列/索引在同一事务。真实业务界面后续接线。

## ADR-049：首页是根数据的有界投影，不拥有播放器（2026-09-05）

HomeController由DependencyGraph持有，三个独立布局只组合受控原生组件；路由/断点变化不创建
新数据库或AudioEngine。最近7天查询20条，历史20条按完整TrackRef去重解析；精选最多6首，
优先可用历史，否则只过滤普通曲库首20条中的本地曲目。这不是完整推荐算法或全库本地筛选。
目录显式刷新，历史/来源订阅更新，分区失败互不覆盖；请求与事件版本拒绝晚到结果，错误为固定文字。
来源只显示持久公开状态，不读取端点或秘密，也不把卡片当连接测试。选择曲目先复用已有队列条目，
没有则追加后播放，不替换整队列。清除历史必须由视图确认，只修改历史Repository。
根关闭同步禁止新操作并取消监听，等待首页在途读取/动作完成，再释放底层存储；不把Widget销毁
等同于数据Future已经结束。无曲目使用真实空态，不注入HTML样本；本批封面保留明确占位。

## ADR-050：搜索先按实体分页，再于同一只读语句展开关联（2026-09-05）

CatalogSearchRepository由正式DriftLibraryRepository实现，但不扩张普通LibraryRepository合同或让UI
订阅全库过滤。歌曲、专辑、艺人各自分页：CTE先筛选/稳定排序并取limit+1个实体，外层连接有序
艺人信息再按完整身份归组，避免多艺人吃掉页容量或两次读取混合不同版本。查询值/来源/分页全部绑定。
初版尝试用Drift transaction保护两次读取；真实双连接测试发现其BEGIN IMMEDIATE会排斥并发写入，
因此改为一次SELECT，不改全局SQLite设置、不开写事务。子串搜索仍可能扫描数据库，不是FTS/拼音索引，
大曲库真实设备性能仍待Phase6出口验收；不把450首合成测试外推到任意规模。
内建lower只保证ASCII大小写折叠，中文按字面子串；百分号/下划线不是通配符。取消为合作式结果丢弃，
不谎称底层语句已中断。取消异常独立于数据库损坏错误；空查询不触发SQL。
SearchHistoryRepository只在显式record时保存用户本机搜索，ASCII归一查询和可空来源共同确定身份。
旧ID等价项替换、写入与保留20项在同一事务，clear只清历史；查询本身无写入、网络或音乐下载。
共享存储默认不归历史Repository关闭，拥有存储时排空在途操作再关闭。根/UI接线属于下一增量。

## ADR-051：搜索按独立结果区域投影，播放意图可撤销（2026-09-06）

Phase6D把原生Search接入根图，同一个Library实例提供CatalogSearch合同，不创建另一套数据库或引擎。
三类实体按本地/已入库REST引用分为六区；每页20条，完整身份去重但offset仍按原始返回行数递增。
每区200条上限和Sliver惰性构建约束内存；新查询取消旧token，仅丢弃迟到结果，不承诺打断SQLite。
页面明确实时在线搜索尚未实现。输入法结束后300ms防抖，历史只在显式提交时写入，record/list/clear
串行防止清除后复活；任何异常都以固定文案呈现，公开来源名之外不读取配置私密字段。
Enter只在可见曲目区域选第一个可用结果，先本地后已保存在线引用；已有本地结果不等慢在线/其他实体。
输入/筛选/离页/销毁撤销播放意图；根播放器在队列调度和异步读/解析/加载边界检查，撤销加载不播放。
原子复用或追加完整TrackRef，保留其他队列条目；不因撤销而回滚已提交的追加。普通playEntry行为保留。
根关闭先禁止新工作、取消搜索timer/订阅，等待在途查询/历史/播放任务后释放存储；控制器借用的合同
不由其关闭，正式数据作用域负责历史Repository与数据库。Ctrl+K聚焦/滚动属于UI，不在业务层持有FocusNode。

## ADR-052：音乐库浏览使用来源隔离的只读分页合同（2026-09-06）

CatalogBrowseRepository独立于普通Library和Search接口，但正式实现共享DriftLibraryRepository、
数据库和生命周期。排序/过滤/专辑与艺术家详情是数据能力，不能让页面先读取整库再排序分页。
AlbumRef/ArtistRef按既有Schema保留sourceId与实体ID；曲目仍使用完整三元TrackRef。
私有Dart part封装浏览SQL；排序仅由闭合枚举映射，所有外部ID、状态、来源和页参数使用绑定值。
单条CTE先过滤/排序并取limit+1实体，再展开有序艺人，避免关联截断、N+1和多读版本混合。
NULL始终最后，主排序支持升降序，完整身份后备顺序保持升序；文字只用SQLite ASCII lower，
按艺人排序指首位credit，不假称拼音/区域化排序。不同分页请求不提供跨写入快照保证。
专辑/艺人筛选使用存在匹配曲目的条件；组合来源/可用性/艺人要求同一条曲目满足，不能分开匹配。
返回计数是完整实体的既有聚合值，不是过滤后条数。来源配置已被删除也不自动隐藏保存的引用。
复用SearchCancellation合作式丢弃，不声称中断原生SQL；缺失返回null，数据库损坏保持固定安全错误。
本批只导出根数据合同，不改UI/Schema/依赖，不写搜索历史、联网、扫描文件或创建新的音频实例。

## ADR-053：音乐库分类页是根目录的有界投影，曲目不可播放不等于不能收藏（2026-09-06）

LibraryController由根图拥有，三端布局共用分类/排序/筛选与播放器，不在Widget创建业务引擎或存储。
目录分类各保存一个有类型实体的分页投影，每页20、最多200条原始返回行；完整身份去重不改变offset。
排序按分类保留，来源/状态改变使所有目录旧token失效，切分类保留其他页；一次查询错误不清除旧行。
歌单暂使用既有元数据流并截取200项，不假装该合同支持数据库分页、目录来源筛选或完整歌单管理。
收藏/歌单/来源订阅互相独立；公开来源名可用则显示，否则显示未配置，不解析URL/凭据到界面。
播放使用根playCatalogTrack原子复用/追加，切分类/筛选/离页/关闭撤销未执行意图。已接受的收藏写入
排空后才释放共享数据库，离页不会悄悄回滚用户操作；引用不可用仍允许收藏，并不允许实际播放。
YYTrackTile新增默认false的allowMoreWhenDisabled，只有Library显式启用；主动作仍禁用/变淡，
更多按钮保留可见性和操作能力，旧组件调用方和Golden不变。菜单为页面内原生Flutter浮层，
不覆盖Shell播放栏/导航；Esc、Android Back或页面失活关闭菜单，返回焦点由页面持有。
根关闭先同步停命令/取消token，等待本页在途读写与订阅释放后，再关闭共享存储。
专辑/艺人/歌单本批只展示真实元数据；不添加模拟详情/导入/连接成功按钮，不把持久REST引用称为实时在线。

## ADR-054：详情为根注册的短期只读会话，分页与摘要独立（2026-09-06）

CatalogDetailSessions由根图持有，只借用既有CatalogBrowseRepository。每次打开专辑或艺人创建
独立会话，目标固定为完整AlbumRef/ArtistRef；不以显示名称猜关联、不创建第二个数据作用域。
摘要先确认身份；缺失不发子查询，错误不伪装空目录。艺人专辑与歌曲各自请求、错误、重试，
保持完整目录计数。分页20、200原始行上限、完整身份去重，不把去重后的数量用于offset。
刷新取消摘要及全部分区旧token；迟到结果不通知、不改变新一轮loading/错误。取消不承诺中断SQL。
可由模型验证的来源/专辑关系不符时整页失败，保留已加载数据；艺人关联由Repository的曲目credit
合同保障。Track只有艺人显示名，合辑的album artist也不必包含曲目艺人，不做名字/专辑credit猜测。
关闭会话同步禁用新查询并取消token，注册表保留它直到在途Future排空。根关闭先停止所有会话，
再等待其关闭，最后关闭共享数据库；不将Widget.dispose等同于底层读取已经完成。
Phase6G1只提供可测试读模型与生命周期；路由、三套布局及曲目动作在Phase6G2接入。
审查补充：详情、Library和Search均按剩余容量计算末页limit，并按该limit截断实际响应。
只检查offset>=200再固定取20，遇到15/18条的短中间页会越界；新增三个先失败的回归后修复，
原始offset语义、重试、去重和UI不变，不降低200上限或更改Golden。

## ADR-055：详情路由保留来源与返回栈，界面复用根播放（2026-09-06）

AppNavigation增加类型化openAlbum/openArtist，URI路径只放实体ID，source查询参数单独转义；
入口禁止名字查找和模型对象extra兜底，非法/重复/缺失来源参数显示安全错误，不输出原始路由。
详情Page Key同时包含路由栈Key和强类型完整引用；系统替换同路径的来源/ID时关闭旧会话及滚动Bucket，
相同完整引用更新则保留状态，不能只按/album/:id模板复用旧来源的数据。
详情路由为普通非全屏页面，使用相同AdaptiveRoot/PlaybackPresenter，push/pop保留原主页面与详情栈。
每个详情Widget只持有根注册的会话、滚动与选区；平台/尺寸改变不创建另一会话或播放器。
详情State位于可切换Shell之上，由App注入frame包装内容；不能把State放在Phone/Tablet
不同父类型之下，否则600断点会销毁路由会话。视图层不自行依赖或选择Shell。
三套布局使用同一PageStorageKey，在各自路由Bucket内恢复滚动位置；不串页或因横竖屏归零。
详情会话增加借用根PlaybackController与MusicSourceRepository；公开来源名独立加载，失败回退，
不等在线连接或接触凭据。仅当前可见、可用曲目可以播放；刷新/覆盖路由/销毁撤销在途播放意图。
根追加/复用队列已经提交的部分不因撤销回滚，播放仍持续于正常离页；会话关闭等待在途动作。
本增量暂不提供详情收藏菜单；YYTrackTile新增默认true的showMore，详情显式false隐藏无动作按钮，
现有调用方保留原样。音乐库专辑卡启用和艺人明确详情按钮引起的视觉变化分别更新Golden，
不降低比较阈值，不改变其他旧页面基线。详情外观延续App.tsx标题/图标/20圆角/阴影，封面明确占位。

## ADR-056：详情收藏为按需投影，已接受写入排空后关闭（2026-09-06）

详情会话借用根CollectionRepository，不创建收藏存储或依赖Library页面启动。首次打开曲目菜单才订阅
收藏流，普通详情读取不新增收藏查询；私有投影只缓存完整TrackRef集合、ready和安全错误，不以名字关联。
读取失败禁用收藏写入并允许单独重试，不把未知状态当成未收藏；旧订阅代次取消，迟到事件丢弃。
收藏命令按可见完整引用和已知状态执行，失效曲目也允许收藏；与详情播放共享busy，防止重复提交。
成功写入后重新订阅取得当前状态，旧代次不能覆盖成功后的新投影。离页/刷新不撤回已经接受的收藏写入；
关闭同步停止新命令、关闭投影，根注册表等待写入、订阅取消及其他在途工作后才释放共享数据库。
订阅的创建/取消也登记在会话pending中，即使订阅建立过程重入关闭也必须清理刚创建的订阅。
菜单仅为原生受控UI，不执行构造期查询；操作反馈不含原始错误。Phone底部/桌面居中，Esc/Back先关闭
菜单、恢复有效焦点；刷新、分区切换、失活关闭菜单。复用既有设计原语和根播放，不引入下载或假动作。

## ADR-057：歌单编辑采用原子命令与根级写入排空（2026-09-06）

既有savePlaylist是引导/数据层upsert，不适合用户创建或重命名：ID碰撞可能覆盖，读取后保存也可能
复活已经删除的目标。CollectionRepository新增createPlaylist（只插入自定义歌单）和renamePlaylist
（只修改仍存在的自定义歌单名称），Drift事务中核验身份，不改变Schema或既有savePlaylist语义。
编辑名称统一trim、1–512字符并拒绝控制字符；创建不允许系统身份，改名保留description/createdAt/
全部条目，updatedAt取现有值与当前UTC时间较晚者。重命名不存在目标失败，禁止静默重建；删除保持既有幂等行为。
删除复用已有系统保护/级联条目删除，不删除曲目、收藏、历史、队列或来源内容。

根PlaylistController只管理命令生命周期，借用根CollectionRepository；列表仍属于既有Library投影，
不建立第二列表/存储，不在构造期查询，不依赖某个Shell的启动。ID采用随机128位值，不按名称生成。
单命令busy拒绝并发点击；结果为固定状态/安全文案而不是异常原文；UI负责未提交草稿与删除确认。
所有命令在发出通知前登记，已接受的写入不因离页或根关闭而撤回，关闭拒绝新命令并等待已登记工作，
最后才释放共享数据库。创建碰撞失败而不是覆写，用户可重试；不自动重试可能已成功的存储写入。
Phase6H1只提供这个数据/状态基础，Phase6H2再接三端原生编辑界面，未接线不得宣称用户已能管理歌单。

## ADR-058：歌单草稿位于自适应 Shell 之上，确认与写入分离（2026-09-08）

AppRouter借用根PlaylistController，在StatefulShellRoute的AdaptiveRoot上方放置编辑宿主，
以受控作用域向Library提供创建/重命名/删除请求，不扩展持久化或建立第二份列表。
宿主拥有未提交文本与焦点，Phone/Tablet Shell替换和窗口尺寸变化不销毁草稿；
离开Library或覆盖其路由时关闭草稿。接受的命令仍由根Controller排空，不因Widget销毁取消。
异步完成必须检查宿主挂载及每次打开的独立递增代次，不能关闭或覆盖随后打开的新草稿。
请求值可能是Dart规范化的同一const对象，不能用identical(request)作为会话身份。
关闭后的失败在Library显示可确认的安全提示，不改变新草稿；进程关闭后不尝试通知已销毁的界面。

删除请求只打开确认UI，明确只删除歌单和条目，不删除歌曲文件或来源；确认按钮才调用命令。
系统歌单无编辑入口，命令层系统保护仍独立生效；busy禁用输入/提交，失败保留文本及安全反馈。
列表继续响应既有Library投影，不乐观捏造成功或对已删除身份执行upsert。

Phone使用YYBottomSheet，Tablet/Windows使用YYDialog；原生名称输入保持field语义与done动作，
共享搜索输入既有的原生选择手柄/编辑菜单，不复制搜索图标、清空搜索文案或search输入动作。
宿主覆盖整个Shell的点击、焦点和语义，处理Back/Esc及快捷导航离页，输入时不触发播放快捷键。
SafeArea和viewInsets参与可用高度计算；变更后仍按完整App.tsx覆盖层与基础HTML检查三端Golden。

## ADR-059：歌单条目以身份和锚点原子编辑（2026-09-08）

既有 replacePlaylistEntries 保持引导/导入整表替换合同；交互不能读取列表后整表覆盖，
否则会丢失期间的追加或改序。新增 PlaylistEntryDraft（ID、完整 TrackRef、UTC addedAt），
appendPlaylistEntry 在事务内确定尾部位置；removePlaylistEntry 按条目 ID 移除；
movePlaylistEntry 的 beforeEntryId 指定同歌单现存锚点，null 表示移动到当前末尾。
条目身份独立于曲目，同一曲目可重复加入，本地/在线/已失效来源的完整软引用均保留。

三命令只允许现存自定义歌单，系统歌单拒绝交互编辑。追加 ID 为全表唯一，碰撞失败而非覆盖。
缺失歌单、移动目标或锚点，以及跨歌单条目引用返回 notFound。移除真正不存在的条目幂等；
自己作为锚点、已相邻或已在末尾均无操作，无操作不修改 updatedAt。
位置必须从零连续；通过 count/max 与既有唯一/非负约束验证，不默默修复损坏数据。
受影响位置先移入空闲正数区间，再回填最终位置，避免 SQLite 唯一冲突和负数 CHECK 失败；
目标移动、邻居位移、父歌单 updatedAt 在同一事务，任何失败整体回滚。
仅真实改变触发父歌单时间更新，取当前 UTC 与旧值较晚者；不改变名称、说明、createdAt、
条目 addedAt、曲目/收藏/历史/队列/来源或文件，不添加 schema/依赖。

根 PlaylistController 复用已有命令通道，追加 ID 采用独立随机 128 位身份且仅在接受命令后生成。
元数据与条目命令共享 busy；接受后先登记再通知，关闭排空后才能释放根存储。
失败使用固定状态/安全文案，不自动重试不确定写入，不构造第二份列表或播放实例。
Phase6H3 只实现可验证命令基础，后续增量再接读取会话和原生管理入口。

## ADR-060：歌单内容以一致窗口读取，通知和在途查询分别排空（2026-09-08）

CollectionRepository 增加 readPlaylistContent(id, PageRequest) 与 watchPlaylistContentChanges()。
前者返回单条 SQL 的 PlaylistContent 或缺失 null；包含父歌单、真实总数和按位置排序的窗口，
每项为 PlaylistContentEntry（PlaylistEntry 与可空 Track）。完整 TrackRef 左连接，条目 ID 聚合，
重复歌曲不去重；缺失曲目保持引用而非自动删除或杜撰标题/路径。现存空歌单与父歌单缺失不同。
SQL 先分页后展开艺人，禁止逐条 getTrack/N+1，不扫描解析窗口外曲目；count/max 检查位置连续性。
本合同限自定义歌单，系统歌单实时视图由收藏/历史/队列合同另行提供，不能把持久空条目误报为空系统歌单。

失效流不做内容查询或携带整库数据，可因相关表的其他歌单改变或事务回滚而保守失效。
它不是提交日志，收到通知必须重读当前持久内容，不能把通知本身当作写入成功。
根 PlaylistContentSessions 创建惰性独立会话；首次 start 先订阅再读取。会话保留单个一致窗口，
初始20，按20扩展至200，达到上限明确 capped；仓库 offset 合同仍可读取任意窗口。
重新读取整个可见前缀而非拼接不同数据库版本的页，条目增删改序及曲目/艺人更新同时刷新。
不把 updatedAt 当作可靠版本：时钟回退或同毫秒编辑仍必须刷新。通知合并，读取期间失效就丢弃旧结果再读。
读取失败保留旧内容但标记过期，禁止把其当作可操作的新数据；失效流错误/提前结束也进入安全错误并可重建订阅。

库中 Drift 的查询流取消不保证原生 SQL Future 已结束。因此失效通知与显式查询分开，
每个查询、订阅创建/取消都在通知 UI 前登记，关闭同步停止新工作并等待真实在途读取及取消完成，
最后才从根注册表移除并关闭共享数据库。订阅构造/取消中的重入、旧事件/旧结果均有代次隔离。
ChangeNotifier 通知期间发生同步根关闭时，先停止新工作并登记 close Future，
待通知栈退出才调用 super.dispose；不能在活动通知栈中清空监听器，也不能因此漏掉在途查询。
本增量不改 UI/路由/播放/Schema/依赖，不做网络解析，不复制第二份曲库或依赖 Library 页面启动。

## ADR-061：原生歌单内容路由与受控条目动作（2026-09-08）

AppNavigation增加openPlaylist(id)，严格URI编解码只携带稳定自定义歌单ID；错误链接不回显原始参数。
页面状态在AdaptiveRoot之上，路由借用根PlaylistContentSessions，会话借用根PlaybackController/PlaylistController。
不新增播放器、数据库、曲库缓存或来源查询；既有单语句读取和20→200上限保持，系统歌单仍拒绝此合同。

会话按独立entryId定位当前内容，逐首播放复用根playCatalogTrack，不替换整个队列。
任何失效刷新/离页/覆盖/关闭撤销尚未执行的播放意图；持久化可用性仅作界面提示，最终解析仍由根播放器负责。
移除和上/下移动仅在当前一致窗口与根writer可用且空闲时接受；锚点按当前条目身份传递，
未知窗口尾部禁用下移，不以null将其误移到整张歌单末尾。写入不做乐观整表覆盖或自动重试。
动作Future在通知前登记；writer同步接受后即使离页/根关闭也排空；根保存安全的条目错误文案，
由原有PlaylistEditorScope传给音乐库，关闭内容路由后的失败仍可见、可显式清除。

菜单使用独立请求身份和快照身份，过期/同ID重开/迟到回调都不能执行；失效或覆盖路由关闭菜单。
菜单覆盖包括Shell的页面交互，Back/Esc优先关闭菜单，完成后仅向仍有效的控件恢复焦点。
Phone/Tablet/Windows各自布局使用原有YY组件/SVG/Token，不将HTML运行时或在线Figma节点猜测带入客户端。
本批不交付添加选择器、播放全部/随机、拖拽、系统视图或超过200条的连续浏览，不能声明整个Phase6完成。

## ADR-062：添加歌单选择器使用显式有界读取与根原子追加（2026-09-08）

CollectionRepository增加readCustomPlaylists(PlaylistNameQuery, PageRequest)，只读自定义歌单元数据。
名称为修剪后0–512字符、无控制符的字面子串，仅ASCII大小写折叠（中文原样匹配）；百分号/下划线不是通配符。
按updatedAt降序、ID的Unicode标量顺序升序稳定分页；SQLite BINARY UTF-8与Fake同序。
limit+1在单次查询判断hasMore，窗口外元数据不解码，不查询歌曲/条目/来源或返回假计数。

根PlaylistAddSessions拥有惰性独立会话，复用watchPlaylistContentChanges的失效信号与显式读取，
查询Future/订阅创建取消/已接受写入分别登记排空，最终才释放共享库。会话不依赖Library页面是否启动。
20→200完整可见前缀，每次重读而非拼接异步排序版本；达到上限明确提示筛选缩小范围。
筛选输入显式提交；草稿与已读筛选不同或IME合成时旧选项不能提交，快照/请求代次阻止迟到回调。

AppNavigation添加Future<void> addToPlaylist(TrackRef, title)，根原生模态路由不将完整Track、路径或URI传入路由参数。
调用页面在模态期间撤销待执行播放并阻止旧菜单；关闭后仅在原页面仍有效时恢复活动状态与行焦点。
Phone BottomSheet与Tablet/Windows Dialog共用业务会话，模态覆盖Shell并阻隔键盘/语义，Back/Esc关闭。
写入只调用根PlaylistController.addTrack，目标必须是当前快照的自定义歌单，最终原子命令再次校验父身份。
重复TrackRef允许独立条目；只保存引用，不解析/下载/复制文件，也不创建第二播放或持久状态。
接受后即使离页或关闭仍排空；失败安全化，离页后的错误由既有根entryFailure返回Library显示。
本批仅已有歌单选择；新建并添加需要后续真正原子组合，不将两个独立成功/失败冒充原子操作。

## ADR-063：新建并添加必须是一个原子根命令（2026-09-08）

CollectionRepository.createPlaylistWithEntry(Playlist, PlaylistEntryDraft)在同一事务内创建自定义父歌单及首条引用。
复用新建名称/系统身份/父ID碰撞保护，entry ID全局唯一，首位置0，元数据与addedAt按输入保留。
只保存完整TrackRef，允许来源缺失；不复制或读取音乐文件，不更新旧父歌单或条目。
任一插入/校验失败整体回滚；不是UI先create再append，也不自动重试不确定写入。

根PlaylistController.createPlaylistWithTrack只生成一次父ID/entry ID与UTC时间，调用单个Repository合同；
所有写入仍共用busy/错误/关闭排空，失败纳入既有entryFailure，离页可见且可清除。
PlaylistAddController.createAndAdd复用已接受写入的登记/完成逻辑；不要求已有列表读取成功，
因为创建不依赖列表内容，最终数据库事务负责名称/身份校验。没有生成第二个持久列表或播放实例。

选择器保留独立名称草稿，显式“新建并添加”，不复用/自动提交名称筛选草稿。
提交前同时确认活动路由、当前草稿、非IME合成与根可写状态；旧按钮不能提交修改后的新草稿。
成功只显示真实提交反馈；旋转/零尺寸保留草稿，关闭后的已接受写入继续排空，不误关后来的弹层。

## ADR-064：歌单用有界一致窗口遍历，不无限累积分页结果

2026-09-08，Phase6H8。复用CollectionRepository.readPlaylistContent的现有offset合同，
每次仍最多200个条目；首组20条递增，达到200条后切换下一组，上一组完整读取。
分页动作绑定当前快照并检查活动路由/busy；每次查询替换完整窗口，失效通知刷新同一目标，
不合并跨版本页、不使用updatedAt充当版本、不复制整份歌单或建立第二存储。
删除导致目标offset越界时，先依据本次一致总数回退最后有效200条组，再查询并发布；
旧响应/错误通过readRevision隔离，根关闭继续排空真实Future和订阅。
界面显示真实范围及上一组/下一组，只有组偏移改变才重置滚动；系统投影与跨组移动另行设计，
不推测未读取的相邻条目身份。Schema、SQL、播放实例及安全边界不变。

## ADR-065：歌单整体播放使用轻量一致计划和单个根队列命令

2026-09-08，Phase6H9。CollectionRepository新增readPlaylistPlaybackPlan：一个绑定SQL，
读取父身份和全部条目ID/位置/完整TrackRef/持久可用性，不取曲目Metadata/封面/艺人、不N+1、不拼分页。
计划是仅供显式播放命令的一次性轻量快照，不是第二个内容缓存；重复条目与不可用软引用保留，系统视图另行实现。

PlaylistContentController从当前快照接受动作，先登记Future，读取计划后按可用性过滤；没有可用项时不动队列。
根PlaybackController.playCatalogSelection冻结完整引用集、唯一ID和随机次序，在一个串行任务内持久化/安装队列与模式，
再调用现有根播放流程。播放全部从首项开始且关闭随机；随机播放预先打乱队列项ID（不改持久歌单顺序），首项也随机，
后续沿同一随机序列前进。随机源失败必须发生在队列/音频变动之前。队列与模式在同一次通知中一致可见。

UI明确说明替换当前队列；不是追加，也不是只取当前200条。读取时已不可用的条目跳过并显示计数，原歌单保留。
活动路由/代次/菜单/当前快照/busy保护接受动作；提交前撤销不写，持久化已开始则排空并保留真实提交，不补偿覆盖。
根关闭等待计划查询与批量播放操作，再释放SQLite/后端；已真正开始的播放不会因正常离页而停止。
读取之后新失效/解析/引擎错误使用现有安全错误态，完整队列运行时跳过策略留在后续Phase7，不宣称全部异常自动跳过。

本批回归暴露Windows WindowFrame零尺寸卸载Navigator的问题：改为保留上一次有效约束离屏布局，
Offstage/ExcludeFocus/TickerMode共同隐藏、隔离焦点并暂停页面；未曾显示时仍保持空占位。
不新建播放器/路由、不发明最小尺寸；恢复后保持同一会话，最小化期间撤销延迟播放，正常已开始音频继续。

## ADR-066：系统歌单是枚举选择的只读集合投影，不是持久父歌单

2026-09-08，Phase6H10。CollectionRepository提供按SystemPlaylistType读取的有界内容窗口与类型相关失效流。
模型不含Playlist父记录或可删除伪ID；喜欢的条目身份为完整TrackRef，历史/队列为已有真实记录ID。
时间按来源语义投影（收藏addedAt、历史startedAt、队列addedAt），缺失曲目仍保留引用，队列重复曲目不去重。
一个SQL选择受信任的枚举固定查询，所有分页值绑定；计数与队列当前ID同快照，先页后艺人展开。
喜欢时间倒序/完整身份正序，历史时间倒序/ID正序且最多20，队列原position顺序。
队列状态缺失/悬空或全局位置不连续安全失败；当前条目在页外合法，不为显示窗口重置当前播放。
失效流不自动读取内容；只监听对应集合及曲目/署名表，取消后不继续通知，不包装为提交日志。
不新增写入/Schema/播放实例；UI与根会话的查询排空、历史真实开始记录和系统操作随后接入并验收。

## ADR-067：系统歌单用固定类型、根注册的只读窗口会话

2026-09-08，Phase6H11。SystemPlaylistSessions由DependencyGraph持有，仅借用根CollectionRepository；
open(SystemPlaylistType)创建独立会话但不工作，start显式订阅类型相关失效流后首次读取，无伪Playlist ID或第二队列真相。
状态包含明确idle/loading/data/empty/error；加载和失败期间可保留旧窗口供显示，但isCurrent与导航授权关闭。
类型在会话寿命内不变，跨类型响应、错误offset/limit安全拒绝，不把缺依赖当成空歌单。

沿用已有自定义歌单的有界窗口交互：20条增至200，随后前后整组；每次仅一个整体窗口，不累积跨版本分页。
导航必须绑定当前快照并校验活动状态，末组删除越界会重读最后有效组，不发布伪空歌单。
每个会话单worker串行读取，失效风暴只补一次最新读，revision隔离旧成功/错误；显式refresh重建监听并保留目标窗口。
订阅错误/结束使内容失效；取消异步Future、重入产生的订阅及已接受读取必须注册并排空，之后根才关闭存储。
只读会话关闭不停止根播放；当前队列ID完全来自同一投影，可在页外且不触发选曲。
本批没有写命令/新UI/Schema/平台或播放器变更，系统入口与动作以及真正开始播放后的历史持久化分批验收。

## ADR-068：系统入口用枚举路由，队列单项播放必须保留真实条目身份

2026-09-08，Phase6H12。AppNavigation.openSystemPlaylist(SystemPlaylistType)路由到独立/system-playlist?type=闭合枚举，
不复用/猜测自定义Playlist ID、不分配系统父记录。Library三入口复用最终YYPlaylistCard/heart/history/queue资产，
未读取汇总前只显示说明不伪造计数；页面会话读取实际总数。三端独立布局共用H11根会话，UI不访问SQL/插件。

SystemPlaylistSessions借用唯一PlaybackController。会话从当前活动快照接受单项播放并登记Future，旧快照/关闭/显式刷新和翻页撤销未开始动作。
喜欢/最近使用根playCatalogTrack(完整TrackRef)，队列使用既有真实entry ID并在根队列验证完整引用一致，不能按歌曲去重选择第一项。
PlaybackController.playEntry增加可选canPlay，复用已有内部查询/解析/持久化/load边界检查，不创建第二队列或播放器。
队列自身currentEntryId持久化会引发会话刷新，不能仅凭readRevision变化取消它自己的合法动作；通过动作代次、活动状态、监听健康与根条目身份保护。
喜欢/最近的集合失效可撤销未开始播放；读取失败/监听结束不可授权后续播放。正常离页仅撤销待开始工作，不停止已播放音频。
系统路由状态位于可替换Shell之上；覆盖/零尺寸撤销待播放且保持滚动/会话，恢复时按窗口偏移重置必要滚动。
本批不新增系统集合写菜单/真实播放历史/Schema/权限，不以UI错误提示或Fixture替代真实数据；新增及受影响Golden逐张验证。
PlaylistEditorScope额外暴露只读interactionEnabled，让新系统入口在编辑面板遮挡期间拒绝保留的旧导航回调，不携带业务写状态。

## ADR-069：播放历史以时钟前进确认，保存故障不影响播放

2026-09-08，Phase6H13。PlaybackController拥有唯一PlaybackHistoryRecorder，借用同一CollectionRepository；不在Shell或插件中写库。
新加载或已完成后的明确重放建立聆听周期，启动命令仅打开观察窗口。playing样本后实际位置前进（或短曲completed前进）才确认一次。
pause/resume、buffering恢复与普通seek保留同次聆听；seek前清除位置基线，stop/错误/新加载隔离旧周期，无已加载身份或加载中的事件不确认。
这验证的是音频状态与时钟事实，不保证外部设备实际可听；两次原生快照之间极短且没有任何前进证据的曲目保守不记录。

确认时冻结完整TrackRef、随机ID、UTC时间与位置，注册后串行保存；时钟回拨/同毫秒使用最大已存/已分配排序时间+1ms，保证重放置顶。
Repository历史ID若属于其他完整来源则在同一事务中拒绝，不能先删除旧同曲再覆盖外来ID；同ID同引用仍支持幂等重试。
独立保存失败状态不改变PlaybackState音频phase，不阻塞音频命令；根关闭等待已接受读写结束才释放SQLite。
最近页由Presenter暴露安全失败与代次令牌，复用YYErrorBanner；仅最新确认项允许重试，以冻结身份/时间重放写入；更早失败只能知悉，避免重试改变后续聆听排序。
正常播放成功不自动抹掉此前未保存提示；重试成功或显式知悉才清除，旧失败回调不得误操作新失败。系统最近页新清空入口留待下一独立阶段。
既有首页确认清除改走同一Recorder串行通道：先前已接受写入先完成再清除，后来确认的播放排在清除之后。
清除成功同时撤销此前失败的重试资格；保持当前聆听已确认标记，继续播放不会把刚清除的同次记录写回来。
清除失败向首页返回安全Failure；不会改变音频phase，也不绕过根关闭排空。

## ADR-070：系统管理写入由根会话集合持有，弹层只提交当前快照

2026-09-09，Phase6H14。SystemPlaylistSessions拥有唯一SystemPlaylistWriter，借用同一CollectionRepository与PlaybackHistoryRecorder。
取消喜欢传完整TrackRef并显式favorite:false，不依赖曲目可播放/可解析，也不修改曲库或其他集合；清除历史复用H13的有序clear。
写入前登记排空Future，再调用可重入的Repository/Recorder；任一系统会话关闭不取消已接受写入，根关闭等待Writer结束。
写入器忙时拒绝重复提交，失败为安全的操作/引用与DomainFailure，不保留底层异常；失败留在根，可返回系统页查看及显式知悉。
成功仅清除同一操作/引用的旧失败，不抹掉另一条尚未处理的失败；旧失败回调不得操作新失败。
系统会话仅在活动、当前、监听健康的同一快照接受取消喜欢或确认清除；清除需匹配同一根Repository，拒绝错接存储。
原生弹层保存请求身份和快照；刷新/变更/覆盖/零尺寸撤销旧授权，Esc/返回先关闭弹层，隔离下层焦点/语义与键盘动作。
三个系统集合仍不可重命名/删除；本批不新增Schema、平台权限、第二队列或手写图标。

## ADR-071：本地音乐概览是现有连接上的只读一致快照

2026-09-09，Phase6I1。新增LocalLibraryRepository，由现有DriftLibraryRepository实现，不创建第二数据库或独立存储生命周期。
一个SQL语句组合仅source_type=local曲目统计、全部已保存文件夹统计和有界稳定排序的文件夹窗口；无artist连接计数放大。
窗口超出末尾仍返回完整统计，文件夹摘要只含id/displayName/platform/enabled/lastScannedAt，不带路径、Content URI或grantRef。
enabled只表示已保存配置，历史扫描时间只表示已保存记录，二者不得解释为当前授权/可读性或正在扫描。
轻量变化流只使消费者失效，不加载全曲库；消费者负责刷新、撤销旧结果、取消订阅并在关闭数据库前排空已接受读取。
沿用SearchCancellation协作取消：前后检查并丢弃旧结果，不承诺中断原生SQL；SQL错误转换为安全DomainFailure。
模型不可变，计数和分页元数据保持一致，调试字符串脱敏。本批不接入UI/平台扫描、不添加Schema或模拟生产数据。

## ADR-072：本地概览根状态在三套受控原生布局之间保留

2026-09-09，Phase6I2。AppDataServices以同一DriftLibraryRepository提供localLibrary；DependencyGraph拥有唯一LocalMusicController，LibraryController仅借用。
本地概览Panel挂载后显式start，依当前页面/正尺寸/TickerMode设活动状态；隐藏、覆盖或卸载撤销订阅代次和读取令牌，保留已显示窗口但不再授权旧操作。
先订阅后读取，最多一个读取worker；失效合并、分页快照身份校验，页尾删除回退最后有效页；错误不替换成虚假零值。
根关闭先停止新工作，再排空已登记读取及异步取消，之后才释放数据库；同一根播放器和队列不受影响。
Phone竖向、Tablet按横竖屏重排、Windows宽屏统计与目录组合，复用YY组件/原始SVG/Token；统计/文件夹普通纯色表面，不使用玻璃。
保留20条目录分页与历史扫描日期，明确不是当前权限/文件可读验证；不新增导入/扫描/授权按钮、文件操作或平台依赖。
LibraryScreen用稳定GlobalKey迁移唯一LocalMusicPanel，避免Phone/Tablet布局替换时旧Panel在新Panel激活后dispose，错误地停用共享Controller。
同一Element保留活动状态和回调身份；真正卸载仍立即撤销。YYSurface新增可选radius参数保留原默认值，仅本地统计18/目录16使用App.tsx精修Token。

## ADR-073：外观设置以白名单快照保存，根恢复与写入有序

2026-09-09，Phase6J1。AppearanceSettings是纯Domain不可变模型，只含显示模式、五预设/自定义色、glassEnabled、reduceMotion；与YY设计类型在根控制器显式映射。
DriftAppearanceSettingsRepository借用同一数据库，只查询themeMode/accentPreset/customAccent/glassEnabled/reduceMotion五键，并在一个事务内保存整个快照，保留其他设置。
缺失键按明确默认值补齐但读取不写库；损坏/未知类型拒绝为安全Failure，不把错误假装默认成功，不接收任意键、原始JSON或凭据。
根AppearanceSettingsController监听唯一YYAppearanceController，启动时先恢复再呈现业务UI；原子恢复只通知一次且不回写。启动前/期间已发生的用户变更优先于晚到读取。
持久化最多一个worker，连续变更合并为最新快照但不并发写；已接受变更在关闭时继续排空，随后才释放共享数据范围，失败不会驱动音频或假报已保存。
读取失败保持原界面，不自动覆盖损坏存储；显式重试先读成功再保存尚未落库的用户变更。保存失败可重试最新快照，新用户变更可触发下一次保存。
无仓储的隔离Fixture保持明确session-only语义，正式AppDataServices必须提供同连接外观仓储。原生Settings UI下一批消费状态，不在本批增加无效平台开关。
外观通知期间重入根关闭时，YYAppearanceController先停止变更，等待当前通知展开结束再释放ChangeNotifier；已接受偏好仍由桥接器排空，不在notifyListeners栈内直接销毁。

## ADR-074：原生设置只编辑根外观，草稿与持久化状态分离

2026-09-09，Phase 6J2。AppRouter 借用根 AppearanceSettingsController，正式 `/settings` 使用三套原生布局，共用受控内容组件，不拥有仓储生命周期。
显示模式/主题色/玻璃/动效修改唯一 YYAppearanceController，由既有桥接器保存。读取失败禁用偏好编辑并显式重试；保存失败保留当前视觉并可重试最新快照，不谎报已保存。
自定义 Hex 是页面草稿，显式应用并校验六位格式；未应用草稿不进入数据库。布局、主题或后台保存通知不得覆盖脏草稿或选区。
路由/活动代次和实时正尺寸限制每个事件，隐藏或覆盖后旧回调失效，界面卸载不取消根已经接受的保存。
Phone 使用横向紧凑分类与单列内容；Tablet 横屏主从、竖屏上分类；Windows 分类侧栏与内容栏。设置分类用 App.tsx 圆角 11，普通内容用纯色 YYSurface。
只呈现已实现的外观与关于（真实许可入口、准确开发版本与本机存储说明）；其他分类随对应能力实现再接入，不引入模拟导入/音源/播放开关。
精确路由活动状态由 AppRouter 通过只读 ValueListenable<bool> 借给 SettingsScreen；go_router 仅留在 app 组合层，Feature 不依赖第三方路由类型。控件按活动变化撤销代次，测试不得放宽既有架构边界门禁。
滚动视口与编辑面板分别使用根页面持有的稳定 GlobalKey，在 Phone/Tablet 重排时迁移视口/编辑 Element，保留滚动偏移与原生选区，不要求 Flutter 的内部 ScrollPosition 实例身份不变；内容变短时仅按新的合法滚动范围收敛。

## ADR-075：歌词时间轴只投影根播放位置，活动快照授权 Seek

2026-09-09，Phase 7A。纯 Domain LyricsTimeline 借用不可变 LyricsDocument；同步行有效区间为 [start,end)，正 offset 延迟显示/Seek，负 offset 提前。
二分查找最后一个 start <= (position-offset) 的行，同 start 取最后一行；候选已结束、区间间隙、首行之前或尾行之后不高亮，不回退到更早重叠行。零长度行不高亮；纯文本不高亮/Seek。
Seek 目标为 start+offset，负值收敛到零，达到/超出已知媒体时长或整数溢出拒绝；媒体位置与偏移运算在微秒精度作溢出保护，不改数据库格式。
唯一根 LyricsController 默认不活动，显式激活才监听根播放器与读仓储。身份为队列 entryId + 完整 TrackRef；切歌/刷新/隐藏撤销代次并清空旧状态，最多一个读取 worker，积压变化合并为最新身份。
数据/空/错误/读取中/无曲目的空闲状态明确；错误诊断使用固定标识，跨来源错配拒绝，不转发仓储原始异常或私密字段。纯文本/翻译保留实际文档，不复制 HTML 按标题生成歌词逻辑。
UI 点击必须带当前 LoadState 快照身份；新读取即使返回同一文档实例也不会恢复旧回调权限。PlaybackController.seek 新增可选 canSeek，在串行命令实际开始时再次检查代次、快照、完整曲目和可 Seek 状态；不乐观修改歌词高亮。
隐藏停止监听且丢弃晚到结果；根关闭同步撤销新工作，并等待已登记的歌词读取/Seek，随后排空播放器，最后释放引擎和数据。同步器只借用仓储，不自行销毁。
歌词/播放器通知中重入关闭时先标记停止，ChangeNotifier 的最终 dispose 延迟到自身通知栈展开后；不修改队列、历史或音频资源所有权。
本批只接共享核心，原生歌词页面、滚动跟随、翻译开关与沉浸能力由后续 Phase 7 增量消费，不提前接模拟 UI。

## ADR-076：独立播放页面借用根投影，手势授权与媒体状态分离

2026-09-09，Phase 7B1。`/player` 在主 Shell 之外显示原生 PlayerScreen，三个布局只排列视图，播放真相仍为根 PlaybackController / PlaybackPresenter。
复用已有原始 SVG、ArtworkPlaceholder、Slider、TransportButton；新的受控全页内容不访问数据层或插件。封面语义明确兜底，普通页面为纯色，不模拟专辑数据。
页面只拥有滚动与正在拖动的进度/音量预览；活动由 app 通过只读 ValueListenable 注入，结合 ModalRoute/TickerMode/正尺寸保护事件。切歌、离页和布局变化撤销代次，原生输入进行中不得误 Seek 新歌曲。
PlaybackPresenter.seek 扩展可选 isIntentCurrent，传入根串行 Seek 的 canSeek 实际执行检查。取消手势不停止已接受的播放/暂停；返回保持队列/位置/根实例，重复打开当前 `/player` 不叠加页面。
Windows 保持桌面双栏；Phone 竖单列/短横双栏，Tablet 横双栏/竖上下。进度按真实位置和总时长，未知时长禁用，减少动态不缩放封面。
底栏元数据提供打开原生播放页回调，不启用未实现的 OS 全屏按钮；当前队列先复用既有真实系统队列路由，独立管理路由与歌词/沉浸/收藏后续按真实能力接入。
活动判断读取 GoRouter 最后匹配的叶路由，而非仍可能指向底层主路由的 currentConfiguration.uri；第三方类型仅留 app 组合层。PlayerScreen 拦截系统返回并委托统一 back，直接进入无返回栈时也回首页；重复点击打开在异步 push 尚未生效时同样去重。

## ADR-077：歌词正文采用双向惰性锚点，手动浏览不改变媒体位置

2026-09-09，Phase 7C1。LyricsViewport 只接受文档、同步行号/位置、显式排版、快照令牌和回调，不读取仓储或拥有播放时钟。
两个惰性 Sliver 从锚点向前/后构建；远距离自动跟随重设锚点并按实际行高度居中，不创建全部行或用平均行高猜测。自定义 ScrollController 只属于视口。
手动触摸/滚轮/键盘滚动暂停跟随，停止五秒后或按“回到当前歌词”恢复；恢复只滚动，不 Seek、不抢焦点。纯文本没有高亮/Seek/自动跟随。
文档/快照换代、失活、零面积、卸载撤销旧动作，后帧定位也校验代次。根位置仍是唯一真相；行点击只提交当前快照的索引，由后续页面桥接既有根 Seek 授权。
复用 YYLyricsLine 的最终原始字体与颜色，新增可选显式 phoneLayout，Windows 小窗不以宽度冒充 Android 手机；减少动态禁用歌词缩放，保留语义当前行。
本批为独立歌词页正文组件，路由/Dock/加载空错状态和平台沉浸接线在后续增量，不能宣称完整歌词功能已可用。
无 Seek 回调的歌词渲染为真实只读语义，不冒充禁用按钮或再次降低文本透明度。YYControlAction 可选 onFocusReveal 让自定义双向视口按实际位置显示已获焦点的行，默认消费者保持既有行为；这不授予组件请求焦点的权力。
双向居中采用实际 RenderBox 中心差值而非通用 ensureVisible 的边缘假设；rebase 同时更换滚动子树身份，避免只换 ScrollController 时仍复用旧 ScrollPosition。当前测量行换索引时使用新 Key，不把原来已获焦点的控件身份冒用于另一句歌词；同一行翻译重排可保留焦点。

## ADR-078：独立歌词页面借用单根活动状态，导航不堆叠播放器

2026-09-09，Phase 7C2。正式 LyricsScreen 借用根 LyricsController/PlaybackPresenter，三端布局只排列头部/正文/Dock；页面仅持有翻译显示、手势草稿、快照代次，不拥有媒体或仓储。
app 注入只读路由活动；结合 ModalRoute/TickerMode/正尺寸判定，激活在安全后帧合并，失效同步撤销页面意图。LyricsController.seekLine 的可选 isIntentCurrent 在入队和实际执行前检查，不能用稍后停用同步器代替旧手势保护。
独立 player/lyrics 页面有明确路由名称，重复打开去重；Dock 返回播放页复用已有命名播放页，否则替换当前歌词页；普通返回保留原始入口关系，不停止音乐。
底栏元数据添加受控原生长按歌词动作，普通单击仍打开播放页；YYControlAction 新增长按回调默认关闭，旧使用者行为不变。Windows L 不拦截原生文字输入，Ctrl+L仍为音乐库。
歌词页使用深色单一兜底色与现有玻璃Dock；隐藏本批未接的收藏控件，不提供伪全屏/来源/权限开关。封面提色、平台沉浸和独立队列后续验收。

## ADR-079：原生全屏会话保存恢复快照，生命周期恢复不依赖页面存活

2026-09-09，Phase7D1。扩展未接入的FullscreenGateway，握手返回可空原生模式快照，事件/enter/restore只描述本窗口会话；close撤销待发命令、排空在途后detach。MissingPlugin表示不可用，其余异常只转固定错误，不能伪造进入成功。enabled表示原生模式生效，不将临时系统栏显示当退出，也不通过Flutter视口猜测。
两端原生仅接受无参数白名单方法；Windows使用独立fullscreen通道，不争夺窗口控制通道处理器，保存原样式/扩展样式/WINDOWPLACEMENT且重复进入不覆盖。恢复失败保留快照供重试；窗口detach/最小化/显示配置变化优先恢复，不修改显示模式或他人HWND。
Android借用Flutter已有AndroidX兼容Insets控制器，保存系统栏可见性/行为与旧API标志；不覆盖Flutter的Insets监听或修改全局设置。暂停、失焦、引擎解绑及销毁原生恢复，返回前台不擅自重新进入；后续根协调器负责当前路由/前台/正尺寸授权及UI切换，页面不拥有平台Gateway。
本批仅平台能力与自动验收，不注入正式页面、隐藏标题栏或启用伪F键。图标/字体/Golden、媒体/Schema/依赖/权限保持不变。

## ADR-080：根全屏协调器以原生快照和可撤销路由意图控制展示

2026-09-09，Phase7D2。FullscreenPresenter由应用根拥有；Navigator顶层路由观察器提供实际页面身份和弹层覆盖，页面只借用展示状态/回调，不创建Gateway。仅有效前台、正视口和player/lyrics页面允许进入，切页/后台/关闭同步撤销目标，单worker使最终原生状态收敛；事件优先于较早命令响应，不让晚到成功覆盖系统恢复。
Android进入独立页面自动请求沉浸；Windows使用显式按钮/F。player/lyrics间可延续原生会话，离开/被弹层覆盖恢复；生命周期或原生中断后不自动重新进入。Esc先撤销/退出全屏，再返回；Android系统返回直接遵循原路由，并由观察器恢复系统UI。
隐藏Windows标题栏只折叠现有Chrome槽，不改变Navigator祖先结构；原生状态或恢复错误时保留可用出口，固定错误提示提供恢复重试。全屏关闭在业务图关闭前排空，意外Widget卸载也释放同一根通道。旧DependencyGraph.fullscreen保持可选注入，由根取得使用/关闭所有权，不另建第二份媒体或UI业务状态。

## ADR-081：队列编辑绑定不可变根快照并按条目锚点排序

2026-09-09，Phase7E1。QueueEdit保存根QueueSnapshot对象身份；同值或同时间的新快照也不能复用旧菜单/拖拽确认。移除/排序使用独立entry ID，排序用beforeEntryId（null为末尾），不把旧可见索引直接作用于最新队列。模型纯转换，重复曲目/完整来源/addedAt保留，空清空及不改变顺序的移动不写库。
PlaybackController仍是唯一队列/音频真值和串行命令执行者；执行前与可能等待的停止后检查快照和页面许可，SQL一旦开始则排空并应用成功状态，不因离页尝试回滚。QueueController只转发并撤销释放前未接受的编辑，不拥有第二份队列。
编辑失败返回固定脱敏DomainFailure，不将纯队列保存错误发布为音频播放失败；移除当前项/清空沿用先停止再持久化，若停止后保存失败则旧队列保留但不擅自重播。业务根既有关闭屏障负责等待已接受SQL，不扩展图所有权或平台能力。独立UI的忙态/失败反馈另批接线。

## ADR-083：独立队列页面借用有界投影与唯一根快照

2026-09-12，Phase 7E3。`/queue` 复用根 SystemPlaylistSessions 的有界元数据读取和根 QueueController 的写入反馈；页面绑定只存不可变根快照身份，不创建第二份队列或数据库。根快照变化立即撤销旧视图编辑许可并请求新队列投影；该只读刷新不递增播放意图，防止当前 ID 发布取消正在接受的准确条目播放。投影必须逐项匹配位置、entry ID、完整 TrackRef、addedAt、总数与 current ID 才可编辑。

页面隐藏、被覆盖、零面积、尺寸变化、卸载撤销交互意图；已接受 SQL 仍由根排空，失败在根保留。当前项移除和清空显式确认停止且不自动播放邻项；非当前项直接移除。不可播放条目仍允许管理，不用虚假 onPressed 冒充可播放。旧系统队列 URL 保留只读兼容，新入口指向独立 `/queue`。本阶段上下移动为键盘/触控等价操作，拖拽另行验收。

## ADR-082：根队列编辑反馈保留失败身份，不自动重放旧确认

2026-09-09，Phase7E2。QueueController保留唯一待提交结果与最新安全失败，队列真值仍借用PlaybackController。submitEdit返回applied/cancelled/busy/failed，busy防双击；跨页面订阅变化不清除失败。retryEdit仅接受当前失败对象且根快照仍是失败请求的原始对象，SQL开始后离页遵循E1提交语义。
其他成功操作不抹去旧失败，仅显式知悉或同失败身份的成功重试清除；旧知悉/重试不能影响新失败，失败重新发生创建新身份。不保存异常正文或用户路径。注册pending/关闭屏障先于通知，异步结算先清除busy再通知；监听者可立即重入提交或关闭，根在业务存储释放前等待队列反馈排空。

## ADR-084：队列拖拽只把有界视窗移动转换为原根条目锚点

2026-09-12，Phase7E4。借用 Flutter widgets 层 SliverReorderableList 的惰性布局、拖放间隙与边缘滚动，不使用默认 Material ReorderableListView。Windows 精确 drag SVG 手柄即时拖动，Android 整项长按，保留上下移按钮。QueueDragSession 捕获根快照/有界投影/源索引及许可，onReorderItem 的归一化目标索引转换为原根 beforeEntryId；有界组尾使用下一条根锚点而不是整队列末尾。

内容对象、根快照或页面交互版本变化重建原生拖拽状态。落下与动画完成之间仍检查旧许可；旧语义排序回调亦绑定原视图，不能把旧索引重绑新数据。PointerCancel/no-op 不保存；排序不切换当前项、不停止/重载音频；已经接受的 SQL 排空及安全失败继续由根负责。拖拽限当前最多200条元数据组，跨组继续有键盘/触控上下移动与分页；不增加第二份可写队列。

根编辑的 busy 是准入门禁，不能因自身 busy 通知撤销已接受拖拽的持久化许可。Windows 上下移按钮的 FocusNode 由页面按条目与动作保存，数据刷新后仅恢复原有焦点；显式转移到其他控件、离页或尺寸变化不抢焦点。每次组内容更新清理不再显示条目的焦点，页面关闭释放全部节点，保持有界。真实指针测试需先结束 Flutter 的落下动画，再排空其回调启动的数据库任务，不把动画之前的等待当作提交完成。

## ADR-085：添加与下一首使用同一根编辑授权与提交后随机次序

Phase7E5A，2026-09-12。QueueEdit 增加携带新 QueueEntry 的末尾/下一首插入；entry ID 必须不在捕获快照中，同 TrackRef 可有多个队列条目。纯 apply 保留完整引用与 addedAt/current，位置重排，空队列不自动选中/播放；根 submitEdit 统一准入、过期取消、安全失败、同快照重试和关闭排空。

插入不重新洗牌既有条目，而是成功落库后扩展原随机顺序，显式下一首置于当前游标之后；最近指定的下一首优先，随后添加末尾不撤销该优先序。失败或取消不改变随机顺序。沿用根唯一 _shuffleOrder，无额外队列或数据库字段；普通排序/移除/替换仍采用既有策略。运行时随机顺序不跨启动保存，重启恢复物理队列与当前条目。后续 UI 需捕获源条目/页面与根身份，不能直接调用无页面许可的旧低层接口。

## ADR-086：歌曲菜单捕获源与根，提交后借根反馈

2026-09-12，Phase7E5B。根QueueController准备插入意图并分配不冲突entry ID，页面不生成ID或直写存储。音乐库菜单持有打开时expected队列和准确Track对象/读取意图；旧菜单、根替换、刷新、尺寸或路由变化撤销，落库前复核。菜单正常选择后关闭不取消其已接受请求，SQL接受后的关闭仍由根排空。缺失文件可添加软引用，但不变成可播放状态。

音乐库反馈订阅同一根busy/失败；成功提示只属页面，失败仍在根并可跨页回到队列/音乐库显式重试或知悉。重试绑定原失败与根身份，旧回调不解释为新失败；无后台自动重试。三端使用既有原生YYContextMenu/YYButton/YYErrorBanner，菜单渲染拆出受控组件，后续其他歌曲入口再复用，无第二份队列。

## ADR-087：详情菜单跨布局保留外观，重发当前交互许可

2026-09-12，Phase7E5C。专辑/艺人详情借根QueueController与QueueOperationFeedback，源许可只承认准确Track对象、当前详情读取意图/活动状态。刷新、关闭与隐藏永久撤销旧许可。详情原来允许跨Phone/Tablet布局保留打开的菜单，本批保持这一行为，但每次尺寸变化递增菜单/页面代数并重新捕获当前根；旧闭包不能解释为新布局动作。艺人Tab切换、路由覆盖和零面积同样撤销。菜单动作part不拥有额外播放器、存储或队列，成功页内提示/根失败边界沿用ADR086。

## ADR-088：自建歌单入队依据窗口和条目身份，不依赖元数据解析

2026-09-12，Phase7E5D。PlaylistContentActions只向当前准确窗口内的同一PlaylistContentEntry对象授予可撤销源许可，捕获读取/操作意图；未解析或失效条目依然具有完整TrackRef，可保存到队列但不变成可播放。页面捕获根快照并借QueueController分配独立队列ID，不能复用歌单ID或改变其顺序/内容。跨尺寸重新发出菜单请求，旧请求失效，内容刷新/离页/零面积/关闭同样撤销；已接受队列写入由根排空，成功页内提示和持久失败/显式重试沿用E5B边界。

## ADR-089：系统歌曲菜单与历史清除确认分离

2026-09-12，Phase7E5E。系统歌单源许可只授予我喜欢/最近播放的准确窗口内同一条目对象，捕获读取意图；队列投影不授予插入许可。请求持有可空 SystemPlaylistEntry，非空代表歌曲菜单、空代表独立历史确认，不能把同一个回调解释为两种动作。收藏 TrackRef 和历史 ID 均不替代根分配的新队列 ID；入队不写历史或收藏。

尺寸变化重新生成请求身份并捕获根/源，旧菜单和旧清除确认永久失效；隐藏/零面积/卸载清空请求与返回焦点。根队列变化只关闭歌曲菜单，不影响独立历史确认。沿用 E5B 的根 busy/安全失败/显式重试和页面成功提示，已接受 SQL 仍由根排空。

## ADR-090：当前曲目收藏投影属于根，不属于播放页面

2026-09-12，Phase7F1。PlaybackFavoriteController借用唯一PlaybackController和CollectionRepository，跟随准确根QueueSnapshot的当前entry完整TrackRef，通过唯一可重订阅收藏流读取真值。构造不读库，DependencyGraph初始化播放后显式启动，所有消费者共享同一状态；不借用有可见列表约束的LibraryController，不新增播放或队列状态源。

操作捕获不可变收藏投影（包含根队列身份和已知收藏值）及可撤销页面许可，显式设置目标值，不延迟重新计算toggle。busy在排队前发布，执行前再验；Repository已接受后不因离页/切歌/关闭回滚。失败保存安全类型/原目标和投影身份，重试只接受同一失败且原投影仍有效；外部收藏刷新或队列替换永久撤销旧操作。只有Repository流证明收藏状态，不做乐观翻转；关闭排空订阅读取与写入后再释放存储。

初始化仅启用跟随，无当前条目时不发起收藏查询；首次出现选中的队列条目才建立订阅，位置变化不重读。显式retryRead可重建订阅。此边界避免空库启动/只读详情页产生无关查询，保留原SQL查询数量与关闭时序断言。

## ADR-091：歌词收藏借根真值，忙态与播放独立

Phase7F2A，2026-09-12。AppRouter仅借用可选PlaybackFavoriteController，正式持久化图注入同一根，无存储预览不模拟收藏。LyricsScreen监听根但不拥有/关闭它；显示仅根据根流，未知不显示未收藏。Dock增加独立favoriteBusy，收藏等待不锁播放/返回；手机继续遵循原HTML隐藏心形。

按钮闭包捕获收藏投影、目标值与页面代数，提交前复核当前ModalRoute、活动、面积及代数，根再次复核快照；尺寸/覆盖/离页/更换依赖永久撤销旧许可。共用受控反馈显示根busy/安全失败，重试和知悉绑定准确失败对象，读重试也要复核身份。失败跨页保留，已接受持久化由根排空，不制造页内成功真值或新增存储/播放器。

## ADR-092：播放页收藏复用根投影与共享失败反馈

Phase7F2B，2026-09-12。PlayerScreen借AppRouter注入的同一根收藏控制器，沿用F2A显式目标/投影/页面代数许可与失败身份。YYFullPlayerContent只增加受控showFavorite/favoriteBusy/onToggleFavorite，在原now-copy标题行复用心形原生按钮；默认不显示，保持无存储预览兼容。收藏保存与播放busy独立，错误反馈在三端可滚动controls区域复用PlaybackFavoriteFeedback，不在Domain传入BuildContext，也不改变音频/队列/历史。

## ADR-093：底栏收藏许可随路由事件撤销，不只依赖组件卸载

Phase7F2C，2026-09-12。AdaptiveRoot给非手机底栏传入根收藏、路由Listenable及选中页面/布局/尺寸身份。ShellPlayer的借用状态监听路由事件递增收藏代数，不能因切到另一主导航后组件仍mounted而接受旧操作；实时ModalRoute/活动/面积检查覆盖独立页面与原生弹层。订阅根收藏不触发I/O，所有底栏共享根流。收藏busy只禁用心形，受控反馈限制高度并滚动，不重复存储失败。未知值使用未知语义，原窄栏/手机/Inspector布局不加心形。

## ADR-094：底栏队列入口借已有导航与交互许可

Phase7G1，2026-09-13。ShellPlayer增加可选onOpenQueue，AdaptiveRoot仅委托现有AppNavigation.openSystemPlaylist(queue)，空队列可打开空态，不依赖音频可播放能力。既有收藏许可的页面/路由/尺寸/焦点排除检查提取为通用Shell交互许可；导航使用同一代数并在接受后立即撤销，根队列与播放控制器不改变。保留原手机/窄栏/Inspector布局和无回调预览行为，不引入第二个路由器或播放真值。

## ADR-095：底栏全屏入口复用根原生会话意图

Phase7G2，2026-09-13。原HTML入口既打开播放界面也请求全屏。AppRouter在构造上下文组合既有FullscreenPresenter.enterOnNextPlayer与openPlayer，把同一闭包传给五处AdaptiveRoot，再传ShellPlayer可选onOpenFullscreen；不扩张AppNavigation协议或创建额外播放器。Shell复用G1可撤销交互许可，接受后立即失效。实际进入/恢复/错误由根会话与路由观察器负责，不支持时只打开播放页而不声称原生全屏成功。手机/Inspector保持原布局。

## ADR-096：侧栏入口借同一Shell导航许可，不拥有独立会话

Phase7G3，2026-09-13。YYNowPlayingInspector只增加可选onOpenFullscreen/onOpenLyrics；AdaptiveRoot为侧栏Shell传同一全屏闭包、既有歌词导航及路由Listenable/布局尺寸身份。跨主导航保留或隐藏侧栏时旧许可撤销，实际按钮复用Shell通用导航方法。全屏播放复用G2原生会话，歌词遵循既有独立页面与平台沉浸策略；无当前队列时歌词禁用。展示组件不调用平台或存储，默认null保持独立预览兼容。

## ADR-097：睡眠截止意图和暂停属于唯一根播放器

Phase7H1A，2026-09-13。PlaybackController增加只读睡眠投影与关闭/15/30/60分钟设置，复用已有UTC clock并注入异步单次Timer工厂；默认无定时器、不读写存储、不跨进程恢复。Timer只是唤醒机制，截止比较使用clock，提前唤醒或时钟回拨按剩余时间重新调度，延迟唤醒立即处理；时钟前跳要等下一次调度唤醒，不能承诺OS挂起期间精确执行。

设置/取消递增意图代数并取消Timer；到期先标为pausing、撤销未执行自动推进，再入根串行命令队列且执行前复核代数。无活动播放直接expired，不调用play或清空队列；有播放/缓冲才pause，失败保留安全failed投影并沿用根错误处理，不自动无限重试。通知重入取消/关闭可撤销未接受操作；进入引擎的pause必须排空，即使随后重设/关闭也不自动恢复播放。新意图不会被旧完成结果覆盖。

本批不提供本曲结束模式，不把completed流后的补pause冒充完成事件拦截；该模式下一增量绑定准确queue entry并在根自动推进前决策。睡眠信息不加入平台媒体播放状态，只随根通知供后续UI读取；不创建第二个播放器或Widget计时器。

补充竞争边界：到期撤销已有自动推进还不够，pausing阶段收到新的completed也必须在根入口禁止创建自动推进。已用先失败用例复现旧行为stop/load/play；取消定时不会补发已被抑制的完成事件或自动重播。

## ADR-098：本曲结束绑定已加载的准确条目，在根完成事件前消费

Phase7H1B，2026-09-13。新增同步bool设置接口，只在可用引擎、非加载中的当前已加载条目和ready/playing/buffering/paused阶段接受；拒绝不修改旧意图。睡眠投影的entryId表示本曲结束，与分钟deadline互斥；Timer仍归根，模式切换撤销旧回调。

当前条目自然完成时同步消费armed为expired并阻止自动推进，无需在completed后补pause。按queue entry身份而不是歌曲身份，重复/随机不能绕过一次性消费。暂停/恢复/seek保留；停止、错误、队列当前项改变或重载撤销。已经消费后的取消/重设不恢复旧自动推进，显式用户play仍可重播。没有新的流订阅、Widget定时器、持久化或平台协议。

## ADR-099：睡眠卡片投影复用根意图，UI动作绑定双快照

Phase7H2A，2026-09-13。分钟armed投影记录原PlaybackSleepDuration，不能从动态剩余时间猜测选中项；非armed阶段不呈现活动分钟选中态。本曲可用性由根同一判定提供，UI不复制引擎加载/条目匹配逻辑。现有PlaybackPresenter借用根状态，不再创建一个业务控制器或Timer。

新增睡眠选项枚举及一次性动作工厂，捕获当前PlaybackState和PlaybackSleepTimerState对象身份；动作在调用外部页面许可前后均复查双快照与生命周期，许可重入或抛错按拒绝处理，消费先于根通知。返回accepted/rejected/failed明确结果，错误不泄露原始异常。允许关闭无可用引擎上的旧设置；开启分钟或本曲仍由根能力约束。播放快照任何变化都会撤销旧动作，界面必须从最新构建获取新动作；已接受动作不被后续页面变化倒放或撤销。

补充：const off会在关闭/重复取消后保持对象身份，不能仅依靠双快照。根显式isClosed提供关闭判定，Presenter每次根通知递增sleepRevision并纳入动作校验；先失败复现off→off仍接受旧分钟动作，再补版本校验。此版本只撤销UI动作，不是新播放或计时状态。

## ADR-100：共享睡眠面板借根动作，宿主管理弹层插入

Phase7H2B，2026-09-13。SleepSettingsPanel只持有临时错误/关闭许可及构建代数，借现有PlaybackPresenter监听投影，每次构建重新取H2A动作。onClose由宿主移除，外部isCurrent许可与自身生命周期/面积/ModalRoute/TickerMode/Focus检查组合；不重建根或产生UI Timer。选择即时生效，完成只关闭；不显示伪秒级倒计时，活动分钟用原选项描述。

视觉复用原生YYDialog/YYBottomSheet的焦点与滚动，新增纯受控YYOptionCard匹配本地导出双行卡片，复用主题/字体/圆角，不更改YYButton现有默认外观。手机/短Android窗口用sheet，其余dialog；正文宽不足500单列，否则双列。生产入口及Overlay生命周期绑定下一批完成，本批只交付有真实根联动的共享面板和独立视觉/交互证据。

## ADR-101：播放设置modal归根路由拥有，按准确实例关闭

Phase7H2C1，2026-09-13。AppRouter借唯一PlaybackPresenter插入一个RawDialogRoute，记录拥有者路径，PlayerScreen只接可选打开闭包并使用原有可撤销页面动作。主题/字号来自根WidgetsApp builder，不复制或冻结主题。面板许可要求router未关闭、实例匹配、拥有者路径匹配且modal当前；重复打开被记录实例拒绝。

主动关闭或拥有者路径变化先清除实例许可，再帧后对仍活动且Navigator仍挂载的准确route调用removeRoute；不盲pop，避免导航竞争误关新页面。router销毁只撤销许可，由Navigator正常销毁子route。返回先关闭当前设置；遮罩与系统回退通过route future清理。面板外层消费未被控件处理的Space，避免触发根播放快捷键；Esc由原生modal焦点处理。生产入口先播放页，其他页按后续增量共用该宿主协议。

## ADR-102：歌词与播放页设置入口显式绑定拥有者

Phase7H2C2，2026-09-13。复用ADR101唯一modal，打开函数增加必填AppRoute owner，播放页/歌词页各传自身，当前路径不匹配即拒绝。LyricsScreen只借可选闭包并走既有_canUse代数/可见性/路由保护，didUpdateWidget闭包更换撤销旧动作。面板继续使用根应用主题，不复制歌词局部氛围主题；遮罩期间歌词原有活动门禁暂停自动滚动/seek，关闭后重新激活，旧seek不能恢复权限。两个页面共享根睡眠意图，页面切换只关闭设置不取消定时。

视觉审核发现390px全屏手机的翻译/全屏/刷新/设置挤压曲目信息；不足500px将翻译按钮移至标题栏第二行，不删功能或缩小触控目标。始终保持Column→headerRow的结构，覆盖期间原歌词控制器清空数据、恢复加载时不因翻译行增减重建入口焦点；新增360px全屏元信息宽度/实际翻译操作和390px键盘恢复验收。

## ADR-103：Shell睡眠入口捕获完整URI，仍借唯一modal

Phase7H2C3，2026-09-13。详情页同路径可能对应不同歌单/来源，因此在原路径校验外添加完整Uri拥有者。主Shell与各详情frame以当次GoRouterState.uri生成闭包，调用时与根当前位置比较；路径或参数变更先撤销旧modal再精确移除。原player/lyrics的AppRoute包装保留，统一委托Uri宿主，不新增导航接口或平台真值。

AdaptiveRoot只向底栏传递可选onOpenSettings，ShellPlayer通过既有_navigationAction一次性撤销机制绑定，回调替换同样增加代数。Inspector下一增量接入；本批不改变YYDesktopPlayerBar既有>=1200设置可见性或Phone mini布局。窄栏可先进入播放页使用设置，不能宣称直接按钮全布局就绪。

GoRouter18本地源码核对：currentConfiguration.uri可能仍是push前的匹配配置，完整栈顶位置使用公开GoRouter.state.uri；复验player→lyrics push及同路径系统歌单参数切换。测试根关闭在测试体finally排空，不能把仍有Timer的图延后到绑定不变量检查之后销毁。

## ADR-104：Inspector两个设置按钮共用同一可撤销动作

Phase7H2C4，2026-09-13。纯受控YYNowPlayingInspector增加可选onOpenSettings，原顶部more和快捷device都使用它；默认null保留组件预览禁用语义，不改视觉结构。AdaptiveRoot→ShellPlayer复用既有URI捕获与导航代数，不复制modal。两个按钮同帧竞争只接受首个，底栏与Inspector并发由同一AppRouter实例拒绝重复；隐藏/换布局后旧入口永久失效。

窄栏/手机原设计未显示直接设置按钮，不增加未经审计的拥挤控件；真实元信息点击进入播放页再进入设置作为可达性契约，并在窄Windows、Android平板竖屏、手机130%字号验收。Inspector小高度内容沿用滚动，实际ensureVisible+点击验证快捷设置，不以离屏绘制当作可操作。

## ADR-105：侧栏摘要先投影准确队列身份，不推测播放顺序

Phase7H3A，2026-09-13。先提供PlaybackQueueSummary只读快照，再进行Inspector视觉绑定。由根PlaybackState的QueueSnapshot生成总数、当前QueueEntry和1起始序号；以entry ID而非TrackRef定位，重复曲目仍是不同条目。没有当前条目时保留null，不伪造第一首；序号仅指保存列表位置，随机/单曲重复时不声称下一首或剩余播放时长。

PlaybackPresenter暴露该快照，沿用原根通知，缓存键为QueueSnapshot对象身份。位置/音量通知不重新遍历大型队列；替换/重排/当前条目变更自然撤销缓存。不可变快照不持有控制器、音频后端、订阅或异步库查询，也不向界面暴露来源凭据。H3A不改界面或导航；H3B再复用原设计组件绑定摘要和受保护队列入口。

## ADR-106：侧栏显示列表摘要，队列操作仍留在独立队列页

Phase7H3B，2026-09-13。复用HTML queue-section-heading/queue-open的展开入口，使用既有YYButton quiet及换行布局保持窄侧栏可操作。显示准确总数与当前1起始列表序号，空队列保留空态，无当前项明确说明。只读摘要不冒充HTML中的模拟下一首列表，随机播放也明确标为列表顺序；曲目元数据与管理仍由原生队列页承担。

AdaptiveRoot把已有openSystemPlaylist(queue)传入Inspector ShellPlayer，使用既有_queueAction一次性许可，隐藏/覆盖/导航/卸载撤销旧回调。不创建新的路由、队列、播放器或读取会话；入口即使空队列也可访问空队列页，默认无回调的纯组件预览保持禁用。按130%字号验证短窗口滚动、宽Windows/平板及生命周期。

## ADR-107：播放设置能力以真实根/平台行为验收，补回§26缺口

Phase7H4审计，2026-09-13。依赖声明具备某能力不等于YYMusic已接入，平台方法返回成功也不证明实际音效。锁定just_audio_windows0.2.3的player.hpp对Android音效方法直接Success空Map，不能据此启用Windows标准化；AndroidLoudnessEnhancer是目标增益，不是跨曲目响度分析。根目前单源串行load，不因插件支持playlist/gapless就标记应用无缝。

总指令§26的剩余时间、未过期恢复、平滑暂停仍缺失；此前session-only是增量限制，不构成用户放弃这些验收项。先H4A根时钟剩余投影和可见界面刷新，再H4B持久化/初始化恢复/过期清理，H4C可撤销音量淡出并恢复用户意图；每项先共享协议和竞争测试，再UI。不可另建播放器或让Widget拥有业务截止计时。

输出设备后续通过真实平台Gateway读取/变化通知/系统设置入口；不知设备时明确无法获取，不能把“系统默认”当已证实设备名；无真实路由选择能力时不显示可切换列表。自动继续明确为完成事件的根策略，手动下一首独立；无缝和标准化须分别验证原生行为与安全增益，缺乏实现时无假开关。

## ADR-108：剩余时间只读根时钟，展示秒数向上取整

Phase7H4A1，2026-09-13。先补根/Presenter只读接口，再H4A2可见刷新与UI。PlaybackController.sleepRemaining只在未关闭且armed分钟截止有效时返回deadline减注入UTC时钟，过期但业务回调未执行返回零；off、本曲结束、pausing/expired/failed均为null，由原状态文案说明，不能伪造流媒体本曲剩余秒数。

读取不通知、不写状态、不取消/重设业务Timer、不触发暂停；原duration与选中项保持不变。时钟回拨可增加显示剩余量但不更改绝对deadline，不以原duration强行裁剪而掩盖墙钟变化。Presenter.sleepRemainingSeconds仅对正微秒向上取整，避免尚余小于1秒时提前显示结束；dispose后为null，不再读根时钟。展示刷新下一批使用此查询契约，不把本批接口称为界面已显示倒计时。

## ADR-109：倒计时子组件只拥有可撤销的展示刷新

Phase7H4A2a。SleepRemainingText借用Presenter，独立重建文本；唯一根仍拥有业务截止和暂停。宿主必须提供active/isCurrent可见许可，应用进入后台取消展示Timer；恢复重新读取绝对截止，不累计tick。revision阻止过时回调，监听业务状态及时取消或重新调度。剩余文本使用既有caption/secondary样式，非liveRegion，避免每秒自动播报。组件先独立验证，后续A2b接入原面板并审核截图，不混称完整显示验收。

### ADR-109实施补充：A2b正式面板绑定

SleepSettingsPanel复用现有_surfaceActive/_closing和_allowed(generation)作为展示许可，新增文本在原状态文案之后。每秒更新仅发生在子组件，不重建父选项许可。DependencyGraph透传可选playbackClock给唯一根，默认仍由根使用真实UTC时钟；生产页面Golden显式注入固定时钟，防止截图随机器耗时变化。此注入也沿用根既有历史记录时钟语义，不增加独立业务计时源。

## ADR-110：恢复快照与根状态分离，先验证严格分钟契约

H4B1。SleepTimerSnapshot位于domain，只有原durationMinutes（15/30/60）与UTC deadline；编码在data，固定version=1，不携带播放器/队列/媒体标识。剩余量只根据调用者传入now计算，过期返回null，绝不把剩余量当新选项。非法记录抛无原文的FormatException，读取/清理决定留给未来Repository及协调器，不能静默用默认定时替换损坏数据。未知版本拒绝解释，后续清理需明确版本迁移策略。

本曲结束没有绝对到期且绑定会话entryId，本阶段不纳入分钟快照，不暗示它已经支持跨启动恢复。Repository要求接受顺序串行、保存/清理原子且隔离专用键、关闭真实排空；root恢复必须优先于旧异步加载且不触发自动播放。当前只实现快照/编码/契约，真实存储与根绑定分后续阶段验证。

## ADR-111：存储尾链保证清理不会被旧保存复活

H4B2。DriftSleepTimerRepository借用AppDatabase、只访问playbackSleepTimer键，单语句upsert/delete原子操作，不改schema。read/save/clear在调用时挂到同一Future尾链；内部尾链吸收失败以继续排队，但原Future仍抛安全DomainFailure。解析错误用私有标记映射schemaMismatch，其他异常统一databaseCorrupted，禁止把坏记录当missing或自动覆盖未知版本。dispose在依赖回调前已有尾链登记，拒绝后续操作并等待接受工作，不关闭数据库。本批真实适配器独立验证，尚不注册生产数据范围或根恢复。

## ADR-113：启动读写协调与根业务截止分离

H4B3b。SleepPersistenceController构造即捕获许可并观察意图；单worker负责读取与最新快照写入，根独占业务Timer/暂停。普通播放通知不写设置，off取消通过独立许可失效识别。过期/坏版本由协调层清理，I/O失败保留记录并反馈。关闭先冻结观察和排空写入，再由数据范围关闭数据库，不持久化根退出产生的off。分钟恢复和本曲结束会话意图区别明确。

## ADR-112：根恢复使用一次性睡眠generation许可

H4B3a。captureSleepRestore只能从off捕获一次性许可；晚到存储结果若用户已新设/取消、根关闭或已接受另一恢复，一律superseded。恢复直接使用快照原UTC deadline和原选项，不经setSleepTimer重新加分钟，不调用play。结果区分过期、不可用和失败，读取/清理/反馈由下一批协调器承担。依赖及通知重入后复核generation，过时调度返回的Timer立即取消，不覆盖新的有效Timer。本批只提供根API和测试，尚未接应用启动。

许可对象另提供非消费式isCurrent，读失败或missing时也能判断是否已被用户操作撤销；无需伪造快照来检测许可。到期唤醒读取外部时钟后同样再次检查generation，防止该回调中的新用户定时被旧到期路径消费。
