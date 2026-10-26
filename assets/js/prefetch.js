/*
 * Prefetches a page when the reader is about to open it, so that the next page appears at once.
 *
 * A finger on a link (touchstart) or a pointer that rests on it for 65 ms (mouseover) fetches the
 * page of an internal link in the background; the click that follows finds it in the cache. Browsers
 * that read speculation rules (Chromium) do this themselves from the rules in
 * _includes/metadata-hook.html, and this script leaves them alone. It also stays idle with the
 * data saver on and on a slow connection, and fetches no file but a page.
 */
(() => {
  if (HTMLScriptElement.supports?.('speculationrules')) return;
  const connection = navigator.connection;
  if (connection && (connection.saveData || /2g/.test(connection.effectiveType || ''))) return;

  const seen = new Set();
  let timer;

  const address = (event) => {
    const link = event.target.closest?.('a[href]');
    if (!link || link.target === '_blank' || link.hasAttribute('download')) return null;
    const url = new URL(link.href, location.href);
    if (url.origin !== location.origin || /\.[a-z0-9]{2,5}$/i.test(url.pathname)) return null;
    url.hash = '';
    return url.href === location.href.split('#')[0] ? null : url.href;
  };

  const prefetch = (href) => {
    if (seen.has(href)) return;
    seen.add(href);
    const link = document.createElement('link');
    if (link.relList?.supports?.('prefetch')) {
      link.rel = 'prefetch';
      link.href = href;
      document.head.append(link);
    } else {
      fetch(href, { credentials: 'same-origin', priority: 'low' }).catch(() => {});
    }
  };

  const options = { capture: true, passive: true };
  document.addEventListener('touchstart', (event) => {
    const href = address(event);
    if (href) prefetch(href);
  }, options);
  document.addEventListener('mouseover', (event) => {
    const href = address(event);
    if (href) timer = setTimeout(() => prefetch(href), 65);
  }, options);
  document.addEventListener('mouseout', () => clearTimeout(timer), options);
})();
