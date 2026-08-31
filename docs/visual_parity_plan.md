# 视觉还原与 Golden 计划

## Phase 0 当时证据与限制

- 已生成与App.tsx合成顺序一致的静态HTML、44个SVG、完整polish.css及映射。
- 指纹、合成字节一致性、图标路径、CSS覆盖完整性、源JS语法、生成确定性已用Node测试验证。
- Browser技能连接成功，但file: URL被浏览器安全策略阻止；**未截图、未测computed style**。没有改用其他浏览器、localhost代理或底层协议绕过限制；临时viewport已恢复。
- 没有Flutter/Dart可执行命令，未运行Flutter Golden或真机性能检查。生成的参考HTML不是Golden通过证据。

## Phase 2A 新证据与未解决限制

现已使用本机Flutter3.47.2/Windows测试宿主、固定打包Inter/NotoSansSC生成3张原生Golden，逐张查看后非更新模式精确比较通过。基线在test/golden/baselines：浅/深组件390×900、文字130%；全部44SVG的800×590图标集。真实字体Widget另覆盖360×800、390×844、600×900、1280×800、844×390，不代表这些尺寸已完成参考截图比对。

这些是原生组件自身回归基线；没有Figma远端/网页截图，没有computed-style或设备Profile测量。此前浏览器拒绝仍不绕过，网页像素一致性保持待办。初次Golden捕获曾遗漏祖先背景，已将实际主题背景放入捕获边界，重新查看和非更新复测；未通过加宽像素容差掩盖差异。

## 后续合法可访问预览环境的参考采集

在获准且可访问的开发预览环境中加载原样合成参考，不加载旧HTML单独截图，也不加载用户真实音乐库/凭据。固定浏览器版本、字体、DPR1、语言、时区与逻辑viewport。用测试Fixture固定时间、曲目、队列、收藏、源状态；通过UI暂停demo播放并将进度设为固定值，避免每秒变化。

如需专门测试入口，只能在开发副本中显式新增并记录差分，不能改动归档原文件及其指纹。不要通过读用户浏览器存储取得测试状态。截图不包含用户真实媒体或秘密。

| UI | 参考尺寸 | 正式Flutter验收尺寸 |
| --- | --- | --- |
| Windows | 1440×900、1024×720 | 同上 +840×640 |
| Android Phone | 390×844、430×932 | 同上 +360×800、844×390横屏 |
| Android Tablet | 1024×768、1280×800、800×1280 | 同上 +700×900分屏 |

横屏Phone测试设备使用当前窗口宽度分类，见ADR-002。网页Tablet大宽度不等同正式Tablet Shell，平台主动适配应进入差异报告而不是用错误截图强行验收。

## 场景与顺序

1. Home Light/Dark；核对Shell/Profile/导航/mini或desktop player。
2. Library albums/tracks/artists/playlists/local，Search idle/results/empty/error。
3. Fullscreen Player、独立Lyrics（active/past/future/translation/empty）、Queue。
4. Source Manager/form/testing/auth error，Appearance与局部离线错误。
5. 先结构，再Token，再字体，再图标，再状态，再断点，再动效，最后主题变体。

所有关键组件覆盖Light/Dark、Coral/Cobalt/Jade/Amber/Graphite、自定义亮/暗accent、Reduced Glass、Reduced Motion。状态覆盖Hover/Pressed/Focus/Selected/Disabled/Loading；Phone不模拟持续Hover。

每个关键Golden检查App.tsx新图标路径、44px双Ring账户、Windows/Tablet3×18指示条、Phone替代选中样式、Hero28/Artwork20/Dialog30/Dock26、多层轻阴影、歌词Dock两层重排及130%字体缩放。

## 比对方法与出口

固定同一平台字体和Flutter renderer，不把CSS blur42直接当sigma42。先建立截图基线和无变化重跑噪声，再确定容差；不能在没有测量时发明“99%一致”或任意通过阈值。像素差/半透明叠图用于定位，结构、安全区、文字截断、焦点和图标漏绘不能被总平均分掩盖。

差异记录格式：Screen / Reference size / Flutter size / Difference category / Expected / Actual / Root cause / Token-or-component fix / Validation result。

必须单独记录：全屏slider5/15与4/12 → 正式3/14；Phone导航24 →32；大宽Tablet Shell；immersive artwork ID specificity；Pressed优先Hover；Reduce Glass范围。不要修改原参考隐藏冲突。

先修共享Token/组件，再修必要布局。Flutter Golden通过后仍需Windows与Android真机Profile：模糊区域/帧时间、长列表、频繁位置流、封面解码、歌词滚动。没有重大未解释差异才进入下一视觉阶段。
