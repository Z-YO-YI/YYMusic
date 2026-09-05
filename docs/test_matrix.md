# 原生基础验证矩阵

Phase4P 当前：282 Flutter（35 Golden）、57 Node、严格 analyze 0 问题。新增 4 个本地来源
解析用例、3 个有序关闭用例、5 个双平台启动/异常/晚到 Widget 用例；已有 3 个页面生命周期
断言改为等待 close 完成，未删除断言或修改视觉基线。同步关闭和异步关闭使用同一根所有权。
平台设备运行不使用这些 Fake 测试替代；真实后端的运行证据仍归属 Phase4L，当前构建见本批报告。

2026-09-05 Phase4N/O 增量：N 的 `f324ed2` 两组 GitHub checks/Android/Windows 均 success，
51 项原生依赖材料和包内完整文本实际日志复核通过。O 新增 6 个许可单元测试、6 个 Widget 场景、
3 张 Golden：无 SDK 组件标签的文本组、全文/引用/指纹、超时/畸形/重试与脱敏、搜索/返回/Esc、
四种手机横竖/平板/Windows 布局与 130% 字号。270 Flutter（35 Golden）、56 Node、严格分析、
格式与 Android Debug/48资产/六包许可/原生材料通过。Windows 构建与发布状态以各批精确报告为准。

当前Phase4N新增5项原生许可回归；本地255 Flutter/56 Node、源码/三变体依赖精确比对、Android包内
许可和48项设计资产/v2签名通过。云端结果见[本批报告](phase_4n_native_notices_report.md)，
不能把只读Release依赖解析当作Release构建成功。下文旧候选状态仅保留历史归属。

Phase4H删除已拒绝media_kit适配器的5项Fake测试后，保留227项Flutter检查；35项Node仍包含4项历史清单/失败关闭反向门禁。不包含用户音乐、在线密钥、媒体二进制、证书或私钥。旧media_kit原生POC job已经移除，只保留默认关闭、只读且不上传产物的just_audio双平台手动作业；其Windows真时钟证据仍因无播放端点而失败关闭。

