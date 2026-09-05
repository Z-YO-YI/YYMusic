# Phase 4P — 真实音频根接线报告

2026-09-05，分支 `codex/production-audio-bootstrap`，基于已 pull 的 `60a79c7`。
前置 Phase4O 精确实现的 push/PR 两组云端三 job 均 success；其报告已补齐证据。

## 本批实现

ADR-044 根据 Phase4L 原生运行、Phase4M/N 完整许可/实际打包核验、Phase4O 查看入口，选择
just_audio 0.10.6 + just_audio_windows 0.2.3 为当前工程后端。六包清单更新工程接线和原生材料
审核状态并链接证据；其覆盖范围未扩大，两个 manifest 的全应用 releaseApproved 仍为 false。
没有新增依赖、权限、网络探针、Fixture 媒体、下载、代理或 Header 能力。

默认 Bootstrap 获取数据后通过可注入工厂创建一个引擎，并移交根 DependencyGraph；
三个 Shell 和断点共享原控制器，恢复队列不自动播放，主页面明确说明业务播放控件尚未实现。
main_dev 显式保留不可用后端。构造/初始化失败或异步完成时 Widget 已销毁，都清理已取得资源；
某一释放操作异常不阻止下一项清理，界面仅固定“无法初始化应用”，不暴露插件/路径详情。

本地解析器只转换 Repository 的 Track：Android content URI 优先，否则 POSIX 绝对路径；
Windows 驱动器绝对路径/有效 UNC 文件。拒绝跨平台、相对、设备命名空间和无效引用；
缺少 REST Adapter 明确失败，不采纳 metadata 中的 URL，不读文件或获取权限。
文件是否存在、授权是否有效仍由平台打开结果/后续本地 Gateway 判断，不伪造可播放状态。

新增 Controller.close/Graph.close：同步拒绝后续命令与状态，等待订阅、已有播放命令和媒体同步，
再释放引擎、媒体接口和数据；幂等共享 Future。同步 dispose 安全启动同一关闭。
关闭失败调用方得到固定 `app.shutdown-failed`，仍确保其余资源尝试释放。

## 本地验证

- 严格 analyze 0 问题；完整 Flutter 282/282，含旧 35 张 Golden，基线均未修改。
- 新增 4 本地解析、3 关闭生命周期、5 根启动 Widget 用例；支持初始化/清理异常、晚到、
  跨断点单实例、无自动播放、延迟 load 退出无晚播放、媒体更新期间退出和二次关闭。
- Node 57/57；工程选型新门禁同时核验完整原生材料、证据文件、根创建/清理、固定关闭代理与
  Header、Fixture 隔离与 REST 失败关闭。旧脱敏提示断言随“本地数据”→“应用”精确更新。
- 旧 Widget 用例最初因仍期望即时释放而失败，已保留次数断言并等待 close；SDK stream cancel
  可能含真实 zone 的缓存 Future，测试有界推进真实回调与虚拟微任务，不靠丢弃关闭 Future 通过。

- 最终 format：173 文件零差异；build_runner 72 项内部缓存输出，跟踪数据库生成代码/Schema
  与 lockfile 零 Git 差异；Drift make-migrations、原 ZIP 24/24、六包源码许可指纹均通过。
- Android 默认入口 Debug 构建成功（17.7 秒）；48 设计资产、六包 NOTICES.Z、原生许可材料通过；
  APK 231,521,505 字节，SHA256 `15967286a80abef8dd930e505325e08a0fdb4cec963676bd226986fea01693c4`，
  v2 签名有效，1 个 Debug 签名者。Java 原生访问警告保留，未改全局参数压制。

精确提交 `4a5b32de46b6630b096abb600bb31b6e05c2605d` 的 push
[33960148896](https://github.com/Z-YO-YI/YYMusic/actions/runs/33960148896) 和 PR
[33960169694](https://github.com/Z-YO-YI/YYMusic/actions/runs/33960169694) 均 completed/success：
checks、Android Debug、Windows Debug 全部通过。六个实际 job 日志已复核，源码六包、Android
51 坐标/三份完整文本/48 资产、Windows 65 文件及双平台包内完整许可均 PASS。
原生 POC 两 job 按设计 skipped，不计为新设备运行。Draft PR #32 未合并，没有新 Release。
本批未重跑原生播放 POC，不以 Fake/Golden 替代设备证据；尚未创建发行包或宣布 Phase5—11 完成。
下一步核对 Phase4 出口与同入口运行，然后接三套 Shell 的真实播放器表面，继续业务页面、
导入/REST、媒体平台能力和最终 QA/发布。Phase2 网页参考对照仍待补齐。
