#!/usr/bin/env ruby
#
# The Tags tab in groups by subject instead of one wall of tags.
#
# Chirpy's tags layout lists every tag alphabetically in one flex row. After rendering, this hook
# sorts Chirpy's own tag pills into groups: a tag goes to the subject (primary › secondary
# category) of most of its notes, and the groups follow the order of the category tree
# (_plugins/category-tree.rb, pins and `order` of _data/categories.yml first). Each group has a
# muted heading with links to its categories, its number of tags, and a stripe in the colour of
# its primary category (--note); in a group the tags run from the most used to the least.
#
# Depends on Chirpy's `<div id="tags"` and its items `<div> <a class="tag" href=...>`. If they are
# missing, the hook prints a build warning and leaves the page as Chirpy renders it.
#
# Hook: :documents, :post_render (the Tags tab is a document of Chirpy's collection of tabs).
# Styles: _sass/_tag-groups.scss. Needs CategoryTree.

require 'cgi'

# Groups of tags by subject. `module_function` methods.
module TagGroups
  OPEN = %r{<div id="tags"[^>]*>}
  ITEM = %r{<div>\s*<a class="tag" href="[^"]*">\s*(.*?)<span}m
  ITEMS = %r{<div>\s*<a class="tag".*?</a>\s*</div>}m

  module_function

  # The subject of a note for its tags: the first three names of its main path.
  # @return [Array<String>]
  def subject(doc)
    Array(Array(doc.data['category_paths']).first).first(3)
  end

  # The subject of each tag: the one of most of its notes, the earlier in the tree on a tie.
  # @param site [Jekyll::Site]
  # @return [Hash{String=>Array<String>}] tag => subject
  def subjects(site)
    by_tag = Hash.new { |h, k| h[k] = Hash.new(0) }
    site.posts.docs.each do |doc|
      next if doc.data['hidden']

      key = subject(doc)
      Array(doc.data['tags']).each { |tag| by_tag[tag.to_s][key] += 1 unless key.empty? }
    end
    by_tag.transform_values { |counts| counts.max_by { |key, n| [n, -place(key)] }.first }
  end

  # @return [Integer] the position of a subject in the order of the category tree
  def place(key)
    @places ||= {}
    @places[key] ||= begin
      walk = lambda do |node, path|
        here = path + [node.name]
        [here, *CategoryTree.children(node).flat_map { |child| walk.call(child, here) }]
      end
      order = CategoryTree.roots.flat_map { |root| walk.call(root, []) }
      order.index(key) || order.size
    end
  end

  # The Tags tab in groups.
  # @param out [String] the rendered page
  # @param site [Jekyll::Site]
  # @return [String, nil] the new page, or nil if Chirpy's markup is missing
  def grouped(out, site)
    open = out.match(OPEN)
    return nil unless open

    items = out[open.end(0)..].to_enum(:scan, ITEMS).map { Regexp.last_match }
    return nil if items.empty?

    start = open.end(0) + items.first.begin(0)
    stop = open.end(0) + items.last.end(0)
    @places = nil
    keys = subjects(site)
    groups = items.map { |m| m[0] }.group_by { |item| keys[CGI.unescapeHTML(item[ITEM, 1].to_s.strip)] || [] }
    sections = groups.sort_by { |key, _| place(key) }.map do |key, tags|
      tags = tags.sort_by { |item| [-item[%r{<span class="text-muted">(\d+)</span>}, 1].to_i, item[ITEM, 1].to_s.strip.downcase] }
      section(site, key, tags)
    end
    out[0...open.begin(0)] + '<div id="tags" class="tag-groups mx-xl-2">' + sections.join + out[stop..].sub(/\A\s*/, '')
  end

  # One group: its heading and its tags.
  # @return [String] a <section>
  def section(site, key, tags)
    slug = key.first.to_s.downcase.strip.gsub(/[^a-z0-9]+/, '-')
    title = key.empty? ? 'Other' : key.map { |name| CategoryTree.link(site, name) }.join(CategoryTree::SEP)
    count = "#{tags.size} #{tags.size == 1 ? 'tag' : 'tags'}"
    %(<section class="tag-group" style="--note: var(--graph-node-#{slug}, var(--graph-node))">) +
      %(<h2 class="tag-group-title">#{title}<span class="tag-group-count">#{count}</span></h2>) +
      %(<div class="d-flex flex-wrap">#{tags.join}</div></section>)
  end
end

Jekyll::Hooks.register :documents, :post_render do |doc|
  next unless doc.data['layout'] == 'tags' && doc.output_ext == '.html'

  output = TagGroups.grouped(doc.output, doc.site)
  if output
    doc.output = output
  else
    Jekyll.logger.warn 'Tag groups:', "no Chirpy tags found in #{doc.url}; the theme's markup may have changed"
  end
end
