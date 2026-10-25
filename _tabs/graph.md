---
# the default layout is 'page'
title: Note Graph
icon: fas fa-diagram-project
order: 3
panel_graph: false # the page shows the whole graph, so the right panel leaves it out
---

This graph shows every note on the site, coloured by its category. A solid line joins two notes when one links to the other, and each tag is a small glowing circle, <span class="in-dark">gray with an amber glow</span><span class="in-light">eggshell with an orange ring and glow</span>, with dotted lines to its notes.

{% include notes-graph.html page=true %}

The graph turns slowly by itself, and you are welcome to play with it. Drag to move it, drag with Shift held down to turn it, scroll to zoom, and click a note or a tag once to select it and a second time to open it.

The legend below the graph filters the notes by category, and Tags only shows the tags on their own, joined by a line when they share at least two notes. The buttons in the corner of the graph zoom, reset the view, pause the turning and clear the filters.

## The idea behind the graph

The German sociologist Niklas Luhmann kept his notes on index cards in a set of wooden drawers, which he called his [Zettelkasten](https://en.wikipedia.org/wiki/Zettelkasten){:target="_blank" rel="noopener"}, or slip box. He wrote one idea on each card, gave every card an address, and wrote on it the addresses of the other cards it related to, so that over the forty-odd years he kept it, the box grew into a web of some 90,000 connected cards. Luhmann thought of the box as a partner in conversation. When he sat down to write, he followed the links from card to card, and he often ended up somewhere he had not planned to go. If you want to try the method yourself, the [overview at zettelkasten.de](https://zettelkasten.de/overview/){:target="_blank" rel="noopener"} is a good place to start. Abram Demski's [The Zettelkasten Method](https://www.lesswrong.com/posts/NfdHG6oHBJ8Qxc26s/the-zettelkasten-method-1){:target="_blank" rel="noopener"} on LessWrong describes how he keeps one and what it has done for his research, and Bob Doto has gathered his own [writing on the Zettelkasten](https://writing.bobdoto.computer/zettelkasten/){:target="_blank" rel="noopener"} on his site.

A whole family of note-taking software has grown out of this idea. [Roam Research](https://roamresearch.com){:target="_blank" rel="noopener"} made backlinks popular, where every note also lists the notes that point to it, so that you can follow a link in either direction. [Obsidian](https://obsidian.md){:target="_blank" rel="noopener"} keeps your notes as plain Markdown files in a folder on your own computer and draws the links between them as a graph, much like the one above. [Zettlr](https://www.zettlr.com){:target="_blank" rel="noopener"} is a free and open-source Markdown editor made with academic writing in mind, and it borrows Luhmann's habit of giving each note an ID and can cite straight from a Zotero library. I write these notes with [Foam](https://foambubble.github.io/foam/){:target="_blank" rel="noopener"}, which brings the same ideas to VS Code as an extension.

I should say that I do not keep a strict Zettelkasten here. Luhmann's cards each held a single idea, while most of my notes are longer pieces, closer to lecture notes, tutorials and reading lists in the traditional academic sense. I link them to each other whenever one note leads naturally to another, and the graph shows where those links have grown so far.

When people publish their linked notes on the web and keep tending them over time, the result is often called a digital garden, and my own collection of notes is something like one. A blog post is finished and dated, whereas a garden is allowed to stay a little messy, and its notes keep growing and changing as their author learns more. Maggie Appleton has written [a lovely history of the idea](https://maggieappleton.com/garden-history){:target="_blank" rel="noopener"}, if you are curious.

I am no gardener, though, and I tend to these notes only now and then. The neat, carefully pruned kind of garden has never quite been my thing, and bonsai, I suspect, is for older and more patient people. I have a soft spot for cosy woods and dense wilderness instead, where things grow as they please and you find your own way through. I would like these notes to feel a little more like that, simple and natural but with a bit of style. Be warned that the woods can be scary at night, and that rainforests can be downright terrifying even during the day!

There are a couple of good ways to grow such a garden with Jekyll. Maxime Vaillancourt's [Digital Garden Jekyll Template](https://github.com/maximevaillancourt/digital-garden-jekyll-template){:target="_blank" rel="noopener"} understands `[[wikilinks]]`, shows the backlinks under each note, and draws a graph of the notes. hikerpig's [foam-jekyll-template](https://github.com/hikerpig/foam-jekyll-template){:target="_blank" rel="noopener"} publishes a Foam workspace in a similar way, and the idea for this site came from it. On this site, Jekyll turns Foam's links into ordinary links when it builds the pages and lists under each post the notes that link to it, and a small script draws the graph above from the links and the tags.
