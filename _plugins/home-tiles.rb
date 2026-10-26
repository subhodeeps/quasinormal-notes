#!/usr/bin/env ruby
#
# Post list of the home page as bands and tiles, and the data for the sort buttons.
#
# The post list becomes a grid of tiles whose size follows the length of the post without its
# code (HomeTiles.size). The grid of the first page opens with the pinned categories of
# _data/categories.yml (HomeTiles.category_tile: name, description, counts, and a link to its
# page) and the pinned posts, each marked with Chirpy's thumbtack (tile-pinned); these stay first
# when the sort buttons reorder the rest. Every card takes the colour of its
# subject from --graph-node-<category> (_sass/amore/) as a thin stripe, and an unpublished note
# gets a dashed outline in that colour. The card names only the category of the note, the last
# name of its main path (`category_paths`, _plugins/category-tree.rb); a small tile shows only
# the date. A tall, wide or large tile also shows the opening paragraphs of the post
# (HomeTiles.excerpt). The tiles of all pages are written to assets/data/home-tiles.json for
# assets/js/list-sort.js, and assets/js/home-tiles.js closes the gaps at the end of the grid.
#
# Depends on Chirpy's cards (`<article class="card-wrapper card">` with `post-preview`). If
# they are missing, the hook prints a build warning and leaves the list as Chirpy renders it.
#
# The number of posts a page follows from `paginate` in _config.yml (HomeTiles.per_page), so that
# the pages hold even numbers of tiles and the last page no fewer than three posts.
#
# Hooks: :site, :post_read (before jekyll-paginate); :pages, :post_render; :site, :pre_render and
# :post_write. Styles: _sass/_home-tiles.scss
# and _sass/_note-cards.scss. Needs NoteStage from draft-category.rb and CategoryTree.

require 'cgi'
require 'fileutils'
require 'json'
require 'zlib'

