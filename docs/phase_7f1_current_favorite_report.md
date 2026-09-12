# Phase 7F1 完成报告：当前曲目收藏核心

2026-09-12，仓库Z-YO-YI/YYMusic；分支`codex/current-track-favorite-core`，基线`449b1ffde107961ba31b75fc78587f1a5289e356`。开发前fetch/ff-only pull，提交前fetch确认远程基线0/0未变；Stacked Draft base=`codex/system-playlist-queue-actions`。[计划](phase_7f1_current_favorite_plan.md)与ADR090先于共享接口修改。

## 实际新增、修改与结果

- 新增playback_favorite_controller.dart、playback_favorite_state.dart、playback_favorite_actions.dart；DependencyGraph注册唯一当前曲目收藏投影，借现有PlaybackController和CollectionRepository，无第二播放器、队列或数据库。
- 状态绑定准确QueueSnapshot/current entry的完整TrackRef和收藏读取身份，未知收藏用null而不是false。重复歌曲可共享收藏引用但旧队列条目操作不可重用；失效/未解析引用仍可收藏，空当前项不可操作。
- 初始化仅启用跟随，有当前条目后才订阅；空库不新增收藏查询，音频位置更新不重读或改变投影身份。显式重读、读取错误/结束、晚到事件、重入listen及取消都带代数保护。现有曲库/详情收藏写入仍走原Repository，本批通过流同步，不重构所有旧writer。
- 显式设置捕获的目标值，不在等待后重新计算toggle；busy同步防重复，页面许可调用前后都复核当前投影，许可回调重入刷新/关闭不能放行写入。Repository已接受后切歌或关闭仍排空，始终写原引用。
- 只根据Repository流更新收藏显示，不乐观伪造成功状态；已持久化但流尚未发出时仍保持上次已知投影。安全读/写失败不存异常正文，写失败仅在同一失败/原投影有效时显式重试原目标，旧知悉不能清新失败。
- 关闭先撤销新操作，等待订阅取消和接受的写入，再释放播放器/引擎/存储；取消失败安全汇总，不跳过其他资源释放。两处旧Node关闭顺序断言精确增加playbackFavorite.close，原相对顺序保留。

## 与设计源对应及边界

对应原始播放区心形收藏的当前歌曲语义，后续Phone/Tablet/Windows按钮共用这一投影。本批没有改UI、播放Presenter或启用按钮，也没有新增/更新Golden；不把核心验证当成按钮可用。四源ZIP/App.tsx（NEW_ICON_SPRITE/POLISH_CSS）/基础HTML/总指令SHA256与Phase0一致，ZIP24文件逐字节匹配。无WebView、原图标重画或原资产变化。

## 测试命令和实际结果

- 最终`flutter test --no-pub --reporter expanded`：**1621/1621通过，73秒**；新增31项，27单元及4真实SQLite。**178旧Golden全部通过且字节未变**，无UI或基线更新。
- 单元覆盖构造闲置/空库无查询/首个当前项自动订阅、未知状态、位置流不重读、队列同值替换与重复条目身份、外部收藏变更、显式刷新、读错误/结束、过期编辑/失败、busy双击、页面许可重入、接受后切歌/关闭成功或失败排空、无乐观流更新、订阅取消等待和失败、reentrant listen关闭。
- SQLite四组（解析/未解析×添加/取消）验证INSERT/DELETE触发器失败回滚、原目标重试、不同来源相同歌曲ID隔离、收藏时间不误改；队列重复ID/顺序/current/updatedAt、历史ID/开始时间/最后位置和曲库保持。外部Repository写入会刷新根投影并撤销旧动作，Fake音频没有调用，不计设备出声。
- 初次全量发现6项旧回归因空库过早查询/订阅时序失败。修复按需订阅后原查询数和关闭断言不修改，相关**50项**（含当时新增29项）通过，完整1619通过；追加切歌和无乐观状态两项后最终完整1621再通过。
- `node --test tools/*.test.mjs`：两次 **135/135通过，33.9/18.7秒**；新增2项收藏架构门禁，原2处精确关闭顺序加入新根屏障。初次Node失败对应旧顺序断言，未删除检查或放宽正则。
- `dart format --output=none --set-exit-if-changed lib test integration_test`：**501文件零改动**。`flutter analyze --no-pub --fatal-infos --fatal-warnings`：**零问题，8.1秒**。初期初始化形式参数/大括号提示已修正，没有关闭lint。
- `dart run build_runner build`13秒成功，`dart run drift_dev make-migrations`成功，生成文件/Schema零漂移。依赖/平台/原资产/Golden无变更；六锁定音频包LICENSE及两个原生构建来源指纹通过。

## 构建与GitHub

本地`flutter build apk --debug --no-pub`预检**35.9秒成功**；48包内原始资产、六包及完整原生音频许可通过；APK v2签名通过、单签名者。232,213,316 bytes，SHA256 `7d7c442b78de641e89551b0a921240adfd3262b4d05cad0db8af9e3d9fb01c05`。Java native-access警告保留，未声称无警告；本批无本地Windows编译、实机安装或出声。

前置E5E head449b1ff的[push34701388602](https://github.com/Z-YO-YI/YYMusic/actions/runs/34701388602)与[PR34701391525](https://github.com/Z-YO-YI/YYMusic/actions/runs/34701391525)均SUCCESS，#79和报告已回填。PR日志Linux1412通过/Windows178Golden和2真实Runner、65文件正式入口Debug包及Android48资产/许可/签名通过；PR合并检验提交与本地APK各自记录，媒体诊断/Release未执行。

本批提交/push后在新Stacked Draft PR回填精确SHA和push/PR运行，GitHub Android/Windows独立验收；前置成功不代替本批构建。未提交凭据、用户媒体或构建产物，不自动合并、变更默认分支或发布Release。

## 限制与下一阶段

2026-09-12后续核验：head `4302cbbb7ee98f5ef5df8ba6c62f55123e7df5de` 的[push34703279070](https://github.com/Z-YO-YI/YYMusic/actions/runs/34703279070)及[PR34703282153](https://github.com/Z-YO-YI/YYMusic/actions/runs/34703282153)均已完成SUCCESS；源码检查、Android/Windows原生构建成功。此结果仅对应F1，不代替后续接线提交验证。

本批仅当前曲目收藏核心。下一批Phase7F2接三端播放区/歌词Dock的收藏状态、按钮、busy/失败和页面许可，并补真实Widget/Golden；Shell剩余导航入口及Phase7整体出口继续核查。Phase8真实导入/扫描/权限、Phase9来源、Phase10完整后台媒体和Phase11正式发布仍未完成，新安装仍为空库。