| 类别 | 已有自动检查 |
| --- | --- |
| 源身份 | ZIP/App/HTML/package/master 五份指纹；24 个 ZIP entry；44 SVG、81/203 Polish、合成确定性 |
| 原型保留 | 13 个归档文件的大小/SHA-256 和完整文件集合 |
| 代码边界 | 无 WebView/HTML 嵌入、无 Gradient/旧原型导入；注入/路由库局限 app；Shell 不创建业务 Controller |
| 布局单元 | Windows 1440/1439/1024/1023/599；Android 599/600/正方形/844×390/1024×768/大竖屏；非法约束、非支持平台 |
| 根状态 | ProviderScope 内单一 graph；无后端不伪播放；音频事件/错误；取消订阅与只销毁一次；按路由存偏移/选中 |
| Widget | Windows 1440/1024/840/599实时切换且始终Windows，240/72侧栏与320 Inspector条件正确；Android Phone/Tablet/横竖屏实时切换；route/controller/position/selection不丢 |
| 导航 | player→lyrics返回player；主页面→lyrics返回主页面；系统pop/Esc；直接lyrics回home；未知路径不显示敏感query |
| 滚动 | 实际拖动、切主路由再返回、Phone→Tablet后的合法范围内偏移恢复 |
| 无障碍 | 360宽+130%文本、Semantics标签、按钮命中区>=44、点击导航 |
| CI 配置 | YAML真实解析、三个job、构建依赖checks、固定SHA与contents:read、SDK与pubspec一致 |
| Phase2A资产 | Google Fonts固定提交/大小/SHA/OFL、44SVG枚举全覆盖与真实解码；pubspec严格assets白名单、无默认Material视觉/网络字体 |
| 外观 | 五预设+216自定义色网格的正常/按下/浅深文字对比；非法HEX不改状态、System亮度/减少动态、会话通知 |
| 原生控件 | 键盘/指针动作、语义、44dp、选中、Disabled/Loading、Hover/Pressed/Focus、Reduce Glass几何保留 |
| 跨平台 Gallery | Android返回和根状态保留、真实字体130%手机/平板/横屏尺寸、示例动作与HEX校验；Windows同一路由保留Shell并展示明确标注的Chrome Fixture |
| Android原生导航 | Phone64/32、Tablet72及3×18条、低高度滚动、键盘/语义/Disabled、低对比色边界；599/600/1280/844横屏、SafeArea和根图保留 |
| Slider | 3/14/44几何、两端/步进、预览/单次提交/系统取消、纵向滚动不改值、RTL/键盘/语义、禁用/Loading/零范围/拖动中禁用、ReduceMotion |
| Artwork | 七种最终CSS背景真实像素、48/96/192尺寸、10/20/26圆角、image语义、local accent更新与Gallery本地数值 |
| Phase2C输入 | Switch几何/语义/键盘/RTL/取消、分段可滚动与单次选择/焦点可见、IME组合区/提交/清空、复制粘贴替身、禁用/Loading/错误公告、外部状态所有权、130%/360/600/键盘insets |
| Phase2D内容组件 | Album/Track几何、Hover/Pressed/Focus/Disabled/Selected或Playing/Loading、主动作与更多动作分离、键盘/语义、130%/390/600、Phone隐藏时长与长来源省略、Gallery仅本地状态 |
| Phase2E Windows Chrome | 42工具区、240/72侧栏、3×18选中条、Profile/Source状态、Hover/Pressed/Focus、Tab/Enter、Tooltip、独立窗口Fixture动作；正式Shell无假窗口/在线状态 |
| Phase2F播放器表面 | Mini64、Desktop88/76、封面54/50/48、视觉控制34/42与44命中；独立动作、语义/键盘、进度预览/提交/取消、音量、低宽降级、Loading/Disabled；不调用音频/队列/系统/持久化 |
| Phase2G弹层原语 | Context Menu 224/244/20/7/44、Dialog 680/30/72、Phone Sheet、Toast 42/420/14；受控动作、禁用/加载、方向键/Tab/Enter/Space/Esc、焦点闭环/恢复、live region、130%与Reduce Motion；不插入业务Overlay/Route/计时器 |
| Phase2H状态原语 | Swatch 30视觉/44命中及指针/键盘/语义；Empty 28/16/24；Error 12/14/15与live region、独立禁用/加载action；Skeleton纯色/填宽/无渐变；Gallery只更新本地状态 |
| Phase2I集合卡片 | Source 72/12/42/16/13/6与四种调用方色调；Playlist桌面16/44/18、Phone13/40及最终20/14圆角；collection/create、指针/键盘/语义、选中/禁用/加载、130%响应式；无Repository/网络/持久化 |
| Phase2J队列/歌词 | Queue标准/沉浸几何、独立动作与44dp命中；Lyrics future/past/active/双语/ReduceMotion；Dock桌面/Phone/低高度、进度提交/取消及ReduceGlass；无算法/Seek/计时器/持久化 |
| Phase3A Domain合同 | 稳定TrackRef、独立QueueEntry/重复曲目、不可变JSON、UTC/连续位置、歌词时序/翻译、HTTPS/公开Header/受限映射、凭据与失败脱敏、分页运行时校验、Fake替换及Graph释放 |
| Phase3B数据库 | v1精确17表/10索引、user_version/迁移审计/空队列状态、官方Schema验证、Track/Queue/Playlist/歌词约束、catalog/歌单外键级联、来源删除引用保留、敏感列白名单、后台文件打开与生成快照复现 |
| Phase3C LibraryRepository | remote/local双向row映射、递归JSON/UTC/URI/枚举、稳定TrackRef、确定分页、关联watch单次提交、事务回滚、Album/Artist聚合/替换、availability/notFound、损坏row/SQL脱敏、生命周期与owned/shared DB |
| Phase3D CollectionRepository | 歌单确定排序/系统身份保护、混合来源entries、连续位置校验、歌单/队列事务回滚、队列重复TrackRef/current/单次流、收藏幂等、历史去重20条/清空、损坏row脱敏与shared/owned DB |
| Phase3E LyricsRepository | plain/synchronized双语规范JSON、完整TrackRef隔离、upsert/remove、损坏JSON/UTC/SQLite脱敏及shared/owned生命周期 |
| Phase3F MusicSourceRepository | REST/local配置往返、排序JSON、确定watch、稳定身份/内置删除保护、用户引用保留、损坏配置/SQLite脱敏及shared/owned生命周期 |
| Phase3G SecureCredentialGateway | Android/Windows save-read-delete、确定载荷、四类凭据、碰撞不覆盖、非法引用预拒绝、损坏/插件失败脱敏、并发串行与限额fail-closed |
| Phase3H Bootstrap/Dev Fixture | Android/Windows生产组合和平台Gateway选择、共享作用域/幂等释放、Gateway构造失败关闭、真实内存Drift样本往返、非空拒绝无突变、默认入口隔离、loading/success/脱敏失败/卸载后晚到释放 |
| Phase4A 播放核心 | 三种PlayableSource验证/全量脱敏、八阶段Engine/Playback状态、值与队列一致性、load/状态流/Seek夹紧/音量/速率、重复entry队列操作/持久恢复、随机一轮、repeat off/all/one、自然下一首、错误脱敏、MediaSession回调、根幂等释放 |
| Phase4B media_kit候选 | file/content/HTTPS与Header瞬时映射、open不自动播放、八阶段snapshot合成、0–1/0–100音量、transport/Seek/rate、命令/异步错误脱敏、并发dispose/幂等、插件只在单一playback backend文件；Fake不冒充native播放 |
| Phase4C 原生本地WAV | 运行时固定PCM16/mono/16kHz/3秒字节与SHA、参数拒绝；Windows/Android同一集成测试验证load不自动播放、duration、play/position、seek、pause、volume/rate、completed、stop/idle、无error和dispose；不提交媒体二进制 |
| Phase4D 原生来源 | HEAD-only HTTPS探针、禁止自动重定向/响应持久化、HTTP与offline/timeout/TLS脱敏映射；Android debug-only只读Provider；双平台受控HTTPS及Android content URI真实candidate集成测试 |
| Phase4E just_audio候选 | file/content/HTTPS瞬时映射、load不自动播放、五种processing与八阶段合成、未知duration、transport/Seek/volume/rate、命令/异步错误脱敏、Header能力未声明时预拒绝、并发幂等释放；插件只在单一backend文件，生产入口不创建候选 |
| Phase4G media_kit分发门禁 | 四个package版本/许可指纹、Android 4 JAR/8 SO与APK 6 SO、Windows 7z/DLL与Debug bundle、内嵌FFmpeg/mpv配置、来源映射/阻断；拒绝擅自approved、删除阻断、APK→JAR哈希漂移或生产接线 |
| Phase4H 候选移除门禁 | pubspec/lockfile无任何media_kit包，活动适配器/测试/CI输入和双平台注册为0；历史manifest固定rejected/inactive；APK逐entry拒绝libmpv/helper/media_kit，生产仍Unavailable；测试数只减少已删除的5项候选Fake |
| Golden | 保留Windows Shell及既有组件29张；新增浅珊瑚/深翡翠/自定义白ReduceGlass队列歌词板3张，总计32张精确像素比较，旧基线不改 |

