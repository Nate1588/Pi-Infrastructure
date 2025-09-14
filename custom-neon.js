/* custom-neon.js — reads tag colors, sets CSS vars for tiles and banner */
(function () {
  function rgbToHex(rgb) {
    if (!rgb) return null;
    const m = rgb.match(/rgba?\(\s*(\d+),\s*(\d+),\s*(\d+)/i);
    if (!m) return null;
    const r = parseInt(m[1]).toString(16).padStart(2,'0');
    const g = parseInt(m[2]).toString(16).padStart(2,'0');
    const b = parseInt(m[3]).toString(16).padStart(2,'0');
    return '#'+r+g+b;
  }

  function setTileGlows() {
    // target common tile selectors
    const tiles = document.querySelectorAll('.list .item, .monitor, .monitor-tile, .grid-stack-item, .grid-stack-item-content');
    tiles.forEach(tile => {
      // guard
      if (!tile) return;
      // find first tag colour inside this tile
      const firstTag = tile.querySelector('.extra-info .tag-wrapper, .tags .tag, .tag-wrapper');
      let glow = null;
      if (firstTag) {
        const bg = getComputedStyle(firstTag).backgroundColor;
        glow = rgbToHex(bg) || bg;
      }
      // fallback colours by status classes if no tag
      if (!glow) {
        if (tile.classList.contains('down')) glow = '#ff0033';
        else if (tile.classList.contains('maintenance') || /maint|warn|partial/i.test(tile.className)) glow = '#ffcc00';
        else glow = '#22c55e'; // up green
      }
      tile.style.setProperty('--glow-color', glow);
      tile.setAttribute('data-neon','true');
    });
  }

  function setStatusBanner() {
    const banner = document.querySelector('.overall-status, .status-title, .hero, .status, .global-status');
    if (!banner) return;
    let txt = (banner.textContent || banner.innerText || '').toLowerCase();
    let statusColor = '#22c55e';
    let statusText = 'STATUS: ALL SYSTEMS GREEN';
    if (/outage|down|offline|unavailable/i.test(txt)) {
      statusColor = '#ff0033';
      statusText = '⚠ ALERT — SOME SERVICES DOWN';
    } else if (/degrad|partial|issue|maintenance|warn/i.test(txt)) {
      statusColor = '#ffcc00';
      statusText = '⚠ PARTIAL OUTAGE / DEGRADED';
    } else {
      statusColor = '#22c55e';
      statusText = 'STATUS: ALL SYSTEMS GREEN';
    }
    banner.style.setProperty('--status-glow', statusColor);
    banner.setAttribute('data-status-neon','true');

    // add or update small custom text
    let el = banner.querySelector('.neon-status-text');
    if (!el) {
      el = document.createElement('div');
      el.className = 'neon-status-text';
      banner.appendChild(el);
    }
    el.textContent = statusText;
  }

  function setGroupTitleColours() {
    // Look for group title elements and match by name text
    const titles = document.querySelectorAll('.monitor-group-title, .monitor-list-title, h2, .group-title, .title');
    titles.forEach(t => {
      const text = (t.textContent || '').toLowerCase();
      if (text.includes('core')) {
        t.setAttribute('data-group','Core');
      } else if (text.includes('infrastructure') || text.includes('infra')) {
        t.setAttribute('data-group','Infrastructure');
      } else if (text.includes('health')) {
        t.setAttribute('data-group','Health');
      }
    });
  }

  function applyAll() {
    setTileGlows();
    setStatusBanner();
    setGroupTitleColours();
  }

  // run now and whenever DOM changes (SPA)
  applyAll();
  const root = document.getElementById('app') || document.body;
  const mo = new MutationObserver(() => { applyAll(); });
  mo.observe(root, { childList: true, subtree: true });
})();
