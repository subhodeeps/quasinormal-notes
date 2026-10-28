# Categories and Tags

Every note on the site is filed twice. Its categories put it in one place of a tree of subjects, which the Categories tab and the category pages show, and its tags name everything it is about, which the note graph draws. This page explains how to fill in both when writing a new note.

## 1. Front matter

The fields sit in the front matter of the note, next to the title:

```yaml
categories: [Physics, Black Holes, Black Hole Shadows]
also_in: [[Physics, General Relativity], [Physics, Classical Mechanics]]
order: 1
tags: [black-hole-shadows, hamiltonian-mechanics, geodesics, general-relativity, julia]
primary_tags: [hamiltonian-mechanics, geodesics]
```

Only `categories` and `tags` are needed. `also_in`, `order` and `primary_tags` are optional.

## 2. Categories

`categories` is a path from the general to the specific: the primary category (Physics, Coding, Code Carpentry, Homelab, Personal), then a secondary one, then, if needed, a tertiary one. The note above lives in Black Hole Shadows, inside Black Holes, inside Physics. The path may be as deep as the subject needs, although three levels have been enough so far.

1. Choose categories by subject. The kind of note (tutorial, project, paper notes, guide) is not a category; the old categories of that kind were replaced in October 2026.
2. Give each category one place in the tree. The site builds one page for each name, so a name under two parents would mix both on one page, and the build warns about it.
3. Reuse an existing category before making a new one, and make a subcategory when a category grows past ten or so notes of a distinct subject, or when a series starts.
4. The first category colours the note in the graph and on the home page, so it is always one of the primary categories.
5. Never write a stage (Draft, To Write, Private) in `categories`. The site works out the stage from the folder of the note.

## 3. Further places: `also_in`

A note that is equally at home in a second subject gets that path in `also_in`: one path as a list (`also_in: [Coding, Julia]`) or several as a list of lists, as in the example. The note then appears on the pages of those categories too, and its post header shows all its paths. Typical cases are notes on a general method that a series needs (the Hamilton–Jacobi formalism in the shadow series is also Classical Mechanics) and notes whose code is the point (the Julia ray tracer is also Coding › Julia). The main path in `categories` remains the place where a reader would look first.

## 4. Order: `order`

`order` gives the place of a note among the notes of its own category, the last name of `categories`, as in a series. The hub of a series takes 0, and its parts follow in reading order. Notes without `order` come after the ordered ones, newest first. A number between two others, such as 2.5, inserts a note without renumbering the rest. To see the numbers in use, run `ruby tools/categories.rb --notes`.

## 5. Pinned categories and their order

Categories themselves have no files, so their pins, their order and their descriptions sit in `_data/categories.yml`, under their names:

```yaml
Physics:
  pin: true
  order: 1
  description: Black holes, general relativity, classical mechanics and quantum gravity.
```

A description is one plain line. It appears under the title of the category's page and, for a pinned category, on its card on the home page, where the pinned categories and the pinned notes open the grid, each with a thumbtack.

On the Categories tab, in the folders of a category page and in `ruby tools/categories.rb`, pinned categories come first and carry a thumbtack, then the categories with an `order`, then the rest alphabetically. Any category of any level can appear in the file; `order` ranks a category among its siblings only. The build warns about a name in the file that no note uses.

## 6. Tags

Tags follow the science. They name the objects, the subjects, the methods and the tools of a note, in lowercase words joined by hyphens: `kerr-black-holes`, `quasinormal-modes`, `ray-tracing`, `julia`.

1. Reuse an existing tag where it fits. `ruby tools/categories.rb --tags` lists every tag with the number of its notes.
2. Add every tag that a reader might look for; four to eight tags are typical.
3. Never merge or drop tags to make the graph tidier. A tag on one note is fine when the note is about it.
4. `primary_tags`, one to three tags, say what the note is mainly about. The note graph in the right panel joins two notes that share a primary tag. Without `primary_tags`, the first two tags count, except for a tag on more than 15 notes, so a note whose subject is a broad tag (such as `black-hole-shadows`) names it in `primary_tags`.

## 7. Seeing the current tree

The Categories tab of the preview (`bash tools/run.sh -d`) shows the whole tree, drafts included, with the deeper levels in folders that open on a click. A category page with subcategories shows them as folders, each of which opens on its subtopics and its notes in order, and then the notes filed in the category itself; a category without subcategories lists its notes in order. Every note there shows the date of its last change, marked Updated, or else of its creation, marked Created. The last change is `last_modified_at` in the front matter of the note, which you set by hand when you revise it (`last_modified_at: 2026-10-26 12:00:00 +0530`); Chirpy shows the same date as Updated on the post itself. The buttons above the list, and above the folders of a category with subcategories, sort by reading order (the order of a series, and pinned and ordered categories first), by the last change, by the creation (a second click turns newest first into oldest first) or by title. Folders stay above the notes, as in a file explorer, and sort by the latest change or creation of the notes inside them. On every category page, the right panel lists the five notes inside the category that changed last, under the heading Recently Updated in, followed by the name of the category. In a terminal, after `source .venv/bin/activate`, run:

```shell
ruby tools/categories.rb            # the tree with the number of notes in each category
ruby tools/categories.rb --notes    # the tree with the notes of each category, in order
ruby tools/categories.rb --tags     # every tag with the number of its notes
ruby tools/categories.rb --write    # the tree below into this file
```

The tree on the date of the last `--write`, with an asterisk on the categories that hold only unpublished notes and the pinned categories first:

<!-- tree:start -->
```text
- Physics (79, pinned)
  - Black Holes (59)
    - Black Hole Environments * (4)
    - Black Hole Shadows * (36)
    - Pseudospectra * (4)
    - Quasinormal Modes (8)
    - Superradiance * (3)
  - Classical Mechanics (5)
    - Nonlinear Dynamics (3)
  - General Relativity (6)
    - Numerical Relativity * (1)
  - Machine Learning * (1)
  - Physics Resources (5)
  - Quantum Field Theory in Curved Spacetime * (1)
  - Quantum Gravity * (2)
  - Research * (12)
    - Discussions * (6)
- Coding (9, pinned)
  - Julia (4)
  - Python (5)
- Code Carpentry (10)
  - Code Carpentry Resources (2)
  - Environments (2)
  - Remote Access (5)
  - Version Control * (2)
- History of Science * (1)
  - History of Physics * (1)
- Homelab (4)
  - Laptop Cluster (4)
- Personal (1)
  - Advice (1)
```
<!-- tree:end -->
