# Phase 7C1 阶段报告 — 原生歌词正文与跟随视口

2026-09-09；Z-YO-YI/YYMusic；分支 `codex/lyrics-follow-viewport`；基线 `af1b07b`，Draft PR base=`codex/native-player-route`。
开始前核对干净分支并 fetch/pull。前置 7B1 两组源码/Android/Windows 全部 SUCCESS，报告与 PR #65 已回填精确证据；不将该成功归给本批。

## 实际实现

- 新增 `lib/features/lyrics/common/lyrics_viewport.dart`：只消费不可变文档、根行号/播放位置、活动状态、快照令牌和 Seek 回调，不访问数据层或创建播放器。
- 双向惰性 Sliver 从当前行向前/后构建，以实际行高与视口中心定位；10,000 行首/尾/远跳和手动滚动 10,000 像素后恢复均覆盖。测试断言可构建歌词行少于 35，不全量生成 Widget，不测量全部文本或估计平均行高。
- 手动触摸/滚轮/键盘焦点浏览暂停跟随；停止五秒后或“回到当前歌词”恢复，恢复只滚动不 Seek。位置更新而行号不变不重建滚动控制器；时序间隙无高亮，恢复不突然跳回第一行。
- 文档/快照变化、失活、零面积、旋转/字体/翻译重排和卸载撤销旧动作与定时器；禁用 Seek 后保留的回调也不会误调用空函数。偏移时间比较使用不溢出的整数差值。
- `YYLyricsLine` 复用最终字体/圆点/颜色，新增显式 phoneLayout，Windows 窄窗不冒充手机。只读歌词提供文本语义而非禁用按钮，不再额外降低透明度；减少动态真正禁用行缩放。
- `YYControlAction` 新增可选 onFocusReveal；普通控件默认不变，双向视口按实际位置显示已获焦点的行，不调用 requestFocus，不把焦点移到新当前行。翻译改变可保留同一行原生 Focus。
- 新增 21 项 Widget 与 7 张/项 Golden、1 项 Node 架构门禁；计划/ADR-077 先于共享 API 修改。更新开发文档与前置云端证据。

## 来源与视觉审查

使用 figma-design-to-code 的组件复用流程；只有已审计本地 Figma Make 导出，无在线 node，不伪造 get_design_context。主指令第 19 节/Phase7、完整 App.tsx 的 NEW_ICON_SPRITE 与 POLISH_CSS 审计产物、基础 HTML 的歌词结构/scrollIntoView/点击行为作为来源。
复用 YYLyricsLine/YYButton 和原始图标，不引入 WebView、渐变、模糊封面或生产 Fixture。背景色由未来页面决定；本批 Golden 使用明确测试纯色，不声称已提取真实封面颜色。
7 张正文 Golden 已逐张检查：手机竖/横、平板、Windows 宽/窄、纯文本和手动跟随暂停，均以 130% 字体绘制。它们不是完整歌词页面截图。
旧回归唯一差异为 3 张 queue_lyrics_primitives 基线的当前行缩放：测试均开启 Reduce Motion，旧版仍为 1.018，本批修正为 1。差异每图 11,741 像素/1.02%，已查看差异区域和三张完整结果，只更新这三张；其余 117 旧图不变，不降低阈值。

## 验证记录

- 新增 21 Widget + 7 Golden：28/28 通过。覆盖实际手势、鼠标滚轮、五秒恢复、远距离恢复、纯文本语义、时序间隙、快照/空回调、零面积/卸载、键盘焦点和减少动态。
- 根接线测试使用既有 LyricsFixture/真实根 LyricsController 和 PlaybackController：读取同一快照，15 秒高亮首行，点击按 +3 秒 offset Seek 到 13 秒；只读取一次仓储，无第二时钟。音频端为 Fake，不冒充本批实机出声。
- `node --test tools/*.test.mjs`：文档写入后 119/119 通过，15.6 秒。
- `dart run build_runner build`：13 秒通过；`dart run drift_dev make-migrations` 通过。生成/Schema/锁文件/平台配置/原始资产无漂移。
- 原始设计 5 指纹/44 SVG/52 确定产物、24 ZIP、六音频包/两个原生构建来源和完整原生许可材料复验通过。
- `dart format --output=none --set-exit-if-changed lib test integration_test`：428 文件、零修改；`flutter analyze --no-pub --fatal-infos --fatal-warnings`：最终零问题，9.5 秒。
- `flutter test --no-pub --reporter expanded`：最终 1188/1188 通过，62 秒，含 127 张 Golden；远距离恢复修正后完整重跑，没有以先前 1187 项结果替代。
- `flutter build apk --debug --no-pub`：最终增量构建成功，7.0 秒（此前同批全构建20.1秒）；`verify_android_apk.ps1`：48 原始资产、六音频包/原生完整许可与私密/参考文件排除通过。
- `apksigner verify --verbose`：v2、单签名者通过。APK 232,077,507 bytes，SHA-256 `5fec2228811efae9995eb9df32a0b26a7920173dc3f48aa340a433eda75b0b73`，仅保留忽略的本地 build 目录，不提交产物。
- 提交前 13 个变更文本文件敏感模式零命中；23 个候选仅包含13个文本和10张Golden（7新增/3精确更新），没有凭据、环境文件或构建产物。`git diff --check` 通过。

开发过程中定位并修正了双向通用定位偏移、保留旧 ScrollPosition 的远距离恢复失效、测试 Focus 层级与真实/测试异步区混用；失败均先复现再重跑，没有跳过用例或关闭 Lint。

## 边界与后续

本批为歌词正文组件，不修改正式 `/lyrics` 路由，未提供完整顶部、播放 Dock、翻译切换入口或加载/空/错误页面，也未启用平台全屏。后续以同一根同步器分批接三套页面布局与返回关系。
当前居中使用即时精确定位，不声称跨任意距离平滑滚动、实机性能 Profile 或屏幕阅读器人工验收完成。仅原生焦点和语义自动测试通过；窗口与 Android 设备验收单列。
没有本机 Windows 构建、本批 Android 安装/出声、Release/AAB/商店发布。新安装仍为空库，真实导入/扫描、来源、后台媒体和发行仍待后续 Phase8–11。
阶段提交/push 后核对精确 GitHub Android/Windows 流水线；不自动合并、触发手动诊断或提交安装包/凭据。Windows Debug 依赖 Debug CRT，普通 Android CI 尚无 APK artifact，不能当作通用安装版交付。
