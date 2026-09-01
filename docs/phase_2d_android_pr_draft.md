# PR 草稿：Android native content cards

Head：`feat/android-content-cards`；Base：`fix/reference-audit-hidden-files@b0abd9d`。不自动合并、不改写历史；云端运行与PR状态以推送后的实际结果为准。

## 变更

- 新增原生受控`YYAlbumCard`与`YYTrackTile`，复用既有Theme、Typography、Artwork和SVG图标；覆盖默认、Hover、Pressed、Focus、禁用、选中/播放及加载状态。
- Track主动作与更多按钮使用独立语义/焦点/命中边界；Phone隐藏时长并省略长来源，Tablet/桌面保留时长。
- Gallery新增明确标注的内容Fixture，只更新本页状态，不接入播放、菜单、数据库、网络、文件或持久化。
- 更新内部动作语义合同、Token、ADR、架构、视觉差异、验证矩阵和阶段文档；没有WebView、Material默认视觉、新依赖或权限。

## 测试

- 58个Dart文件格式检查：0改动；严格分析：0问题。
- 82项Flutter测试通过，包含14张Windows宿主精确Golden；新3张逐张视觉检查，旧11张未改。
- 28项Node测试通过；24个ZIP entry逐字节一致，五份源指纹、44 SVG、52份派生产物及13个归档文件保持完整。

## 影响与未验收项

影响范围限于设计系统、Android Gallery Fixture、测试与文档；现有路由、根Controller、Android/Windows Shell和CI合同不变。组件是受控外观，不实现音乐业务。

网页截图对照、Android真机/TalkBack、性能、正式菜单/MiniPlayer、数据库及真实音频仍未验收。APK不得本机构建后上传；目标commit须由GitHub Actions手动运行生成草稿Release，并复核metadata、SHA256SUMS与Debug签名。Debug签名不是正式发布密钥。
