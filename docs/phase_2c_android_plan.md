# Phase 2C — Android 表单与选择控件

基线2f35cf5；本批分支feat/android-ci-and-form-controls，先单独交付GitHub APK工作流，再实现本阶段。已fetch/pull、核验5份指纹与完整24entry；本地不构建新APK，云端状态必须另行验证。

范围限定YYToggle、YYSegmentedControl、YYSearchField和Gallery接入：沿用原始SVG/字体/Token，读取App.tsx完整相关POLISH_CSS及基础HTML669–756/1084/1153规则。Search15/460、常规58高/20圆角、Phone52/18；Segment外14/内11，触控从34提高到44；Toggle46×28、22thumb、18行程、160/180ms。

所有状态由调用者持有，支持键盘、语义、RTL、Disabled/Loading及减少动态；搜索仅本页文本示例，不实现网络/数据库/假搜索结果。文字编辑保留IME组合区、选择和清空，剪贴板仅通过用户编辑动作访问。Gallery的减少动态/透明改用真实Toggle，原根状态与返回测试不删。

新增Widget和真实字体Golden，既有60项Flutter与23项Node测试全部保留。修复组件而非放宽截图容差，未改变的8张基线不更新。此批不等于整个Phase2完成，也不跳到Phase3/4；PR与云端APK验收仍受连接器仓库授权影响。
