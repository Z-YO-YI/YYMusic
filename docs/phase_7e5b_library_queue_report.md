# Phase 7E5B — 音乐库队列菜单阶段报告

2026-09-12；GitHub `Z-YO-YI/YYMusic`；分支`codex/library-queue-actions`；fetch/pull后基线`f9590f25dea6ece18179fa25ffd9bdd72f1abfa7`，工作区干净；Stacked Draft PR base=`codex/queue-insert-intents`。[计划](phase_7e5b_library_queue_plan.md)和ADR086先于共享API与UI修改。

## 实际交付

- 音乐库歌曲菜单新增“下一首播放”“添加到队列”：Android手机/平板长按/更多、Windows右键与原生键盘菜单。复用YYContextMenu及App.tsx准确next/list-plus图标，不重新绘制或引入WebView。受控LibraryTrackMenu与页面菜单动作part分离，保留原播放/收藏/添加歌单入口。
- 根QueueController.prepareInsertion在同一expected根上生成唯一队列entry ID、UTC addedAt并准备E5A编辑；同一时刻多次准备有独立ID，已恢复候选碰撞跳过，stale/busy/关闭返回空。准备本身不写入，重试继续使用原编辑ID，不重复添加或新建播放器/数据库。
- LibraryController源许可绑定准确Track对象和读取意图；同引用但不同元数据对象不获授权，刷新/分类/隐藏/关闭撤销旧许可。缺失文件可保存队列软引用，但其播放按钮与不可用元数据保持真实。
- 菜单捕获打开时根快照与源许可；根替换、刷新、尺寸变化、覆盖/离页、零面积、卸载/关闭后旧回调无效。正常选择关闭菜单不会误取消已接受提交，落库前再验源/页面；SQL接受后由根排空。返回歌单选择器后恢复页面交互，菜单焦点只在当前可见页面恢复。
- QueueOperationFeedback借同一根busy/失败，显示成功提示、安全错误、显式同身份重试/知悉和查看队列；失败跨页保留，旧提示关闭不能清除新提示。添加/下一首操作不启动、停止或重载当前音频，空队列不自动选中，重复TrackRef保留独立条目。

Figma转代码技能促使复用已审计原组件与精确导出图标；输入为本地完整Figma Make，无在线node URL，未虚构线上读取。ZIP/App.tsx/基础HTML/主指令四源指纹复核无变化，检查覆盖NEW_ICON_SPRITE和POLISH_CSS，不只读取旧HTML。

## 验证

- 新增3根工厂、6源许可单元，15Widget，2真实SQLite菜单回归，5Golden及1Node。三端实际触摸/右键/ArrowDown+Enter验证重复歌曲插入、下一首位置、当前播放保持和进入独立队列；7类旧菜单回调失效、不可用项、双点busy、写入接受后离页、失败跨页重试、歌单选择器返回及旧提示身份均覆盖。
- 两组真实SQLite从数据库读取歌曲并实际打开菜单，用INSERT触发器制造事务失败，验证队列保持为空、私有异常正文不进入页面；显式重试后保存唯一ID/完整TrackRef，current仍为空、音乐记录保留，Fake音频没有启动。没有用Widget/Fake当作真机出声验收。
- 完整Flutter **1476/1476通过**（74秒）；Node **130/130通过**（约28.9秒）；**481 Dart文件**格式零改动，严格分析零问题（7.8秒），build_runner成功（14秒），Drift迁移通过。生成文件、Schema、锁文件、平台与原始资产零差异。
- **166 Golden**全部通过：新增360手机菜单、1024平板深色菜单、1440Windows深色菜单、390手机成功、1024Windows失败五图；仅既有840窄Windows菜单因新增两项精确更新，其他**160旧图字节不变**。六张变更逐张查看，130%字体、原圆角/图标/焦点风格，未降低阈值。菜单滚动和原Shell保留，不把队列反馈误放入另一套框架。
- 开发时发现初始导航方法名、State扩展中受保护的setState、花括号/可空元素格式，以及测试Track缺duration/localPath；分别改用既有openSystemPlaylist、State内更新方法和完整合法测试模型后重跑。保留失败用例与严格检查，不把初次失败计为通过。原音乐库22项回归通过。
- ZIP全部24导出条目逐字节一致，44原SVG/52输出、六锁定音频包许可与完整原生材料通过。诊断日志/包仅存忽略的build目录，不提交用户媒体、凭据、环境或签名文件。

## 构建与 GitHub

本地Android Debug仅预检，**19.3秒成功**；48原始资产、六包许可/完整原生材料一致，APK v2签名通过、单签名者。232,180,851 bytes；SHA256 `fd7fd1989d7a745e7318cede5ec728bd27f831e5abcf4d6ed13f1303e46b0fc4`。Java native-access警告仍存在，未掩盖为无警告。没有本批本机Windows编译、实机安装/出声或发行验收。

前置E5A精确`f9590f2`的[push34687758792](https://github.com/Z-YO-YI/YYMusic/actions/runs/34687758792)和[PR34687761190](https://github.com/Z-YO-YI/YYMusic/actions/runs/34687761190)均SUCCESS，已回填[Draft PR #75](https://github.com/Z-YO-YI/YYMusic/pull/75)和E5A报告。PR日志：Linux1284通过/161Windows Golden按平台跳过，Windows161Golden、2Runner、正式入口Debug重建/65文件包，Android48资产/许可/签名通过。手动原生音频诊断跳过，无Release。

本批审查、提交、push后在Stacked Draft PR记录精确SHA和两组CI；Android/Windows由GitHub常规CI独立构建，不借E5A成功或本地APK表示E5B云端通过。主要文件：QueueController、LibraryController/Screen/Sections、新LibraryTrackMenu/library_queue_actions与QueueOperationFeedback、AppRouter根注入；单元/Widget/SQLite/Golden/Node及README/ADR/状态/矩阵/计划/报告。

后续核验：提交`4f508195f9a1977a23f44895c8437e4778ef246b`已同步，Stacked [Draft PR #76](https://github.com/Z-YO-YI/YYMusic/pull/76)，base=`codex/queue-insert-intents`。精确[push34689627222](https://github.com/Z-YO-YI/YYMusic/actions/runs/34689627222)与[PR34689643919](https://github.com/Z-YO-YI/YYMusic/actions/runs/34689643919)均SUCCESS。PR日志Linux1310通过/166 Windows Golden按平台跳过；Windows166Golden、2真实Runner、正式入口Debug重建与65文件包通过；Android48资产/完整许可/v2单签名者通过。手动媒体诊断和Release跳过，不将窗口测试当作设备出声验收。

未合并、改默认分支、发布Release、触发手动诊断或使用付费服务。本批仅音乐库歌曲菜单；专辑/艺人详情、自建/系统歌单等歌曲入口后续复用。Phase7其余能力、Phase8真实导入/扫描/授权、Phase9来源、Phase10后台/系统媒体和Phase11签名/安装/发行未完成。新安装仍为空库，Debug不是日常可用发行版。