## CI

`.github/workflows/foundation.yml`：checks 在 Ubuntu24.04 跑 Node/PowerShell 源核验、Dart格式/严格分析/Flutter测试；checks 成功后独立 Windows2025 Debug 和 Ubuntu Android Debug 构建。push feat/fix/refactor/docs、PR或手动运行触发，超时20/30分钟。Android执行验签/48文件比对/三文件白名单和被拒绝原生库排除；只有手动workflow_dispatch在全部门禁后创建私有draft/prerelease，普通push/PR不创建下载产物。个人令牌不注入runner，checkout不保留凭据。

`.github/workflows/foundation.yml` 的 `run_just_audio_poc` 默认 false，只有手动设为 true 才运行原生测试。
Phase4K 增加 `just_audio_poc_platform=both|android|windows`（默认 both）；它只缩小明确选择的测试范围，
不改变发布权限，不把另一平台 skipped 计为通过。Windows 先要求真实播放端点，缺失即失败关闭，仍运行原始 WAV。
Android API36 x86_64 运行原始 WAV 加 Debug-only content URI 缺失/同引擎恢复/播放/seek/completed/释放测试。
原生模式跳过常规构建/发布，不使用 Secret、不上传 artifact、不创建 Release。
另有默认关闭且与原生模式互斥的 `build_windows_audio_probe`，只生成保留一天的 Windows Profile 诊断包。
普通 push 的 Windows Debug 包保留14天，需要 Debug CRT，不是通用 portable 发行包；PR 不重复上传。
所有结果只适用于被触发的精确提交，原生测试用 APK 在模拟器临时构建安装，不作为交付物上传。

