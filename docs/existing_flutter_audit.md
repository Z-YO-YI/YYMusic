# 现有本地 Flutter 原型检查

任务开始目录有README/pubspec/lib/test/assets，但没有.git。GitHub查询/fetch成功且没有refs。现有工程名sonic_gallery、产品文案声场画廊，不是已确认的YYMusic基线。本轮保留这些文件，不修改代码，也不替它们声明测试通过。

检查范围：main/app/models/icons/theme、两份测试完整内容；shell与pages中布局/标题栏/播放页关键片段及全目录静态检索。不是声称全量审查每个旧Widget。

| 位置 | 实测问题 | 处置阶段 |
| --- | --- | --- |
| lib/main.dart / lib/src/app.dart:23 | SonicGalleryApp、MaterialApp.title为声场画廊；不是YYMusic | Phase 1整理入口/品牌，保留旧文件历史 |
| lib/src/app.dart:80 | 只按width600/1024分compact/medium/expanded，不先判断平台 | Phase 1 classifier与三个空Shell，后续Phase 5布局 |
| lib/src/app.dart:48 | _playing/_queueOpen保存在AppFrame，未见AudioEngine/Repository实现 | Phase 3–4共用状态核心 |
| lib/src/icons.dart | 手绘SgGlyph不等同最终44SVG；包含download枚举及绘制case | Phase 2接入最终Sprite，移除旧禁止资产前先确认迁移范围；本轮未改 |
| lib/src/icons.dart:164附近 | pause第一根矩形后有break，第二根绘制不可达 | 旧原型缺陷，不能用该图标替代新SVG；未运行analyzer，不声称编译报错已复现 |
| lib/src/theme.dart:53 | light bg F6F6F3/accent F05252，与目标F5F5F2/FF3B5C不同；没有完整五accent语义 | Phase 2重新Token化 |
| lib/src/pages.dart:979 | _lyrics bool；Phone内嵌LyricsView、桌面歌词/队列tab，不是独立/lyrics | Phase 7独立路由 |
| lib/src/shell.dart:580附近 | window最小化/最大化/关闭回调为空 | Phase 10真实WindowGateway |
| lib/src/models.dart | Track没有稳定ID/来源引用、duration是String，内置静态专辑歌曲 | Phase 3模型+Fixture隔离 |
| assets/images/album_atlas.png | 旧封面图集，不是本次Figma纯色几何源 | 原地保留，不默认为YYMusic正式资产 |
| test/design_tokens_test.dart / app_smoke_test.dart | 验证旧颜色/旧品牌；未覆盖Android平台区分、独立歌词和正式播放器 | Phase 1起逐阶段追加或迁移，不删测试换绿 |
| 项目根 | 没有android/windows runner；Flutter/Dart不在当前PATH | Phase 1前建立SDK/平台工具链并验证 |

静态搜索未发现旧lib中的WebView/iframe/三类Gradient调用；这只是文本检查，不等于所有产品约束通过。特别是download图标和内嵌歌词已经不符合新要求。未修改、未“修顺手”这些旧原型功能。

Git范围：旧lib/、test/、pubspec.yaml、analysis_options.yaml、assets/images/album_atlas.png未纳入本轮提交；根README保留旧说明并加上明确历史标签。远程Phase 0分支只跟踪审计来源、工具、SVG、文档和保护性Git配置。
