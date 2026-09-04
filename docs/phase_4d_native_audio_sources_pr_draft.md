# PR 草稿：Android Content URI 与受控 HTTPS 音频 POC

Head：`feat/native-audio-content-network-poc`；Base：
`feat/native-audio-local-poc@faf13f466e2a26b6aeacbb31a2f4edeebbe22da6`。创建为Draft，不自动合并、
不改写历史。

## 变更

- 新增只读HEAD网络探针，将401/403/404/408/410/429/3xx/5xx与offline/timeout/TLS/unknown映射为
  脱敏DomainFailure；不跟随重定向、不保存响应。
- 新增Android debug-only、不可导出、只读的应用内ContentProvider，只暴露cache目录中的固定运行时
  WAV；main/profile不注册、不新增存储或媒体权限。
- 新增双平台受控loopback HTTPS服务器与原生集成测试；证书/私钥只在CI忽略目录运行时生成，原始
  文件立即删除，不提交、不上传。
- 新增仅供测试的candidate创建入口；默认生产路径继续验证TLS并使用真实音频设备，生产Bootstrap仍为
  `UnavailableAudioEngine`。
- 新增默认关闭、手动显式选择、`contents: read`的Phase4D双平台job；不上传artifact、不创建Release。

## 本地测试

- 153文件format 0变化，严格analyze 0问题，完整225项Flutter含32张Windows宿主Golden通过。
- 31项Node、24项ZIP通过；4项新增网络探针单元测试通过。
- Android Debug成功：279,083,994字节、SHA-256
  `a77f94094676bf6a5ee10dd18c526e707ef59fa11c686e10c048fa2d4b3ab405`，48资产和v2单Debug签名通过。
- Debug合并Manifest确认POC Provider不可导出/不可授权；生产source set未注册。
- 实现提交`913f3d75e06a144c25c56175b5c9428d1090f44f`的标准PR运行33878401743整体成功：
  checks、Windows Debug、Android Debug均成功；同提交push运行因并发替代而cancelled。
- 专用运行33878710671整体成功：Windows HTTPS为load 77 ms/首进度244 ms/seek 2 ms；Android
  HTTPS为110/143/3 ms，`content://`为56/151/2 ms；全部completed，失败矩阵通过，两端日志均为
  `All tests passed!`。运行artifact为0，匹配Release为0。

## 影响与限制

本批不改变正式应用行为，不访问用户文件或真实在线源，不实现下载/离线保存。受控自签名TLS绕过只在
专用集成测试入口启用；如该入口出现在生产组合即否决。无头/模拟器结果不证明实体设备、真实API、
MediaStore/SAF持久授权、后台/焦点、系统媒体会话或可发布许可证。
