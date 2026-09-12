# Phase 7E4 — 原生队列拖拽

2026-09-12；fetch/pull 后基线 `32edb5be72e2c7999a92009046063f7c6aacf3be`，分支 `codex/queue-drag-sorting`，Stacked Draft PR base=`codex/native-queue-route`。前置 E3 云端在运行，无已知失败，独立跟进。

目标：Windows 原始 drag SVG 手柄鼠标拖动，Android 手机/平板长按条目拖动；保留上下移键盘/触控替代。惰性 SliverReorderableList 原生间隙/边缘自动滚动；仅当前有界读取组内拖动，跨组继续使用上下移/分页，不误移到整个队列末尾。拖动本身只改变临时原生呈现，正式顺序仍通过根 QueueEdit/反馈持久化，不复制乐库/播放器。

来源：主指令20/Phase7/38–39，完整设计源指纹复核；figma-design-to-code 技能复用已有 Token/YYQueueTile/YYSurface 及 App.tsx 精确 drag 图标。输入为本地导出，没有在线 node URL。检查本地与 CI 同版本 Flutter 3.47.2 的 reorderable_list.dart：使用未弃用 onReorderItem（目标索引已扣除源项），onReorderEnd 早于动画后的实际提交，必须保护两者间隙。

文件：QueuePageController/QueueDragSession、原生 QueueReorderSliver、队列页面与内容接线、单元/实际指针 Widget/Golden/Node、README/ADR/状态/矩阵/报告。无依赖、Schema、原生通道或引擎修改。

风险：同值快照/元数据刷新/页组或尺寸变化、拖放动画间隙离页、PointerCancel/无移动、缺失项、重复条目、组尾锚点、屏幕阅读器排序动作、原生自动滚动。每次内容/根/交互版本变化重建拖拽状态，旧语义回调也不能重新解释旧索引；实际 SQL 接受后由根排空。

出口：目标及完整 Flutter/Node、格式/严格分析/生成/迁移、源/许可、Android本地预检和精确SHA GitHub双平台构建。受影响 Golden 精确更新并逐张检查，不降低阈值。添加/下一首入口留下一增量；无合并、Release、手动媒体诊断或付费操作。

实施补充：原生列表按版本替换时暴露了 Windows 连续键盘排序焦点丢失，加入页面拥有的有界动作焦点及保守恢复，扩展 YYQueueTile 的可选焦点参数；不新增全局状态。E3 精确提交两组 CI 后续均成功，结果已回填 E3 报告与 PR #73。
