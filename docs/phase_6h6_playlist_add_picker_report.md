# Phase 6H6 — 添加到已有歌单报告

2026-09-08，仓库 `Z-YO-YI/YYMusic`，分支 `codex/playlist-add-picker`。
从 fetch/pull 后的 `4847f29b66d1b3d82f32e71aa43309cc3f6dfac4` 创建独立分支；
先校验五份指纹、ZIP24项并记录计划/ADR-062，再实现本批。没有跳过Phase0审计或一次生成整个项目。

## 现在距离安装使用还有多少

现有Android Debug可编译，Windows有GitHub开发Debug包，但不能据此称为日常可用版。
默认新安装为空库，本地音乐导入与真实扫描尚未实现；Windows开发Debug另依赖Debug CRT。
按主指令仍有四组本地可用版工作：Phase6主要页面收尾；Phase7完整播放器/歌词/队列；
Phase8双平台导入、扫描和授权；Phase10—11系统媒体/后台、Release打包和设备验收。
完整产品还要完成Phase9第三方音乐源。阶段工作量并不相等，不能用编号或测试数计算完成百分比。

## 交付及边界

- 音乐库与专辑/艺人详情的曲目菜单新增“添加到歌单”，打开覆盖整个Shell的原生根模态路由。
  路由只在内存传递完整TrackRef与标题，不把本地路径、媒体URI或Track对象写入URL/extra/新存储。
  Phone使用YYBottomSheet，Tablet/Windows使用YYDialog；表面、文本框、按钮、颜色/圆角和歌单SVG
  复用已有YY设计系统及App.tsx最终NEW_ICON_SPRITE/POLISH_CSS，不新增图标体系或WebView。
  figma-design-to-code采用离线资产/组件复用流程；ZIP没有fileKey/nodeId，不虚构在线Figma读取。
- 新增显式只读元数据合同：一条参数绑定SQL筛选自定义歌单，名称字面子串匹配，
  ASCII大小写折叠、更新时间降序和SQLite BINARY稳定ID次序；limit+1判断更多且不解析哨兵行。
  不订阅整份歌单投影，不展开歌曲或条目。Fake遵守相同筛选/顺序/分页合同。
- 根注册的惰性会话先订阅已有失效通知再读取，20→200一致前缀；200个匹配未读完时明确要求缩小范围。
  原生输入法组合期间不查询，点击筛选/提交后才读取；草稿不同于已应用查询时旧选项不可添加。
  Loading/Empty/Error/重试/成功明确；空库提示先去音乐库创建，本批不做选择器内“创建并添加”。
- 选择稳定歌单ID后调用唯一根PlaylistController的原子追加命令，只保存完整歌曲引用。
  同名歌单独立，重复曲目成为独立entry，文件失效引用可保留；不复制媒体、不下载、不另建播放器。
  当前快照、活动路由、草稿、根busy和请求代次共同阻止旧回调或连续点击误写。
- 弹层会话不随Phone/Tablet断点替换，旋转/零尺寸/键盘保留输入和滚动。
  Tab闭环、Space不泄漏到背景播放器、Back/Esc先关闭，恢复原曲目行焦点时重新检查活动路由。
  弹层打开撤销调用页尚在加载的播放意图，但不会停止已经播放的音乐。
  覆盖弹层时暂停其动作；旧关闭回调和同一帧重复关闭不能误关后来打开的面板或下层页面。
- 已接受写入在通知前登记，关闭仍排空；离页失败保留根级脱敏提示，不自动重试不确定写入。
  根关闭等待实际SQLite查询、订阅取消和已接受写入，再释放共享数据库；不把取消订阅当成SQL已结束。

## 验证

- **718/718 Flutter**：新增38项，包括7查询/SQLite/Fake合同、13根会话、14三端Widget、
  1真实SQLite全根界面和3Golden。真实SQLite重复添加两次得到两个独立条目，原歌曲路径未改变。
  覆盖同名/失效/重复引用、旧成功/失败/回调、监听错误/结束/重建、根busy与重入关闭、实际查询排空，
  235个歌单的20→200分页/末项筛选、覆盖路由、迟到播放取消、已有播放不受弹层开关影响等。
