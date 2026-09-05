# Phase 6G4 — 详情曲目收藏与原生菜单

2026-09-06，基于已fetch/pull的`4386bd4`，分支`codex/catalog-detail-track-actions`。
前置双组checks/Android/Windows已success；五份源指纹与ZIP24一致，完整App.tsx及POLISH覆盖继续适用。

本批只补专辑/艺人详情已加载曲目的菜单：更多/长按/右键→播放、收藏/取消收藏。不可播放引用仍可收藏。
收藏借用根CollectionRepository，首次打开菜单时才订阅，不让普通只读详情新增收藏SQL或阻塞摘要。
读失败不伪装未收藏，提供重试；以完整TrackRef写入，已经接受的写入离页不撤回，根关闭等待写入/取消排空。

先增加ADR-056再改会话公共构造/动作。修改根接线/详情Controller与Sessions，新增私有收藏投影和菜单UI，
修改详情Screen/Sections及对应单位、真实SQLite、Widget/Golden/Node、README/状态/矩阵/报告。
不修改Library、Search、Domain/Data/Schema/播放器/平台或公开AppNavigation，不造第二存储/播放实例。

菜单在页面内容区，Phone靠底部、Tablet/Windows居中；背景不接收点击/焦点，Shell保持独立。
Esc/Android Back先关菜单而不退详情，关闭恢复可用的入口焦点；刷新/切分区/离页关闭菜单。
真实动作失败用固定安全文案，不输出来源路径/凭据/异常原文。没有下载、删除文件、歌单编辑或播放全部。

验证：跨来源/不可用引用收藏、读取错误/恢复、取消迟到事件、重复命令/写失败、关闭等待真实在途工作，
真实SQLite持久收藏及只读详情查询不变；三端130%/键盘/鼠标/长按/返回/焦点/菜单播放。
只更新详情曲目显示更多的预期Golden，新增菜单Golden逐张检查，其余基线不改。全量测试/分析/格式、
ZIP/许可/生成代码、Android本地预检、提交推送stacked Draft PR与GitHub精确双端核验；不合并或发布。
