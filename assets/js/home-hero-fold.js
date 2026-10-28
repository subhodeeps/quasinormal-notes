/*
 * Fold of the home hero on a phone or a tablet (max-width 991.98px, the breakpoint of
 * _sass/_motion.scss and _sass/_mobile.scss).
 *
 * The hero (_includes/home-hero.html) is a figure, a tagline and an intro line. On a narrow screen
 * the figure and the intro line are folded away behind the button "Know more", so that the posts
 * show on the first screen: the script hides them (the `hidden` attribute), shows the button
 * (.home-hero-toggle) and sets aria-expanded and aria-controls. A reload always starts folded: nothing
 * is stored. On a wide screen the button stays hidden and everything shows, as before. Without
 * JavaScript the hero is complete, since the folding is done here and not in the CSS.
 *
 * After every change the script sends the event `hero:toggle` (detail.open) on #home-hero.
 * assets/js/home-hero-pocket.js waits for it, so that the animation is fetched and started on the
 * first opening only, and stops when the hero is folded (its canvas leaves the screen).
 *
 * Markup it depends on: #home-hero, with .home-hero-toggle (a button), .home-hero-figure and
 * .home-hero-subtext. If the button or the parts are missing, it leaves the hero as it is.
 * This script must come before home-hero-pocket.js in the page; both are deferred and run in
 * the order of the page.
 */
(() => {
  const hero = document.getElementById('home-hero');
  const button = hero && hero.querySelector('.home-hero-toggle');
  const parts = hero ? [...hero.querySelectorAll('.home-hero-figure, .home-hero-subtext')] : [];
  if (!button || !parts.length) return;

  const phone = window.matchMedia('(max-width: 991.98px)');
  const label = button.querySelector('.home-hero-toggle-label');
  parts.forEach((part, i) => {
    if (!part.id) part.id = `home-hero-part-${i + 1}`;
  });
  button.setAttribute('aria-controls', parts.map((part) => part.id).join(' '));

  function show(open) {
    parts.forEach((part) => {
      part.hidden = !open;
    });
    button.setAttribute('aria-expanded', String(open));
    label.textContent = open ? 'Hide' : 'Know more';
    hero.dispatchEvent(new CustomEvent('hero:toggle', { detail: { open } }));
  }

  function apply() {
    button.hidden = !phone.matches;
    hero.classList.toggle('is-folded', phone.matches);
    show(!phone.matches);
  }

  button.addEventListener('click', () => show(button.getAttribute('aria-expanded') !== 'true'));
  phone.addEventListener('change', apply);
  apply();
})();