Phase4E修复提交`a2b517b`的PR运行33936726367与push运行33936724989均完成checks、Windows Debug和Android Debug。push的Windows Debug artifact按既有策略保留14天；Android签名/48资产/打包成功但Release步骤skipped，匹配新Release为0。该证据只证明备用候选编译/打包，不证明native播放。

Phase4H目标提交`2ec37ef`的push运行33946021637和PR运行33946023102均完成checks、Windows Debug与Android Debug。Windows上传前排除门禁通过；push artifact下载ZIP共64项、66,407,581字节，API/download SHA-256一致且libmpv/media_kit为0。PR artifact与匹配Release均为0。该证据只证明被拒绝候选已从当前双平台包移除，不证明正式音频选型完成。

32张Golden按Windows宿主标记，Linux明确跳过（非静默通过）并运行完整非Golden回归，Windows job构建前执行`flutter test --tags windows-golden`。checks在分析前重跑build_runner与make-migrations，并要求g.dart/v1快照Git零差异。没有删除或跳过原有回归，远程状态须按目标commit单独核验。

云端交付增量：1项YAML门禁测试、4项Node元数据/拒绝本地打包测试。APK必须在build→signature→assets→package均成功后上传，不使用always/continue-on-error；metadata不复制环境变量或秘密，下载URL必须属于本run。4be8ba2的手动运行已完成既有交付复核；每个新commit仍须重新取得运行证据。

Phase2E实现提交86d5cf5的push运行33458611100、PR运行33458660012与手动运行33459298221均为三job success。手动运行的草稿Release三资产已下载，APK大小、SHA256SUMS、metadata、API digest及v2签名一致；此证据只适用于该实现提交，不扩展为本机安装或正式发布证明。

Phase2F实现提交a1eacd9的push运行33462315349、PR运行33462439635与手动运行33462929516均为三job success。手动运行的草稿Release三资产已下载，APK为175792949字节，SHA256SUMS、metadata、API digest与`df0b96062e96332206630ded3cc35117f244d31c079f2ec76c3f3b3d06a3254a`一致且v2签名有效；临时副本已清理。证据只适用于该实现提交。

Phase2G实现提交a56d4aa的push运行33465720644、PR运行33465784721与手动运行33466396076均为三job success。手动运行的草稿Release三资产已下载，APK为175818389字节，SHA256SUMS、metadata、API digest与`836e97c46aef2ed0036aaec085b8fb6113beeb2fe363749a7dfa3e817f648a88`一致且v2签名有效；临时副本已清理。证据只适用于该实现提交。

Phase2H实现提交9f71d14的push运行33468979883、PR运行33469047182与手动运行33469832392均为三job success。手动运行的草稿Release三资产已下载，APK为175828689字节，SHA256SUMS、metadata、API digest与`b9494ff75b5176b97ac11360a4b496c5182acdc5b0e875087a25d299989f6231`一致且v2签名有效；临时副本已清理。证据只适用于该实现提交。

