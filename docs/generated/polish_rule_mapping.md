# POLISH_CSS 全量规则到 Flutter 计划

逐条从源文件提取，不是人工摘录。共 81 个规则块、203 个声明；逗号多选择器仍属一个规则块。所有条目仅是 Phase 2 计划。

| # / App.tsx 行 | 选择器 | 全部声明 | Token / 组件计划 |
| --- | --- | --- | --- |
| 1 / 241 | `body` | `font-feature-settings: "cv01","cv02","ss01","calt"` | YYTypography / font.features |
| 2 / 246 | `.brand-mark` | `width: 44px !important`<br>`height: 44px !important`<br>`border-radius: 50% !important`<br>`background: var(--text-primary) !important`<br>`color: var(--bg-elevated) !important`<br>`font-size: 15px !important`<br>`font-weight: 800 !important`<br>`letter-spacing: -1.5px !important`<br>`box-shadow: 0 0 0 2px var(--bg-elevated), 0 0 0 3.5px var(--border-default) !important`<br>`flex-shrink: 0 !important` | YYProfileHeader / profile.size, typography, ring; footer deduplication |
| 3 / 260 | `.brand-name` | `font-size: 13.5px !important`<br>`font-weight: 720 !important`<br>`letter-spacing: -.4px !important` | YYProfileHeader / profile.size, typography, ring; footer deduplication |
| 4 / 265 | `.brand-subtitle` | `font-size: 10px !important`<br>`font-weight: 540 !important`<br>`letter-spacing: .05px !important`<br>`margin-top: 2px !important` | YYProfileHeader / profile.size, typography, ring; footer deduplication |
| 5 / 273 | `.sidebar-footer .profile-avatar, .sidebar-footer .profile-copy` | `display: none !important` | YYProfileHeader / profile.size, typography, ring; footer deduplication |
| 6 / 275 | `.sidebar-footer` | `justify-content: flex-end !important` | YYProfileHeader / profile.size, typography, ring; footer deduplication |
| 7 / 279 | `.nav-item` | `border-radius: 14px` | YYNavigationItem / radius.navigation, accent, selectionIndicator; Phone adaptation |
| 8 / 281 | `.nav-item.active` | `position: relative` | YYNavigationItem / radius.navigation, accent, selectionIndicator; Phone adaptation |
| 9 / 283 | `.nav-item.active::before` | `content: ""`<br>`position: absolute`<br>`left: 0`<br>`top: 50%`<br>`transform: translateY(-50%)`<br>`width: 3px`<br>`height: 18px`<br>`border-radius: 0 3px 3px 0`<br>`background: var(--accent)` | YYNavigationItem / radius.navigation, accent, selectionIndicator; Phone adaptation |
| 10 / 294 | `.icon` | `stroke-width: 1.72` | YYIcons / icon.strokeWidth |
| 11 / 297 | `.page-title` | `font-weight: 800`<br>`letter-spacing: -.82px` | YYTypography / pageTitle, sectionTitle |
| 12 / 298 | `.section-title` | `letter-spacing: -.45px` | YYTypography / pageTitle, sectionTitle |
| 13 / 299 | `.hero h2` | `letter-spacing: -2.1px` | YYHero / typography.hero, radius.hero, shadow.hero |
| 14 / 300 | `.hero-kicker` | `font-size: 10.5px`<br>`font-weight: 760`<br>`letter-spacing: .55px`<br>`text-transform: uppercase` | YYHero / typography.hero, radius.hero, shadow.hero |
| 15 / 301 | `.album-title` | `font-size: 12.5px`<br>`font-weight: 700`<br>`letter-spacing: -.15px` | YYAlbumCard / typography.albumTitle, radius.album, shadow.album[-hover] |
| 16 / 304 | `.hero` | `border-radius: 28px`<br>`box-shadow: 0 4px 20px rgba(15,18,20,.06), 0 1px 3px rgba(15,18,20,.05)` | YYHero / typography.hero, radius.hero, shadow.hero |
| 17 / 310 | `.hero-stage-disc` | `box-shadow: 0 30px 72px rgba(15,18,20,.26)` | YYArtworkPlaceholder / heroDisc geometry, ring, shadow.heroDisc |
| 18 / 313 | `.hero-stage-disc::before` | `inset: 24px`<br>`border: 1px solid rgba(255,255,255,.17)`<br>`box-shadow: inset 0 0 0 22px rgba(255,255,255,.024), inset 0 0 0 52px rgba(255,255,255,.024), inset 0 0 0 82px rgba(255,255,255,.024)` | YYArtworkPlaceholder / heroDisc geometry, ring, shadow.heroDisc |
| 19 / 321 | `.hero-stage-disc::after` | `font-size: 11px`<br>`font-weight: 900`<br>`letter-spacing: -1.9px`<br>`box-shadow: 0 6px 20px rgba(var(--accent-rgb),.32)` | YYArtworkPlaceholder / heroDisc geometry, ring, shadow.heroDisc |
| 20 / 329 | `.floating-note` | `border-radius: 20px` | YYFloatingNowPlaying / radius.floatingNote, radius.floatingArtwork |
| 21 / 330 | `.floating-note-art` | `border-radius: 12px` | YYFloatingNowPlaying / radius.floatingNote, radius.floatingArtwork |
| 22 / 333 | `.button-primary` | `font-weight: 700`<br>`letter-spacing: .1px`<br>`box-shadow: 0 6px 18px rgba(var(--accent-rgb),.2)` | YYButton / typography.button, shadow.primaryButton, hover |
| 23 / 338 | `.button-primary:hover` | `box-shadow: 0 9px 26px rgba(var(--accent-rgb),.3)` | YYButton / typography.button, shadow.primaryButton, hover |
| 24 / 341 | `.icon-button` | `border-radius: 13px`<br>`box-shadow: 0 1px 6px rgba(15,18,20,.06)` | YYIconButton / radius.iconButton, shadow.iconButton |
| 25 / 347 | `.album-card .art` | `border-radius: 20px`<br>`box-shadow: 0 10px 26px rgba(15,18,20,.13)` | YYAlbumCard / typography.albumTitle, radius.album, shadow.album[-hover] |
| 26 / 351 | `.album-card:hover .art` | `box-shadow: 0 16px 34px rgba(15,18,20,.19)` | YYAlbumCard / typography.albumTitle, radius.album, shadow.album[-hover] |
| 27 / 354 | `.track-art` | `border-radius: 10px` | YYTrackTile / radius.trackArtwork |
| 28 / 355 | `.queue-item-art` | `border-radius: 10px` | YYQueueTile / radius.queueArtwork |
| 29 / 356 | `.now-artwork` | `border-radius: 26px`<br>`box-shadow: 0 22px 50px rgba(15,18,20,.2)` | YYPlayerArtwork / radius.playerArtwork, shadow.playerArtwork.light&#124;dark; specificity exception |
| 30 / 360 | `html[data-theme="dark"] .now-artwork` | `box-shadow: 0 24px 58px rgba(0,0,0,.46)` | YYPlayerArtwork / radius.playerArtwork, shadow.playerArtwork.light&#124;dark; specificity exception |
| 31 / 365 | `.range::-webkit-slider-runnable-track` | `height: 3px` | YYSlider / trackHeight, thumbSize, ring, hoverScale; fullscreen variants |
| 32 / 366 | `.range::-webkit-slider-thumb` | `width: 14px`<br>`height: 14px`<br>`margin-top: -5.5px`<br>`box-shadow: 0 0 0 3px var(--bg-elevated), 0 3px 10px rgba(var(--accent-rgb),.32)`<br>`transition: transform 130ms ease` | YYSlider / trackHeight, thumbSize, ring, hoverScale; fullscreen variants |
| 33 / 371 | `.range:hover::-webkit-slider-thumb` | `transform: scale(1.24)` | YYSlider / trackHeight, thumbSize, ring, hoverScale; fullscreen variants |
| 34 / 372 | `.range::-moz-range-track` | `height: 3px` | YYSlider / trackHeight, thumbSize, ring, hoverScale; fullscreen variants |
| 35 / 373 | `.range::-moz-range-thumb` | `width: 14px`<br>`height: 14px`<br>`box-shadow: 0 0 0 3px var(--bg-elevated), 0 3px 10px rgba(var(--accent-rgb),.28)` | YYSlider / trackHeight, thumbSize, ring, hoverScale; fullscreen variants |
| 36 / 379 | `.transport-button.primary` | `box-shadow: 0 12px 32px rgba(15,18,20,.2)` | YYTransportButton / shadow.primaryControl, hoverScale, pressed |
| 37 / 382 | `.transport-button.primary:hover` | `transform: scale(1.04) !important`<br>`box-shadow: 0 16px 40px rgba(15,18,20,.27)` | YYTransportButton / shadow.primaryControl, hoverScale, pressed |
| 38 / 386 | `.player-control.primary` | `box-shadow: 0 8px 22px rgba(15,18,20,.16)` | YYDesktopPlayerBar / shadow.playerControl |
| 39 / 391 | `.surface-card` | `box-shadow: 0 1px 4px rgba(15,18,20,.04), 0 4px 18px rgba(15,18,20,.04)` | YYSurface / shadow.surface |
| 40 / 396 | `.glass` | `-webkit-backdrop-filter: blur(42px) saturate(1.3)`<br>`backdrop-filter: blur(42px) saturate(1.3)` | YYGlassSurface / glass.blur, glass.saturation; clipped platform calibration |
| 41 / 402 | `.sidebar` | `border-radius: 24px` | YYWindowsSidebar, YYTabletNavigationRail / radius.sidebar; Phone adaptation |
| 42 / 403 | `.now-panel` | `border-radius: 24px` | YYNowPlayingInspector / radius.nowPanel |
| 43 / 406 | `.track-row` | `border-radius: 14px` | YYTrackTile / radius.trackRow |
| 44 / 409 | `.source-icon` | `border-radius: 13px` | YYSourceCard / radius.sourceIcon, radius.sourceStatus |
| 45 / 410 | `.source-status` | `border-radius: 20px` | YYSourceCard / radius.sourceIcon, radius.sourceStatus |
| 46 / 413 | `.dialog` | `border-radius: 30px` | YYDialog, FullscreenPlayerPage / radius.dialog; immersive specificity |
| 47 / 414 | `.now-dialog` | `border-radius: 30px` | YYDialog, FullscreenPlayerPage / radius.dialog; immersive specificity |
| 48 / 415 | `.context-menu` | `border-radius: 20px` | YYContextMenu / radius.contextMenu |
| 49 / 418 | `.settings-nav-item` | `border-radius: 11px` | YYSettingsNavigation / radius.settingsNav |
| 50 / 421 | `.playlist-card` | `border-radius: 20px` | YYPlaylistCard / radius.playlistCard, radius.playlistIcon |
| 51 / 422 | `.playlist-icon` | `border-radius: 14px` | YYPlaylistCard / radius.playlistCard, radius.playlistIcon |
| 52 / 425 | `.badge` | `font-weight: 720`<br>`letter-spacing: .1px` | YYBadge / typography.badge |
| 53 / 426 | `.metric-card` | `border-radius: 18px` | YYMetricCard / radius.metric |
| 54 / 427 | `.folder-row` | `border-radius: 16px` | YYFolderRow / radius.folder |
| 55 / 428 | `.drop-zone` | `border-radius: 26px` | YYDropZone / radius.dropZone |
| 56 / 429 | `.now-panel-action-icon` | `border-radius: 11px` | YYNowPlayingAction / radius.nowPanelAction |
| 57 / 430 | `.search-input` | `font-weight: 460` | YYSearchField / typography.search |
| 58 / 433 | `.lyric-primary` | `font-weight: 780`<br>`letter-spacing: clamp(-1.9px, -.05em, -.45px)` | YYLyricsLine / typography.lyrics, activeDot.ring |
| 59 / 437 | `.fullscreen-lyric-line.active::before` | `box-shadow: 0 0 0 6px rgba(255,255,255,.08)` | YYLyricsLine / typography.lyrics, activeDot.ring |
| 60 / 440 | `.lyrics-player-dock` | `border-radius: 26px` | YYLyricsPlayerDock / radius.lyricsDock; responsive reflow |
| 61 / 443 | `.art-orbit` | `background: #0D0F12` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 62 / 444 | `.art-orbit::before` | `width: 80%`<br>`height: 80%`<br>`left: -14%`<br>`top: 10%`<br>`border-radius: 50%`<br>`background: #C42230` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 63 / 445 | `.art-orbit::after` | `width: 30%`<br>`height: 30%`<br>`right: 9%`<br>`bottom: 12%`<br>`border-radius: 50%`<br>`background: #ECE7DC` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 64 / 447 | `.art-tide` | `background: #0468C4` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 65 / 448 | `.art-tide::before` | `width: 22%`<br>`height: 114%`<br>`left: 21%`<br>`top: -7%`<br>`background: #EDF2F8`<br>`transform: rotate(10deg)` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 66 / 449 | `.art-tide::after` | `width: 40%`<br>`height: 40%`<br>`right: 8%`<br>`top: 10%`<br>`border-radius: 50%`<br>`background: #FFA820` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 67 / 451 | `.art-noon` | `background: #E9DDC8` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 68 / 452 | `.art-noon::before` | `width: 56%`<br>`height: 56%`<br>`left: 22%`<br>`top: 20%`<br>`background: #13171B`<br>`transform: rotate(18deg)`<br>`border-radius: 11%` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 69 / 453 | `.art-noon::after` | `width: 13%`<br>`height: 84%`<br>`left: 44%`<br>`top: 8%`<br>`background: #C83828`<br>`transform: rotate(-26deg)` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 70 / 455 | `.art-mono` | `background: #0C2030` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 71 / 456 | `.art-mono::before` | `width: 82%`<br>`height: 36%`<br>`left: 9%`<br>`top: 32%`<br>`border-radius: 50%`<br>`background: #009970`<br>`transform: rotate(-13deg)` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 72 / 457 | `.art-mono::after` | `width: 25%`<br>`height: 25%`<br>`right: 12%`<br>`bottom: 12%`<br>`background: #E2E4D8`<br>`border-radius: 5px` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 73 / 459 | `.art-signal` | `background: #F0A018` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 74 / 460 | `.art-signal::before` | `width: 18%`<br>`height: 78%`<br>`left: 19%`<br>`bottom: 0`<br>`background: #14181C`<br>`box-shadow: 35px -27px 0 #14181C, 70px -54px 0 #14181C` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 75 / 461 | `.art-signal::after` | `width: 26%`<br>`height: 26%`<br>`right: 10%`<br>`top: 10%`<br>`border: 3px solid #FFF3DE`<br>`border-radius: 50%` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 76 / 463 | `.art-quiet` | `background: #F2EEE8` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 77 / 464 | `.art-quiet::before` | `width: 63%`<br>`height: 63%`<br>`left: 18%`<br>`top: 18%`<br>`background: #0F1113`<br>`border-radius: 50%` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 78 / 465 | `.art-quiet::after` | `width: 80%`<br>`height: 11%`<br>`left: 10%`<br>`top: 45%`<br>`background: #C82826`<br>`transform: rotate(-16deg)` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 79 / 467 | `.art-local` | `background: #1A1E24` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 80 / 468 | `.art-local::before` | `width: 73%`<br>`height: 50%`<br>`left: 14%`<br>`top: 25%`<br>`border: 2.5px solid #E4E7F0`<br>`border-radius: 16px` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |
| 81 / 469 | `.art-local::after` | `width: 33%`<br>`height: 6%`<br>`left: 34%`<br>`top: 48%`<br>`background: var(--accent)`<br>`border-radius: var(--radius-pill)`<br>`box-shadow: 0 -17px 0 rgba(var(--accent-rgb),.62), 0 17px 0 rgba(var(--accent-rgb),.38)` | YYArtworkPlaceholder / fixture palette and geometry; never production catalog |

注意：最后注入不等于无条件胜出。ID 选择器、组合类选择器、!important、伪元素与媒体查询均参与层叠。详见 design_source_composition.md 和 responsive_layout_map.md。
