(() => {
  const script = document.currentScript;
  const fetchTheme = window.fetch.bind(window);
  const resource = window.GetParentResourceName?.() || script?.dataset.resource;
  const mirrorSecondary = script?.dataset.secondary === 'accent';
  const style = document.createElement('style');
  style.dataset.sleeplessUiTheme = '';
  document.head.appendChild(style);

  function isEnvBrowser() {
    return !window.invokeNative;
  }

  function applyPrimary(value) {
    if (typeof value !== 'string' || !/^#[0-9a-f]{6}$/i.test(value)) return;
    const channels = [1, 3, 5].map((offset) => Number.parseInt(value.slice(offset, offset + 2), 16));
    const linear = channels.map((channel) => {
      const s = channel / 255;
      return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
    });
    const luminance = linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722;
    const foreground = luminance > 0.179 ? '0, 0, 0' : '255, 255, 255';
    const rgb = channels.join(', ');
    const dark = (factor) => channels.map((channel) => Math.round(channel * factor)).join(', ');
    style.textContent = `:root, body {
      --primary: ${rgb} !important;
      ${mirrorSecondary ? `--secondary: ${rgb} !important;` : ''}
      --theme-color: rgb(${rgb}) !important;
      --on-accent: ${foreground} !important;
      --dark-primary-1: ${dark(0.6)} !important;
      --dark-primary-2: ${dark(0.4)} !important;
    }`;
  }

  async function loadTheme(attempt = 0) {
    try {
      const response = await fetchTheme(`https://${resource}/sleeplessUiTheme`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: '{}',
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const theme = await response.json();
      applyPrimary(theme.primary);
    } catch (error) {
      if (attempt < 4) {
        setTimeout(() => loadTheme(attempt + 1), 250 * 2 ** attempt);
      } else {
        console.warn(`[${resource}] Unable to load UI accent; using the default palette.`, error);
      }
    }
  }

  if (isEnvBrowser()) {
    applyPrimary(new URLSearchParams(window.location.search).get('uiPrimary'));
  } else if (resource) {
    loadTheme();
  }
})();
