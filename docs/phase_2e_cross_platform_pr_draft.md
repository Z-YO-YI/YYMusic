# PR 草稿：Windows navigation foundation

Head：`feat/windows-navigation-foundation`；Base：`feat/android-content-cards@f5bbf52`；Draft PR待创建。不自动合并、不改写历史。

## 变更

- 新增原生受控`YYWindowsSidebar`、`YYWindowToolbar`与Widgets-only Tooltip；实现42/240/72/320/88/76审计几何和1440/1024断点。
- Windows Shell使用侧栏驱动现有四条路由；正式Shell隐藏未接Gateway的窗口按钮并明确音乐源尚未接入，不伪造系统或在线状态。
- Windows与Android共享Gallery路由；Windows Chrome Fixture仅更新本页状态。账户文字按App.tsx修正为`YY Listener / 本地账户`。
- 新增父约束玻璃面板但保持旧Android固定玻璃表面几何；更新架构、视觉、矩阵、状态和阶段文档。没有WebView、Material默认视觉、新依赖或权限。

## 测试

- 88项Flutter测试通过，包含17张Windows宿主精确Golden；新3张逐张视觉检查，2张旧组件图仅因账户空格有记录更新，旧Android导航基线未改。
- 严格分析0问题；28项Node测试与24个ZIP entry逐字节核验通过。
- GitHub目标commit的push/PR双平台构建、手动APK与草稿Release复核待推送后补录。

## 影响与未验收项

影响范围限于Windows导航基础、跨平台Gallery、共享玻璃/Profile小修、测试与文档；现有Android路由、根Controller、内容组件及CI合同保留。

本机Windows C++工具链仍受UAC限制。网页截图对照、Windows本机安装/系统无障碍/GPU性能、真实窗口控制、Android真机、正式MiniPlayer/Inspector、数据库及音频仍未验收。
