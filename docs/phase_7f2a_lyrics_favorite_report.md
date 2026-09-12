# Phase 7F2A 完成报告：歌词页收藏接线

2026-09-12。基线4302cbbb7ee98f5ef5df8ba6c62f55123e7df5de，分支codex/lyrics-current-favorite-ui；Stacked Draft基于codex/current-track-favorite-core。计划与ADR091先于代码，保持原设计源指纹，无WebView。

## 实际新增与修改

- AppRouter/YYMusicApp注入可选根PlaybackFavoriteController；LyricsScreen借用监听并在dispose解绑，不关闭根。只有存在CollectionRepository时注入，无存储预览不模拟成功。
- 新增lyrics_favorite_actions.dart，捕获原不可变投影、显式目标和页面代数，迟到回调不能切换为新歌曲。保留活动/面积/尺寸/依赖撤销，并补实时ModalRoute检查。
- YYLyricsPlayerDock新增独立favoriteBusy，保存不锁播放或返回；收藏值只由Repository流驱动，未知状态不显示未收藏按钮。
- 新增受控PlaybackFavoriteFeedback，读写失败脱敏、显式同身份重试/写失败知悉，失败保留于根。读失败不允许隐藏唯一恢复入口。
- 12 Widget测试、3 Golden、1 Node门禁；更新旧“收藏未接线”精确断言、README/实施状态/测试矩阵及前置CI报告。

## 与原设计对应

设计转代码技能沿用已审计本地导出，无在线Figma节点。App.tsx的NEW_ICON_SPRITE原heart和POLISH_CSS合成保持不改；基础HTML1937–2035/2483已有38px歌词Dock心形、7px间距与手机隐藏规则。复用现有原生组件及资产，未添加手机Dock按钮或生成替代SVG。三张新图逐张检查，178旧图不变。

## 测试与构建

- `flutter test --no-pub --reporter expanded`：**1636全部通过，87秒**，包括**181 Golden**。新增12交互：两平台真实点击/外部流同步、队列和音频不改；手机隐藏/空项；resize/离页/重复队列条目/外部变化/卸载撤销；独立busy/接受后离页排空；写失败重试与旧回调；读失败恢复与旧重试。原歌词页加新测试42项先行通过。
- `node --test tools/*.test.mjs`：**136全部通过，18.4秒**。旧showFavorite:false约束按本批功能改为已知根状态，未删门禁。
- `dart format --output=none --set-exit-if-changed lib test integration_test`：**505文件零变更**；严格`flutter analyze --no-pub --fatal-infos --fatal-warnings`：**零问题，8.4秒**。
- build_runner13秒、Drift迁移成功，生成/Schema零漂移；ZIP24条目逐字节、四源SHA256及六音频LICENSE/两个原生源指纹一致。
- Android Debug本地预检**19.1秒通过**，APK **232220315 bytes**，SHA256 **57fedc95314e68c6ec53cebbff2dc8aee589b3247a3433e7af41644b99f22050**。48资产及完整音频许可通过，v2签名/单签名者通过；Java native-access警告保留。

初次发现Semantics非const构造错误，修复后再测；新测试夹具跨Fake/Real Zone等待及自动关闭/阴影清理顺序修正为既有借用根模式和finally恢复。初次失败日志保留，不把生成图片当作测试通过；最终全量包含三张Golden比较通过。没有删除旧Dart测试、关闭lint或修改旧Golden。

## GitHub、限制与下一阶段

2026-09-12后续核验：精确head `d29356cc0419bd878a0bc995f19c5057994c19fe` 的[push34704863898](https://github.com/Z-YO-YI/YYMusic/actions/runs/34704863898)与[PR34704867239](https://github.com/Z-YO-YI/YYMusic/actions/runs/34704867239)均SUCCESS；源码、Android及Windows构建通过，两个显式媒体诊断作业跳过。此为F2A结果，不替代F2B新提交验证。

前置F1的push34703279070/PR34703282153均SUCCESS，精确head4302cbb，报告已回填。本批提交push与Draft PR后按新SHA独立核验双平台，不将本地APK或前置成功当作本批CI成功。未提交凭据、用户媒体或构建产物；不自动合并、不变默认分支、不发布Release。

本批仅歌词页收藏。播放页/Shell收藏尚待接入；手机继续遵循原Dock隐藏规则。真实SQLite路径沿用本轮重跑的F1四项，无新增UI-SQLite联调用例；无本批本地Windows编译/真机安装/出声验收。Phase7整体及Phase8真实导入、Phase9来源、Phase10后台媒体、Phase11签名发布未完成，新安装仍为空库。下一批继续播放页/Shell接线及相应交互/Golden验证。
