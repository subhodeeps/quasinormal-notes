/*
 * Sizes of the tiles on the home page after a sort (_plugins/home-tiles.rb).
 *
 * The plugin gives every tile of a page its size, squares (tile-small) and one pair of rectangles
 * (tile-wide), so that the grid closes in four columns and in two. The sort buttons of
 * assets/js/list-sort.js reorder the tiles, or put in the tiles of other pages, and then send the
 * event tiles:reorder; this script applies the same rule to the tiles in their new order. The rule
 * is the one of HomeTiles.sizes: a page of up to three tiles has squares only; otherwise the pair of
 * rectangles stands at the third place when half the tiles (rounded down to an even number) make an
 * even number of rows, and at the fifth place when they make an odd number.
 */
(() => {
  const grid = document.querySelector('#post-list .home-tiles');
  if (!grid) return;

  const sizes = (count) => {
    const kinds = Array(count).fill('tile-small');
    if (count < 4) return kinds;
    const even = count - (count % 2);
    const at = (even / 2) % 2 === 0 ? 2 : 4;
    kinds[at] = kinds[at + 1] = 'tile-wide';
    return kinds;
  };

  grid.addEventListener('tiles:reorder', () => {
    const tiles = [...grid.querySelectorAll(':scope > .tile')];
    const kinds = sizes(tiles.length);
    tiles.forEach((tile, i) => {
      tile.classList.remove('tile-small', 'tile-wide');
      tile.classList.add(kinds[i]);
    });
  });
})();
