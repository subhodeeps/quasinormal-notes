/*
 * Sort the posts of a category or a tag page (Chirpy's _layouts/category.html and tag.html) and
 * the tiles under "Explore" on the home page (_plugins/home-tiles.rb).
 *
 * Chirpy lists the posts newest first. This script adds four buttons above the list or the grid,
 * for the newest or the oldest post first and for titles from A to Z or from Z to A. The order by
 * date is Chirpy's own order or its reverse: Chirpy's date script removes the timestamps (data-ts)
 * from the page once it has formatted the dates, so the dates themselves cannot be read back.
 *
 * On a category or a tag page, the buttons reorder the items of the list in place. On a category
 * page, _plugins/category-tree.rb writes the date of creation and of the last change of each note
 * (data-created, data-updated). The buttons there are Updated and Created, newest first and,
 * after a second click, oldest first, then A–Z and Z–A, and first Reading order where some notes
 * of the category have an order of their own (data-order); Reading order is then the default, and
 * Updated otherwise. A category page with subcategories gets the same buttons, with Reading order
 * as the default, and sorts every list of its explorer, the lists of open folders included, with
 * the folders first, as a file explorer does: by the latest change or creation of the notes under
 * a folder, or by its name.
 *
 * The home page shows ten posts to a page, so its buttons sort the latest posts of all pages:
 * they load the tiles of every page from assets/data/home-tiles.json (the grid's data-all, which
 * the plugin writes), sort them, and show on each page the slice of the order that falls on it,
 * with as many tiles as Chirpy puts there. "Newest" brings back the page as Chirpy built it. If
 * the file cannot be loaded, the buttons sort the tiles of the page in view. The pinned posts
 * stay where they are. After a sort, the script asks assets/js/home-tiles.js to pack the grid
 * again (the event tiles:reorder) and MathJax to typeset the excerpts of the new tiles.
 *
 * The browser keeps the choice (localStorage), one each for the tag pages, the category pages, the
 * category pages with an order and the home page, so the next page opens in the same order.
 *
 * The script edits no layout of the theme. If a Chirpy release changes the markup of a list, it
 * finds nothing to sort and leaves the page as Chirpy renders it.
 */
