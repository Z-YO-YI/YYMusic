import { useEffect, useRef } from 'react';
import rawHTML from './imports/YYMusic_HTML_Preview_v4_Separate_Fullscreen_Lyrics.html?raw';

/* ─────────────────────────────────────────────────────────────────
   Refined icon sprite — every symbol rebuilt for clarity & weight.
   Filled shapes (play, pause, skip, dots) use presentation attrs
   so they override inherited fill:none from .icon CSS.
───────────────────────────────────────────────────────────────── */
const NEW_ICON_SPRITE = `<svg aria-hidden="true" height="0" style="position:absolute" width="0">

<symbol id="i-home" viewBox="0 0 24 24">
  <path d="M3 13 12 5 21 13"/>
  <path d="M6 11.5v9h4v-5h4v5h4v-9"/>
</symbol>

<symbol id="i-search" viewBox="0 0 24 24">
  <circle cx="10.5" cy="10.5" r="6.5"/>
  <path d="m15.5 15.5 5 5"/>
</symbol>

<symbol id="i-library" viewBox="0 0 24 24">
  <rect height="16" rx="1.5" width="3.5" x="4" y="4"/>
  <rect height="16" rx="1.5" width="3.5" x="9.5" y="4"/>
  <rect height="14" rx="1.5" width="3.5" x="15" y="6"/>
</symbol>

<symbol id="i-settings" viewBox="0 0 24 24">
  <path d="M4 6h1.5M10.5 6h9.5M4 12h7.5M16.5 12h3.5M4 18h3M12 18h8"/>
  <circle cx="8" cy="6" r="2.5"/>
  <circle cx="14" cy="12" r="2.5"/>
  <circle cx="9.5" cy="18" r="2.5"/>
</symbol>

<symbol id="i-moon" viewBox="0 0 24 24">
  <path d="M20.5 15.5A9 9 0 0 1 8.5 3.5a9 9 0 1 0 12 12z"/>
</symbol>

<symbol id="i-sun" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="4.2"/>
  <path d="M12 2.5v2M12 19.5v2M4.5 12h-2M21.5 12h-2M5.7 5.7 7.1 7.1M16.9 16.9l1.4 1.4M18.3 5.7l-1.4 1.4M7.1 16.9l-1.4 1.4"/>
</symbol>

<symbol id="i-play" viewBox="0 0 24 24">
  <path d="M7.5 5 19 12 7.5 19z" fill="currentColor" stroke="none"/>
</symbol>

<symbol id="i-pause" viewBox="0 0 24 24">
  <rect fill="currentColor" height="14" rx="2.2" stroke="none" width="4.2" x="5.2" y="5"/>
  <rect fill="currentColor" height="14" rx="2.2" stroke="none" width="4.2" x="14.6" y="5"/>
</symbol>

<symbol id="i-prev" viewBox="0 0 24 24">
  <rect fill="currentColor" height="13" rx="1.8" stroke="none" width="3.2" x="5" y="5.5"/>
  <path d="M19.2 6.5 9.8 12l9.4 5.5z" fill="currentColor" stroke="none"/>
</symbol>

<symbol id="i-next" viewBox="0 0 24 24">
  <rect fill="currentColor" height="13" rx="1.8" stroke="none" width="3.2" x="15.8" y="5.5"/>
  <path d="M4.8 6.5 14.2 12 4.8 17.5z" fill="currentColor" stroke="none"/>
</symbol>

<symbol id="i-shuffle" viewBox="0 0 24 24">
  <path d="M2 18h1.5c1.25 0 2.4-.6 3.1-1.6l6-8.8C13.3 6.6 14.4 6 15.7 6H20"/>
  <path d="m17 14 3 3-3 3M2 6h1.5c1.4 0 2.7.8 3.3 2.1"/>
  <path d="m17 4 3 3-3 3M20.8 16.6H18c-1.3 0-2.4-.6-3.1-1.6l-.5-.8"/>
</symbol>

<symbol id="i-repeat" viewBox="0 0 24 24">
  <path d="M17 4.5 20 7l-3 2.5M20 7H7a3 3 0 0 0-3 3v1"/>
  <path d="M7 19.5 4 17l3-2.5M4 17h13a3 3 0 0 0 3-3v-1"/>
</symbol>

<symbol id="i-volume" viewBox="0 0 24 24">
  <path d="M4 10v4h4l5 4V6L8 10z"/>
  <path d="M16 9a4 4 0 0 1 0 6M18.5 6.5a7.5 7.5 0 0 1 0 11"/>
</symbol>

<symbol id="i-queue" viewBox="0 0 24 24">
  <path d="M5 6h10M5 11h10M5 16h6"/>
  <path d="m16 15 4 2.5-4 2.5z" fill="currentColor" stroke="none"/>
</symbol>

<symbol id="i-more" viewBox="0 0 24 24">
  <circle cx="5.5" cy="12" fill="currentColor" r="1.3" stroke="none"/>
  <circle cx="12" cy="12" fill="currentColor" r="1.3" stroke="none"/>
  <circle cx="18.5" cy="12" fill="currentColor" r="1.3" stroke="none"/>
</symbol>

<symbol id="i-heart" viewBox="0 0 24 24">
  <path d="M20.4 6a5.1 5.1 0 0 0-7.2 0L12 7.2l-1.2-1.2a5.1 5.1 0 0 0-7.2 7.2L12 22l8.4-8.8A5.1 5.1 0 0 0 20.4 6z"/>
</symbol>

<symbol id="i-folder" viewBox="0 0 24 24">
  <path d="M3.5 7.5a2 2 0 0 1 2-2H9l2 2h8.5a2 2 0 0 1 2 2v8.5a2 2 0 0 1-2 2h-14a2 2 0 0 1-2-2V7.5z"/>
</symbol>

<symbol id="i-cloud" viewBox="0 0 24 24">
  <path d="M7.5 18.5h10a4 4 0 0 0 .4-8 6 6 0 0 0-11.5-1.4A4.8 4.8 0 0 0 7.5 18.5z"/>
</symbol>

<symbol id="i-plus" viewBox="0 0 24 24">
  <path d="M12 5v14M5 12h14"/>
</symbol>

<symbol id="i-chevron-right" viewBox="0 0 24 24">
  <path d="m9.5 5.5 7 6.5-7 6.5"/>
</symbol>

<symbol id="i-chevron-down" viewBox="0 0 24 24">
  <path d="m5.5 9.5 6.5 6.5 6.5-6.5"/>
</symbol>

<symbol id="i-x" viewBox="0 0 24 24">
  <path d="M6.5 6.5 17.5 17.5M17.5 6.5 6.5 17.5"/>
</symbol>

<symbol id="i-minimize" viewBox="0 0 24 24">
  <path d="M6 13.5h12"/>
</symbol>

<symbol id="i-maximize" viewBox="0 0 24 24">
  <rect height="12" rx="2" width="12" x="6" y="6"/>
</symbol>

<symbol id="i-music" viewBox="0 0 24 24">
  <path d="M9 18V6l10-2v12"/>
  <circle cx="6.5" cy="18" r="2.5"/>
  <circle cx="16.5" cy="16" r="2.5"/>
</symbol>

<symbol id="i-palette" viewBox="0 0 24 24">
  <path d="M12 3a9 9 0 0 0 0 18h1.2a1.8 1.8 0 0 0 1.3-3l-.2-.2a1.8 1.8 0 0 1 1.3-3H17a4 4 0 0 0 4-4A8 8 0 0 0 12 3z"/>
  <circle cx="7.5" cy="10" fill="currentColor" r="1.1" stroke="none"/>
  <circle cx="10" cy="6.8" fill="currentColor" r="1.1" stroke="none"/>
  <circle cx="14" cy="6.5" fill="currentColor" r="1.1" stroke="none"/>
  <circle cx="17" cy="9" fill="currentColor" r="1.1" stroke="none"/>
</symbol>

<symbol id="i-key" viewBox="0 0 24 24">
  <circle cx="8.5" cy="12" r="4.5"/>
  <path d="M13 12h8M17 12v3M20 12v2"/>
</symbol>

<symbol id="i-info" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="9.5"/>
  <path d="M12 16.5v-5.5M12 8h.01"/>
</symbol>

<symbol id="i-check" viewBox="0 0 24 24">
  <path d="M4.5 12.5 9.5 17.5 19.5 7"/>
</symbol>

<symbol id="i-playlist" viewBox="0 0 24 24">
  <path d="M4 6h10M4 11h8M4 16h6"/>
  <path d="M16 8v9.2a2.7 2.7 0 1 1-2-2.6V10l6-1.5v6.7a2.7 2.7 0 1 1-2-2.6V8.5"/>
</symbol>

<symbol id="i-history" viewBox="0 0 24 24">
  <path d="M4.5 6.5V3.7M4.5 6.5h2.8"/>
  <path d="M5 6.2A8.5 8.5 0 1 1 3.5 12"/>
  <path d="M12 7.5V12l3 2"/>
</symbol>

<symbol id="i-timer" viewBox="0 0 24 24">
  <circle cx="12" cy="13" r="8.2"/>
  <path d="M9 2.8h6M12 5v2M12 13l3-2"/>
</symbol>

<symbol id="i-device" viewBox="0 0 24 24">
  <rect height="12" rx="2" width="16" x="4" y="3.5"/>
  <path d="M8 20.5h8M12 15.5v5"/>
</symbol>

<symbol id="i-trash" viewBox="0 0 24 24">
  <path d="M3.5 7h17M9 3.5h6l1 3.5H8zM7 7l.8 13.5h8.4L17 7"/>
  <path d="M10 10.5v7M14 10.5v7"/>
</symbol>

<symbol id="i-list-plus" viewBox="0 0 24 24">
  <path d="M4 6h9M4 11h9M4 16h6M18 11v8M14 15h8"/>
</symbol>

<symbol id="i-up" viewBox="0 0 24 24">
  <path d="m5.5 14.5 6.5-6.5 6.5 6.5"/>
</symbol>

<symbol id="i-down" viewBox="0 0 24 24">
  <path d="m5.5 9.5 6.5 6.5 6.5-6.5"/>
</symbol>

<symbol id="i-refresh" viewBox="0 0 24 24">
  <path d="M20 7v5h-5M4 17v-5h5"/>
  <path d="M6.1 8.2A7 7 0 0 1 19.7 12M4.3 12a7 7 0 0 0 13.6 3.8"/>
</symbol>

<symbol id="i-speaker" viewBox="0 0 24 24">
  <path d="M5 9h4l5-4v14l-5-4H5z"/>
  <path d="M17 9a4.5 4.5 0 0 1 0 6M19.5 6.5a8 8 0 0 1 0 11"/>
</symbol>

<symbol id="i-drag" viewBox="0 0 24 24">
  <circle cx="9" cy="7" fill="currentColor" r="1.1" stroke="none"/>
  <circle cx="15" cy="7" fill="currentColor" r="1.1" stroke="none"/>
  <circle cx="9" cy="12" fill="currentColor" r="1.1" stroke="none"/>
  <circle cx="15" cy="12" fill="currentColor" r="1.1" stroke="none"/>
  <circle cx="9" cy="17" fill="currentColor" r="1.1" stroke="none"/>
  <circle cx="15" cy="17" fill="currentColor" r="1.1" stroke="none"/>
</symbol>

<symbol id="i-wave" viewBox="0 0 24 24">
  <path d="M4 14.5v-5M8 17.5V6.5M12 21V3M16 17.5V6.5M20 14.5v-5"/>
</symbol>

<symbol id="i-fullscreen" viewBox="0 0 24 24">
  <path d="M8.5 4H6a2 2 0 0 0-2 2v2.5"/>
  <path d="M15.5 4H18a2 2 0 0 1 2 2v2.5"/>
  <path d="M20 15.5V18a2 2 0 0 1-2 2h-2.5"/>
  <path d="M4 15.5V18a2 2 0 0 0 2 2h2.5"/>
</symbol>

<symbol id="i-fullscreen-exit" viewBox="0 0 24 24">
  <path d="M9 4v2.5A2.5 2.5 0 0 1 6.5 9H4"/>
  <path d="M15 4v2.5A2.5 2.5 0 0 0 17.5 9H20"/>
  <path d="M20 15h-2.5A2.5 2.5 0 0 0 15 17.5V20"/>
  <path d="M4 15h2.5A2.5 2.5 0 0 1 9 17.5V20"/>
</symbol>

<symbol id="i-lyrics" viewBox="0 0 24 24">
  <path d="M5 6h14M5 10.5h10M5 15h7.5"/>
  <path d="M17 13v5.2a2.3 2.3 0 1 1-1.7-2.2V11l4-1v5.2a2.3 2.3 0 1 1-1.7-2.2"/>
</symbol>

</svg>`;

