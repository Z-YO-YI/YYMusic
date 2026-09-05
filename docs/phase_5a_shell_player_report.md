# Phase 5A — 共用 Shell 播放器接线报告

2026-09-05，分支 `codex/shared-shell-player`，基于已 fetch/pull 的 `4a5b32d`。
前置 Phase4P 精确提交的 push 33960148896 / PR 33960169694 两组 checks、Android、Windows
均 success，六个实际 job 的源码、51 坐标、两端包内许可与设计资产 PASS 日志已独立复核。

## 实现与边界

ADR-045：PlaybackPresenter 只订阅根 PlaybackController、映射视图与转发命令，Graph 拥有其
生命周期；三个 Shell 只接收 Widget 插槽。Mini64、Tablet Compact76、Windows88/76 共享状态。
空队列/不可用后端不假装播放；加载抑制重复命令；失败仅显示固定脱敏 Banner 并允许重试。
Windows Space 排除重复按键与 EditableText，既有子控件优先消费自己的按键。

短期 Seek/音量预览仅存 Widget，取消不提交。队列条目/布局变化重建手势子树；Controller.seek
在串行操作真正执行时再次核对 expectedEntryId，防止外部换曲已经排队后旧进度误作用于新曲。
此可选参数不改变既有系统媒体 Seek 回调接口。没有新位置计时器、队列算法、插件或状态库。

复核 App.tsx POLISH_CSS 后修正旧主播放按钮：深色 rgba(15,18,20,.16) 阴影、偏移 0/8、blur22，
不再复用强调色 Primary Button 阴影。截图还发现未开放详情动作让曲目信息一起变灰，已将
无动作的元信息渲染为正常可读、没有按钮语义的静态内容，不用空回调伪造可点击状态。

收藏、真实封面、完整播放器、歌词、队列/设备工具尚未接通，对应回调保持 null；普通手机/窄屏
按既有组件隐藏额外工具，较宽桌面提供进度和音量。四个业务页面、音乐导入和 REST 仍未完成。
生产数据库不注入 Fixture，本批新增的歌曲只在测试 Fake 中存在，不构成可用音乐应用交付。

## 回归与视觉

- 严格 analyze 0 问题；完整 Flutter 300/300，含 38 张 Windows 宿主 Golden。
- 新增 5 个 Presenter 单元、10 个 Widget/契约用例、3 个播放态 Golden，覆盖重复命令、失败重试、
  销毁期间命令、非法数值、延迟执行的条目保护、真实 Pointer Cancel/切歌/Windows 缩放取消拖动、
  Android 横竖/平板/分屏无重载、130% 双语长标题，以及 Space/输入焦点和静态元信息语义。
- 首次视觉非更新测试精确出现 8 个预期旧基线差异；3 个播放器面板为原稿阴影/静态信息修正，
  2 个 Android 和 3 个 Windows Shell 为占位槽→播放器及间距变化。新增 3 张完整播放态图，
  逐张查看后只重捕获上述文件；其余 27 张旧图未变，最终全套非更新模式通过。
- 新交互测试最初错误地在 Compact76 查询被设计隐藏的 Slider；改为 Windows Full→Compact
  的真实拖动测试，并单独保留 Android Phone/Tablet 分屏播放连续性，不删除产品行为断言。
- Node 58/58，新增根 Presenter/无独立引擎/条目保护/禁用未实现动作门禁。

- 格式179文件零差异；build_runner 196 项内部缓存输出，跟踪的数据库生成代码、Drift v1
  快照和 pubspec.lock 零 Git 差异；ZIP 24/24、六包源码许可指纹通过。
- Android 默认 Debug 构建成功（20.1秒），48份设计资产、六包 NOTICES.Z、原生许可资产通过；
  APK 231,537,082字节，SHA256 `ac9a97b6978ec45ded70383f9fbca763deff116941af1eb7b0460174ee595d8f`，
  v2签名有效，1个Debug签名者；原生Java警告保留，未改全局参数压制。

精确提交的 GitHub Android/Windows 构建在推送后记录。无 WebView、新权限、缓存/下载、
Header 代理、用户媒体/凭据提交或 Release。本批 Fake/Golden 不替代 Phase4L 的原生播放证据；
Phase2 网页参考截图与原生页面逐像素对照仍未完成，不能声称视觉最终验收或 Phase5 整体完成。
