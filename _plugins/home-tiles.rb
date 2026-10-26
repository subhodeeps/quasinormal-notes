#!/usr/bin/env ruby
#
# Post list of the home page as a grid of square and rectangular tiles, and the data for the sort
# buttons.
#
# Chirpy's list becomes one grid. The first page opens with a card for each pinned category of
# _data/categories.yml (HomeTiles.category_tile: name, description, counts and a link to its page),
# then come the pinned posts, each marked with Chirpy's thumbtack (tile-pinned), then the others.
# A page of eight tiles has six squares and two rectangles, the rectangles side by side, half as
# high as a square and as wide as two (HomeTiles.sizes); the grid closes without a gap in every
# number of columns, and the last page may end with an empty cell. A tile shows the title, the
# description and a quiet line "date · category" (the last name of the main path of the note,
# `category_paths`, _plugins/category-tree.rb); a rectangle shows no description. Every card takes
# the colour of its subject from --graph-node-<category> (_sass/amore/) as a thin stripe, and an
# unpublished note gets a dashed outline in that colour.
#
# The button Pinned of assets/js/list-sort.js keeps Chirpy's order, with the pinned tiles first; the
# other buttons sort all posts and the category cards together, a card by the last change of the
# notes under its category. The tiles of all pages are written to assets/data/home-tiles.json for
# them, and assets/js/home-tiles.js sizes the tiles again after a sort.
#
# MathJax, a large script, is loaded on the home page only when the description of a post has math.
#
# Depends on Chirpy's cards (`<article class="card-wrapper card">` with `post-preview`). If they
# are missing, the hook prints a build warning and leaves the list as Chirpy renders it. The
# number of posts a page is `paginate` of _config.yml, which Chirpy's paginator reads.
#
# Hooks: :pages, :pre_render and :post_render; :site, :pre_render and :post_write. Styles:
# _sass/_home-tiles.scss and _sass/_note-cards.scss. Needs NoteStage and CategoryTree.

require 'cgi'
require 'fileutils'
require 'json'

