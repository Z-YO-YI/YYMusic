# PR 草稿：Cross-platform player surfaces

Head：`feat/cross-platform-player-surfaces`；Base：`feat/windows-navigation-foundation@99b664a`；[Draft PR #4](https://github.com/Z-YO-YI/YYMusic/pull/4)。不自动合并、不改写历史。

## 变更

- 新增受控原生`YYMiniPlayer`、`YYDesktopPlayerBar`和只读UI数据模型；实现64/88/76高度、54/50/48封面、34/42视觉控制与44dp命中。
- 复用最终SVG、Slider、Artwork、Theme和Glass；进度保持预览/提交/取消边界，所有工具动作独立。
- Android/Windows Gallery新增本地Fixture与正常/紧凑/Loading状态；正式Shell不接假播放，不引入新依赖、权限或用户数据访问。
- 新增4项Widget、3张130%播放器组件Golden，以及架构、视觉、矩阵和阶段文档。

## 测试

- 69个Dart文件格式无变更，严格分析0问题；95项Flutter全部通过，包含20张Windows宿主精确Golden，新增3张逐图审计且旧17张不更新。
- 28项Node、设计指纹/派生产物与24个ZIP entry逐字节核验通过。
- 实现提交`a1eacd9`的push运行33462315349与PR运行33462439635各自三个job全部成功；手动运行33462929516的checks、Windows、Android/验签/资产核验均成功。
- 私有草稿Release三资产已下载复核；APK为175792949字节，SHA-256/API digest为`df0b96062e96332206630ded3cc35117f244d31c079f2ec76c3f3b3d06a3254a`，metadata身份一致且v2签名有效。

## 影响与未验收项

影响范围限于设计系统播放器表面、跨平台Gallery Fixture、测试与文档；正式路由、Shell播放真相、Controller、Repository和CI合同不变。

本机Windows C++工具链仍受UAC限制。网页截图对照、Windows本机安装/系统无障碍/GPU性能、Android真机、真实音频、队列算法、媒体会话、后台播放和正式播放器接线均未验收。