Phase2I实现提交c2948e8的push运行33472070037、PR运行33472095784与手动运行33472750596均为三job success。手动运行的草稿Release三资产已下载，APK为175843741字节，SHA256SUMS、metadata、API digest与`3035e3b5a031ef283af098514c78ee8264a5d03ed3aa71f335d177da3ad11417`一致且v2签名有效；临时副本已清理。证据只适用于该实现提交。

Phase2J实现提交a20e0fb的push运行33475675911、PR运行33475736751与手动运行33476650469均为三job success。手动运行的草稿Release三资产已下载，APK为175880481字节，SHA256SUMS、metadata、API digest与`864a557af71841280ed938e80090a07e3bd7764a8e3680a17b6eef81e19af43f`一致且v2签名有效；48份打包资产逐字节一致，临时副本已清理。证据只适用于该实现提交。

Phase3A实现提交8506afc的push运行33480316280、PR运行33480358335与手动运行33481171269均为三job success。手动运行的草稿Release三资产已下载，APK为175891537字节，SHA256SUMS、metadata、API digest与`1500bd28956befbb697cbe160c388d25a1c900e6454b180bed4335aaec05b712`一致；48份打包资产逐字节匹配，v2单签名有效，临时副本已清理。证据只适用于该实现提交。

Phase3B实现提交31121d4的push运行33484750785、PR运行33484779370与手动运行33485752421均为三job success。手动运行的草稿Release三资产已下载，APK为183603621字节，SHA256SUMS、metadata、API digest与`3bdd3a74f8344df0c5124ffe25eee8c01d0d8985639ed91ff9084dac67defc69`一致；48份打包资产逐字节匹配，v2单签名有效，临时副本已清理。证据只适用于该实现提交。

Phase3C实现提交a155d65的push运行33490505244、PR运行33490538057与手动运行33491551841均为三job success。手动运行的草稿Release三资产已下载，APK为183604101字节，SHA256SUMS、metadata、API digest与`ed964e21cbf6e4994c3829b330399d4b30a6ee31f80a8d3d1089b87f6d380be2`一致；48份打包资产逐字节匹配，v2单签名有效，临时副本已清理。证据只适用于该实现提交。

Phase3D实现提交9468c2a的push运行33495498260、PR运行33495519334与手动运行33496511117均为三job success。手动运行的草稿Release三资产已下载，APK为183604101字节，SHA256SUMS、metadata、API digest与`d6b03be16d907103b7b3bbb421108f82a32a06e7687d115194be73a86b9fffb9`一致；48份打包资产逐字节匹配，v2单签名有效，临时副本已清理。证据只适用于该实现提交。

Phase3E本地增量：6项真实SQLite覆盖plain upsert/remove、同步双语/规范JSON、完整TrackRef隔离、损坏JSON/缓存时间与SQLite异常脱敏、shared/owned生命周期；完整181项Flutter含32 Golden、122文件format、严格分析、29项Node、24项ZIP、lockfile及生成/v1快照零差异已通过。目标提交云端证据另行记录。

Phase3E实现提交1e45532的push运行33499761224、PR运行33499787210与手动运行33500756816均为三job success。手动运行的草稿Release三资产已下载，APK为183604101字节，SHA256SUMS、metadata、API digest与`fd71936ef590dc18b1e851572c21cbf6d10f157a495298022dec3f2dd384020a`一致；48份打包资产逐字节匹配，v2单签名有效，临时副本已清理。证据只适用于该实现提交。

Phase3F本地增量：8项真实SQLite覆盖REST完整往返/规范JSON、local内置、确定watch、身份/删除保护、用户引用保留、损坏配置/SQLite脱敏及shared/owned生命周期；完整189项Flutter含32 Golden、125文件format、严格分析、29项Node、24项ZIP、lockfile及生成/v1快照零差异已通过。

