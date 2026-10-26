#!/usr/bin/env ruby
#
# Categories as a tree of any depth, on the Categories tab and on the category pages.
#
# The `categories` of a note is a path from the primary category down:
# [Physics, Black Holes, Black Hole Shadows] puts the note in Black Hole Shadows, inside Black
# Holes, inside Physics. `also_in` gives more paths, one ([Coding, Julia]) or several
# ([[Coding, Julia], [Physics, Classical Mechanics]]), and `order` places the note among the notes
# of its own category, the last name of `categories`. Notes without `order` follow, newest first.
#
# At :post_read the plugin stores the paths of every post in `category_paths` and appends the
# names of `also_in` to `categories`, so that jekyll-archives builds their pages and Chirpy links
# them. The first category, which colours a note in the graph and on the home page, stays first.
# After rendering, it replaces the cards of Chirpy's Categories tab, which show two levels, with
# the whole tree, deeper levels in closed folders (<details>). A category page gets its parent
# categories in Chirpy's breadcrumb. With subcategories it becomes an explorer: the subcategories
# as closed folders that open on their subtopics and their notes in order, then its own notes,
# without dates. A category
# without subcategories keeps Chirpy's list of its notes, in order; those items are Chirpy's own,
# picked out and reordered. post-topics-top.rb and home-tiles.rb show the paths on a post and on
# its card (CategoryTree.trail).
#
# _data/categories.yml can pin a category (`pin: true`) and give it an `order` among its siblings:
# pinned categories come first, then those with an order, then the rest by name.
#
# jekyll-archives builds one page for each name, so a name has one place in the tree; a name
# under two parents gives a build warning, and the tree keeps its first place. If Chirpy's markup
# is missing (`<div class="card categories">`, `<div id="page-category">`,
# `<ul class="content ps-0">`), the hooks print a build warning and leave the page as Chirpy
# renders it.
#
# Hooks: :site, :post_read; :documents (the tab) and :pages (jekyll-archives), :post_render. Styles: _sass/_category-tree.scss. Sort buttons
# of the category pages: assets/js/list-sort.js. Design: .claude/DESIGN.md.

require 'cgi'
require 'set'