/* ─────────────────────────────────────────────────────────────────
   Visual polish CSS — second pass.
   Goals: premium feel, no gradients, no purple, Swiss precision.
───────────────────────────────────────────────────────────────── */
const POLISH_CSS = `
/* ── Font & base ── */
body {
  font-feature-settings: "cv01","cv02","ss01","calt";
}

/* ── Sidebar: profile avatar at top ── */
.brand-mark {
  width: 44px !important;
  height: 44px !important;
  border-radius: 50% !important;
  background: var(--text-primary) !important;
  color: var(--bg-elevated) !important;
  font-size: 15px !important;
  font-weight: 800 !important;
  letter-spacing: -1.5px !important;
  box-shadow: 0 0 0 2px var(--bg-elevated), 0 0 0 3.5px var(--border-default) !important;
  flex-shrink: 0 !important;
}

/* ── Profile name / subtitle in brand area ── */
.brand-name {
  font-size: 13.5px !important;
  font-weight: 720 !important;
  letter-spacing: -.4px !important;
}
.brand-subtitle {
  font-size: 10px !important;
  font-weight: 540 !important;
  letter-spacing: .05px !important;
  margin-top: 2px !important;
}

/* ── Hide duplicate profile block in footer ── */
.sidebar-footer .profile-avatar,
.sidebar-footer .profile-copy { display: none !important; }
.sidebar-footer { justify-content: flex-end !important; }

/* ── Nav typography & indicator ── */

.nav-item { border-radius: 14px; }

.nav-item.active { position: relative; }

.nav-item.active::before {
  content: "";
  position: absolute;
  left: 0; top: 50%;
  transform: translateY(-50%);
  width: 3px; height: 18px;
  border-radius: 0 3px 3px 0;
  background: var(--accent);
}

/* ── Icon stroke ── */
.icon { stroke-width: 1.72; }

/* ── Headings ── */
.page-title       { font-weight: 800; letter-spacing: -.82px; }
.section-title    { letter-spacing: -.45px; }
.hero h2          { letter-spacing: -2.1px; }
.hero-kicker      { font-size: 10.5px; font-weight: 760; letter-spacing: .55px; text-transform: uppercase; }
.album-title      { font-size: 12.5px; font-weight: 700; letter-spacing: -.15px; }

/* ── Hero card ── */
.hero {
  border-radius: 28px;
  box-shadow: 0 4px 20px rgba(15,18,20,.06), 0 1px 3px rgba(15,18,20,.05);
}

/* ── Hero disc ── */
.hero-stage-disc {
  box-shadow: 0 30px 72px rgba(15,18,20,.26);
}
.hero-stage-disc::before {
  inset: 24px;
  border: 1px solid rgba(255,255,255,.17);
  box-shadow:
    inset 0 0 0 22px rgba(255,255,255,.024),
    inset 0 0 0 52px rgba(255,255,255,.024),
    inset 0 0 0 82px rgba(255,255,255,.024);
}
.hero-stage-disc::after {
  font-size: 11px;
  font-weight: 900;
  letter-spacing: -1.9px;
  box-shadow: 0 6px 20px rgba(var(--accent-rgb),.32);
}

/* ── Floating now-playing card ── */
.floating-note { border-radius: 20px; }
.floating-note-art { border-radius: 12px; }

/* ── Buttons ── */
.button-primary {
  font-weight: 700;
  letter-spacing: .1px;
  box-shadow: 0 6px 18px rgba(var(--accent-rgb),.2);
}
.button-primary:hover {
  box-shadow: 0 9px 26px rgba(var(--accent-rgb),.3);
}
.icon-button {
  border-radius: 13px;
  box-shadow: 0 1px 6px rgba(15,18,20,.06);
}

/* ── Album / queue artwork ── */
.album-card .art {
  border-radius: 20px;
  box-shadow: 0 10px 26px rgba(15,18,20,.13);
}
.album-card:hover .art {
  box-shadow: 0 16px 34px rgba(15,18,20,.19);
}
.track-art     { border-radius: 10px; }
.queue-item-art { border-radius: 10px; }
.now-artwork {
  border-radius: 26px;
  box-shadow: 0 22px 50px rgba(15,18,20,.2);
}
html[data-theme="dark"] .now-artwork {
  box-shadow: 0 24px 58px rgba(0,0,0,.46);
}

/* ── Progress bar ── */
.range::-webkit-slider-runnable-track { height: 3px; }
.range::-webkit-slider-thumb {
  width: 14px; height: 14px; margin-top: -5.5px;
  box-shadow: 0 0 0 3px var(--bg-elevated), 0 3px 10px rgba(var(--accent-rgb),.32);
  transition: transform 130ms ease;
}
.range:hover::-webkit-slider-thumb { transform: scale(1.24); }
.range::-moz-range-track { height: 3px; }
.range::-moz-range-thumb {
  width: 14px; height: 14px;
  box-shadow: 0 0 0 3px var(--bg-elevated), 0 3px 10px rgba(var(--accent-rgb),.28);
}

/* ── Player controls ── */
.transport-button.primary {
  box-shadow: 0 12px 32px rgba(15,18,20,.2);
}
.transport-button.primary:hover {
  transform: scale(1.04) !important;
  box-shadow: 0 16px 40px rgba(15,18,20,.27);
}
.player-control.primary {
  box-shadow: 0 8px 22px rgba(15,18,20,.16);
}

/* ── Surface cards ── */
.surface-card {
  box-shadow: 0 1px 4px rgba(15,18,20,.04), 0 4px 18px rgba(15,18,20,.04);
}

/* ── Glass ── */
.glass {
  -webkit-backdrop-filter: blur(42px) saturate(1.3);
  backdrop-filter: blur(42px) saturate(1.3);
}

/* ── Panel shapes ── */
.sidebar   { border-radius: 24px; }
.now-panel { border-radius: 24px; }

/* ── Track list ── */
.track-row { border-radius: 14px; }

/* ── Source ── */
.source-icon   { border-radius: 13px; }
.source-status { border-radius: 20px; }

/* ── Dialogs ── */
.dialog     { border-radius: 30px; }
.now-dialog { border-radius: 30px; }
.context-menu { border-radius: 20px; }

/* ── Settings ── */
.settings-nav-item { border-radius: 11px; }

/* ── Playlist ── */
.playlist-card { border-radius: 20px; }
.playlist-icon { border-radius: 14px; }

/* ── Misc detail ── */
.badge              { font-weight: 720; letter-spacing: .1px; }
.metric-card        { border-radius: 18px; }
.folder-row         { border-radius: 16px; }
.drop-zone          { border-radius: 26px; }
.now-panel-action-icon { border-radius: 11px; }
.search-input       { font-weight: 460; }

/* ── Lyrics surface ── */
.lyric-primary {
  font-weight: 780;
  letter-spacing: clamp(-1.9px, -.05em, -.45px);
}
.fullscreen-lyric-line.active::before {
  box-shadow: 0 0 0 6px rgba(255,255,255,.08);
}
.lyrics-player-dock { border-radius: 26px; }

/* ──────── Album artwork palette (flat geometry, no gradients) ──────── */
.art-orbit { background: #0D0F12; }
.art-orbit::before { width:80%; height:80%; left:-14%; top:10%; border-radius:50%; background:#C42230; }
.art-orbit::after  { width:30%; height:30%; right:9%; bottom:12%; border-radius:50%; background:#ECE7DC; }

.art-tide { background: #0468C4; }
.art-tide::before { width:22%; height:114%; left:21%; top:-7%; background:#EDF2F8; transform:rotate(10deg); }
.art-tide::after  { width:40%; height:40%; right:8%; top:10%; border-radius:50%; background:#FFA820; }

.art-noon { background: #E9DDC8; }
.art-noon::before { width:56%; height:56%; left:22%; top:20%; background:#13171B; transform:rotate(18deg); border-radius:11%; }
.art-noon::after  { width:13%; height:84%; left:44%; top:8%; background:#C83828; transform:rotate(-26deg); }

.art-mono { background: #0C2030; }
.art-mono::before { width:82%; height:36%; left:9%; top:32%; border-radius:50%; background:#009970; transform:rotate(-13deg); }
.art-mono::after  { width:25%; height:25%; right:12%; bottom:12%; background:#E2E4D8; border-radius:5px; }

.art-signal { background: #F0A018; }
.art-signal::before { width:18%; height:78%; left:19%; bottom:0; background:#14181C; box-shadow:35px -27px 0 #14181C, 70px -54px 0 #14181C; }
.art-signal::after  { width:26%; height:26%; right:10%; top:10%; border:3px solid #FFF3DE; border-radius:50%; }

.art-quiet { background: #F2EEE8; }
.art-quiet::before { width:63%; height:63%; left:18%; top:18%; background:#0F1113; border-radius:50%; }
.art-quiet::after  { width:80%; height:11%; left:10%; top:45%; background:#C82826; transform:rotate(-16deg); }

.art-local { background: #1A1E24; }
.art-local::before { width:73%; height:50%; left:14%; top:25%; border:2.5px solid #E4E7F0; border-radius:16px; }
.art-local::after  {
  width:33%; height:6%; left:34%; top:48%;
  background: var(--accent);
  border-radius: var(--radius-pill);
  box-shadow: 0 -17px 0 rgba(var(--accent-rgb),.62), 0 17px 0 rgba(var(--accent-rgb),.38);
}
`;

export default function App() {
  const iframeRef = useRef<HTMLIFrameElement>(null);

  useEffect(() => {
    // Swap icon sprite
    const s0 = rawHTML.indexOf('<svg aria-hidden="true" height="0"');
    const s1 = rawHTML.indexOf('</svg>', s0) + '</svg>'.length;
    let html = rawHTML.slice(0, s0) + NEW_ICON_SPRITE + rawHTML.slice(s1);

    // Replace brand mark with profile avatar
    html = html.replace('<div class="brand-name">YYMusic</div>', '<div class="brand-name">YY Listener</div>');
    html = html.replace('<div class="brand-subtitle">YOUR MUSIC, YOUR WAY</div>', '<div class="brand-subtitle">本地账户</div>');

    // Inject polish CSS
    html = html.replace('</head>', `<style>${POLISH_CSS}</style>\n</head>`);

    const blob = new Blob([html], { type: 'text/html' });
    const url = URL.createObjectURL(blob);
    if (iframeRef.current) iframeRef.current.src = url;
    return () => URL.revokeObjectURL(url);
  }, []);

  return (
    <iframe
      ref={iframeRef}
      style={{ width: '100%', height: '100vh', border: 'none', display: 'block' }}
      title="YYMusic"
    />
  );
}
