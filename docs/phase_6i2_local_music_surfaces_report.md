# Phase 6I2 — 本地音乐原生概览完成报告

2026-09-09，Z-YO-YI/YYMusic，`codex/local-music-surfaces`。
fetch及`git pull --ff-only origin codex/local-library-overview`确认基于`79540d0b0dd99c0024277457b3d39da951be727d`，独立stacked Draft PR以`codex/local-library-overview`为base。未在main开发或自动合并。

## 实际新增与修改

- `lib/features/local_music/common/local_music_controller.dart`：根持有只读概览、加载/空/错误状态、安全Failure及20条分页。先订阅后读取，失效合并到一个worker；快照身份拒绝旧分页，删除末页后回退有效页。
- `local_music_panel.dart`/`local_music_sections.dart`及Phone/Tablet/Windows三套布局：音乐库本地分类接入真实统计、目录分页、配置/历史日期、刷新/重试。无数据未返回时不显示假零值，错误保留旧数据时明确提示过期。
- `AppDataServices`/`DatabaseAppDataServices`/`DependencyGraph`：复用同一DriftLibraryRepository，根关闭排空读取和订阅取消再释放数据库，LibraryController仅借用，不创建第二播放器或数据范围。
- `LibraryScreen`/`LibrarySections`：本地分类内嵌概览，稳定GlobalKey在布局替换时迁移唯一Panel；遮挡、隐藏、零尺寸、实际卸载撤销读取与旧动作，回到页面重读。
- `YYSurface`新增保留原默认值的可选radius；`YYRadius.metricCard=18`、`folderRow=16`来自App.tsx精修规则。
- 新增Controller/SQLite/Widget/Golden测试与隔离Probe/Harness；既有根Fake补齐接口，Node门禁明确验证新Controller在存储之前关闭。
- ADR-072先于共享API改动；README、实施状态、测试矩阵、计划与本报告同步更新，回填I1精确云端完成证据。

## 设计对应与边界

来源为主指令17/21/29/36、基础HTML `libraryLocal`与完整506行App.tsx，包含44最终NEW_ICON_SPRITE、全部POLISH_CSS和两项账户品牌替换。
使用figma-design-to-code技能复用原生YY组件、精确folder/refresh/up/down SVG和既有字体/颜色/阴影；仅有本地Make导出，没有在线node，不伪造get_design_context。
Phone统计纵向；Tablet横屏统计/目录分栏、竖屏统计横排；Windows统计横排/目录列表。普通内容使用纯色轻阴影，不新增玻璃、渐变、默认Material组件或手绘近似图标。
本地曲目数只统计local来源；可用性、文件夹enabled与lastScannedAt均是已保存记录，不表示刚完成权限或文件可读性检查。界面不展示路径/Content URI/授权引用。
本批不接入HTML模拟dropzone/扫描按钮，不创建假目录，不执行任何真实文件扫描、导入、系统授权或数据写入；既有本地曲目浏览/播放入口保留。

## 测试命令与实际结果

- `dart format --output=none --set-exit-if-changed lib test integration_test`：397文件零修改。
- `flutter analyze --no-pub --fatal-infos`：零问题，最终9.4秒。
- `flutter test --no-pub --reporter expanded`：最终1029/1029通过，55秒。新增29项：13 Controller、8 Widget、2真实SQLite、6 Golden。
- `node --test tools/*.test.mjs`：113/113通过，约15秒；新增两项合同门禁，既有顺序检查加入localMusic.close而不是删除或放宽。
- `dart run build_runner build`、`dart run drift_dev make-migrations`：通过；生成代码、Schema、lockfile、平台和原始资产无差异。
- `node tools/design_audit.mjs --check`：5指纹/44图标/52产物通过；`tools/verify_reference_archive.ps1`：24原ZIP条目逐字节一致。
- `tools/verify_audio_licenses.ps1 -Mode Source`和`tools/verify_native_audio_notices.ps1 -Mode Source`：分别独立执行通过。
- `flutter build apk --debug --no-pub`：成功；`tools/verify_android_apk.ps1`：48原始资产、六音频包许可证及完整原生材料通过，参考/私密文件未打包。
- `apksigner verify --verbose`：v2单签名者通过。APK为232,007,064 bytes，SHA-256 `98058bc29370e191328e8518dab9ecca9f53ff6191697826c0439058b8a78705`。

最终104张Golden全部通过：六张新增逐张检查，唯一旧图`library_phone_empty.png`因新增概览更新，其余97张字节不变。截图夹具修正为包含页面底色，不接受透明底冒充完整视觉；未降低阈值。
初轮暴露的Drift isNull导入冲突、Widget关闭时假时钟未推进、隔离夹具无真实路由焦点、旧Panel在断点后误停根状态、旧关闭顺序门禁和预期空库基线变化均已修正后重跑。没有删测试、静音Lint或忽略失败推进。
SQLite真实延迟SELECT证明根关闭等待查询结束再关数据库；真实应用返回/旋转/分屏、Windows Tab/Enter和覆盖按钮回归通过，不用单独布局夹具替代路由验收。

## GitHub 与已知限制

前置I1精确push/PR均success，Linux902/98宿主跳过、Windows98 Golden+1窗口集成、双平台Debug通过；完整回填见I1报告，不作为本批云端验收。
本报告记录提交前本地结果。本批源码推送及Draft PR后由GitHub Actions对精确提交重新构建Android和Windows；完成状态以对应PR/运行日志为准，不能用本机通过代替云端通过。
未运行本批Android实机安装/出声或本机Windows构建，未发布Release或运行额外手动音频诊断。APK和测试日志保留在忽略的build目录，不提交构建产物或凭据。
提交前检查38个变更文件，其中31个文本文件敏感模式扫描零命中，七张PNG为六新增/一预期更新；`git diff --check`通过，无.env、密钥或不必要二进制产物。

当前可查看原生本地概览不等于日常可用播放器，新安装仍为空库且没有导入入口；Windows Debug依赖Debug CRT，不是通用安装版。
下一步按Phase6顺序开发Settings，然后Phase7完整播放/歌词/队列、Phase8真实导入与授权扫描、Phase9来源、Phase10平台媒体、Phase11设备/性能/视觉与发行验收。整个产品和上线尚未完成。