Phase3F实现提交22d68f2的push运行33503815038、PR运行33503837936与手动运行33504877925均为三job success。手动运行的草稿Release三资产已下载，APK为183604101字节，SHA256SUMS、metadata、API digest与`db2946d4b416971b2fbb89cc754ba77cdf0c03f36aff3f84b2ad425a281c24a2`一致；48份打包资产逐字节匹配，v2单签名有效，临时副本已清理。证据只适用于该实现提交。

Phase3G本地增量：10项安全Gateway覆盖Android/Windows生命周期、规范JSON/四类凭据、碰撞不覆盖、非法引用、损坏载荷/插件失败脱敏、并发串行及限额；完整199项Flutter含32 Golden、130文件format、严格分析、29项Node、24项ZIP、lockfile及生成/v1快照零差异均通过。本机Android Debug成功，APK为237658550字节、48份资产逐字节匹配、Manifest禁用备份且v2单签名有效。

Phase3G实现提交4daf380的push运行33510086595、PR运行33510153174与唯一手动运行33511421874均为三job success。手动运行的草稿Release三资产已下载，APK为189393711字节，SHA256SUMS、metadata、API digest与`2623eab9590f4f333bc7327ee4d4dea49ee5b6f6789219f129b44f1e7108bcdf`一致；48份打包资产逐字节匹配、Manifest确认`allowBackup=false`、v2单签名有效，临时副本已清理。证据只适用于该实现提交。

Phase3H本地增量：8项覆盖双平台生产组合、共享数据生命周期、构造失败关闭、真实Drift Fixture/非空拒绝、Graph所有权和Bootstrap异步状态；完整207项Flutter含32 Golden、137文件format、严格分析、29项Node、24项ZIP、lockfile及生成/v1快照零差异均通过。本机默认生产入口Android Debug成功，APK为238963881字节、48份资产逐字节匹配、Manifest确认`allowBackup=false`且v2单Debug签名有效。

Phase3H实现提交27dd76c的push运行33517332873、PR运行33517452005与唯一手动运行33518770911均为三job success。手动运行的草稿Release三资产已下载，APK为190701235字节，SHA256SUMS、metadata、API digest与`e2d6e9be3d366a792c381662b3041f9ed9ac826e2d4c6bf19b8325c266e946e2`一致；48份打包资产逐字节匹配、无参考/凭据文件、Manifest确认`allowBackup=false`、v2单签名有效，临时副本已清理。证据只适用于该实现提交。

Phase4A本地增量：7项覆盖来源脱敏、完整状态、load/Seek/音量/速率、重复队列、随机/循环/自然完成、错误、MediaSession和持久恢复；完整214项Flutter含32 Golden、143文件format、严格分析0问题、30项Node、24项ZIP、lockfile及生成/v1快照零差异均通过。本机默认生产入口Android Debug成功，APK为238997827字节、SHA-256为`ea40ebd646300b0f14c1dcef9aef2971d19fba6da515e83b6f88c8e05bd66ab1`，48份资产匹配、Manifest正确且v2单Debug签名有效。

Phase4A实现提交ec508df的push运行33845988715、PR运行33846020650与唯一手动运行33848236710均为三job success。手动运行的草稿Release三资产已下载，APK为190735487字节，SHA256SUMS、metadata、API digest与`3f95cea301d6710ac46a40a5fbfcd0d4561d91f310ca5d04506d5389a1272aa4`一致；48份打包资产逐字节匹配、无参考/凭据文件、Manifest确认`allowBackup=false`、v2单签名有效，临时副本已清理。证据只适用于该实现提交。

Phase4B本地增量：5项Fake backend覆盖Windows file URI、Android content URI、HTTPS/Header瞬时传递、open不自动播放、八阶段合成、transport/Seek/音量/速率、命令与异步错误脱敏、并发幂等释放和非法输入；完整219项Flutter含32张Windows宿主Golden、严格分析0问题、30项Node、24项ZIP、lockfile及生成/v1快照零差异均通过。本机Android Debug成功，APK为279083792字节、SHA-256为`f3026e694c597b83297405c6587d46dc2906aa422b471838796950f776c59dd8`；48份资产逐字节匹配、Manifest确认`allowBackup=false`、仅INTERNET及生成的not-exported receiver权限、三种Flutter目标ABI仅含libmpv/libmediakitandroidhelper，v2单Debug签名有效。此证据只证明适配合同与native打包；未运行扬声器播放。

