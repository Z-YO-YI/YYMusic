# PR 草稿：media_kit 音频候选适配与原生打包验证

Head：`feat/media-kit-audio-poc`；Base：
`feat/playback-core-contracts@3e52f94`。创建为Draft，不自动合并、不改写历史。

## 变更

- 精确加入`media_kit 1.2.6`与`media_kit_libs_audio 1.0.7`，只解析audio native库。
- 新增项目自有MediaKitPlayerBackend与MediaKitAudioEngine；插件类型只存在于单一playback
  backend文件，生产Bootstrap继续使用UnavailableAudioEngine。
- 映射Windows绝对文件URI、Android content URI与HTTPS/Header瞬时来源，open不自动播放。
- 把插件快照映射为既有八阶段Engine状态，串行处理transport、Seek、音量、速率与幂等释放。
- 底层命令/异步错误只转为固定DomainFailure，不泄露URL、Header或插件原始信息。
- 更新架构、依赖审计、音频POC计划、状态、验证矩阵、README和CHANGELOG。

## 测试

- 5项Phase4B Fake backend测试通过；完整219项Flutter含32张Windows宿主Golden通过。
- format、严格analyze 0问题、30项Node、24项ZIP通过。
- lockfile严格复现；build_runner/Drift make-migrations后g.dart/v1快照零差异。
- 本机Android Debug成功；279,083,792字节APK的48资产、Manifest、权限、三种目标ABI
  audio-only原生库和v2单Debug签名通过，诊断SHA-256为
  `f3026e694c597b83297405c6587d46dc2906aa422b471838796950f776c59dd8`。
- 实现提交`b7e0b0f`的push运行33853006353与PR运行33853041607均为三job success，分别完成
  checks、Android Debug和Windows Debug；该SHA没有workflow_dispatch或新Release。

## 影响与未验收项

正式入口和可见UI没有播放能力变化。Fake测试与Debug构建只证明适配合同、编译和打包，不证明
Windows/Android真实解码、扬声器输出、Seek时延、buffering、音频焦点、后台、系统媒体会话、
性能或设备运行。Android JAR未附带native LICENSE/NOTICE，Windows依赖固定旧libmpv归档；
传递许可证未闭合前候选不进入生产组合，本PR不触发手动APK Release。
