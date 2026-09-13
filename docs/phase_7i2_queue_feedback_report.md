# Phase 7I2：队列播放失败的可见反馈

## 目标与来源

基线c1e8bda，开始前确认干净工作区并fetch/ff-only pull，建立codex/queue-skip-feedback，仓库Z-YO-YI/YYMusic。上一轮实际实现并提交了有界跳过，属于有效进展；本轮将安全记录接到真实队列页面，而非停留根接口。

遵循主指令§20错误记录与§30/31安全反馈、无障碍要求。使用figma-design-to-code技能，复用现有YYErrorBanner/YYButton、Typography/Spacing和队列三套布局；没有在线节点URL，明确以本地Figma导出为参考。复核基础HTML queueOverlay/可访问toast及App.tsx POLISH_CSS对Dialog/Context Menu的覆盖，保留已有合成设计组件，不引入WebView、新图标或外部UI。

## 实现与边界

- PlaybackController按不可变记录列表身份确认，只接受当前非空快照；根已关闭或旧快照无效。确认不改queue或调用音频。
- QueueController借用根投影与确认接口，没有第二份记录真相。
- QueueScreen新增反馈摘要、展开/收起详情及“知道了”。最多20条记录倒序显示，指出本次启动范围、失效曲目仍保留及全部失败会停止推进。
- 详情只从当前有效分页中按entryId和完整TrackRef匹配曲目名，不新增元数据I/O；否则使用当前队列位置或“已移出队列的曲目”。来源只显示本地/在线类型，不展示内部ID、路径、URI或原始错误。
- 展开与确认同时复核页面交互许可、实际路由可见性和记录身份。移除歌曲不自动清除其诊断；确认不等于重试或解决来源问题。每类错误用固定可理解文案，不自动删除或重放。

记录仍仅本次启动保留，未新增长期日志。没有修改歌曲可用性、扫描或音乐源功能。本次补齐可见反馈不代表其他Phase7验收或整体目标已完成。

## 验证

7项新增Widget：手机/平板/Windows真实路由确认且队列和音频命令不变；后续记录使旧UI及根确认失效；离开队列撤销旧操作；已移除条目不泄漏内部ID；568×320短屏真实滚动使控制可达。初轮短屏ensureVisible目标尚未懒构建，测试改为先有限滚动再定位，并等候滚动完成，不删除该测试或隐藏反馈。

修复静态检查指出的多行if括号及extension直接调用受保护setState：状态切换回到State实例方法，未关Lint。最终专项7Widget+3Golden共10通过。新增390×844手机、1280×800深色平板、1024×720Windows的130%字体截图，均逐张查看，反馈与按钮可见、内容可滚动。原223张Golden未修改，总计226张。

最终2380 Flutter通过（108秒），严格分析0问题（18.7秒），161 Node门禁通过（29.77秒），603 Dart文件格式零修改；测试进程均确认退出0。Android Debug构建通过（43.5秒），48资产逐字节一致、六项音频许可及完整原生声明通过。git diff --check通过，变更文本凭据/私钥扫描未命中。四个参考/主指令SHA256匹配审计基线，24个解压文件与ZIP逐字节匹配；无新依赖或SDK升级，既有Java native-access警告保持。

本地Windows构建因既有Developer Mode/symlink限制未运行；GitHub Actions验证本提交。父运行34757960776开始时仍in_progress，不记为通过。不用Golden/本地Debug代替真机听感、系统返回、后台媒体或发布签名验收。

## 交付与后续

独立commit/push，Draft PR基于codex/queue-skip-unplayable，不自动合并/发行。继续Phase7出口差异复核，无缝/标准化及真实来源、封面/LRC、平台QA等仍需按主指令推进，不能把已有数千测试当作全部要求的证明。总体目标保持完整。