# Sizes, colours and excerpts of the tiles. `module_function` methods.
module HomeTiles
  CARD = %r{<article class="card-wrapper card">.*?</article>}m
  TILE = %r{<article class="card-wrapper card tile .*?</article>}m
  SMALL = 300 # words: a shorter post is a small square
  LARGE = 1500 # words: a longer post is a large square
  EXCERPT = { 'tile-tall' => 90, 'tile-wide' => 150, 'tile-large' => 150 }.freeze # words of the opening
  BLOCK = /\A\s*<(?:pre|details|blockquote|figure|table|div|ul|ol|h[1-6])\b/ # ends the opening run
  DATA = 'assets/data/home-tiles.json' # the tiles of all pages, for the sort buttons
  STEPS = [0, 2, 4, 6].freeze # tried in turn around the preferred number of posts a page
  PAGES = {} # page number -> its tiles, collected during the build

  module_function

  # A tile for a pinned category, in the markup of Chirpy's cards, so that it takes their styles.
  # @param site [Jekyll::Site]
  # @param node [CategoryTree::Node]
  # @return [String] an <article>
  def category_tile(site, node)
    subs = CategoryTree.children(node).map(&:name)
    counts = [subs.empty? ? nil : CategoryTree.measure(site, subs.size, 'category_measure'),
              CategoryTree.measure(site, CategoryTree.notes_under(node).size, 'post_measure')].compact.join(' · ')
    colour = %(style="--note: var(--graph-node-#{slug(node.name)}, var(--graph-node))")
    <<~HTML.delete("\n")
      <article class="card-wrapper card tile tile-small tile-pinned tile-category">
      <a href="#{CGI.escapeHTML(CategoryTree.url(site, node.name))}" #{colour} class="post-preview row g-0 flex-md-row-reverse note-card">
      <div class="col-md-12"><div class="card-body d-flex flex-column">
      <h1 class="card-title my-2 mt-md-0"><i class="far fa-folder-open fa-fw me-1"></i>#{CGI.escapeHTML(node.name)}</h1>
      <div class="card-text content mt-0 mb-3"><p>#{CGI.escapeHTML(CategoryTree.description(node.name) || subs.join(' · '))}</p></div>
      <div class="post-meta flex-grow-1 d-flex align-items-end"><div class="me-auto"><span>#{counts}</span></div>
      <div class="pin ms-1"><i class="fas fa-thumbtack fa-fw"></i></div></div>
      </div></div></a></article>
    HTML
  end

  # The number of posts a page of the home list: the first even number, from the preferred one
  # (`paginate` in _config.yml) and then 2 more, 2 fewer, 4 and 6 more, with which the last page is
  # full or holds at least three posts. Every page but the last then holds an even number of tiles,
  # and the first one too, with the cards of the pinned categories, when there are two of them.
  # @param count [Integer] the posts of the list
  # @param preferred [Integer]
  # @return [Integer]
  def per_page(count, preferred)
    base = [preferred + preferred % 2, 2].max
    STEPS.map { |step| base + step }.select(&:positive?)
         .find { |size| (count % size).zero? || count % size >= 3 } || base
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

  # Length of a post without code blocks and tags.
  # @param post [Jekyll::Document]
  # @return [Integer] number of words
  def words(post)
    post.content.to_s.gsub(%r{<pre.*?</pre>}m, ' ').gsub(/```.*?```/m, ' ').gsub(/<[^>]+>/, ' ').split.size
  end

  # The opening paragraphs of a post, up to the first block that is not a paragraph or a display
  # equation (BLOCK), and about `limit` words.
  # @param post [Jekyll::Document]
  # @param limit [Integer] words
  # @return [String] HTML of the paragraphs, "" if the post opens with a block
  def excerpt(post, limit)
    html = post.content.to_s.sub(/\A\s*<!--.*?-->/m, '')
    out = []
    count = 0
    until html.strip.empty? || count >= limit
      html = html.lstrip.sub(/\A<!--.*?-->/m, '').lstrip
      break if html.match?(BLOCK)

      paragraph = html.match(%r{\A<p\b[^>]*>(.*?)</p>}m)
      break unless paragraph
      break if paragraph[1].match?(/\$\$|\\\[|\\begin\{/)

      text = paragraph[1].gsub(/<[^>]+>/, '').gsub(/\s+/, ' ').strip
      out << "<p>#{text}</p>" unless text.empty?
      count += text.split.size
      html = html[paragraph.end(0)..]
    end
    out.join
  end

  # The tile class of a post: tile-small below SMALL words, tile-large above LARGE, otherwise
  # tile-wide or tile-tall by the parity of a hash of its slug, so that it stays the same between builds.
  # @param post [Jekyll::Document]
  # @return [String]
  def size(post)
    count = words(post)
    return 'tile-small' if count < SMALL
    return 'tile-large' if count > LARGE

    Zlib.crc32(post.data['slug'].to_s).even? ? 'tile-wide' : 'tile-tall'
  end
end

Jekyll::Hooks.register :pages, :post_render do |page|
  next unless page.output&.include?('<div id="post-list"')

  # If a theme update changes the markup of the cards, the page keeps Chirpy's list as it is
  unless page.output.match?(HomeTiles::CARD) && page.output.include?('class="post-preview')
    Jekyll.logger.warn 'Home tiles:', "no Chirpy cards found in #{page.url}; the theme's markup may have changed"
    next
  end

  site = page.site
  posts = site.posts.docs.to_h { |post| ["#{site.baseurl}#{post.url}", post] }
  page.output = page.output.gsub(HomeTiles::CARD) do |card|
    post = posts[card[/<a href="([^"]+)" class="post-preview/, 1]]
    next card unless post

    category = HomeTiles.slug(NoteStage.subject(post))
    colour = %(style="--note: var(--graph-node-#{category}, var(--graph-node))")
    unpublished = NoteStage.stage(post) ? ' note-unpublished' : ''
    card = card.sub('class="post-preview', %(#{colour} class="post-preview note-card#{unpublished}))
    # Only the category of the note, in place of Chirpy's list of all its categories
    name = Array(Array(post.data['category_paths']).first).last || Array(post.data['categories']).last
    card = card.sub(%r{<span class="categories">.*?</span>}m) { %(<span class="categories">#{CGI.escapeHTML(name.to_s)}</span>) }
    # A pinned post is a wide tile, title and description, whatever its length
    size = post.data['pin'] ? 'tile-wide tile-pinned' : HomeTiles.size(post)
    card = card.sub('<article class="card-wrapper card">', %(<article class="card-wrapper card tile #{size}">))
    excerpt = HomeTiles::EXCERPT[size] && HomeTiles.excerpt(post, HomeTiles::EXCERPT[size])
    excerpt.to_s.empty? ? card : card.sub('<div class="post-meta', %(<div class="tile-excerpt">#{excerpt}</div><div class="post-meta))
  end

  # The pinned posts and the latest ones form one run of tiles
  tiles = page.output.to_enum(:scan, HomeTiles::TILE).map { Regexp.last_match }
  next if tiles.empty?

  # The tiles of this page that the sort buttons sort, those of all pages; the pinned ones stay first
  number = page.pager&.page || 1
  HomeTiles::PAGES[number] = tiles.reject { |tile| tile[0].include?('tile-pinned') }.map do |tile|
    post = posts[tile[0][/<a href="([^"]+)"/, 1]]
    { title: HomeTiles.plain(post&.data&.fetch('title', nil)), html: tile[0] }
  end

  start = tiles.first.begin(0)
  stop = tiles.last.end(0)
  pinned = number == 1 ? CategoryTree.roots.select { |node| CategoryTree.pinned?(node.name) } : []
  categories = pinned.map { |node| HomeTiles.category_tile(site, node) }.join
  script = %(<script defer src="#{site.baseurl}/assets/js/home-tiles.js"></script>) # closes the gaps
  grid = %(<div class="home-tiles" data-all="#{site.baseurl}/#{HomeTiles::DATA}">)
  page.output = "#{page.output[0...start]}#{grid}#{categories}#{page.output[start...stop]}</div>#{script}#{page.output[stop..]}"
end

# The number of posts a page (HomeTiles.per_page), before jekyll-paginate builds the pages
Jekyll::Hooks.register :site, :post_read do |site|
  HomeTiles.instance_variable_set(:@preferred, site.config['paginate'].to_i) unless HomeTiles.instance_variable_get(:@preferred)
  count = site.posts.docs.count { |post| !post.data['hidden'] }
  preferred = HomeTiles.instance_variable_get(:@preferred)
  site.config['paginate'] = HomeTiles.per_page(count, preferred)
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
