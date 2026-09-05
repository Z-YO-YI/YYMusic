# Phase 6F — 音乐库原生入口

2026-09-06，基于 fetch/pull 后的 `0c38340`，独立分支 `codex/library-surfaces`。
前置 Phase6E 修复的两组 GitHub checks/Android/Windows 已成功，再核四份设计指纹及 ZIP24。

## 目标与来源

按主指令17.3 / Phase6，复核基础HTML2253起的音乐库分类、曲目/艺人/歌单结构，
以及App.tsx NEW_ICON_SPRITE、POLISH_CSS页面标题/专辑20/曲目14等最终覆盖。
复用既有原生设计系统、CatalogBrowseRepository、CollectionRepository与唯一根播放器。

- 根LibraryController持有分类/排序/来源类型/可用性、分页、迟到取消、动作和安全错误；
  页面不直接读数据库/文件/插件，不增加数据库、引擎或生产Fixture。
- 专辑/歌曲/艺人/歌单/本地五分类。目录20项/页，200项有界投影，明确提示缩小范围；
  歌单先读取既有元数据流，不提供未实现的编辑或详情。所有列表惰性构建。
- 原生Phone/Tablet/Windows独立布局，状态跨分类/断点/主路由保持；筛选改变回到页首。
  已保存REST引用不是实时在线搜索，空库/失败/不可用/加载/重试均真实显示。
- 曲目使用根playCatalogTrack，当前播放标识按完整TrackRef；筛选/离页/关闭撤销未执行意图。
  更多按钮、Windows右键、Android长按打开原生菜单，支持实际播放和收藏切换。
- Controller关闭先取消监听/读取意图，排空在途查询与写入，再释放共享存储；不关闭借用仓库。

## 文件、风险与出口

新增lib/features/library/{common,phone,tablet,windows}、Controller/Widget/Golden测试及架构门禁；
修改app根图/路由接线、相关根生命周期测试、README/状态/矩阵/ADR/阶段报告。
重点验证来源身份、分页原始offset/去重/错误重试、空页、切换/关闭竞态、收藏保留、
右键/长按/键盘/焦点、三端布局/130%文字/断点切换与同一播放器状态。
只生成本页新增Golden，不改变已有55张；每张新图查看后再接受，网页对照缺口仍单列。
完成格式/严格分析/全量测试/生成门禁/Android构建、审查与独立提交推送、Draft PR/双端CI。

专辑/艺人详情、歌单编辑与系统歌单、导入/本地恢复/真实封面分别按后续阶段实施，
不展示模拟导入/连接成功，不宣称Phase6或上线已全部完成。