(() => {
  const read = (key) => {
    try {
      return localStorage.getItem(key);
    } catch {
      return null;
    }
  };
  const write = (key, order) => {
    try {
      localStorage.setItem(key, order);
    } catch {
      // private windows may refuse storage; the order then lasts for this page only
    }
  };

  const byTitle = (a, b) => a.title.localeCompare(b.title, undefined, { sensitivity: 'base', numeric: true });
  // Chirpy's order, which is newest first, on a tag page and on the home page
  const byRank = (a, b) => a.rank - b.rank;
  const ORDERS = {
    newest: { label: 'Newest', compare: byRank },
    oldest: { label: 'Oldest', compare: (a, b) => byRank(b, a) },
    az: { label: 'A–Z', compare: byTitle },
    za: { label: 'Z–A', compare: (a, b) => byTitle(b, a) }
  };
  // A category page (_plugins/category-tree.rb): the order of a series, and the date of the last
  // change or of the creation, newest first and, after a second click, oldest first (dated)
  const CATEGORY = {
    order: { label: 'Reading order', compare: byRank },
    updated: { label: 'Updated', compare: (a, b) => b.updated - a.updated, dated: true },
    created: { label: 'Created', compare: (a, b) => b.created - a.created, dated: true },
    az: ORDERS.az,
    za: ORDERS.za
  };

  // The buttons above `container` for the orders of `orders`; `apply(compare)` shows the posts in
  // that order, and `first` is the default. A dated order is stored as "updated" or "updated-asc".
  function buttons(container, key, apply, first, orders = ORDERS) {
    const bar = document.createElement('div');
    bar.className = 'list-sort';
    bar.setAttribute('role', 'group');
    bar.setAttribute('aria-label', 'Sort the posts');
    let current = null;
    const all = Object.entries(orders).map(([order, { label }]) => {
      const button = document.createElement('button');
      button.type = 'button';
      button.dataset.order = order;
      button.textContent = label;
      button.addEventListener('click', () => {
        const flip = orders[order].dated && current === order;
        const choice = flip ? order + '-asc' : order;
        choose(choice);
        write(key, choice);
      });
      bar.append(button);
      return button;
    });
    function choose(choice) {
      const [order, asc] = choice.split('-');
      current = asc ? null : order;
      all.forEach((button) => {
        const on = button.dataset.order === order;
        button.setAttribute('aria-pressed', String(on));
        const { label, dated } = orders[button.dataset.order];
        button.textContent = on && dated ? `${label} ${asc ? '↑' : '↓'}` : label;
      });
      const { compare } = orders[order];
      apply(asc ? (a, b) => compare(b, a) : compare);
    }
    container.before(bar);
    const saved = read(key) || '';
    choose(orders[saved.split('-')[0]] ? saved : first);
  }

  // A category or a tag page: the items of its list, in place
  const list = document.querySelector('#page-category ul.content, #page-tag ul.content');
  if (list) {
    const items = [...list.children]
      .filter((li) => li.querySelector('a'))
      .map((node, rank) => ({
        node,
        rank,
        title: node.querySelector('a').textContent.trim(),
        updated: Date.parse(node.dataset.updated || '') || 0,
        created: Date.parse(node.dataset.created || '') || 0
      }));
    const apply = (compare) => list.append(...[...items].sort(compare).map((item) => item.node));
    if (items.length > 1 && items[0].node.dataset.created) {
      // A category page: Reading order only where some notes have one
      const ordered = items.some((item) => item.node.dataset.order !== undefined);
      const { order, ...rest } = CATEGORY;
      const orders = ordered ? CATEGORY : rest;
      buttons(list, ordered ? 'category-sort-ordered' : 'category-sort', apply, ordered ? 'order' : 'updated', orders);
    } else if (items.length > 1) {
      buttons(list, 'list-sort', apply, 'newest');
    }
  }

  // A category page with subcategories (the explorer of _plugins/category-tree.rb): every list in
  // it, the open folders' lists included, sorted with its folders first, as in a file explorer. A
  // folder carries the latest change and creation of the notes under it, and its name.
  const explorer = document.querySelector('#page-category ul.category-explorer');
  if (explorer) {
    const lists = [explorer, ...explorer.querySelectorAll('ul.category-tree')].map((ul) => ({
      ul,
      items: [...ul.children]
        .filter((li) => li.dataset.updated)
        .map((node, rank) => ({
          node,
          rank,
          folder: node.classList.contains('category-folder') ? 1 : 0,
          title: node.dataset.title || node.querySelector('a').textContent.trim(),
          updated: Date.parse(node.dataset.updated) || 0,
          created: Date.parse(node.dataset.created) || 0
        }))
    }));
    const apply = (compare) =>
      lists.forEach(({ ul, items }) => {
        const sorted = [...items].sort((a, b) => b.folder - a.folder || compare(a, b));
        ul.append(...sorted.map((item) => item.node));
      });
    if (lists.some(({ items }) => items.length > 1)) buttons(explorer, 'explorer-sort', apply, 'order', CATEGORY);
  }

  // The home page: the tiles of all its pages
  const grid = document.querySelector('#post-list .home-tiles');
  if (grid) {
    const own = [...grid.querySelectorAll(':scope > .tile')];
    const local = own.map((node, rank) => ({
      node,
      rank,
      title: (node.querySelector('.card-title')?.textContent || '').trim()
    }));
    const number = Number(location.pathname.match(/\/page(\d+)\/?$/)?.[1] || 1);
    let pages = null; // the tiles of every page, once loaded
    const load = () =>
      (pages ??= fetch(grid.dataset.all)
        .then((response) => (response.ok ? response.json() : Promise.reject(response.status)))
        .then((data) => data.pages)
        .catch(() => null));

    const show = (nodes) => {
      grid.replaceChildren(...nodes);
      grid.dispatchEvent(new CustomEvent('tiles:reorder'));
      if (window.MathJax?.typesetPromise) MathJax.typesetPromise([grid]).catch(() => {});
    };

    let latest = 0; // a later click wins over a slow load
    const apply = async (compare) => {
      const call = ++latest;
      if (compare === ORDERS.newest.compare) return show(own);
      const all = await load();
      if (call !== latest) return;
      if (!all) return show([...local].sort(compare).map((item) => item.node));

      // Every tile, in Chirpy's order, then the slice of the sorted order that falls on this page
      const tiles = all.flatMap((page) => page.tiles).map((tile, rank) => ({ ...tile, rank }));
      const before = all.filter((page) => page.page < number).reduce((sum, page) => sum + page.tiles.length, 0);
      const here = all.find((page) => page.page === number)?.tiles.length ?? own.length;
      const slice = tiles.sort(compare).slice(before, before + here);
      const holder = document.createElement('div');
      holder.innerHTML = slice.map((tile) => tile.html).join('');
      show([...holder.children]);
    };

    if (own.length > 1) buttons(grid, 'home-sort', apply, 'newest');
  }
})();
