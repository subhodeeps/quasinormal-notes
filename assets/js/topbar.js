/*
 * Two buttons for a phone (below 850 px): the theme beside the hamburger of the top bar, and, on a
 * post, the hamburger and the theme at the left of Chirpy's bar of contents.
 *
 * Theme: Chirpy keeps its switch in the sidebar (#mode-toggle, a menu of light, dark and system),
 * which a phone hides. The theme buttons turn the theme the page shows into the other one by pressing
 * the item of Chirpy's menu (.dropdown-item[data-theme-mode]), so that Chirpy stays the only code that
 * stores the theme. The hamburger of the bar of contents presses Chirpy's #sidebar-trigger.
 *
 * Bars: on a post Chirpy shows its bar of contents (#toc-bar: the title of the post and the button of
 * the table of contents) at the top once the head of the post has scrolled away, so that bar, with
 * the two buttons added at its left, is the one bar a phone keeps while scrolling. A page without it
 * keeps the top bar instead (_sass/_mobile.scss).
 *
 * Markup it depends on: #sidebar-trigger in the top bar, the items of the theme menu in the sidebar,
 * and on posts #toc-bar. A part whose markup is missing is left out. Loaded on every page from
 * _includes/metadata-hook.html.
 */
(() => {
  const trigger = document.getElementById('sidebar-trigger');
  if (!trigger) return;

  const button = (id, icon, label) => {
    const b = document.createElement('button');
    b.type = 'button';
    b.id = id;
    b.className = 'btn btn-link';
    b.innerHTML = `<i class="${icon} fa-fw" aria-hidden="true"></i>`;
    b.setAttribute('aria-label', label);
    return b;
  };

  const item = (mode) => document.querySelector(`.dropdown-item[data-theme-mode="${mode}"]`);
  const hasTheme = item('light') && item('dark');
  const shown = () =>
    document.documentElement.getAttribute('data-bs-theme') ||
    (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  const themeButton = (id) => {
    const b = button(id, 'fas fa-circle-half-stroke', '');
    const label = () => b.setAttribute('aria-label', shown() === 'dark' ? 'Switch to the light theme' : 'Switch to the dark theme');
    label();
    b.addEventListener('click', () => {
      item(shown() === 'dark' ? 'light' : 'dark').click();
      label();
    });
    return b;
  };

  // The top bar: the theme beside the hamburger
  if (hasTheme) trigger.after(themeButton('topbar-mode-toggle'));

  // The bar of contents of a post: the hamburger and the theme at its left
  const tocBar = document.getElementById('toc-bar');
  if (!tocBar) return;
  const side = button('toc-bar-sidebar', 'fas fa-bars', 'Sidebar');
  side.addEventListener('click', () => trigger.click());
  const group = document.createElement('div');
  group.className = 'toc-bar-buttons';
  group.append(side);
  if (hasTheme) group.append(themeButton('toc-bar-mode-toggle'));
  tocBar.prepend(group);
})();
