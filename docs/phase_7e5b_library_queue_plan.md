# Phase 7E5B — 音乐库歌曲菜单添加/下一首

2026-09-12；fetch/pull后基线`f9590f25dea6ece18179fa25ffd9bdd72f1abfa7`，工作区干净；分支`codex/library-queue-actions`，Stacked Draft PR base=`codex/queue-insert-intents`。E5A云端仍运行，先处理失败、不借前置证据冒充本批通过。

范围：音乐库歌曲的手机长按/更多、平板菜单、Windows右键/键盘菜单新增“下一首播放”“添加到队列”，复用YYContextMenu与App.tsx原next/list-plus图标。该批先覆盖一个实际数据入口三端，专辑/艺人详情、自建/系统歌单等入口后续复用；不声称全站入口完成。

根QueueController增加准备插入意图的工厂：捕获expected根，生成独立entry ID与UTC addedAt，序号加候选查重，允许重复TrackRef；准备不写入。LibraryController提供准确Track对象/页面意图许可，不依赖音频可用；缺失文件可入队，仍明确不可用元数据。不创建新QueueController/播放器/数据库。

页面持有菜单根快照/源许可，根变化、曲库刷新、路由覆盖、TickerMode关闭、零面积或尺寸变化撤销旧菜单；选择时与执行前复核，关闭菜单本身不能误撤销已接受操作。忙态防双点，成功无自动播放，失败留根、显式同身份重试/知悉，成功可打开队列；返回焦点不抢后台页面。菜单渲染拆为受控Widget，根反馈复用独立原生组件。

出口：准备工厂/源许可单元、三端实际手势与键盘、旧回调/离页/刷新/重复/缺失项/失败重试/SQL验证、Golden精确更新并逐张查看；完整Flutter/Node/格式/分析/生成/迁移、源许可和Android预检，GitHub新SHA独立双平台构建。无Schema/依赖/平台/原始资产改动，不合并/Release/手动音频诊断/付费。

实施补充：拆出受控LibraryTrackMenu及页面菜单动作part，主Screen保持小文件；歌单选择器返回后显式恢复队列交互权限，避免被其关闭期间的路由/Ticker通知永久停用。前置E5A两组CI均SUCCESS，已回填#75，不能代替本批新SHA验收。