# Sizes, colours and cards of the tiles. `module_function` methods.
module HomeTiles
  CARD = %r{<article class="card-wrapper card">.*?</article>}m
  TILE = %r{<article class="card-wrapper card tile .*?</article>}m
  DATA = 'assets/data/home-tiles.json' # the tiles of all pages, for the sort buttons
  PAGES = {} # page number -> its tiles, collected during the build

  module_function

  # The size of each tile of a page: squares (tile-small, one column wide and two units high) and one
  # pair of rectangles (tile-wide, two columns wide and one unit high), the pair placed where it
  # closes the grid in four columns and in two. A page of up to three tiles has squares only. The
  # same rule is in assets/js/home-tiles.js, which applies it again after a sort.
  # @param count [Integer] the tiles of the page
  # @return [Array<String>]
  def sizes(count)
    sizes = Array.new(count, 'tile-small')
    return sizes if count < 4

    even = count - count % 2
    at = (even / 2).even? ? 2 : 4
    sizes[at] = sizes[at + 1] = 'tile-wide'
    sizes
  end

  # A tile for a pinned category, in the markup of Chirpy's cards, so that it takes their styles.
  # @param site [Jekyll::Site]
  # @param node [CategoryTree::Node]
  # @param size [String] tile-small or tile-wide
  # @return [String] an <article>
  def category_tile(site, node, size)
    subs = CategoryTree.children(node).map(&:name)
    counts = [subs.empty? ? nil : CategoryTree.measure(site, subs.size, 'category_measure'),
              CategoryTree.measure(site, CategoryTree.notes_under(node).size, 'post_measure')].compact.join(' · ')
    colour = %(style="--note: var(--graph-node-#{slug(node.name)}, var(--graph-node))")
    <<~HTML.delete("\n")
      <article class="card-wrapper card tile #{size} tile-pinned tile-category">
      <a href="#{CGI.escapeHTML(CategoryTree.url(site, node.name))}" #{colour} class="post-preview row g-0 flex-md-row-reverse note-card">
      <div class="col-md-12"><div class="card-body d-flex flex-column">
      <h1 class="card-title my-2 mt-md-0"><i class="far fa-folder-open fa-fw me-1"></i>#{CGI.escapeHTML(node.name)}</h1>
      <div class="card-text content mt-0 mb-3"><p>#{CGI.escapeHTML(CategoryTree.description(node.name) || subs.join(' · '))}</p></div>
      <div class="post-meta flex-grow-1 d-flex align-items-end"><div class="me-auto"><span>#{counts}</span></div>
      <div class="pin ms-1"><i class="fas fa-thumbtack fa-fw"></i></div></div>
      </div></div></a></article>
    HTML
  end

  # @param html [String, nil]
  # @return [String] the text of html without tags
  def plain(html)
    html.to_s.gsub(/<[^>]+>/, '').strip
  end

  # The name of a category as the graph script writes it, which gives --graph-node-<slug>.
  # @param category [String]
  # @return [String]
  def slug(category)
    category.to_s.downcase.strip.gsub(/[^a-z0-9]+/, '-')
  end
end

# MathJax only when a description has math
Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  next unless page.url.to_s.match?(%r{\A/(page\d+/?)?\z}) && page.data['layout'] == 'home'

  posts = page.site.posts.docs.reject { |post| post.data['hidden'] }
  math = posts.any? { |post| post.data['description'].to_s.match?(/\$|\\\(/) }
  page.data['math'] = math
  payload['page']['math'] = math # Jekyll has built the data of the page for the layouts already
end

Jekyll::Hooks.register :pages, :post_render do |page|
  next unless page.output&.include?('<div id="post-list"')

  # If a theme update changes the markup of the cards, the page keeps Chirpy's list as it is
  unless page.output.match?(HomeTiles::CARD) && page.output.include?('class="post-preview')
    Jekyll.logger.warn 'Home tiles:', "no Chirpy cards found in #{page.url}; the theme's markup may have changed"
    next
  end

  site = page.site
  number = page.pager&.page || 1
  pinned = number == 1 ? CategoryTree.roots.select { |node| CategoryTree.pinned?(node.name) } : []
  sizes = HomeTiles.sizes(pinned.size + page.output.scan(HomeTiles::CARD).size)
  cards = pinned.each_with_index.map do |node, i|
    changed = CategoryTree.notes_under(node).map { |doc| CategoryTree.updated(doc) }.max
    { title: node.name, date: changed&.iso8601, html: HomeTiles.category_tile(site, node, sizes[i]) }
  end

  posts = site.posts.docs.to_h { |post| ["#{site.baseurl}#{post.url}", post] }
  index = pinned.size
  page.output = page.output.gsub(HomeTiles::CARD) do |card|
    post = posts[card[/<a href="([^"]+)" class="post-preview/, 1]]
    index += 1
    next card unless post

    colour = %(style="--note: var(--graph-node-#{HomeTiles.slug(NoteStage.subject(post))}, var(--graph-node))")
    unpublished = NoteStage.stage(post) ? ' note-unpublished' : ''
    card = card.sub('class="post-preview', %(#{colour} class="post-preview note-card#{unpublished}))
    # Only the category of the note, in place of Chirpy's list of all its categories
    name = Array(Array(post.data['category_paths']).first).last || Array(post.data['categories']).last
    card = card.sub(%r{<span class="categories">.*?</span>}m) { %(<span class="categories">#{CGI.escapeHTML(name.to_s)}</span>) }
    kind = [sizes[index - 1], post.data['pin'] ? 'tile-pinned' : nil].compact.join(' ')
    card.sub('<article class="card-wrapper card">', %(<article class="card-wrapper card tile #{kind}">))
  end

  tiles = page.output.to_enum(:scan, HomeTiles::TILE).map { Regexp.last_match }
  next if tiles.empty?

  # The tiles of this page for the sort buttons, which sort the tiles of all pages
  HomeTiles::PAGES[number] = cards + tiles.map do |tile|
    post = posts[tile[0][/<a href="([^"]+)"/, 1]]
    { title: HomeTiles.plain(post&.data&.fetch('title', nil)), date: post&.date&.iso8601, html: tile[0] }
  end

  start = tiles.first.begin(0)
  stop = tiles.last.end(0)
  script = %(<script defer src="#{site.baseurl}/assets/js/home-tiles.js"></script>)
  grid = %(<div class="home-tiles-box"><div class="home-tiles" data-all="#{site.baseurl}/#{HomeTiles::DATA}">)
  page.output = "#{page.output[0...start]}#{grid}#{cards.map { |card| card[:html] }.join}" \
                "#{page.output[start...stop]}</div></div>#{script}#{page.output[stop..]}"
end

Jekyll::Hooks.register :site, :pre_render do
  HomeTiles::PAGES.clear
end

Jekyll::Hooks.register :site, :post_write do |site|
  next if HomeTiles::PAGES.empty?

  path = File.join(site.dest, HomeTiles::DATA)
  FileUtils.mkdir_p(File.dirname(path))
  pages = HomeTiles::PAGES.sort.map { |number, tiles| { page: number, tiles: tiles } }
  File.write(path, JSON.generate(pages: pages))
end
