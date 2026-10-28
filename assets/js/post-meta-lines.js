/*
 * The byline under the title of a post (Posted, Updated, By, read time) wraps on a phone, and the
 * dot that separates its items (a ::before of each item, _sass/_post-topics.scss and Chirpy) would
 * then start the new line on its own. This script marks the first item of every line after the first
 * with the class .meta-line-start and puts an empty full-width .meta-break before it, and
 * _sass/mobile/_components.scss hides the dot of a marked item on a narrow screen. It measures again when the byline changes size (a rotation, a resize, a late font).
 *
 * Markup it depends on: Chirpy's `header > .post-meta`, a flex row whose items are its children and
 * the children of its `.d-flex` blocks (made display: contents in _sass/_post-topics.scss). If the
 * byline is missing, the script does nothing. Loaded on posts only, from _includes/metadata-hook.html.
 */
(() => {
  const meta = document.querySelector('header > .post-meta');
  if (!meta) return;
  const items = [...meta.children].flatMap((el) => (el.classList.contains('d-flex') ? [...el.children] : [el]));
  if (items.length < 2) return;

  // Without its dot, a marked item may fit on the line above; a full-width break before it
  // (.meta-break) keeps the lines as they were measured
  function mark() {
    meta.querySelectorAll('.meta-break').forEach((br) => br.remove());
    items.forEach((el) => el.classList.remove('meta-line-start'));
    const tops = items.map((el) => el.getBoundingClientRect().top);
    items.forEach((el, i) => {
      if (i === 0 || tops[i] <= tops[i - 1] + 2) return;
      el.classList.add('meta-line-start');
      const br = document.createElement('span');
      br.className = 'meta-break';
      br.setAttribute('aria-hidden', 'true');
      el.before(br);
    });
  }

  mark();
  new ResizeObserver(mark).observe(meta);
})();
