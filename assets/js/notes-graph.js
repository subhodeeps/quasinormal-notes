/*
 * The note graph in the right panel and on the Graph tab (_includes/notes-graph.html), from
 * assets/data/notes-graph.json (_plugins/notes-graph.rb).
 *
 * Nodes are posts, coloured by their subject, their first category. A draft, a stub or a
 * private note, which the local preview shows, takes the colour of its subject too, with a
 * dashed ring around the node (stage in the data). Solid edges are links between notes,
 * wikilinks or ordinary links, and dotted edges join notes that share tags. A node grows with
 * the number of its links. Hovering a node highlights it and its neighbours and shows its
 * title, and a click opens it. On a touch screen, which has no hover, the first tap on a node
 * shows its title and the second opens it.
 *
 * The layout is a small force simulation. Every pair of notes repels, links and shared tags
 * pull like springs, and a weak pull holds the whole near the centre. It runs in full before
 * the first frame and starts from positions seeded by the names of the notes, so the same notes
 * always land in the same place. Nodes are solid: each sits on a disc of the background colour,
 * so a faded node hides the lines behind it and does not show them through.
 *
 * The right panel is a quiet map of where a note sits, beside the text it accompanies.
 *
 * - The layout is flat and holds still, since motion or depth would compete with the text.
 * - On a post, the post and the notes it links to or from appear at full strength. The notes
 *   one link further away, and the notes that share a primary tag with the post, appear
 *   faintly (FAR). They give the wider context without asking for attention. On other pages
 *   the panel shows every note with its links only. With every note in view, tag edges would
 *   cover the links.
 * - A tag edge appears only for a primary tag that both notes share. The primary tags say what
 *   a note is about: primary_tags in its front matter, at most three, or else its first two
 *   tags. Minor tags, such as a tool or an operating system, would join almost every note to
 *   every other and bury the links. A tag edge also gives way to a link between the same two
 *   notes, which says more. On a post, every tag edge starts at the post, so the panel shows
 *   how this note relates to the others by topic. A primary tag shared by many notes, such as
 *   black-holes, would otherwise draw a line between every two of them.
 * - The panel has no legend. Hovering a node gives its title, and the Graph tab explains the
 *   colours.
 *
 * The Graph tab is the full picture, inspired by Obsidian's Graph view and Foam's Graph Visualization.
 *
 * - Every tag has a node of its own, a small disc in the muted text colour
 *   with a warm amber glow (--graph-tag-glow), sized by the number of its notes and joined to them by dotted
 *   lines. Tags thus need
 *   no line between every two notes that share them, which grew as the square of the number of
 *   notes and left out the broadest tags, and a tag such as black-holes becomes a hub that the
 *   notes on that subject gather around. Hovering a tag node shows the tag and its number of
 *   notes, and a click on it opens the tag's page (tag_url in _plugins/notes-graph.rb), in two
 *   steps as for a note.
 * - A first click on a note or a tag selects it: the graph stops turning, and the node keeps
 *   its title and its highlight after the pointer moves on. A second click opens its page, and
 *   a click on empty space or Escape clears the selection. The right panel, which holds still,
 *   opens a note on the first click. The tag nodes
 *   keep the colour neutral, since colour stands for the category of a note, and their glow
 *   sets them apart from the notes.
 * - A click on a category in the legend shows only the notes of that category, with the tags
 *   they share; further clicks add or remove categories, and removing the last one shows every
 *   note again. In the local preview, a second row of the legend filters by stage in the same
 *   way: Published, Draft, To Write (the stubs) and Private (_plugins/draft-category.rb). A note
 *   is shown when it passes both rows, so Physics and Draft together show the physics drafts. A
 *   click on Tag hides or shows the tags. The filter only fades the rest of the graph, so the
 *   layout stays as it is. Every entry of the legend that is in view sits on a pill, all of them
 *   while nothing is filtered, and the entries the filter leaves out fade. The
 *   last button in the corner of the graph clears the filter and the selected tag at once.
 * - A click on Tags only turns the graph into a map of the subjects. It hides the notes and
 *   their links and joins two tags by a line when they share at least two notes, as heavy as
 *   the number of notes they share. The tags keep the places they have among their notes. A tag
 *   on more than TAG_HUB notes, such as black-holes, would join almost every other tag, so it
 *   draws no line, and a tag without a partner that shares two notes has none either. Both
 *   stay in view, a little faded (WEAK), and a click on any tag still opens its page, so the map
 *   also works as a table of contents. The category and stage filters then choose the tags of
 *   those notes, and a click on Tag or on the clear button brings the notes back.
 * - It shows every note and every edge in three dimensions and in perspective, and it turns
 *   slowly, so that the depth reads without any interaction. Notes farther back fade a little,
 *   a second cue for depth, and nodes are drawn from back to front.
 * - The forces differ from the flat ones. Notes repel more strongly, since three dimensions
 *   have more room. Tag springs are weaker and longer, because the many shared tags would
 *   otherwise pull the notes into one clump. The pull to the centre is firmer and brings loosely
 *   linked notes in from the edge. On the notes of this site, these choices give a rounder and
 *   more even cloud with fewer stragglers, and linked notes still sit closer together than
 *   unlinked ones.
 * - Before the first frame, the simulation runs on at the strength it has while a note is
 *   pulled (HEAT) until it comes to rest (SETTLE). A pull then moves only the pulled note and the
 *   notes it drags along, and the graph springs back after it (HOLD).
 * - The layout is turned so that its longest extent lies across the screen and its shortest
 *   stands upright, along the eigenvectors of the spread of the notes. The graph spins about
 *   this shortest axis and fills a wide canvas at every angle of the turn.
 * - The starting zoom is the largest at which every note stays inside the canvas through a
 *   full turn of the spin, at the starting tilt and in perspective. The graph opens large and
 *   never leaves the frame.
 * - The interaction follows Obsidian. A drag on empty space moves the graph, and a drag on a
 *   note pulls it, so that its links stretch and take its colour and its neighbours follow. A
 *   drag with Shift or the right button turns the graph about the axes of the screen, all the
 *   way round. On a touch screen, one finger moves the graph or pulls a note, and two fingers
 *   zoom and turn it. The wheel, a pinch, the + and - keys or the buttons in its corner zoom,
 *   and the arrow keys move the graph.
 *
 * Colours come from CSS variables set per theme in _sass/amore: --graph-node-<category>
 * (e.g. --graph-node-physics), --graph-node for other categories, --graph-edge,
 * --graph-edge-faint and --graph-current. They are read again when the theme changes.
 */
