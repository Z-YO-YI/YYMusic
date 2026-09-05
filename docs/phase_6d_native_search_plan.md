# Phase 6D — 原生搜索界面与根作用域接线

## 开始条件

从已同步的 Phase 6C `b5d960f0246968525ecae1a04953e1871e5bb49a` 创建
`codex/native-search-surfaces`，保持 stacked Draft PR，不合并主分支。
已再次校验 ZIP、开发主指令、完整 App.tsx 与基础 HTML 的 SHA-256；沿用
Phase 0 审计。搜索输入沿用 NEW_ICON_SPRITE 的图标与 POLISH_CSS 的
15px / 460 字重、58px（手机 52px）高度；不是只移植旧 HTML。

## 本次边界

- 根作用域拥有搜索控制器；数据作用域提供同一个 DriftLibraryRepository
  的 CatalogSearchRepository 接口和独立搜索历史仓库，关闭前排空任务。
- 手机、平板、Windows 独立布局组合，共享受控输入、结果与历史组件；
  原生 EditableText，无 WebView、生产 fixture、下载或新音频引擎。
- 300ms 防抖与 IME 合成门禁；修改查询/筛选/离页/关闭使旧播放请求失效。
- 全部、曲目、专辑、艺术家、本地、在线来源筛选；三种实体 × 本地/已入库
  REST 引用分为六个独立加载/失败区域，并行查询，远程区域失败不隐藏本地。
- 每页 20 条，完整来源身份去重，原始行数计算 offset；每区最多读取 200 条，
  到限提示缩小查询，列表惰性构建。实时 REST 搜索留给 Phase 9，明确提示。
- 仅显式提交记录历史；历史加载/清除串行，清除需确认，不删除歌曲。
- Enter 搜索并播放当前可见首个可用曲目，搜索按钮只搜索。曲目操作通过唯一
  PlaybackController 原子复用/追加队列条目；专辑/艺术家详情尚未实现，结果
  不提供虚假按钮。Windows Ctrl+K 聚焦输入，Space 输入不切换播放。

## 验证与限制

先做控制器、根作用域与交互测试，再覆盖三平台尺寸、IME、快速换词、分页、
历史、取消播放和关闭。运行格式化、严格 analyze、完整 Flutter/Node 测试、
生成文件稳定性门禁与 Android Debug 构建/资产/许可证检查，推送并跟踪 GitHub
Android/Windows 构建。Golden 只说明原生回归，不替代被浏览器安全边界阻挡的
HTML 截图对照，也不替代真机音频/触摸验证；不声称全项目完成或可上线。
