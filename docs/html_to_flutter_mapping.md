# 基础 HTML → Flutter 映射审计

范围：完整3710行基础HTML + 完整506行App.tsx。下面是实现计划，不是已实现清单。自动索引见 [design_inventory.json](generated/design_inventory.json)：4页、7层、16个media块、12个固定存储键、7个动态toggle键；包含87个箭头函数匹配位置（不是完整JavaScript AST函数总数）。

## 页面与独立交互层

| 源锚点 | 结构 / 入口 | Flutter路由与所有者 |
| --- | --- | --- |
| view-home | 问候/标题、Hero、继续聆听、最近添加、来源、最近播放 | /home；Home组合各Repository，来源错误不阻塞本地 |
| view-search | 输入、6类筛选、最近搜索、结果/空 | /search；SearchController，多源分页/取消 |
| view-library | albums/tracks/artists/playlists/local | /library/*；LibraryController，详情/album/:id、/artist/:id、/playlist/:id |
| view-settings | appearance/sources/local/playback/about | /settings/*；Theme/AppSettings/MusicSourceController |
| nowOverlay | MiniPlayer、F、全屏按钮、双击封面 | /player；FullscreenPlayerPage + FullscreenGateway，无完整歌词Tab |
| lyricsOverlay | L、播放页歌词、MiniPlayer/Inspector | /lyrics；独立FullscreenLyricsPage + LyricsController |
| queueOverlay | queue-open/Inspector展开 | /queue 或自定义弹层；共用QueueController |
| sourceOverlay | 添加/编辑表单 | /sources/:id/edit（新增为独立表单模式）；MusicSourceController |
| sourceManagerOverlay | 来源中心/管理按钮 | /sources；SourceRepository |
| playlistOverlay | 创建歌单/添加曲目到歌单 | YYDialog/Phone Sheet；PlaylistController |
| optionsOverlay | 输出设备/睡眠 | YYDialog/Phone Sheet；OutputGateway + SleepTimerController |

附加交互层：trackContextMenu（6动作）、toast（aria-live polite）、connectionNotice、scanProgress、source/playlist动态列表；不是另外四个主页面，也不计入七个Overlay。

Phase2G已实现`YYContextMenu`、`YYDialog`、Phone适配`YYBottomSheet`与`YYToast`的受控原语，但本表中的路由、Controller、右键/长按触发、菜单锚定、Toast队列/时长及真实业务动作仍是后续实现。Gallery内联Fixture不得被计作上述Overlay流程已交付。

Phase2H已实现`YYThemeSwatch`、`YYEmptyState`、`YYErrorBanner`与`YYSkeleton`，并将Gallery五种强调色改用Swatch。它们只表达受控状态；`idle/loading/data/empty/error`的转换、真实重试、来源失败、搜索结果和扫描进度仍由后续Controller/Feature所有，静态Fixture不能计作业务异步流程。

Phase2I已实现`YYSourceCard`与`YYPlaylistCard`的受控原语，并应用基础HTML与App.tsx最终`POLISH_CSS`的圆角覆盖及Phone尺寸。来源标签/色调、歌单选择/Create动作均由调用方提供；没有创建Source/Playlist Domain、Repository、连接测试、数据库、凭据、真实歌曲计数或持久化。Gallery的确定性内容不能计作来源页或歌单业务流程已交付。

Phase2J已实现`YYQueueTile`、`YYLyricsLine`与`YYLyricsPlayerDock`受控原语。映射同时读取基础HTML的queue、fullscreen lyric、lyrics dock及900/599/低高度规则，并应用App.tsx后置`POLISH_CSS`的Queue artwork 10、歌词780字重/紧字距/6px active ring和Dock最终26圆角；图标继续取`NEW_ICON_SPRITE`的up/down/x、prev/play/pause/next/heart/music原始路径。组件没有接入QueueController、音频Seek、LRC解析、自动滚动、计时器、拖拽、数据库、持久化或独立歌词页。

Phase3A把基础HTML的catalog、favoriteIds、recentIds、playlists、queueIds、sources和lyricsByTitle映射为正式Domain合同。网页slug/随机ID改为调用方提供的稳定TrackRef与独立QueueEntry ID；队列重复曲目不再被trackId合并。localStorage中的来源auth文案不作为秘密，正式Config只存`credentialRef`，敏感字段交给SecureCredentialGateway。按标题生成歌词、object URL、默认connected和示例延迟均不进入生产模型或Fake成功状态。本批没有数据库或UI接线。

Phase3B把上述合同落为Drift v1 Schema，而不是复制localStorage对象：catalog拆为tracks/albums/artists及关联表，playlist/favorite/history/queue保存完整TrackRef，queue另存独立entryId和单行状态；sources只留公开配置JSON与credentialRef，lyrics使用lines JSON缓存。网页随机ID、默认connected、示例Token、Blob URL和用户音乐仍未写入数据库；本批没有Repository或生产Fixture。

Phase3G实现平台安全凭据边界，但明确不迁移HTML `localStorage`里来源表单的auth/token示例或任何浏览器存储值。Android/Windows只保存经Domain验证的`SensitiveCredential`，对外返回不可推导随机`credentialRef`；MusicSourceRepository和Drift仍只看引用。Gateway没有网络、来源连通测试、OAuth流程或AppBootstrap接线，HTML的假延迟/假在线状态仍不进入生产运行路径。

## 六条核心流程与行为边界

| 流程 | 网页真实实现 | Flutter替代 |
| --- | --- | --- |
| 本地音乐 | 文件/目录input或drop → MIME/扩展名过滤 → name/size/mtime去重 → ObjectURL → 文件名解析 → audio探测时长 → 会话catalog | LocalMusicGateway授权 → 可取消扫描 → 元数据/指纹 → Repository事务；Windows路径、Android content URI/SAF grant；禁止上传路径 |
| 播放 | currentTrack/playing/progress全局变量 → objectUrl真实audio，否则demoTimer每秒+1 → UI与歌词同步 | SourceRepository.resolvePlayableSource → AudioEngine.load/play → PlaybackController唯一状态流；异步成功后记历史 |
| 来源 | 表单展示认证等字段，但仅name/type/baseUrl/auth等入localStorage；testSource假延迟/假连通 | 安全存储凭据、DB credentialRef；真实TLS/HTTP/auth/schema/mapping探测；连接成功才connected |
| 全屏播放 | openNowPlaying普通overlay，F/add immersive → 浏览器Fullscreen；退出恢复overlay标志 | /player独立路由；OS全屏与路由两层状态；Windows恢复window bounds，Android恢复System UI |
| 全屏歌词 | 保存lyricsReturnToPlayer、退出player浏览器全屏 → 单独lyrics overlay → timestamp高亮/居中/点击seek | /lyrics push自来源路由，pop回/player或原页；当前曲目共用；手动滚动暂停跟随，LRC解析/offset/translation |
| 队列/收藏/歌单 | 同一catalogById、queueIds、favoriteIds、recentIds；菜单与各视图重渲染 | 稳定TrackRef/QueueEntry ID；单一Controller/Repository；跨Shell/重启恢复，移除来源保留不可用引用 |

## 状态审计

| 领域 | 已存在的网页状态 | 正式状态 / 缺口 |
| --- | --- | --- |
| 播放 | playing bool、progress/duration、audio/demo、repeat off/all/one、shuffle | idle/loading/buffering/ready/playing/paused/completed/error；failure与buffer独立 |
| 来源 | connected/testing/error/disabled + enabled | 增补unauthorized/rateLimited/schemaMismatch/offline；UI不能乐观伪造成功 |
| 内容 | active/hidden、empty search、空曲库/队列/历史 | 所有异步显式idle/loading/data/empty/error；可重试与局部失败 |
| 交互组件 | default/hover/active/focus-visible/selected/disabled/dragging | Typed交互状态 + Semantics；Touch至少44；Pressed优先Hover |
| 歌词 | future/past/active、无歌词 | 无歌词/plain/LRC/双语/loading/error，手动滚动/恢复跟随/偏移 |
| 扫描 | progress、added、文件列表 | discovered/added/updated/duplicates/missing/errors/cancelled；权限拒绝/撤销 |
| 平台 | navigator.onLine、fullscreenElement、设备名字符串 | Connectivity/Fullscreen/MediaSession/OutputGateway，不由Shell保存业务真相 |

## 持久化键完整映射

| HTML键 | 正式归属 | 注意 |
| --- | --- | --- |
| yymusic-theme | Preferences.themeMode | light/dark/system；系统变化继续响应 |
| yymusic-accent | Preferences.accentPreset/customAccent | 保存原Hex并计算可读色，不能照搬lum>.53阈值 |
| yymusic-device | Preferences.outputPreference | 只是偏好，不代表硬件切换成功 |
| yymusic-favorites | favorites表/TrackRef | 原型会残留本地无效ID，正式标记不可用 |
| yymusic-playlists | playlists + playlist_entries | 保留顺序/稳定ID/系统歌单保护 |
| yymusic-queue | queue_entries | current entry、游标与重复项须有独立entryId |
| yymusic-recent | play_history | 成功开始播放后写入、去重、最多20 |
| yymusic-repeat | Preferences.repeatMode | off/all/one，围绕真实队列循环 |
| yymusic-searches | search_history | 网页存8条、展示6；正式可清除，不以Fixture作为用户历史 |
| yymusic-shuffle | Preferences.shuffle | 不复制Shell状态 |
| yymusic-sources | music_sources + SecureCredentialGateway | 普通配置与秘密分开，DB只存credentialRef |
| yymusic-volume | Preferences.volume | 网页0–100，Domain归一化0–1并校验 |
| yymusic-toggle-glassToggle | Preferences.glassEnabled | 所有允许glass区域统一降级 |
| yymusic-toggle-motionToggle | Preferences.reduceMotion | 封面scale/歌词滚动也须降级 |
| yymusic-toggle-keepQueueToggle | Preferences.keepQueue | 原型无行为逻辑；不得丢用户队列 |
| yymusic-toggle-dedupeToggle | Preferences.dedupe | 原型name/size/mtime；正式平台引用+指纹 |
| yymusic-toggle-gaplessToggle | Preferences.gapless | 原型只存开关，POC验证后提供能力 |
| yymusic-toggle-normalizeToggle | Preferences.normalization | 原型只存开关；不伪造响度标准化 |
| yymusic-toggle-autoplayToggle | Preferences.autoplay | 网页已在ended判断；正式在Controller |

不持久化的网页状态：本地文件/授权、ObjectURL、currentView、当前播放进度、historyStack、sleepUntil、sleepAtTrackEnd、各页滚动、来源编辑未保存内容。正式版按主文档补齐，不迁移浏览器存储本身。

## 键盘/鼠标/触控

- Windows：Space播放；Ctrl/Cmd+K搜索、L库、逗号设置、O导入；无修饰F切全屏、L歌词；Esc先浏览器全屏、再context menu、再Overlay。Alt+Left是正式新增要求，网页没有。
- typing检测仅INPUT/TEXTAREA/SELECT；正式Focus策略还需保护可编辑文本、组合输入，不让快捷键误触。
- 静态曲目点击/右键、动态曲目Enter/Space、更多按钮；动态列表实现520ms触摸长按，静态条目没有等价完整长按流程。
- 拖放仅localDropZone；队列无拖拽实现。Flutter桌面右键、平板/手机长按统一Menu模型。
- Overlay打开120ms后focus首控件，关闭不restore focus；正式需焦点范围、Tab顺序、可访问公告和返回确认。

## v1 范围锁定

只Windows10/11 + Android一个APK/AAB（Phone/Tablet Shell）；本地扫描和真实播放；合法用户配置的第三方API；搜索、收藏/历史/歌单/队列、主题、独立player/lyrics、平台媒体能力。无默认在线曲库、下载、离线音频、批量抓取、WebView；不扩展旧原型“设备同步/发现编辑内容”为新业务。

逐阶段交付；本轮不创建Flutter骨架、不实现UI、不安装音频依赖。Phase 1前须解决环境及旧原型迁移范围，详见implementation_status.md。
