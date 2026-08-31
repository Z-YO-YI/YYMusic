# 设计源差异与冲突审计

## 文件身份结论

ZIP、App.tsx、基础 HTML、package.json 的字节数、要求的行数和 SHA-256 全部匹配主指令 §0.1。没有另一个历史 ZIP 可比较，因此不能声称完成两个导出版本之间的差分。主文档 SHA-256 是本轮实测锁定值，不是文档自证值。

以下比较的是**本包基础 HTML → 本包 App.tsx 合成结果**，另附现有本地旧 Flutter 原型差异；不是凭空虚构设计版本变更。

| 类别 | 新增 / 删除 / 变化 |
| --- | --- |
| 主页面 | 仍是 home/search/library/settings 四个；App.tsx 未增删业务页面 |
| Overlay | 仍是 now/lyrics/queue/source/sourceManager/playlist/options 七个；播放与歌词已在基础 v4 分离 |
| 图标 | ID集合均44、无增删；最终路径/尺寸/filled结构以新 Sprite 为准，不能推断每条路径都改变（存在相同几何） |
| 账户 | 顶部两处文本替换，36方形标记变44圆形双Ring；footer头像/文字隐藏，更多按钮保留 |
| 视觉 | 新增81覆盖块/203声明，涵盖字体、导航、圆角、阴影、滑条、玻璃及纯色封面；完整属性见 generated/polish_rule_mapping.md |
| 交互 | App.tsx 不改基础 HTML JavaScript；原有模拟能力没有因换图标就变成真实能力 |
| 响应式 | App.tsx 没新增 @media；后置普通选择器会覆盖部分媒体规则。ID选择器保留专属全屏样式，详见合成文档 |

## 必须明确处置的来源冲突

1. **视觉简表 vs CSS specificity**：普通3/14滑条不代表全屏也3/14；Phase 2按主指令验收尺寸实现并记录偏差，不篡改参考文件。
2. **手机胶囊 vs 全局polish**：网页底部Sidebar变24、nav变14并保留竖条，主文档要求32胶囊/底部适配。Flutter遵循后者。
3. **平台 vs 宽度**：HTML只看宽度，1024宽平板出现240 Sidebar；正式Android始终按Android Shell，不出现Windows标题栏。Windows窄宽也不切手机。
4. **手机横屏844×390**：§6严格按当前width，844属于TabletLandscape；“Phone横屏”是测试设备/尺寸描述，不允许按设备型号强行Phone。共享低高度紧凑player布局保留横屏体验，见ADR-002。
5. **浏览器状态 vs 正式状态**：开关有持久化不表示效果已实现，来源connected/playing也不表示网络/音频成功。
6. **减少玻璃/动态**：网页glassToggle只取消.glass的blur，不处理lyrics/menu，也不提高fill；motionToggle没有禁止updatePlayUI的scale.94。正式版按平台统一降级。
7. **本地歌词**：resolveLyrics对所有local直接返回空，即使字典含Slow Lines/Signal Bloom也不会显示。Flutter须解析本地LRC/内嵌歌词，不能复制此限制。
8. **账户投影**：文档概述“双Ring+轻阴影”，实际polish box-shadow仅双Ring；额外投影是待视觉校准的设计决定。

## 原型功能缺口（不在 Phase 0 偷改）

- 来源表单没有保存认证/Endpoint/Headers/映射；测试是700/850ms延迟和navigator.onLine；保存/重新启用直接connected。
- 搜索只筛内存catalog、按专辑/艺人去重后仍显示Track行；没有真实请求、防抖、取消、分页、独立来源错误。
- 歌单能创建/删除/添加，但没有重命名、移除单曲、排序、随机播放全部等完整操作。
- 队列能上下移动/移除/清空，没有拖拽与完整键盘排序；列表循环错误地回填catalog前六首，previous历史也可能来回循环。
- 本地扫描无取消/增量/持久授权/真实标签；每文件串行探测时长，超时3500ms，失败用228秒替代；拖放仅读取files，不递归目录。
- 本地对象URL被排除出队列/历史/歌单持久化，favorites却可能留下无效ID；清除会话未同步清理所有引用及currentTrack。
- playTrack在audio.play成功前写历史并提示正在播放；无统一buffering/error状态机，无在线流解析。
- 歌词自动滚动没有手动滚动暂停跟随；无实际LRC解析、偏移或逐字数据。
- Overlay的关闭顺序依据对象反向顺序，不是真实路由栈；缺少焦点陷阱、焦点返回、未保存确认。
- 睡眠定时不跨启动恢复、不平滑暂停；输出设备仅文案切换。gapless/normalize/keepQueue仅保存布尔值。
- Window控件无真实OS处理；Alt+Left缺失；多个图标按钮缺label或触控目标不足44。

旧 Flutter 不一致项另见 [existing_flutter_audit.md](existing_flutter_audit.md)。Phase 0的通过不等于旧原型符合YYMusic的静态约束或测试已通过。