Phase4B实现提交b7e0b0f的push运行33853006353与PR运行33853041607均为三job success，分别独立完成checks、Android Debug与Windows Debug。精确SHA只存在这两次运行，workflow_dispatch为0，且没有目标为该SHA或分支的新Release；许可证未闭合前不触发手动Release。证据只适用于该实现提交。

Phase4C本地增量：2项生成器测试锁定96,044字节WAV与SHA-256 `571edd11f9568729867f4a1db7b5f4318e3868024e41253f5c5ca4a09787d51e`并拒绝非法参数；完整221项Flutter含32张Windows宿主Golden、149文件format、严格分析0问题、31项Node、24项ZIP、lockfile及生成/v1快照零差异均通过。本机Android Debug成功，APK为279,083,994字节、诊断SHA-256为`91bee6ec8cc76c324bf009e011a9dd38658bdbbf3f7e32971489af604caa065e`；48份资产匹配且v2单Debug签名有效。

Phase4C实现提交`622408e`的标准push运行33861562956与PR运行33861566379均为checks、Windows Debug、Android Debug成功。专用运行33862786766 attempt 2整体成功：Windows load 62 ms/首进度197 ms/seek 2 ms，Android load 580 ms/首进度155 ms/seek 4 ms；均报告duration 3000 ms、completed和`All tests passed!`。该attempt的普通构建/发布job按设计跳过，artifact总数0、匹配Release总数0。attempt 1的账单/spending limit拦截发生在runner分配前，不计作代码失败；用户授权公开仓库后重跑取得上述证据。Phase4C原生本地WAV出口关闭，但不外推为实体扬声器、真机、后台/焦点、`content://`或HTTPS验证。

Phase4D实现提交`913f3d75`的标准PR运行33878401743整体成功，checks、Windows Debug与Android Debug均成功；同提交push运行33878342752因并发组被PR运行替代而cancelled。专用运行33878710671整体成功：Windows HTTPS load 77 ms/首进度244 ms/seek 2 ms；Android HTTPS为110/143/3 ms，`content://`为56/151/2 ms；全部completed、失败矩阵通过且两端报告`All tests passed!`。专用运行只读、artifact总数0、匹配Release总数0。Phase4D出口关闭，但不证明真实第三方API、跨站重定向、实体设备、MediaStore/SAF持久授权、后台/焦点、系统媒体会话或许可证闭环。

