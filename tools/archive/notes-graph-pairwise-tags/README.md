# The note graph with pairwise tag edges

This folder keeps the version of the note graph that the site used until 25 October 2026, at commit `43b9e09` of the main repository. Jekyll excludes `tools/`, so none of these files is loaded or published.

In this version, the Graph tab drew a faint dotted line between every two notes that share a tag, as the right panel still does for primary tags. A tag on *k* notes thus drew k(k − 1)/2 lines, and a tag on more than 15 notes drew none (`TAG_HUB_LIMIT` in `notes-graph.rb`), so the broadest tags, such as `black-holes`, did not appear in the graph at all. The legend listed the categories without links. The current version gives every tag on two or more notes a square node on the Graph tab, joined by dotted lines to its notes, and a click on a category in the legend filters the graph.

| File | Place in the site |
| --- | --- |
| `notes-graph.rb` | `_plugins/notes-graph.rb` |
| `notes-graph.js` | `assets/js/notes-graph.js` |
| `notes-graph.html` | `_includes/notes-graph.html` |
| `_notes-graph.scss` | `_sass/_notes-graph.scss` |
| `graph.md` | `_tabs/graph.md` |

To restore this version, copy each file back to its place, restart the preview (`bash tools/run.sh -d`), since Jekyll loads plugins only at start-up, and reload the page with Cmd+Shift+R. The five files belong together and should be restored as a set.