(() => {
  const LINK_LENGTH = 30; // rest length of the springs, in layout units
  const TAG_LENGTH = 60;
  const TAG_LENGTH_3D = 80; // on the Graph tab, where weak, long tag springs give a rounder, even spread
  const MEMBER_LENGTH = 45; // from a note to a tag node, on the Graph tab
  const TAG_GLOW = 14; // px: the blur of the warm glow around a tag node
  const ITERATIONS = 400;
  const HIT = 9; // px: how close the pointer must be to a node
  const HIT_TOUCH = 18; // px: the same, for a finger
  const PITCH = 0.35; // rad: the starting tilt of the 3D view
  const SPIN = 0.0025; // rad per frame: how fast the 3D view turns by itself
  const HEAT = 0.3; // strength of the live simulation on the Graph tab, as alpha in step()
  const SETTLE = 3000; // steps at that strength before the Graph tab draws, so the graph starts at rest
  const HOLD = 120; // frames the simulation stays at full strength after a pull, so the graph springs back
  const [ZOOM_MIN, ZOOM_MAX] = [0.5, 4];
  const FAR = 0.4; // opacity of the notes and edges that the panel draws faintly
  const HIDDEN = 0.06; // opacity of the notes that the legend's filter leaves out
  const TAG_HUB = 15; // a tag on more notes than this draws no line on the tag map (TAG_HUB_LIMIT in _plugins/notes-graph.rb)
  const WEAK = 0.5; // opacity of a tag without a line on the tag map

  document.querySelectorAll('.notes-graph').forEach((section) => {
    fetch(section.querySelector('canvas').dataset.src)
      .then((res) => res.json())
      .then((data) => start(section, data))
      .catch(() => section.remove()); // no graph is better than a broken one
  });

  const slugify = (s) => s.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-');
  const clamp = (v, lo, hi) => Math.min(Math.max(v, lo), hi);

  // 3 x 3 rotation matrices, stored by rows: about the vertical axis y and the horizontal axis x
  const rotY = (a) => [Math.cos(a), 0, Math.sin(a), 0, 1, 0, -Math.sin(a), 0, Math.cos(a)];
  const rotX = (a) => [1, 0, 0, 0, Math.cos(a), -Math.sin(a), 0, Math.sin(a), Math.cos(a)];
  const times = (a, b) =>
    Array.from({ length: 9 }, (_, k) => {
      const [i, j] = [Math.floor(k / 3), k % 3];
      return a[3 * i] * b[j] + a[3 * i + 1] * b[3 + j] + a[3 * i + 2] * b[6 + j];
    });

  // Rounding errors pile up over many small turns; Gram-Schmidt on the rows keeps the matrix a rotation
  function orthonormal(m) {
    const unit = (v) => v.map((c) => c / Math.hypot(...v));
    const dot = (u, v) => u[0] * v[0] + u[1] * v[1] + u[2] * v[2];
    const a = unit(m.slice(0, 3));
    const b0 = m.slice(3, 6);
    const b = unit(b0.map((c, i) => c - dot(a, b0) * a[i]));
    const c = [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
    return [...a, ...b, ...c];
  }

  // A small deterministic random generator, seeded from a string
  function seeded(text) {
    let h = 2166136261;
    for (const ch of text) h = Math.imul(h ^ ch.charCodeAt(0), 16777619);
    return () => {
      h = Math.imul(h ^ (h >>> 15), 2246822507);
      h = Math.imul(h ^ (h >>> 13), 3266489909);
      return ((h ^= h >>> 16) >>> 0) / 4294967296;
    };
  }

  // The eigenvalues and eigenvectors of a symmetric 3 x 3 matrix, by Jacobi rotations, largest first
  function eigen(matrix) {
    const a = matrix.map((row) => [...row]);
    const v = [[1, 0, 0], [0, 1, 0], [0, 0, 1]];
    for (let sweep = 0; sweep < 50; sweep++) {
      let [p, q] = [0, 1];
      for (const [i, j] of [[0, 2], [1, 2]]) if (Math.abs(a[i][j]) > Math.abs(a[p][q])) [p, q] = [i, j];
      if (Math.abs(a[p][q]) < 1e-12) break;
      const theta = (a[q][q] - a[p][p]) / (2 * a[p][q]);
      const t = (theta < 0 ? -1 : 1) / (Math.abs(theta) + Math.sqrt(theta * theta + 1));
      const c = 1 / Math.sqrt(t * t + 1);
      const s = t * c;
      const turn = (m, k, i, j) => {
        const [x, y] = [m[k][i], m[k][j]];
        [m[k][i], m[k][j]] = [c * x - s * y, s * x + c * y];
      };
      for (let k = 0; k < 3; k++) turn(a, k, p, q);
      for (let k = 0; k < 3; k++) {
        const [x, y] = [a[p][k], a[q][k]];
        [a[p][k], a[q][k]] = [c * x - s * y, s * x + c * y];
      }
      for (let k = 0; k < 3; k++) turn(v, k, p, q);
    }
    return [0, 1, 2]
      .map((i) => ({ value: a[i][i], vector: [v[0][i], v[1][i], v[2][i]] }))
      .sort((x, y) => y.value - x.value);
  }

  // Turn the 3D layout so that its longest extent lies across the screen and its shortest
  // stands upright: the graph spins about its shortest axis and fills a wide canvas. A
  // rotation about the centre changes no distance between notes
  function alignAxes(nodes) {
    const mean = (key) => nodes.reduce((s, n) => s + n[key], 0) / nodes.length;
    const c = [mean('x'), mean('y'), mean('z')];
    const p = nodes.map((n) => [n.x - c[0], n.y - c[1], n.z - c[2]]);
    const cov = [0, 1, 2].map((i) => [0, 1, 2].map((j) => p.reduce((s, q) => s + q[i] * q[j], 0) / p.length));
    const [long, middle, short] = eigen(cov).map((e) => e.vector);
    const third = [
      long[1] * short[2] - long[2] * short[1],
      long[2] * short[0] - long[0] * short[2],
      long[0] * short[1] - long[1] * short[0]
    ]; // long x short, so that the turn keeps the handedness of the layout
    const sign = third[0] * middle[0] + third[1] * middle[1] + third[2] * middle[2] < 0 ? -1 : 1;
    const rows = [long, short, third.map((v) => v * sign)];
    nodes.forEach((n, i) => {
      [n.x, n.y, n.z] = rows.map((r) => c[0] + r[0] * p[i][0] + r[1] * p[i][1] + r[2] * p[i][2]);
    });
  }

  // The notes and edges to show, and the notes to draw faintly (far). The Graph tab shows them
  // all. The panel keeps a tag edge only for a primary tag that both notes share, and only
  // where no link joins the two notes already. On a post it shows the post with the notes it
  // links to or from, and faintly the notes one link further away and the notes that share a
  // primary tag with it. Its tag edges then all start at the post. On other pages the panel
  // shows every note with its links, and no tag edges
  function subgraph(data, current, panel) {
    const primary = new Map(data.nodes.map((n) => [n.id, n.primary || []]));
    const pair = (e) => [e.source, e.target].sort().join('|');
    const linked = new Set(data.edges.filter((e) => e.kind === 'link').map(pair));
    const sharesPrimary = (e) =>
      (e.tags || []).some((tag) => primary.get(e.source).includes(tag) && primary.get(e.target).includes(tag));
    const edges = panel
      ? data.edges.filter((e) => e.kind === 'link' || (sharesPrimary(e) && !linked.has(pair(e))))
      : data.edges;
    const far = new Set();
    if (!panel) return { ...withTags(data), far };
    if (!current || !data.nodes.some((n) => n.id === current)) {
      return { nodes: data.nodes, edges: edges.filter((e) => e.kind === 'link'), far };
    }

    const linkNeighbours = (ids) =>
      edges
        .filter((e) => e.kind === 'link' && (ids.has(e.source) || ids.has(e.target)))
        .flatMap((e) => [e.source, e.target]);
    const near = new Set([current, ...linkNeighbours(new Set([current]))]);
    const keep = new Set([...near, ...linkNeighbours(near)]);
    edges
      .filter((e) => e.kind === 'tag' && (e.source === current || e.target === current))
      .forEach((e) => keep.add(e.source === current ? e.target : e.source));
    keep.forEach((id) => near.has(id) || far.add(id));
    const fromPost = (e) => e.kind === 'link' || e.source === current || e.target === current;
    return {
      nodes: data.nodes.filter((n) => keep.has(n.id)),
      edges: edges.filter((e) => keep.has(e.source) && keep.has(e.target) && fromPost(e)),
      far
    };
  }

  // The Graph tab: the notes and their links, and a node for every tag, including a tag of one note,
  // joined to each of its notes by a member edge, in place of the edges between notes that share
  // a tag
  function withTags(data) {
    const members = new Map();
    for (const n of data.nodes) for (const tag of n.tags || []) members.set(tag, [...(members.get(tag) || []), n.id]);
    const tags = [...members];
    return {
      nodes: [
        ...data.nodes,
        ...tags.map(([tag, ids]) => ({
          id: `tag:${tag}`,
          kind: 'tag',
          title: tag,
          count: ids.length,
          url: (data.tags || {})[tag] || null
        }))
      ],
      edges: [
        ...data.edges.filter((e) => e.kind === 'link'),
        ...tags.flatMap(([tag, ids]) => ids.map((id) => ({ source: id, target: `tag:${tag}`, kind: 'member' })))
      ]
    };
  }

  // With depth, the nodes start off the plane and the forces act in three dimensions; without
  // it, z stays zero and the layout is the flat one
  function layout(nodes, edges, depth) {
    const random = seeded(nodes.map((n) => n.id).join('|'));
    const byId = new Map(nodes.map((n) => [n.id, n]));
    nodes.forEach((n, i) => {
      const angle = (2 * Math.PI * i) / nodes.length + random() * 0.5;
      const radius = 40 + random() * 40;
      const z = depth ? (random() - 0.5) * 80 : 0;
      Object.assign(n, { x: Math.cos(angle) * radius, y: Math.sin(angle) * radius, z, vx: 0, vy: 0, vz: 0 });
    });
    const springs = edges
      .map((e) => [byId.get(e.source), byId.get(e.target), e])
      .filter(([a, b]) => a && b);

    for (let i = 0; i < ITERATIONS; i++) step(nodes, springs, depth, 1 - i / ITERATIONS);
    return springs;
  }

  // One step of the force simulation, with the forces scaled by alpha. The layout runs it
  // ITERATIONS times with alpha falling to zero; on the Graph tab it runs again while a note is
  // pulled, so that the links stretch and the neighbours follow
  function step(nodes, springs, depth, alpha) {
    for (let i = 0; i < nodes.length; i++) {
      for (let j = i + 1; j < nodes.length; j++) {
        const a = nodes[i];
        const b = nodes[j];
        let dx = b.x - a.x;
        let dy = b.y - a.y;
        let dz = b.z - a.z;
        const d2 = Math.max(dx * dx + dy * dy + dz * dz, 1);
        // 3D has more room, so push harder; a tag node pushes half as hard, so that it settles
        // among its notes instead of at the edge of the graph
        const soft = a.kind === 'tag' || b.kind === 'tag' ? 0.5 : 1;
        const f = ((depth ? 3000 : 900) / d2) * alpha * soft;
        const d = Math.sqrt(d2);
        dx /= d;
        dy /= d;
        dz /= d;
        a.vx -= dx * f;
        a.vy -= dy * f;
        a.vz -= dz * f;
        b.vx += dx * f;
        b.vy += dy * f;
        b.vz += dz * f;
      }
    }
    for (const [a, b, e] of springs) {
      const link = e.kind === 'link';
      const member = e.kind === 'member';
      const rest = link ? LINK_LENGTH : member ? MEMBER_LENGTH : depth ? TAG_LENGTH_3D : TAG_LENGTH;
      const k = (link ? 0.08 : member ? 0.02 : (depth ? 0.004 : 0.015) * (e.weight || 1)) * alpha;
      const dx = b.x - a.x;
      const dy = b.y - a.y;
      const dz = b.z - a.z;
      const d = Math.max(Math.hypot(dx, dy, dz), 0.01);
      const f = (d - rest) * k;
      a.vx += (dx / d) * f;
      a.vy += (dy / d) * f;
      a.vz += (dz / d) * f;
      b.vx -= (dx / d) * f;
      b.vy -= (dy / d) * f;
      b.vz -= (dz / d) * f;
    }
    const pull = depth ? 0.04 : 0.02; // in 3D a firmer pull keeps loosely linked notes close
    for (const n of nodes) {
      n.vx = (n.vx - n.x * pull * alpha) * 0.6;
      n.vy = (n.vy - n.y * pull * alpha) * 0.6;
      n.vz = (n.vz - n.z * pull * alpha) * 0.6;
      n.x += n.vx;
      n.y += n.vy;
      n.z += n.vz;
    }
  }

  function start(section, data) {
    const canvas = section.querySelector('canvas');
    const legend = section.querySelector('.notes-graph-legend');
    const current = canvas.dataset.current || null;
    const big = section.classList.contains('notes-graph-page'); // the Graph tab: larger and in 3D
    const { nodes, edges, far } = subgraph(data, current, !big);
    if (!nodes.length) return section.remove();
    const byId = new Map(nodes.map((n) => [n.id, n]));
    const springs = layout(nodes, edges, big);
    // On the Graph tab the simulation comes alive when a note is pulled; let it come to rest
    // first, so that a pull moves only the pulled note and the notes it drags along
    if (big) {
      for (let i = 0; i < SETTLE; i++) step(nodes, springs, true, HEAT);
      alignAxes(nodes);
    }

    const degree = new Map(nodes.map((n) => [n.id, 0]));
    const neighbours = new Map(nodes.map((n) => [n.id, new Set()]));
    for (const [a, b, e] of springs) {
      if (e.kind === 'link') {
        degree.set(a.id, degree.get(a.id) + 1);
        degree.set(b.id, degree.get(b.id) + 1);
      }
      neighbours.get(a.id).add(b.id);
      neighbours.get(b.id).add(a.id);
    }

    // The tag map: a line between two tags that share at least two notes, as heavy as the number
    // of notes they share. A tag without a line, a hub or a tag that shares no two notes with
    // another, is weak and is drawn fainter. The notes of a tag are its neighbours, since only
    // member edges meet a tag
    const tagNodes = nodes.filter((n) => n.kind === 'tag');
    const tagEdges = [];
    const partners = new Map(tagNodes.map((n) => [n.id, new Set()]));
    tagNodes.forEach((a, i) => {
      for (const b of tagNodes.slice(i + 1)) {
        if (a.count > TAG_HUB || b.count > TAG_HUB) continue;
        const shared = [...neighbours.get(a.id)].filter((id) => neighbours.get(b.id).has(id)).length;
        if (shared < 2) continue;
        tagEdges.push([a, b, shared]);
        partners.get(a.id).add(b.id);
        partners.get(b.id).add(a.id);
      }
    });
    const weak = new Set(tagNodes.filter((n) => !partners.get(n.id).size).map((n) => n.id));

    // Legend: the categories in view and, in the local preview, the stages of the notes, each a
    // button that filters the graph, and a button that hides or shows the tags. The stages sit on
    // a row of their own; a solid disc marks the published notes, and a dot in a dashed ring, as
    // in the graph, the others, both drawn at the same size
    const categories = [...new Set(nodes.map((n) => n.category).filter(Boolean))].sort();
    const stageOf = (n) => n.stage || 'Published';
    const stages = ['Published', 'Draft', 'To Write', 'Private'].filter((st) =>
      nodes.some((n) => n.kind !== 'tag' && stageOf(n) === st)
    );
    const ring =
      '<svg class="ring" viewBox="0 0 16 16" aria-hidden="true">' +
      '<circle cx="8" cy="8" r="3.2" fill="currentColor"/>' +
      '<circle cx="8" cy="8" r="6.2" fill="none" stroke="currentColor" stroke-width="1.3" stroke-dasharray="2.4 1.8"/>' +
      '</svg>';
    const solid =
      '<svg class="ring" viewBox="0 0 16 16" aria-hidden="true"><circle cx="8" cy="8" r="5.6" fill="currentColor"/></svg>';
    const tagMapKey =
      '<svg class="ring" viewBox="0 0 16 16" aria-hidden="true">' +
      '<line x1="4" y1="12" x2="12" y2="4" stroke="currentColor" stroke-width="1.3"/>' +
      '<circle cx="4" cy="12" r="2.6" fill="currentColor"/><circle cx="12" cy="4" r="2.6" fill="currentColor"/></svg>';
    const button = (group, value, key, title) =>
      `<li><button type="button" class="on" data-filter="${group}" data-value="${value}" aria-pressed="false" ` +
      `title="${title}">${key}${value}</button></li>`;
    if (legend) {
      legend.innerHTML =
        categories
          .map((c) =>
            button('category', c, `<span class="dot" data-category="${slugify(c)}"></span>`,
              `Show only the notes in ${c}, or add them to the notes shown`)
          )
          .join('') +
        (nodes.some((n) => n.kind === 'tag')
          ? '<li><button type="button" class="on" data-filter="tags" aria-pressed="true" title="Hide or show the tags">' +
            '<span class="tag-key"></span>Tag</button></li>' +
            '<li><button type="button" data-filter="tagmap" aria-pressed="false" ' +
            'title="Show only the tags, joined when they share at least two notes">' +
            `${tagMapKey}Tags only</button></li>`
          : '') +
        (stages.length > 1
          ? '<li class="legend-break" aria-hidden="true"></li>' +
            stages
              .map((st) =>
                button('stage', st, st === 'Published' ? solid : ring,
                  `Show only the ${st === 'To Write' ? 'stubs' : `${st.toLowerCase()} notes`}, or add them to the notes shown`)
              )
              .join('')
          : '');
    }

    const ctx = canvas.getContext('2d');
    let colours = {};
    let hover = null;
    let selected = null; // the node clicked last on the Graph tab, which stays highlighted until it is cleared
    const focus = () => hover || selected;
    let touch = false; // whether the last pointer was a finger
    // The legend's filter: the categories and the stages to show (an empty set means all), and
    // whether to show the tags. A note must pass both sets, and a tag stays in view while one of
    // its notes does
    const filters = { category: new Set(), stage: new Set() };
    let showTags = true;
    let tagsOnly = false; // the tag map: no notes, and the tags joined by the notes they share
    let shown = new Set(nodes.map((n) => n.id));
    const passes = (n) =>
      (!filters.category.size || filters.category.has(n.category)) &&
      (!filters.stage.size || filters.stage.has(stageOf(n)));
    const isShown = (n) =>
      n.kind === 'tag'
        ? (showTags || tagsOnly) && [...neighbours.get(n.id)].some((id) => passes(byId.get(id)))
        : !tagsOnly && passes(n);
    // What lights up with the node in focus: the notes and tags it is joined to, and on the tag
    // map, the tags it shares notes with
    const adjacent = (id) => (tagsOnly ? partners.get(id) || new Set() : neighbours.get(id));
    let view = { scale: 1, ox: 0, oy: 0, cx: 0, cy: 0, cz: 0, r: 0 }; // r > 0 once the 3D view fits
    // m: how the 3D view is turned, a rotation matrix; px, py: how far it is moved, in px
    let turn = { m: rotX(PITCH), zoom: 1, px: 0, py: 0 };
    const proj = new Map(); // node -> where it is drawn: x, y, depth z and perspective factor f
    const dpr = () => window.devicePixelRatio || 1;
    // For a tag node, the radius of its disc, which grows with the number of its notes
    const radius = (n) =>
      (n.kind === 'tag'
        ? 1.8 + Math.sqrt(n.count) * 0.55
        : n.id === current
          ? 5.5
          : 3.2 + Math.sqrt(degree.get(n.id)) * 1.2) * (big ? 1.6 * proj.get(n).f * Math.sqrt(turn.zoom) : 1);
    const short = (title, max) => (title.length > max ? `${title.slice(0, max - 2)}…` : title);

    function readColours() {
      const css = getComputedStyle(section);
      const get = (name, fallback) => css.getPropertyValue(name).trim() || fallback;
      colours = {
        node: get('--graph-node', '#768594'),
        edge: get('--graph-edge', '#c2c9d1'),
        faint: get('--graph-edge-faint', 'rgba(194, 201, 209, 0.45)'),
        current: get('--graph-current', '#67428a'),
        tag: get('--text-muted-color', '#768594'),
        glow: get('--graph-tag-glow', '#d39b3c'),
        text: get('--text-color', '#28313d'),
        bg: get('--main-bg', '#ffffff'),
        font: css.fontFamily || 'sans-serif',
        category: Object.fromEntries(
          categories.map((c) => [c, get(`--graph-node-${slugify(c)}`, get('--graph-node', '#768594'))])
        )
      };
      legend?.querySelectorAll('.dot[data-category]').forEach((dot, i) => {
        dot.style.background = colours.category[categories[i]];
      });
    }

    legend?.addEventListener('click', (event) => {
      const pressed = event.target.closest('button[data-filter]');
      if (!pressed) return;
      const { filter: group, value } = pressed.dataset;
      if (group === 'tagmap') {
        tagsOnly = !tagsOnly;
        if (tagsOnly) showTags = true;
      } else if (group === 'tags') {
        if (tagsOnly) tagsOnly = false; // back to the notes, with their tags
        else showTags = !showTags;
      } else if (filters[group].has(value)) {
        filters[group].delete(value);
      } else {
        filters[group].add(value);
      }
      refilter();
    });

    // Mark the legend's buttons as the filter stands, and work out which nodes it shows. An entry
    // in view sits on a pill (on), as every entry does while nothing is filtered, and an entry
    // that the filter leaves out fades (off)
    function refilter() {
      legend?.querySelectorAll('button[data-filter]').forEach((b) => {
        if (b.dataset.filter === 'tagmap') {
          // A mode and not a filter: a pill while it is on, and none otherwise
          b.setAttribute('aria-pressed', String(tagsOnly));
          b.classList.toggle('on', tagsOnly);
          return;
        }
        const tags = b.dataset.filter === 'tags';
        const set = filters[b.dataset.filter];
        const pressed = tags ? showTags : set.has(b.dataset.value);
        const inView = tags ? showTags : !set.size || pressed;
        b.setAttribute('aria-pressed', String(pressed));
        b.classList.toggle('on', inView);
        b.classList.toggle('off', !inView);
      });
      shown = new Set(nodes.filter(isShown).map((n) => n.id));
      if (hover && !shown.has(hover.id)) hover = null;
      if (selected && !shown.has(selected.id)) selected = null;
      draw();
    }

    function fit() {
      const w = canvas.clientWidth;
      const h = canvas.clientHeight;
      canvas.width = Math.round(w * dpr());
      canvas.height = Math.round(h * dpr());
      if (big) {
        // The 3D view turns about the centre of the notes. The scale is the largest at which every
        // note stays inside the canvas through a whole turn of the spin, at the starting tilt and
        // in perspective, so the graph starts as large as it can
        const mean = (key) => nodes.reduce((s, n) => s + n[key], 0) / nodes.length;
        const [cx, cy, cz] = [mean('x'), mean('y'), mean('z')];
        const r = Math.max(...nodes.map((n) => Math.hypot(n.x - cx, n.y - cy, n.z - cz)), 1);
        let [ex, ey] = [1, 1]; // the half-width and half-height the notes reach, in layout units
        for (let k = 0; k < 72; k++) {
          const m = times(rotX(PITCH), rotY((2 * Math.PI * k) / 72));
          for (const n of nodes) {
            const [x, y, z] = [n.x - cx, n.y - cy, n.z - cz];
            const f = (3 * r) / (3 * r + m[6] * x + m[7] * y + m[8] * z);
            ex = Math.max(ex, Math.abs(m[0] * x + m[1] * y + m[2] * z) * f);
            ey = Math.max(ey, Math.abs(m[3] * x + m[4] * y + m[5] * z) * f);
          }
        }
        const pad = w < 500 ? 24 : 40;
        view = { scale: Math.min((w / 2 - pad) / ex, (h / 2 - pad) / ey), ox: w / 2, oy: h / 2, cx, cy, cz, r };
        return;
      }
      const xs = nodes.map((n) => n.x);
      const ys = nodes.map((n) => n.y);
      const [x0, x1, y0, y1] = [Math.min(...xs), Math.max(...xs), Math.min(...ys), Math.max(...ys)];
      const pad = 14;
      const scale = Math.min((w - 2 * pad) / Math.max(x1 - x0, 1), (h - 2 * pad) / Math.max(y1 - y0, 1), 3);
      view = { ...view, scale, ox: w / 2 - ((x0 + x1) / 2) * scale, oy: h / 2 - ((y0 + y1) / 2) * scale };
    }

    // Turn the 3D layout by the matrix turn.m, and look at it from a distance of three radii;
    // z grows away from the viewer
    function project() {
      if (!big) {
        for (const n of nodes) proj.set(n, { x: n.x * view.scale + view.ox, y: n.y * view.scale + view.oy, z: 0, f: 1 });
        return;
      }
      const m = turn.m;
      const distance = 3 * view.r;
      for (const n of nodes) {
        const [x, y, z] = [n.x - view.cx, n.y - view.cy, n.z - view.cz];
        const x1 = m[0] * x + m[1] * y + m[2] * z;
        const y1 = m[3] * x + m[4] * y + m[5] * z;
        const z1 = m[6] * x + m[7] * y + m[8] * z;
        const f = distance / (distance + z1);
        const s = view.scale * turn.zoom * f;
        proj.set(n, { x: view.ox + turn.px + x1 * s, y: view.oy + turn.py + y1 * s, z: z1, f });
      }
    }

    const screen = (n) => [proj.get(n).x, proj.get(n).y];
    // Notes at the back of the 3D view fade a little, so the eye reads the depth
    const depth = (z) => (big ? 0.55 + 0.45 * clamp((view.r - z) / (2 * view.r), 0, 1) : 1);

    function draw() {
      if (big && !view.r) return;
      project();
      const s = dpr();
      ctx.setTransform(s, 0, 0, s, 0, 0);
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      // The note or tag under the pointer is highlighted with its neighbours, and otherwise the
      // selected tag
      const lit = focus() ? adjacent(focus().id) : null;
      const dim = (id) => focus() && id !== focus().id && !lit.has(id);

      if (tagsOnly) {
        // The tag map: a solid line for each pair of tags, heavier for more shared notes
        for (const [a, b, shared] of tagEdges) {
          if (!shown.has(a.id) || !shown.has(b.id)) continue;
          const [ax, ay] = screen(a);
          const [bx, by] = screen(b);
          const f = focus();
          const glow = f && (a === f || b === f);
          ctx.globalAlpha = (f && !glow ? 0.25 : 1) * depth((proj.get(a).z + proj.get(b).z) / 2);
          ctx.strokeStyle = glow ? colours.tag : colours.edge;
          ctx.lineWidth = (0.6 + 0.7 * Math.min(shared, 8)) * (big ? 1.25 : 1);
          ctx.beginPath();
          ctx.moveTo(ax, ay);
          ctx.lineTo(bx, by);
          ctx.stroke();
        }
      }
      for (const [a, b, e] of tagsOnly ? [] : springs) {
        if (!shown.has(a.id) || !shown.has(b.id)) continue;
        const [ax, ay] = screen(a);
        const [bx, by] = screen(b);
        const link = e.kind === 'link';
        const fade = depth((proj.get(a).z + proj.get(b).z) / 2);
        // On the Graph tab, the links of the note under the pointer take its colour
        const f = focus();
        const glow = big && f && (a === f || b === f);
        const remote = far.has(a.id) || far.has(b.id) ? FAR : 1;
        ctx.globalAlpha = (f && !(a === f || b === f) ? 0.25 : 1) * fade * remote;
        const glowColour = f?.kind === 'tag' ? colours.tag : colours.category[f?.category] || colours.node;
        ctx.strokeStyle = glow ? glowColour : link ? colours.edge : colours.faint;
        ctx.lineWidth = glow ? 2 : (link ? 1.2 : 0.8) * (big ? 1.25 : 1);
        ctx.setLineDash(link ? [] : [2, 3]);
        ctx.beginPath();
        ctx.moveTo(ax, ay);
        ctx.lineTo(bx, by);
        ctx.stroke();
      }
      ctx.setLineDash([]);

      // From the back to the front, so that nearer notes cover farther ones
      const order = big ? [...nodes].sort((a, b) => proj.get(b).z - proj.get(a).z) : nodes;
      for (const n of order) {
        const [x, y] = screen(n);
        if (n.kind === 'tag') {
          if (shown.has(n.id)) tagNode(n, x, y, dim(n.id), tagsOnly && weak.has(n.id) && n !== focus());
          continue;
        }
        if (tagsOnly) continue; // the tag map has no notes, not even faint ones
        const hidden = !shown.has(n.id); // left out by the legend's filter: a faint dot, no ring
        ctx.beginPath();
        ctx.arc(x, y, radius(n), 0, 2 * Math.PI);
        // A disc in the background colour first, so that a faded node hides the lines behind it
        ctx.globalAlpha = 1;
        ctx.fillStyle = colours.bg;
        ctx.fill();
        ctx.globalAlpha = (hidden ? HIDDEN : dim(n.id) ? 0.3 : 1) * depth(proj.get(n).z) * (far.has(n.id) ? FAR : 1);
        ctx.fillStyle = colours.category[n.category] || colours.node;
        ctx.fill();
        if (hidden) continue;
        if (n.stage) {
          // A dashed ring in the colour of the note marks a draft, a stub or a private note
          ctx.strokeStyle = colours.category[n.category] || colours.node;
          ctx.lineWidth = big ? 1.4 : 1;
          ctx.setLineDash(big ? [3, 2.5] : [2, 2]);
          ctx.beginPath();
          ctx.arc(x, y, radius(n) + (big ? 3 : 2.5), 0, 2 * Math.PI);
          ctx.stroke();
          ctx.setLineDash([]);
          ctx.beginPath();
          ctx.arc(x, y, radius(n), 0, 2 * Math.PI);
        }
        if (big) {
          // A ring in the background colour lifts the node off the lines that meet it
          ctx.strokeStyle = colours.bg;
          ctx.lineWidth = 2;
          ctx.stroke();
          if (n === hover || n === selected) {
            ctx.strokeStyle = colours.category[n.category] || colours.node;
            ctx.lineWidth = 1.5;
            ctx.beginPath();
            ctx.arc(x, y, radius(n) + 4, 0, 2 * Math.PI);
            ctx.stroke();
          }
        }
        if (n.id === current) {
          ctx.strokeStyle = colours.current;
          ctx.lineWidth = 1.5;
          ctx.beginPath();
          ctx.arc(x, y, radius(n) + 3, 0, 2 * Math.PI);
          ctx.stroke();
        }
      }
      ctx.globalAlpha = 1;

      if (selected && selected !== hover) label(selected);
      if (hover) label(hover);
    }

    // A tag node: a disc in the muted text colour with a warm glow around it. A disc of the
    // background colour goes first, so that the node hides the lines behind it, and a ring marks
    // it while the pointer rests on it
    function tagNode(n, x, y, faded, weakTag) {
      const r = radius(n);
      const disc = (grow) => {
        ctx.beginPath();
        ctx.arc(x, y, r + grow, 0, 2 * Math.PI);
      };
      const alpha = (faded ? 0.3 : weakTag ? WEAK : 1) * depth(proj.get(n).z);
      ctx.globalAlpha = 1;
      ctx.fillStyle = colours.bg;
      disc(1);
      ctx.fill();
      ctx.save();
      ctx.shadowColor = colours.glow;
      ctx.shadowBlur = TAG_GLOW * (big ? proj.get(n).f * Math.sqrt(turn.zoom) : 1);
      ctx.globalAlpha = alpha * 0.9; // the glow: the shadow of a disc in the glow colour, laid on twice
      ctx.fillStyle = colours.glow;
      disc(0);
      ctx.fill();
      ctx.fill();
      ctx.restore();
      ctx.globalAlpha = alpha;
      ctx.fillStyle = colours.tag;
      disc(0);
      ctx.fill();
      if (n === hover || n === selected) {
        ctx.strokeStyle = colours.tag;
        ctx.lineWidth = 1.5;
        disc(4);
        ctx.stroke();
      }
    }

    // The title of a node, or the name of a tag and its number of notes, on the page's
    // background, kept inside the canvas
    function label(n) {
      const [x, y] = screen(n);
      ctx.font = `${big ? '600 13px' : '12px'} ${colours.font}`;
      const w = canvas.clientWidth;
      const text = n.kind === 'tag' ? `${n.title} · ${n.count} ${n.count === 1 ? 'note' : 'notes'}` : short(n.title, 42);
      const tw = ctx.measureText(text).width;
      const lx = clamp(x - tw / 2, 2, w - tw - 2);
      const ly = y - radius(n) - 6 < 12 ? y + radius(n) + 14 : y - radius(n) - 6;
      ctx.fillStyle = colours.bg;
      ctx.globalAlpha = 0.85;
      ctx.fillRect(lx - 3, ly - 11, tw + 6, 15);
      ctx.globalAlpha = 1;
      ctx.fillStyle = colours.text;
      ctx.fillText(text, lx, ly);
    }

    // The nearest node under the pointer; in 3D, the frontmost one wins a tie
    function nodeAt(event) {
      const rect = canvas.getBoundingClientRect();
      const px = event.clientX - rect.left;
      const py = event.clientY - rect.top;
      let best = null;
      let bestD = touch ? HIT_TOUCH : HIT;
      for (const n of nodes) {
        if (!shown.has(n.id)) continue;
        const [x, y] = screen(n);
        const d = Math.hypot(x - px, y - py) - radius(n);
        if (d < bestD || (d === bestD && best && proj.get(n).z < proj.get(best).z)) [best, bestD] = [n, d];
      }
      return best;
    }

    // The 3D view: turning by itself, by hand, moving, zooming, and pulling notes
    let spinning = false;
    let frame = null;
    let heat = 0; // strength of the live simulation: HEAT during a pull and HOLD frames after, then it cools
    let hold = 0;
    let grab = null; // the note being pulled: { node, z: its depth, off: pointer offset in px, target }
    let mode = null; // what a drag does: 'pull', 'pan', 'turn' or, with two fingers, 'pinch'
    const spinButton = section.querySelector('[data-graph="spin"]');

    function setSpin(on) {
      spinning = on;
      if (spinButton) {
        spinButton.querySelector('i').className = on ? 'fas fa-pause' : 'fas fa-play';
        spinButton.setAttribute('aria-label', on ? 'Stop turning' : 'Start turning');
        spinButton.title = spinButton.getAttribute('aria-label');
      }
      if (on) wake();
    }

    const wake = () => {
      if (!frame) frame = requestAnimationFrame(tick);
    };

    // The view holds still while the pointer rests on a note, so that its title can be read
    function tick() {
      frame = null;
      const live = heat > 0.005;
      if (!spinning && !live) return;
      if (live) {
        for (let i = 0; i < 2; i++) {
          step(nodes, springs, true, heat);
          if (grab) pin();
        }
        if (grab) hold = HOLD;
        heat = hold-- > 0 ? HEAT : heat * 0.97;
      }
      const turning = spinning && !hover;
      // About the layout's own vertical axis, like a globe, whichever way the view is tilted
      if (turning) turn.m = orthonormal(times(turn.m, rotY(SPIN)));
      if (live || turning) draw();
      frame = requestAnimationFrame(tick);
    }

    // The pulled note sits where the pointer holds it
    function pin() {
      const n = grab.node;
      [n.x, n.y, n.z] = grab.target;
      n.vx = n.vy = n.vz = 0;
    }

    // Move the pulled note to the pointer, at the depth where it was picked up: undo the
    // perspective, then the turn (the transpose of a rotation is its inverse)
    function pullTo(event) {
      const rect = canvas.getBoundingClientRect();
      const s = view.scale * turn.zoom * ((3 * view.r) / (3 * view.r + grab.z));
      const x = (event.clientX - rect.left - grab.off[0] - view.ox - turn.px) / s;
      const y = (event.clientY - rect.top - grab.off[1] - view.oy - turn.py) / s;
      const [z, m] = [grab.z, turn.m];
      grab.target = [
        view.cx + m[0] * x + m[3] * y + m[6] * z,
        view.cy + m[1] * x + m[4] * y + m[7] * z,
        view.cz + m[2] * x + m[5] * y + m[8] * z
      ];
      pin();
      heat = HEAT;
      wake();
    }

    // About the axes of the screen, so that the view follows the pointer and turns all the way
    // round in every direction, upside down included
    function turnBy(dx, dy) {
      turn.m = orthonormal(times(times(rotX(dy * 0.008), rotY(dx * 0.008)), turn.m));
    }

    function zoomBy(k) {
      turn.zoom = clamp(turn.zoom * k, ZOOM_MIN, ZOOM_MAX);
      draw();
    }

    const pointers = new Map(); // the pointers down on the 3D canvas: id -> last position
    let travel = 0; // px the pointers moved since they went down; a drag is not a click

    function drag(event) {
      const [px, py] = pointers.get(event.pointerId);
      const [qx, qy] = [event.clientX, event.clientY];
      pointers.set(event.pointerId, [qx, qy]);
      if (mode === 'pinch') {
        if (pointers.size < 2) return;
        const [ox, oy] = [...pointers].find(([id]) => id !== event.pointerId)[1];
        zoomBy(Math.hypot(qx - ox, qy - oy) / Math.max(Math.hypot(px - ox, py - oy), 1));
        turnBy((qx - px) / 2, (qy - py) / 2); // the point between the fingers moves half as far
        travel += 10;
        draw();
        return;
      }
      travel += Math.hypot(qx - px, qy - py);
      if (travel <= 4) return; // still a click
      canvas.style.cursor = 'grabbing';
      if (mode === 'pull') {
        hover = grab.node;
        pullTo(event);
      } else if (mode === 'turn') {
        turnBy(qx - px, qy - py);
      } else {
        turn.px += qx - px;
        turn.py += qy - py;
      }
      draw();
    }

    // A finger cannot hover, and it leaves the canvas at the end of every tap, so only taps
    // move the highlight on a touch screen
    canvas.addEventListener('pointerdown', (event) => {
      touch = event.pointerType === 'touch';
      if (!big) return;
      pointers.set(event.pointerId, [event.clientX, event.clientY]);
      canvas.setPointerCapture(event.pointerId);
      setSpin(false);
      if (pointers.size > 1) {
        // A second finger: pinch to zoom and turn, and let go of the note
        grab = null;
        mode = 'pinch';
        return;
      }
      travel = 0;
      const n = nodeAt(event);
      if (n) {
        const rect = canvas.getBoundingClientRect();
        const [x, y] = screen(n);
        grab = { node: n, z: proj.get(n).z, off: [event.clientX - rect.left - x, event.clientY - rect.top - y] };
        mode = 'pull';
      } else {
        mode = event.shiftKey || event.button === 2 ? 'turn' : 'pan';
      }
    });
    canvas.addEventListener('pointermove', (event) => {
      touch = event.pointerType === 'touch';
      if (big && pointers.has(event.pointerId)) return drag(event);
      if (touch) return;
      const n = nodeAt(event);
      canvas.style.cursor = n ? 'pointer' : big ? 'grab' : 'default';
      if (n === hover) return;
      hover = n;
      draw();
    });
    const release = (event) => {
      pointers.delete(event.pointerId);
      if (!big) return;
      if (!pointers.size) {
        grab = null; // the note springs back as the simulation cools
        mode = null;
        if (touch && travel > 4) hover = null;
      }
      if (!touch) canvas.style.cursor = 'grab';
    };
    canvas.addEventListener('pointerup', release);
    canvas.addEventListener('pointercancel', release);
    canvas.addEventListener('pointerleave', (event) => {
      if (event.pointerType === 'touch') return;
      hover = null;
      canvas.style.cursor = 'default';
      draw();
    });
    canvas.addEventListener('click', (event) => {
      if (big && travel > 4) return;
      const n = nodeAt(event);
      // On the Graph tab, the first click on a note or a tag selects it: the graph stops turning,
      // and the node keeps its title and its highlight. The second click opens its page, and a
      // click on empty space clears the selection
      if (big) {
        if (n && n !== selected) {
          selected = n;
          setSpin(false);
          draw();
        } else if (n?.url) {
          window.location.href = n.url;
        } else if (!n && selected) {
          selected = null;
          draw();
        }
        return;
      }
      if (touch && n !== hover) {
        hover = n;
        draw();
        return;
      }
      if (n && n.id !== current && n.url) window.location.href = n.url;
    });

    if (big) {
      canvas.addEventListener(
        'wheel',
        (event) => {
          event.preventDefault();
          zoomBy(Math.exp(-event.deltaY * 0.0015));
        },
        { passive: false }
      );
      // The graph turns when the page opens, unless the reader's system asks for less motion,
      // and both reset buttons bring it back to that state
      const restartSpin = () => setSpin(!window.matchMedia('(prefers-reduced-motion: reduce)').matches);
      const actions = {
        'zoom-in': () => zoomBy(1.25),
        'zoom-out': () => zoomBy(0.8),
        reset: () => {
          turn = { m: rotX(PITCH), zoom: 1, px: 0, py: 0 };
          restartSpin();
          draw();
        },
        spin: () => setSpin(!spinning),
        // Clear the legend's filter and the selected tag, and show the notes and the tags again
        clear: () => {
          filters.category.clear();
          filters.stage.clear();
          showTags = true;
          tagsOnly = false;
          selected = null;
          restartSpin();
          refilter();
        }
      };
      section.querySelectorAll('[data-graph]').forEach((button) => {
        button.addEventListener('click', () => actions[button.dataset.graph]());
      });
      // As in Obsidian, + and - zoom and the arrow keys move the graph, once the canvas has the focus
      const keys = {
        '+': () => zoomBy(1.25),
        '=': () => zoomBy(1.25),
        '-': () => zoomBy(0.8),
        ArrowLeft: () => (turn.px += 40),
        ArrowRight: () => (turn.px -= 40),
        ArrowUp: () => (turn.py += 40),
        ArrowDown: () => (turn.py -= 40)
      };
      canvas.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && selected) {
          selected = null;
          draw();
          return;
        }
        const key = keys[event.key];
        if (!key || event.metaKey || event.ctrlKey || event.altKey) return;
        event.preventDefault(); // the arrow keys would scroll the page
        setSpin(false);
        key();
        draw();
      });
      canvas.addEventListener('contextmenu', (event) => event.preventDefault()); // right-drag turns
      canvas.style.cursor = 'grab';
      restartSpin();
    }

    readColours();
    new ResizeObserver(() => {
      fit();
      draw();
    }).observe(canvas);
    document.fonts.ready.then(draw); // the labels use the page's web font

    const recolour = () => {
      readColours();
      draw();
    };
    new MutationObserver(recolour).observe(document.documentElement, { attributeFilter: ['data-bs-theme'] });
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', recolour);
  }
})();
