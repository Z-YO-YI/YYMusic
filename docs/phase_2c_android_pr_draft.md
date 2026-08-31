# PR 草稿：GitHub APK delivery and Android form controls

Head：feat/android-ci-and-form-controls；增量基线：feat/android-navigation-controls@2f35cf5。CI阶段7458a28已独立推送；UI阶段在同分支继续。PR尚未创建，连接器仓库404、授权账户为空；待有权限后选择正确base，不自动合并或改写历史。

## 变更

- GitHub runner编译APK，验签/核验原始资产后上传三文件白名单，提供commit/run/校验和与下载摘要；不是本机上传旧包。固定Action SHA、14天保留、无秘密/仓库写权限。
- 原生YYSearchField、YYToggle、YYSegmentedControl，共用动作/语义层；IME/选择菜单/清空、键盘、RTL、禁用加载与低对比适配。
- Gallery真实外观开关和仅本地文本示例；保留全部原有导航/播放边界/资产/Golden，无WebView、Material默认外观、网络或假曲库。

## 测试

74项Flutter（含11张精确Golden）和23项Node通过；53文件format/strict analyze通过；5指纹/52产物、ZIP24entry保持一致。原8张Golden未修改，新增三张经逐张视觉检查。详细结果见[Phase2C报告](phase_2c_android_report.md)。

## 风险与未验收项

本轮未在本机重建APK；云端run/artifact不可读，**不能标记GitHub构建成功**。获得授权后检查当前commit的checks/android-debug及artifact，再单独核验Windows job。临时Debug签名可能跨runner变化，不能当稳定升级/Release签名。

真机IME/TalkBack/性能与网页视觉对照未验收，输入组件不是完整搜索业务。数据库/音频/正式业务页未接入。没有新增依赖或媒体权限，不提交APK、机器配置、用户文本、剪贴板内容或密钥。