# The tree of the categories of one build. `module_function` methods.
module CategoryTree
  # One category: the name of its parent (nil for a primary category), the names of its
  # subcategories, and its own notes as [doc, main] pairs, where main is true when the category
  # ends the note's first path.
  Node = Struct.new(:name, :parent, :children, :notes)

  # Chirpy's markup on the Categories tab and on a category page.
  CARD = '<div class="card categories">'
  PAGE = '<div id="page-category">'
  LIST = '<ul class="content ps-0">'
  # The start of an item; the compressed HTML of a production build drops the optional </li>
  ITEM = /(?=<li\b)/

  # Separator between the names of a path.
  SEP = '<span class="category-sep">›</span>'

  @nodes = {}

  module_function

  # @param doc [Jekyll::Document]
  # @return [Array<Array<String>>] the path of `categories`, then those of `also_in`
  def paths(doc)
    extra = Array(doc.data['also_in'])
    extra = [extra] unless extra.empty? || extra.first.is_a?(Array)
    [doc.data['categories'], *extra].map { |path| Array(path).map(&:to_s).reject(&:empty?).uniq }.reject(&:empty?)
  end

  # Reads the paths of every post and builds the tree.
  # @param site [Jekyll::Site]
  # @return [Hash{String=>Node}] the categories by name
  def build(site)
    @nodes = {}
    @warned = Set.new
    @meta = site.data['categories'].is_a?(Hash) ? site.data['categories'] : {}
    site.posts.docs.each do |doc|
      doc.data['category_paths'] = paths(doc)
      doc.data['categories'] = doc.data['category_paths'].flatten.uniq
      next if doc.data['hidden']

      doc.data['category_paths'].each_with_index do |path, i|
        path.each_with_index do |name, depth|
          node = place(name, depth.zero? ? nil : path[depth - 1], doc)
          node.notes << [doc, i.zero?] if depth == path.length - 1 && node.notes.none? { |d, _| d == doc }
        end
      end
    end
    (@meta.keys - @nodes.keys).each do |name|
      Jekyll.logger.warn 'Categories:', "_data/categories.yml names '#{name}', which no note uses"
    end
    @nodes
  end

  # @param name [String]
  # @return [Boolean] whether _data/categories.yml pins the category
  def pinned?(name)
    @meta.dig(name, 'pin') == true
  end

  # The place of a category among its siblings: pinned ones first, then those with an `order` in
  # _data/categories.yml by order, then the rest by name.
  # @param node [Node]
  # @return [Array]
  def rank(node)
    order = @meta.dig(node.name, 'order')
    [pinned?(node.name) ? 0 : 1, order.nil? ? 1 : 0, order.to_f, node.name.downcase]
  end

  # The node of a category, made at its first appearance under its first parent.
  # @param name [String]
  # @param parent [String, nil]
  # @param doc [Jekyll::Document] the note, for the warning
  # @return [Node]
  def place(name, parent, doc)
    node = @nodes[name]
    unless node
      node = @nodes[name] = Node.new(name, parent, [], [])
      @nodes[parent].children << name if parent
      return node
    end
    if node.parent != parent && @warned.add?([name, parent])
      Jekyll.logger.warn 'Categories:', "#{doc.relative_path}: '#{name}' sits under '#{parent || 'the top'}' here " \
                                        "and under '#{node.parent || 'the top'}' elsewhere; give it one place"
    end
    node
  end

  # @param name [String]
  # @return [Node, nil]
  def node(name)
    @nodes[name]
  end

  # @param node [Node]
  # @return [Array<Node>] the subcategories, in the order of rank
  def children(node)
    node.children.map { |name| @nodes[name] }.sort_by { |child| rank(child) }
  end

  # @return [String] the thumbtack of a pinned category, as Chirpy marks a pinned post
  def pin(node)
    pinned?(node.name) ? '<i class="fas fa-thumbtack fa-fw category-pin" title="Pinned"></i>' : ''
  end

  # @param node [Node]
  # @return [Array<Node>] the ancestors, from the primary category down
  def ancestors(node)
    chain = []
    while (parent = (chain.first || node).parent)
      chain.unshift(@nodes[parent])
    end
    chain
  end

  # @param node [Node]
  # @return [Set<Jekyll::Document>] the notes of the category and of all its subcategories
  def notes_under(node)
    node.children.reduce(node.notes.to_set(&:first)) { |all, child| all | notes_under(@nodes[child]) }
  end

  # The notes of the category itself: those whose first path ends here and that have `order`, by
  # order, then the others, newest first.
  # @param node [Node]
  # @return [Array<Jekyll::Document>]
  def notes_of(node)
    ordered, rest = node.notes.partition { |doc, main| main && !doc.data['order'].nil? }
    ordered.map(&:first).sort_by { |doc| [doc.data['order'].to_f, doc.data['title'].to_s] } +
      rest.map(&:first).sort_by { |doc| -doc.date.to_f }
  end

  # @param site [Jekyll::Site]
  # @param name [String]
  # @return [String] the address of the category's page, as jekyll-archives builds it, with the
  #   slug encoded as Chirpy encodes it (`slugify | url_encode`)
  def url(site, name)
    config = site.config['jekyll-archives'] || {}
    permalink = config.dig('permalinks', 'category') || '/categories/:name/'
    slug = CGI.escape(Jekyll::Utils.slugify(name, mode: config['slug_mode']))
    "#{site.config['baseurl']}#{permalink.sub(':name', slug)}"
  end

  # @return [String] a link to the category's page
  def link(site, name, css = nil)
    %(<a href="#{CGI.escapeHTML(url(site, name))}"#{css ? %( class="#{css}") : ''}>#{CGI.escapeHTML(name)}</a>)
  end

  # @param count [Integer]
  # @param key [String] category_measure or post_measure, from Chirpy's locale file
  # @return [String] such as "3 posts"
  def measure(site, count, key)
    words = site.data.dig('locales', site.config['lang'] || 'en', 'categories', key)
    word = words.is_a?(Hash) ? words[count == 1 ? 'singular' : 'plural'] : words
    "#{count} #{word || (key == 'post_measure' ? 'posts' : 'categories')}"
  end

  # @return [String] the counts after a category's name, as Chirpy writes them
  def counts(site, node)
    parts = []
    parts << measure(site, node.children.size, 'category_measure') unless node.children.empty?
    parts << measure(site, notes_under(node).size, 'post_measure')
    %(<span class="text-muted small font-weight-light">#{parts.join(', ')}</span>)
  end

  # A note in the explorer of a category page, without a date.
  # @return [String] an <li>
  def file(site, doc)
    css = defined?(NoteStage) && NoteStage.stage(doc) ? ' note-unpublished' : ''
    %(<li class="category-note#{css}"><i class="far fa-file-lines fa-fw"></i> ) +
      %(<a href="#{CGI.escapeHTML("#{site.baseurl}#{doc.url}")}">#{doc.data['title']}</a></li>)
  end

  # A subcategory as a folder, closed at first, that opens on its own subcategories and, with
  # notes, on its notes in order. A folder with nothing to open is a plain row.
  # @param notes [Boolean] list the notes too (category pages) or only the subcategories (tab)
  # @return [String] an <li>
  def folder(site, node, css = nil, notes: false)
    inner = children(node).map { |child| folder(site, child, notes: notes) }.join
    inner += notes_of(node).map { |doc| file(site, doc) }.join if notes
    label = %(<i class="far fa-folder fa-fw"></i> #{link(site, node.name, 'mx-2')} #{counts(site, node)}#{pin(node)})
    li = %(<li class="category-folder#{css ? " #{css}" : ''}">)
    return %(#{li}<span class="category-row"><i class="fas fa-fw category-chevron"></i>#{label}</span></li>) if inner.empty?

    %(#{li}<details><summary class="category-row"><i class="fas fa-angle-right fa-fw category-chevron"></i>#{label}) +
      %(</summary><ul class="category-tree">#{inner}</ul></details></li>)
  end

  # The cards of the Categories tab: one card for each primary category, in Chirpy's markup, with
  # every level below it.
  # @param site [Jekyll::Site]
  # @return [String]
  def tab(site)
    roots = @nodes.values.select { |node| node.parent.nil? }.sort_by { |node| rank(node) }
    roots.each_with_index.map do |root, i|
      subs = children(root)
      icon = subs.empty? ? 'fa-folder' : 'fa-folder-open'
      head = %(<span class="ms-2"><i class="far #{icon} fa-fw"></i> #{link(site, root.name, 'mx-2')} #{counts(site, root)}#{pin(root)}</span>)
      if subs.empty?
        trigger = '<span data-bs-toggle="collapse" class="category-trigger hide-border-bottom disabled">' \
                  '<i class="fas fa-fw fa-angle-right"></i></span>'
        body = ''
      else
        trigger = %(<a href="#l_#{i}" data-bs-toggle="collapse" aria-expanded="true" aria-label="h_#{i}-trigger" ) +
                  'class="category-trigger hide-border-bottom"><i class="fas fa-fw fa-angle-down"></i></a>'
        body = %(<div id="l_#{i}" class="collapse show" aria-expanded="true"><ul class="list-group">) +
               subs.map { |sub| folder(site, sub, 'list-group-item') }.join + '</ul></div>'
      end
      %(<div class="card categories"><div id="h_#{i}" class="card-header d-flex justify-content-between ) +
        %(hide-border-bottom">#{head}#{trigger}</div>#{body}</div>)
    end.join
  end

  # The paths of a note as text, such as "Physics › Black Holes · Coding › Julia", for its card.
  # With html, each name is the link that `links` gives it (Chirpy's own), for the post's header.
  # @param doc [Jekyll::Document]
  # @param links [Hash{String=>String}, nil] the HTML link of each name
  # @return [String, nil] nil if the note has no categories
  def trail(doc, links = nil)
    paths = doc.data['category_paths']
    return nil if paths.nil? || paths.empty?
    return paths.map { |path| path.join(' › ') }.join(' · ') unless links

    paths.map do |path|
      %(<span class="category-path">#{path.map { |name| links[name] || CGI.escapeHTML(name) }.join(SEP)}</span>)
    end.join
  end

  # Puts the parent categories into Chirpy's breadcrumb, before the name of the category, so that
  # it reads Home › Categories › Physics › Black Holes › Black Hole Environments. Without that
  # breadcrumb (`<nav id="breadcrumb"`), the parents go in a line of their own above the title.
  # @param out [String] the rendered page
  # @param parents [Array<Node>] from the primary category down
  # @return [Array(String, String)] the page, and the HTML of the fallback line ("" if not needed)
  def with_parents(out, parents, site)
    return [out, ''] if parents.empty?

    nav = out.index('<nav id="breadcrumb"')
    stop = nav && out.index('</nav>', nav)
    last = stop && out.rindex('<span>', stop)
    if last && last > nav
      spans = parents.map { |parent| "<span> #{link(site, parent.name)} </span> " }.join
      return [out[0...last] + spans + out[last..], '']
    end

    [out, %(<nav class="category-crumbs" aria-label="Parent categories">) +
      parents.map { |parent| link(site, parent.name) }.join(SEP) + SEP + '</nav>']
  end

  # A category page with the path above its title. A category with subcategories becomes an
  # explorer: its subcategories as closed folders, then its own notes, without dates. A category
  # without subcategories keeps Chirpy's list, with only its own notes, in order, and the sort
  # buttons of assets/js/list-sort.js.
  # @param page [Jekyll::Page] the page of jekyll-archives
  # @return [String, nil] the new output, or nil if Chirpy's markup is missing
  def page(page)
    site = page.site
    node = @nodes[page.title.to_s]
    out = page.output
    top = out.index(PAGE)
    list = top && out.index(LIST, top)
    close = list && out.index('</ul>', list)
    return nil unless node && close

    out, crumbs = with_parents(out, ancestors(node), site)
    top = out.index(PAGE)
    list = out.index(LIST, top)
    close = out.index('</ul>', list)
    start = top + PAGE.length
    subs = children(node)
    unless subs.empty?
      explorer = %(<ul class="category-tree category-explorer">) +
                 subs.map { |sub| folder(site, sub, notes: true) }.join +
                 notes_of(node).map { |doc| file(site, doc) }.join + '</ul>'
      return out[0...start] + crumbs + out[start...list] + explorer + out[(close + '</ul>'.length)..]
    end

    items = out[(list + LIST.length)...close].split(ITEM).select { |li| li.start_with?('<li') }
                                              .to_h { |li| [CGI.unescape(li[/href="([^"]+)"/, 1].to_s), li] }
    own = notes_of(node).filter_map do |doc|
      li = items["#{site.baseurl}#{doc.url}"] || items[doc.url]
      next unless li

      main = node.notes.any? { |d, first| d == doc && first }
      order = main && !doc.data['order'].nil? ? %( data-order="#{CGI.escapeHTML(doc.data['order'].to_s)}") : ''
      li.sub(/\A<li\b/) { %(<li data-date="#{doc.date.iso8601}"#{order}) }
    end
    out[0...start] + crumbs + out[start...list] + LIST + own.join + out[close..]
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  CategoryTree.build(site)
end

# The Categories tab, a document of Chirpy's collection of tabs: everything between its first card
# and the end of its content
Jekyll::Hooks.register :documents, :post_render do |page|
  next unless page.data['layout'] == 'categories' && page.output_ext == '.html'

  out = page.output
  start = out.index(CategoryTree::CARD)
  stop = start && out.index('</article>', start)
  stop &&= out.rindex('</div>', stop)
  unless stop && stop > start
    Jekyll.logger.warn 'Categories:', "no Chirpy cards found in #{page.url}; the theme's markup may have changed"
    next
  end

  page.output = out[0...start] + CategoryTree.tab(page.site) + out[stop..]
end

Jekyll::Hooks.register :pages, :post_render do |page|
  next unless page.data['layout'] == 'category' && page.respond_to?(:title) && page.output_ext == '.html'

  output = CategoryTree.page(page)
  if output
    page.output = output
  elsif CategoryTree.node(page.title.to_s)
    Jekyll.logger.warn 'Categories:', "no Chirpy list found in #{page.url}; the theme's markup may have changed"
  end
end
