# PR 草稿：Android navigation, slider and artwork foundations

Head：`feat/android-navigation-controls`；本批增量基线：`feat/android-design-foundation@601137c`。GitHub连接器404，尚未创建PR或核验远程CI；不虚构base分支或PR号。若相对主干合并，须同时审核前序Phase0/1/工具链/2A历史，不自动合并。

## 内容

- Phone胶囊/Tablet Rail驱动原有路由，复用44原始SVG、变量字体、根外观及状态；低对比accent补可读边界。
- 受控原生Slider的预览/提交/取消、键盘/RTL/语义及禁用状态；系统取消不得提交。
- 七种App.tsx最终CSS几何封面占位与Gallery本地示例；不加入虚构歌曲/播放、WebView、网络或数据库。
- 新增14项Widget与5张Golden，扩展资产检查，补充ADR-013及使用/验证文档；Windows骨架及CI保留。

## 验证

- enforce-lockfile、46文件format、strict analyze通过；锁文件/原始SVG/字体/源ZIP均不变。
- Flutter59项含8张精确Golden通过；Node19项、5指纹/52确定性产物、ZIP24entry通过。
- Android Debug APK构建与v2签名通过；48个SVG/字体/许可证文件与源码逐字节一致，未打包参考/旧原型档案。
- 默认珊瑚误加边框曾由Golden拦截，修正组件而非更新正常基线；旧3张Golden未改。完整证据和APK指纹见[报告](phase_2b_android_report.md)。

## 影响与注意

业务页/真实音频/数据/后台/系统媒体尚未实现；滑块演示不是音频Seek。没有新增依赖、权限、系统安装或全局环境修改。字体与SVG字节保留，APK/失败差分/机器配置不入Git。

Windows本机构建等待工具链；网页视觉对照、Android真机/IME/TalkBack/Profile仍待验收。远程CI必须获得读取权限后单独确认，不把本地通过当作CI通过。Review后按正确base创建PR；不修改历史或force push。
