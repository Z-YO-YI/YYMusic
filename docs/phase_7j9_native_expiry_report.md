# Phase 7J9：原生操作等待期限保护

## 基线

Z-YO-YI/YYMusic，基线c169efc，fetch/ff-only拉取确认后创建codex/native-source-expiry。上轮恢复位置与历史已验证同步，本轮继续将有效期保护延伸至真实just_audio边界；不将前端或单元级检查作为原生成功证据。

## 实现

- JustAudioPlayerBackend.open携带可选expiresAt；生产原生后端使用可注入时钟，只保留期限列表及失效标记，不增加持久化地址或headers。
- 替换前预检不破坏旧媒体；旧播放器pause/dispose之后、新native load之前再复核。统一操作包装在检查与原生调用之间不插入await，原生Future完成后再次检查，同时禁止关闭后误报成功。
- 单曲和序列加载、追加、play及seek使用该边界。等待期间到期则标记源失效、请求stop并抛出固定无地址JustAudioSourceExpired；stop失败不覆盖过期错误。时钟回退不能解锁已判失效源，新成功load可以恢复。
- 序列期限列表在追加时扩展、截尾时裁切。任一明确期限失效则该批无效；根目前不会预载带期限未来项，因此这不构成对未来网络项自动刷新支持。
- 引擎将typed expiry映射为已有streamUrlExpired，而非丢失原因的一般open/interrupted失败。既有根错误反馈/推进策略继续适用，不增加无限重试或自动播放。

## 验证

10项新增测试使用实际锁定just_audio实现及模拟平台通道，延迟旧释放、load、append、seek响应以跨过期限；验证预检保留旧媒体、关闭可播放性、时钟回退仍失效、重新加载恢复和引擎安全错误映射。专项37项通过。

最终2501 Flutter测试通过（121秒）、161 Node门禁通过（29.72秒），严格分析0问题（14.6秒）；初轮构造器初始化形式Lint已修复。608 Dart格式零修改，226 Golden未改变。Android Debug构建成功（32.7秒），48资产逐字节一致，六项音频许可及完整原生声明通过；现有Java native-access警告不变。

ZIP、主指令、App.tsx、基础HTML四个SHA256符合原审计基线；24解压文件逐字节匹配ZIP。NEW_ICON_SPRITE、POLISH_CSS、UI、依赖、数据库schema及云构建工作流未变。

## 剩余和交付

此边界不能撤回原生内部已经发出的网络请求，操作调用前/完成后的时效检查也不能证明服务端接受。持续播放定时撤销、无期限服务端失效、未来网络项刷新、循环窗口、已播前缀修剪、网络Adapter以及双平台声学/生命周期验收仍缺。生产无缝开关未开放，Phase8–11和全部上线出口不缩减。

本轮确认J6运行34763488905已success；J7运行34763991767和J8运行34764489869检查时仍in_progress。当前提交另行触发GitHub双平台构建，以codex/expired-source-resume为base建立Draft PR，不合并/发行。未绕过本地Windows Developer Mode/symlink限制，未启用可选音频探针，不提交构建产物或凭据。
