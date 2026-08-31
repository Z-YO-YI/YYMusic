# PR 草稿：Android-first Phase 2A design foundation

Head：`feat/android-design-foundation`；本批增量基线：`chore/local-toolchain-setup@261e628`。尚未创建PR（GitHub连接器404），未确定可用PR号或远程CI结论。相对main合并时应同时审核此前Phase0/1及工具链提交；不自动合并/改写历史。

## 变更

- 用户明确要求Android优先，记录ADR-012，Windows原生验收暂缓。
- 原生设计Token/主题/Accent、固定来源字体、44原始SVG、首批控件与Android预览入口。
- 根外观状态和原导航/播放Controller生命周期保留，无WebView/数据库/假播放/运行时字体请求。
- 资产完整性、交互/颜色/布局、3张原生Golden与Windows宿主CI步骤；更新使用/边界文档。

## 测试与构建

- Flutter40项（含3张原生Golden）通过；130%文字覆盖手机/平板和低高度横屏。
- Android Debug构建及v2调试签名通过；APK包含44SVG、2字体与2许可证，未打包参考档案。
- Format/strict analyze/enforce-lockfile通过；Node19项、五指纹/52审计产物、ZIP24entry核验通过。完整结果见phase_2_android_report.md。

## 影响与注意

- 字体原始文件约18.65MB；锁文件增加flutter_svg及必要传递包，不升级现有业务包。
- 外观是会话状态；Gallery不是正式音乐首页，播放/来源/曲库/持久化仍未接入。
- 未完成网页像素对照、真机/IME/TalkBack/性能验收；Windows本地构建未通过验收。
- CI只读，无部署/发布/签名秘密注入；不提交APK、机器配置、用户数据或凭据。

## 需要有仓库访问权后执行

核验本分支远程提交，选择正确base创建PR，并运行/检查checks、windows-debug、android-debug。若Windows-host Golden出现差异先检查引擎/字体/宿主差异，不直接更新基线或加宽容差。
