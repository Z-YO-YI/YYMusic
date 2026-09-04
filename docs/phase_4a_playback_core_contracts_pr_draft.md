# PR 草稿：播放核心合同与唯一状态源

Head：`feat/playback-core-contracts`；Base：
`feat/dev-fixture-bootstrap@e5072a0`。创建为Draft，不自动合并、不改写历史。

## 变更

- 新增Windows绝对路径、Android content URI和HTTPS临时流的脱敏PlayableSource及Resolver合同。
- AudioEngine改为插件无关的八阶段状态流，并补齐load/play/pause/stop/seek/volume/rate。
- PlaybackState覆盖主指令全部字段，PlaybackController成为曲目、进度、队列、随机/循环和
  错误的唯一真相；命令串行，completed驱动自动下一首。
- QueueController仅作为同一状态的命令门面；队列支持重复曲目、持久恢复、替换/添加/
  下一首插入/移动/删除/清空和指定项播放。
- 新增Android MediaSession/Windows SMTC共用Gateway与回调合同；根Graph统一初始化/释放。
- 不新增音频插件、权限、Schema、可播放Fixture、下载/离线API、正式UI或Shell专属逻辑。

## 测试

- 7项Phase4A新测试通过；完整214项Flutter含32张Windows宿主Golden通过。
- 143个Dart文件format、严格analyze 0问题、30项Node、24项ZIP通过。
- lockfile严格复现；build_runner/Drift make-migrations后g.dart/v1快照零差异。
- 本机Android默认生产入口Debug成功；238,997,827字节APK的48资产、Manifest和v2单Debug
  签名通过，诊断SHA-256为
  `ea40ebd646300b0f14c1dcef9aef2971d19fba6da515e83b6f88c8e05bd66ab1`。
- 实现提交`ec508df`的push运行33845988715、PR运行33846020650与唯一手动运行
  33848236710均为三个job success；Draft PR #17的base/head身份已复核。
- 手动运行的私有draft/prerelease只含三项白名单资产；APK为190,735,487字节，SHA-256、
  SHA256SUMS、metadata与API digest均为
  `3f95cea301d6710ac46a40a5fbfcd0d4561d91f310ca5d04506d5389a1272aa4`。48资产、Manifest和
  v2单Debug签名通过，临时下载目录已清理。

## 影响与未验收项

生产启动会恢复持久队列，但不会自动解析、加载或播放。默认AudioEngine和MediaSession仍明确
不可用；可见Shell/播放器不改变。真实Windows/Android本地与HTTPS播放、Seek精度、格式、
buffering、音频焦点、后台、通知/SMTC、性能和真机安装运行均未验收，Phase4尚未关闭。
