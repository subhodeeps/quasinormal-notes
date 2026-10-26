# Quasinormal Notes

The source of [Quasinormal Notes](https://quasinormal-notes.vercel.app), my notes on theoretical physics, numerical methods and programming. The site is built with [Jekyll](https://jekyllrb.com) and the [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy/) theme, and Vercel deploys it from `main`.

## Running the site

```shell
bash tools/setup.sh          # once; installs Ruby, Node and the gems in .venv/
source .venv/bin/activate
bash tools/run.sh -d         # preview at http://127.0.0.1:4000, drafts included
```

`tools/stop.sh` stops the preview, `tools/test.sh` builds the site and checks it with html-proofer, and `tools/new-note.sh name` starts a private note.

## Writing

Published notes are in `_posts/`. Unfinished ones are in `_drafts/`, a separate private repository that the site does not build for the public (`git clone git@github.com:subhodeeps/quasinormal-notes-private-notes.git _drafts`, then `ln -s _drafts/.claude .claude` so that Claude Code finds its rules). To publish a draft, move it to `_posts/YYYY-MM-DD-slug.md` and move its files from `_drafts/_includes/` and `_drafts/assets/` to the same places at the root.

The categories of a note are a path from the general to the specific, such as `[Physics, Black Holes, Black Hole Shadows]`. **How to choose categories, `also_in`, `order` and tags: [docs/categories-and-tags.md](docs/categories-and-tags.md)**, and `ruby tools/categories.rb` prints the current tree. Notes link to each other with `[[slug]]`, and the build turns these into links, backlinks and the graph. Figures, tables and citations follow the examples in the existing posts. The citations come from `_bibliography/references.bib`.

## Changes to Chirpy

Two theme files are replaced: `assets/css/jekyll-theme-chirpy.scss` and `_includes/metadata-hook.html`. Everything else is a new file, so that Chirpy updates merge without conflicts.

| Folder | New files |
| --- | --- |
| `_plugins/` | home page, wikilinks and graph data, the category tree (`category-tree.rb`), post head and panel, drafts, references (`jhep.rb`), footer and page titles |
| `_sass/` | one partial for each feature, and the colours in `amore/` |
| `assets/js/` | note graph, home page tiles, sort buttons, lightbox |
| `_includes/`, `_tabs/` | hero, footer, backlinks, graph, the Note Graph tab |
| `docs/` | notes on writing for the site, such as the guide to categories and tags, mirrored in the wiki by `tools/docs-to-wiki.rb` |
| `tools/` | setup and run scripts, the category tree (`categories.rb`), push to the ThinkPad, style sheet for calibre, bibliography check |

## Credits

[Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy/) by Cotes Chung; [Foam](https://foambubble.github.io/foam/) and [foam-jekyll-template](https://github.com/hikerpig/foam-jekyll-template) by hikerpig; Obsidian's [Graph view](https://obsidian.md/help/plugins/graph); [jekyll-scholar](https://github.com/inukshuk/jekyll-scholar); [JHEP.bst](https://jhep.sissa.it/jhep/help/JHEP/TeXclass/DOCS/JHEP.bst); [INSPIRE](https://inspirehep.net); [JetBrains Mono](https://www.jetbrains.com/lp/mono/).

The code is under the [MIT License](LICENSE).