- **81张Golden**：新增Phone、Tablet深色、Windows三张，逐张查看；旧12张逐张核对更新，
  其中4张新增歌曲菜单入口，另8张只更新背景或底部真实能力说明；其他66张旧图字节未改。
  均使用130%文字，无新增溢出或比较阈值放宽，不把本机Golden当作HTML浏览器对照。
- **92/92 Node**；严格analyze零问题，319个Dart文件格式零修改。
  build_runner、make-migrations重跑后生成代码、Schema、迁移测试和lockfile无差异。
  五份源指纹、ZIP24项逐字节、六个音频包许可及原生许可材料验证通过。
- Android Debug本地预检成功（Gradle22.1秒）；48份SVG/字体/许可资产与源文件逐字节一致，
  六包完整NOTICES.Z和原生声明通过，v2单Debug签名有效。
  APK为231,892,094字节，SHA256
  `fae8d3dda30f88b3d371b3eabadedb6467644c633fe9db6c69d65f8059c8e4d3`。
  `build/app/outputs/flutter-apk/app-debug.apk`不入Git，且只作为本地预检，不替代要求的GitHub构建。
  JDK原生访问警告保留，未关闭校验或修改全局工具链。

复查过程：首轮完整回归的12个旧Golden失败来自上述预期变化，核对后只更新对应图；
新增旧关闭回调回归先复现误关新面板，补活动/closing/销毁保护后通过。
取消加载测试最初误认为不应调用stop；按已有核心合同改为断言释放未播放的pending load，
并额外先开始真实控制器播放、再开关弹层，验证既有音乐没有新stop/pause调用。不是删除行为检查掩盖失败。

主要命令：Dart format、Flutter analyze --fatal-infos、完整Flutter test、Node tools测试、
build_runner、drift_dev make-migrations、指纹/ZIP/许可脚本、Flutter build apk --debug、APK资产校验与apksigner。

## GitHub交付及下一步

前置H5精确提交 `4847f29b66d1b3d82f32e71aa43309cc3f6dfac4` 的
[push34208980405](https://github.com/Z-YO-YI/YYMusic/actions/runs/34208980405) 和
[PR34208990757](https://github.com/Z-YO-YI/YYMusic/actions/runs/34208990757) 标准三job均成功，
Draft PR #50保持OPEN；本批回填其报告并明确Windows artifact与Debug CRT限制。

本批审查后提交并推送stacked Draft PR，base=`codex/playlist-content-surfaces`；
对应PR记录本批精确提交和两组云端checks/Android Debug/Windows native结果，
不以前置或本地成功冒充本批云端通过。普通push上传14天Windows开发Debug审查包，
普通Android job仅构建验证、不上传APK；未手动dispatch、创建Release、合并或覆盖历史。
没有将凭据、用户数据、日志或构建产物提交到仓库。

### 后续回填：H6精确提交云端结果

`b2845a3b23852deb01f41538f4d79cc18a7a2076` 的
[push34215507725](https://github.com/Z-YO-YI/YYMusic/actions/runs/34215507725) 与
[PR34215576065](https://github.com/Z-YO-YI/YYMusic/actions/runs/34215576065) 均整体success，
源码checks、Android Debug和Windows native各三job成功；[Draft PR #51](https://github.com/Z-YO-YI/YYMusic/pull/51)
保持OPEN、未合并。Linux637项通过并明确跳过81张Windows宿主Golden；Windows各自81张及真实窗口首帧/关闭1项通过。
双端包内资产、许可及Android v2单签名通过；两类专用音频、Profile诊断和Release按设计skipped。

push的Windows开发Debug artifact `10052026961`，67,326,377字节，到期 `2026-09-22T10:39:34Z`，
API digest `sha256:6c82dc57c1dc9b78fe46e22065f3f2d45b417aadcb51fef800b38e1f30abaaf4`；
本批没有下载，不将API摘要当成本地复算。PR artifact为0；普通Android job未上传APK，没有新Release。
Windows bundle65份文件已由CI验证，但依赖Debug CRT，不是通用发行安装程序。

H6结束时下一批仍在Phase6：创建并添加的原子组合、播放全部/随机、系统歌单、大歌单完整浏览，
随后Local Music/Settings页面；再按主指令进入后续阶段。
无新增真实设备音频、网页截图对照、导入/REST、Schema、依赖或平台发行接线。
既有网页安全限制不绕过；本机Windows C++/Debug CRT限制未解决，本批不是上线完成。
