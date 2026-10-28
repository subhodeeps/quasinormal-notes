/*
 * A citation in a post, such as [4], shows its reference in a floating band under it before it follows
 * the link. A mouse pointer resting on the citation opens the band, and so does a tap on a touch
 * screen or Tab onto the citation. A second click or tap on the same citation, which the band shows is
 * open, follows the link to the list of references. Without the script, the first tap would jump to
 * the list and the reader would lose the place in the text.
 *
 * The band is a copy of the entries of the list (ol.bibliography > li) that the citation numbers: its
 * text is read from the label [n] of each entry, so a grouped citation such as [28, 29] or [1–3] shows
 * every entry (jekyll-scholar links such a group to its first entry only), and the href is the
 * fallback. The copy is an `ol.bibliography.citation-band` at the end of the post's `div.content`, so
 * that _sass/_bibliography.scss and the reference sizes of _sass/_reading.scss and _sass/mobile/_type.scss
 * apply to it as they do to the list, and _sass/_citation-band.scss adds only the box. The band is
 * positioned in absolute coordinates, below the last line of the citation or above its first line when
 * the viewport has no room below, and as wide as the column of the text (at most 40 rem).
 *
 * Markup it depends on: jekyll-scholar's `a.citation[href^="#"]`, and the entries `ol.bibliography
 * > li` with a `.bib-label` ([n]) from the template in _config.yml (scholar, bibliography_template).
 * A citation without an entry, or a page without `div.content`, is left to the browser. Loaded on
 * posts only, from _includes/metadata-hook.html. The inline script there that opens a folded box
 * around the target of a link still runs on the second click, since this script stops the first
 * click in the capture phase, before that script sees it.
 */
(() => {
  const CITATION = 'a.citation[href^="#"]';
  const HIDE_DELAY = 150; // ms, so that a pointer can cross the gap between a citation and its band
  const GAP = 6; // px between a citation and its band
  const TOP_BAR = 56; // px of the bar that stays at the top of a phone, kept clear when the band opens above

  if (!document.querySelector(CITATION)) return;

  let band = null; // the floating ol.bibliography.citation-band
  let current = null; // the citation whose reference the band shows
  let byKeyboard = false; // the band was opened by Tab onto the citation
  let hideTimer = 0;
  let entries = null; // the entries of the list by their label, [n]

  const citationAt = (node) => (node instanceof Element ? node.closest(CITATION) : null);
  const inBand = (node) => band !== null && node instanceof Node && band.contains(node);

  // The numbers a citation shows, [28, 29] -> 28, 29 and [1–3] -> 1, 2, 3
  function numbersOf(link) {
    const numbers = [];
    for (const part of link.textContent.replace(/[[\]\s]/g, '').split(',')) {
      const [from, to = from] = part.split(/[–-]/).map((n) => Number.parseInt(n, 10));
      if (!(to >= from) || to - from > 50) return [];
      for (let n = from; n <= to; n += 1) numbers.push(n);
    }
    return numbers;
  }

  // The entries of the list that a citation points to, in the order of its numbers
  function entriesOf(link) {
    if (!entries) {
      entries = new Map();
      document.querySelectorAll('ol.bibliography > li').forEach((li) => {
        const label = li.querySelector('.bib-label');
        if (label) entries.set(label.textContent.trim(), li);
      });
    }
    const found = numbersOf(link)
      .map((n) => entries.get(`[${n}]`))
      .filter(Boolean);
    if (found.length) return found;
    const target = document.getElementById(decodeURIComponent(link.getAttribute('href').slice(1)));
    const entry = target && target.closest('ol.bibliography > li');
    return entry ? [entry] : [];
  }

  function createBand() {
    const el = document.createElement('ol');
    el.className = 'bibliography citation-band';
    el.id = 'citation-band';
    el.hidden = true;
    return el;
  }

  // Puts the band below the last line of the link, or above its first line if the viewport has no room
  // below. The band is positioned in the coordinates of whatever contains it, found by measuring where
  // it lands at left 0, top 0.
  function place(link, content) {
    const column = content.getBoundingClientRect();
    const rects = link.getClientRects();
    const first = rects[0];
    const last = rects[rects.length - 1];
    band.style.width = `${column.width}px`;
    band.style.left = '0px';
    band.style.top = '0px';
    const origin = band.getBoundingClientRect();
    const below = last.bottom + GAP;
    const above = first.top - GAP - origin.height;
    const top = below + origin.height > window.innerHeight && above >= TOP_BAR ? above : below;
    band.style.left = `${column.left - origin.left}px`;
    band.style.top = `${top - origin.top}px`;
  }

  function hide() {
    clearTimeout(hideTimer);
    if (!current) return;
    current.removeAttribute('aria-describedby');
    current = null;
    byKeyboard = false;
    band.hidden = true;
  }

  // Shows the band for a citation, and reports whether it has an entry to show
  function show(link) {
    const content = link.closest('div.content');
    const found = content ? entriesOf(link) : [];
    if (!found.length) return false;
    clearTimeout(hideTimer);
    if (current) current.removeAttribute('aria-describedby');
    band = band || createBand();
    band.replaceChildren(
      ...found.map((li) => {
        const copy = li.cloneNode(true);
        copy.querySelectorAll('[id]').forEach((el) => el.removeAttribute('id'));
        return copy;
      }),
    );
    content.append(band);
    band.hidden = false;
    current = link;
    link.setAttribute('aria-describedby', band.id);
    place(link, content);
    return true;
  }

  // A mouse or a pen opens the band on arriving and closes it a moment after leaving. A touch has no
  // hover, so the click handler below opens it.
  document.addEventListener('pointerover', (event) => {
    if (event.pointerType === 'touch') return;
    const link = citationAt(event.target);
    if (link && link !== current) {
      show(link);
    } else if (link || inBand(event.target)) {
      clearTimeout(hideTimer);
    }
  });

  document.addEventListener('pointerout', (event) => {
    if (event.pointerType === 'touch' || !current) return;
    if (!citationAt(event.target) && !inBand(event.target)) return;
    const to = event.relatedTarget;
    if (to instanceof Node && (current.contains(to) || band.contains(to))) return;
    hideTimer = setTimeout(hide, HIDE_DELAY);
  });

  // The first click or tap opens the band, and the second on the same citation follows the link. A
  // click with a modifier key or a middle button is left to the browser.
  document.addEventListener(
    'click',
    (event) => {
      const link = citationAt(event.target);
      if (!link || event.defaultPrevented) return;
      if (event.button || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
      if (current === link) {
        hide();
      } else if (show(link)) {
        event.preventDefault();
        event.stopPropagation();
      }
    },
    true,
  );

  // Tab onto a citation opens the band, and Enter then follows the link. A link that a click or a tap
  // focuses is not :focus-visible, so a tap does not open the band before its click arrives.
  document.addEventListener('focusin', (event) => {
    const link = citationAt(event.target);
    if (link && link !== current && link.matches(':focus-visible') && show(link)) byKeyboard = true;
  });

  document.addEventListener('focusout', (event) => {
    if (byKeyboard && citationAt(event.target) === current && !inBand(event.relatedTarget)) hide();
  });

  document.addEventListener('pointerdown', (event) => {
    if (current && !citationAt(event.target) && !inBand(event.target)) hide();
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') hide();
  });

  // The page reflows after a rotation or a late font, and the band moves with its citation
  new ResizeObserver(() => {
    if (current) place(current, band.parentElement);
  }).observe(document.body);
})();
