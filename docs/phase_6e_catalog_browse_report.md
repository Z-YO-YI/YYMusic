# Phase 6E — 音乐库浏览数据与详情合同

## 交付范围

仓库 `Z-YO-YI/YYMusic`，独立分支 `codex/catalog-browse-data`，
基于 fetch / pull 后的 `40fb7a6`。按主指令 17.3 / Phase 6 分批实现音乐库，
本批只完成原生页面所需的数据基础，不代表完整音乐库或 Phase 6 已完成。

- 新增 AlbumRef / ArtistRef、不可变 CatalogFilter、三类排序查询及 CatalogBrowseRepository。
  保留 sourceId 与实体 ID；非法输入的异常和引用日志不回显原值。
- 曲目五种、专辑四种、艺人三种排序均支持升降序；NULL 始终最后，完整身份后备顺序升序。
  按艺人排序采用首位 credit.position；SQLite lower 仅折叠 ASCII，不是拼音或区域化排序。
- 来源类型、来源 ID、多个可用性状态可组合；空状态集合表示不限制。筛选不要求来源配置仍存在，
  不隐藏保留的失效引用。专辑/艺人通过存在匹配曲目入选，组合条件必须由同一曲目满足。
  返回曲目/专辑计数沿用完整实体的目录聚合值，不能显示为筛选后数量。
- 支持获取单个专辑/艺人、按专辑/艺人分页曲目、按艺人分页专辑；身份不跨来源串联。
- 私有 part 在同一个 DriftLibraryRepository 中实现，不复制存储/生命周期。
  一次只读 CTE 先取 limit+1 个实体再展开完整艺人，避免 N+1、多艺人截断或多语句快照混合。
  所有用户值绑定，排序 SQL 只来自枚举；不开始写事务，也不写历史、扫描文件或联网。
- 根 AppDataServices / DependencyGraph 导出同一 Library 的浏览合同，仍只有一个数据库。
  复用合作式取消：查询前和等待/映射边界丢弃取消结果，不声称中断 SQLite 原生语句。
  缺失返回 null，损坏返回脱敏 DomainFailure；初始化/释放边界沿用既有规则。

## 设计与验证

ZIP、主指令、完整 App.tsx、基础 HTML 四份指纹均与 Phase 0 相同；24 项解压内容逐字节一致。
延续 App.tsx 的 NEW_ICON_SPRITE / POLISH_CSS，不只使用旧 HTML。本批不改页面或 55 张 Golden，
Phase 2 网页对照缺口仍独立记录，未绕过此前浏览器安全限制。

- 423/423 Flutter 测试通过，含全部既有 55 张 Golden；新增 16 项数据/合同测试。
  覆盖 12 种排序的两个方向、NULL/同名稳定顺序、多艺人、完整来源身份、组合条件同曲目匹配、
  字面 SQL 标点参数、缺失/损坏/取消/生命周期、450 实体分页和根作用域共享/关闭一次。
  真实临时文件的两个独立 SQLite 连接验证并发写后单页仍完整保留旧版本，下一请求能读新版本。
  测试多连接的 Drift 调试告警保留，没有修改生产连接方式或屏蔽告警。
- 71/71 Node 门禁通过；新增两项浏览架构检查。原 Repository 接口断言只兼容格式化换行，
  未移除接口约束。首次测试发现 isNull 导入歧义已修正，未放宽领域校验或业务断言。
- 严格 analyze 0 问题；236 文件格式零修改；build_runner / make-migrations 重生成后，
  Drift Schema、生成代码、迁移助手与锁文件均无差异。
- ZIP 24 项、六包 LICENSE / 两个原生构建来源及原生完整许可源码校验通过。
- 本地 Android 默认入口 Debug 构建成功（Gradle 16.3 秒），231,697,019 字节；
  SHA-256 `831c1760ed43de1bb2483bd76d5df13743bae129b9abba1d1c4bd90804322633`。
  APK 48 设计资产、六包 NOTICES.Z、原生完整许可匹配；v2 签名有效，一个签名者。
  Java 原生访问警告保留。包仅供本机诊断，用户 APK 仍在 GitHub 构建。

## GitHub 与剩余边界

前置 Phase 6D `40fb7a6` 的两组 GitHub checks / Android / Windows / Golden / 原生窗口均成功，
已在 Phase 6D 报告与 Draft PR #39 回填精确日志，不算作本批构建成功。
本批提交推送后以 `codex/native-search-surfaces` 为 base 创建 stacked Draft PR；
精确提交的 checks / Android / Windows 状态在该 PR 补记。没有自动合并或公开发布 Release。
APK、临时数据库、运行日志、用户私密数据与密钥不提交 Git。

音乐库 Controller / 三套原生布局、右键/长按菜单、导入/文件恢复与后续业务页尚未实现。
分页保证每页内部一致，不承诺跨多次请求的持续快照；排序/过滤可能在 SQLite 内扫描/排序目录，
450 条合成测试不替代大曲库实机性能验收。无新增依赖、Schema、平台权限、WebView、音乐下载或生产 Fixture。
本轮没有新原生音频验收；Windows 本机 C++ / Debug CRT 限制仍存在，云端构建单独核验。
下一增量接入原生音乐库入口与控制器，继续使用根播放器与真实空态；实时 REST、完整播放器、
平台能力和 Phase 11 上线仍待后续，不宣称当前应用完整可用。