Actions 固定 SHA，来源为维护者公开 refs 和说明：[checkout](https://github.com/actions/checkout)、[setup-node](https://github.com/actions/setup-node)、[setup-java](https://github.com/actions/setup-java)、[flutter-action](https://github.com/subosito/flutter-action)。静态配置验证不代表远程工作流已经通过；每个目标提交仍须单独取得并记录远程结果。

Phase4F实现提交`037db44`的push运行33941592336与PR运行33941595645均整体success，checks、Windows
Debug和Android Debug全部通过。只读运行33942090875中Android `just_audio`本地WAV通过：load 596 ms、
首进度68 ms、seek 9 ms、duration 3000 ms、completed，且代理/Header能力均false；Windows成功启动
AudioEndpointBuilder/Audiosrv但可用播放端点为0，按门禁失败，没有运行或伪造播放case。该运行artifact 0、
匹配Release 0。Phase4F与Windows小批A保持未关闭，小批B未开始。

Phase4G本地证据：Node 35/35、Flutter 232/232、严格analyze、152文件format、build_runner/Drift迁移零差异、
Android Debug及48项资产、原ZIP 24/24均通过。APK仍为279,085,047字节、SHA-256
`bba16856f7cdbc3c909172cafa75ee07c345067cb50f66dcc6cfe21e9adbf601`。机器审计通过的含义是
`blocked`状态和证据自洽，不是许可证通过；GitHub标准三job须按目标提交另行记录。

Phase4J实现提交`25747bc`：本地Flutter 248/248、Node 43/43、Dart格式156文件零变化、严格analyze零问题、
原始ZIP 24/24、生成代码/Drift v1零差异、Android Debug及48项包内资产通过。标准PR运行33951027905的
checks、Windows Debug、Android Debug全部成功；Profile诊断运行33951039057成功，1项一天artifact、0 Release。
同一GitHub Profile包在本机两个独立目录各执行原来的1项真实native WAV case且退出0，
load分别333/301 ms、首次进度158/160 ms、seek均2 ms、duration均3000 ms，completed/stop/释放均通过；
启动前后64项运行文件指纹不变。它不证明主观听感、网络来源、后台/媒体会话或生产应用可用。

Phase4K 实现 `33a0b3c`：本地 249/249 Flutter、44/44 Node、157 文件 format、严格 analyze、ZIP 24/24、
生成代码/Drift 零差异、正式与测试入口 Android Debug 编译以及48项资产通过。PR 33953908502 的
checks/Windows Debug/Android Debug 全部成功；原生运行33953874067成功且两项Android用例通过：
本地WAV load/首进度/seek为536/75/11 ms，content URI为29/170/7 ms，duration均3000 ms。
content缺失文件失败、同引擎恢复、completed、stop和dispose/状态流关闭通过；代理/Header均false。
两个成功运行artifact均0、匹配Release 0。Windows native在Android-only模式明确skipped，不计为新通过。
Phase4F无Header HTTPS、最终候选决策和生产接线仍未关闭；详见Phase4K报告。

Phase4L 实现 `8c4aa6e`：本地完整255/255 Flutter（含32 Windows Golden）、46/46 Node、161文件格式、
严格analyze、ZIP24/24、生成代码/Drift零差异、正式与三来源集成入口Android Debug编译和48资产通过。
标准push33955129003、PR33955146253均完成checks/Windows Debug/Android Debug。
Android原生33955145543三项通过：WAV load/首进度/seek为793/46/11 ms、content为26/171/7 ms，
两者duration3000 ms；HTTPS为1270/107/6 ms、duration1000 ms，固定夹具SHA/Range与释放通过。
Windows Profile运行33955146934构建成功，同包在本机新目录两轮各2项通过且退出0：
WAV为298/155/1、260/157/1 ms，HTTPS为347/94/1、330/91/1 ms，64项运行文件前后指纹不变。
四条运行整体success；产物数依次1/0/0/1，只有既有14天Debug与一天Profile诊断包，匹配Release0。
HTTPS使用默认TLS、无代理/Header、内存限时限额指纹核验，不持久化或提交媒体，不接生产。
此批关闭双平台无Header HTTPS原生缺口；最终候选/NOTICE、正式接线和Phase2网页视觉对照仍待完成。

Phase4M新增六个音频Dart包LICENSE和两个原生构建文件指纹；源码验证精确lockfile，
实际APK/Windows NOTICES.Z逐包验证完整原文。工具限制4 MiB压缩/16 MiB展开/10000组及严格UTF-8，
拒绝缺失、重复、错标签、篡改、空清单和非法压缩，实际APK入口另测缺失/重复/体积及参数大小写。
本地完整255 Flutter、51 Node、161文件格式、严格analyze、ZIP24/24、生成/Drift零差异、
Android Debug/v2签名/48资产/六包许可与既有Windows Profile六包许可全部通过；应用字节未改变。
初始`2143ecf`的push33956519388/PR33956538735两组三job成功，包含新的源码和两端实际打包许可校验。
参数修正`c0e3706`的push33957029385/PR33957031070也均三job成功，实际源码与两端许可日志已独立复核。
四条运行artifact依次1/0/1/0，均未创建Release；原生播放证据仍归属于Phase4L，不伪称本批重跑原生POC。
