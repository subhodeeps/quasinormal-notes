#!/usr/bin/env ruby
#
# Links between notes, backlinks and the data of the note graph.
#
# 1. Wikilinks ([[slug]], [[2026-07-06-slug]], [[slug|text]], [[slug#heading]]) and relative
#    .md links become ordinary links before Markdown is rendered. A link to a missing note
#    becomes muted text and a build warning. Code blocks and inline code are skipped.
# 2. Every link from one note to another, whatever its form, is recorded, and each post gets
#    the notes that link to it (`backlinks`, shown by _includes/backlinks.html).
# 3. assets/data/notes-graph.json holds the nodes (posts, with category, stage, tags and
#    primary tags), the edges (links, and tags shared as a primary tag) and the page of every
#    tag. assets/js/notes-graph.js draws it.
# 4. The post_render hook puts the graph and the backlinks at the top of the right panel.
#
# TAG_HUB_LIMIT: a tag on more notes than this draws no edges in the panel, unless the notes
# name it in `primary_tags`; the first two tags of a note are only a default.
#
# Depends on Chirpy's `<div class="access">` in the right panel; if it is missing, the hook
# prints a build warning and leaves the page as Chirpy renders it. Needs NoteStage from
# draft-category.rb. Design: .claude/DESIGN.md.

require 'json'

# Wikilinks, backlinks and graph data. `module_function` methods.
module NotesGraph
  # Matches, in order of alternatives, a code span or block (kept), a wikilink and a Markdown
  # link target. The named groups are code, target, anchor, label and href.
  WIKILINK = /
    (?<code>
      ^(?<fence>`{3,}|~{3,})[^\n]*\n.*?^\k<fence>[ \t]*$     # fenced code block
      | (?<ticks>`+)(?:(?!\k<ticks>).)+?\k<ticks>             # inline code
    )
    | (?<!!)\[\[(?<target>[^\]|#\n]+)(?<anchor>\#[^\]|\n]*)?(?:\|(?<label>[^\]\n]+))?\]\]
    | (?<mdlink>\]\(\s*<?(?<href>[^)\s>]+?)>?(?<title>\s+"[^"]*")?\s*\))
  /mx

  # Chirpy's block at the top of the right panel; the graph is inserted at its start.
  ACCESS_MARKER = '<div class="access">' # the panel's "Recently Updated" and "Trending Tags"
  # Number of notes above which a default primary tag draws no edges.
  TAG_HUB_LIMIT = 15

  module_function

  # @param html [String, nil]
  # @return [String] the text of html without tags
  def plain(html)
    html.to_s.gsub(/<[^>]+>/, '').strip
  end

  # @param site [Jekyll::Site]
  # @return [Hash{String=>Jekyll::Document}] notes by lowercase slug and file name
  def index(site)
    notes = {}
    site.collections.each_value do |collection|
      collection.docs.each do |doc|
        next unless doc.extname == '.md' || doc.extname == '.markdown'

        [doc.data['slug'], File.basename(doc.path, '.*')].compact.each do |key|
          notes[key.downcase] ||= doc
        end
      end
    end
    notes
  end

  # @param notes [Hash] the result of index
  # @param target [String] a slug, a file name or a path, with or without .md
  # @return [Jekyll::Document, nil]
  def lookup(notes, target)
    key = target.strip.sub(%r{\A.*/}, '').sub(/\.(md|markdown)\z/i, '').downcase
    notes[key]
  end

  # The slug in a /posts/<slug>/ address, with or without the site address.
  # @param href [String]
  # @param site [Jekyll::Site]
  # @return [String, nil]
  def post_slug(href, site)
    base = "#{site.config['url']}#{site.config['baseurl']}".sub(%r{/\z}, '')
    path = href.sub(/\A#{Regexp.escape(base)}/, '').sub(/\A\{\{\s*site\.baseurl\s*\}\}/, '')
    path[%r{\A/posts/([^/#?]+)/?(?:[#?].*)?\z}, 1]
  end

  # Rewrites the wikilinks and .md links of one document in place.
  # @param doc [Jekyll::Document]
  # @param notes [Hash] the result of index
  # @param site [Jekyll::Site]
  # @return [Array<Jekyll::Document>] the other notes that doc links to
  def link(doc, notes, site)
    targets = []
    doc.content = doc.content.gsub(WIKILINK) do
      m = Regexp.last_match
      if m[:code]
        m[0]
      elsif m[:target]
        target = lookup(notes, m[:target])
        label = m[:label]&.strip
        if target
          targets << target
          "[#{label || target.data['title']}](#{target.url}#{m[:anchor]})"
        else
          Jekyll.logger.warn 'Notes:', "#{doc.relative_path}: no note called '#{m[:target].strip}'"
          %(<span class="wikilink-missing" title="No note called #{m[:target].strip} yet">#{label || m[:target].strip}</span>)
        end
      else
        href = m[:href]
        if href =~ /\.(md|markdown)(#.*)?\z/i && href !~ %r{\A[a-z]+://}i && (target = lookup(notes, href.sub(/#.*\z/, '')))
          targets << target
          "](#{target.url}#{href[/#.*\z/]}#{m[:title]})"
        else
          slug = post_slug(href, site)
          target = slug && notes[slug.downcase]
          targets << target if target
          m[0]
        end
      end
    end
    targets.uniq - [doc]
  end

  # @param doc [Jekyll::Document]
  # @return [String] the subject of the note (NoteStage.subject)
  def category_of(doc)
    NoteStage.subject(doc)
  end

  # @param doc [Jekyll::Document]
  # @return [Array<String>] primary_tags of the front matter, at most three, else the first two tags
  def primary_tags(doc)
    explicit = Array(doc.data['primary_tags'])
    (explicit.empty? ? Array(doc.data['tags']).first(2) : explicit).first(3)
  end

  # @param site [Jekyll::Site]
  # @param tag [String]
  # @return [String] address of the tag's page, as jekyll-archives builds it
  def tag_url(site, tag)
    config = site.config['jekyll-archives'] || {}
    permalink = config.dig('permalinks', 'tag') || '/tag/:name/'
    slug = Jekyll::Utils.slugify(tag, mode: config['slug_mode'])
    "#{site.config['baseurl']}#{permalink.sub(':name', slug)}"
  end

  # The data of assets/data/notes-graph.json.
  # @param site [Jekyll::Site]
  # @param posts [Array<Jekyll::Document>] the posts to show
  # @param links [Hash{Jekyll::Document=>Array<Jekyll::Document>}] the links of each note
  # @return [Hash] nodes, edges (kind link or tag) and the address of every tag
  def graph(site, posts, links)
    nodes = posts.map do |doc|
      { id: doc.data['slug'], title: plain(doc.data['short_title'] || doc.data['title']), url: doc.url,
        category: category_of(doc), stage: NoteStage.stage(doc), tags: Array(doc.data['tags']),
        primary: primary_tags(doc) }.compact
    end
    ids = posts.to_h { |doc| [doc, doc.data['slug']] }

    edges = []
    posts.each do |doc|
      (links[doc] || []).each do |target|
        edges << { source: ids[doc], target: ids[target], kind: 'link' } if ids[target]
      end
    end

    by_tag = Hash.new { |h, k| h[k] = [] }
    posts.each { |doc| Array(doc.data['tags']).each { |tag| by_tag[tag] << doc } }
    shared = Hash.new { |h, k| h[k] = [] }
    by_tag.each do |tag, docs|
      docs = docs.select { |doc| Array(doc.data['primary_tags']).include?(tag) } if docs.size > TAG_HUB_LIMIT
      docs.combination(2) { |a, b| shared[[ids[a], ids[b]].sort] << tag }
    end
    shared.each { |(a, b), tags| edges << { source: a, target: b, kind: 'tag', weight: tags.size, tags: tags } }

    { nodes: nodes, edges: edges, tags: by_tag.keys.sort.to_h { |tag| [tag, tag_url(site, tag)] } }
  end

  # @param site [Jekyll::Site]
  # @param name [String] file of _includes
  # @param page [Jekyll::Page, Jekyll::Document] the page that the include sees as `page`
  # @return [String] the rendered HTML
  def render_include(site, name, page)
    template = site.liquid_renderer.file(name).parse("{% include #{name} %}")
    template.render!(site.site_payload.merge('page' => page.to_liquid),
                     registers: { site: site, page: page.to_liquid })
  end

  # Inserts html right after the opening tag `marker`; warns and returns output if it is absent.
  # @param output [String] the rendered page
  # @param marker [String] the opening tag
  # @param html [String]
  # @param where [String] the page, for the warning
  # @return [String]
  def prepend_to(output, marker, html, where)
    unless output.include?(marker)
      Jekyll.logger.warn 'Notes:', "no #{marker} in #{where}; the theme's markup may have changed"
      return output
    end
    output.sub(marker) { marker + html }
  end

  # Collects the links of every note, the backlinks of the posts and the graph data file.
  class Generator < Jekyll::Generator
    priority :low

    # @param site [Jekyll::Site]
    def generate(site)
      notes = NotesGraph.index(site)
      links = {}
      site.collections.each_value do |collection|
        collection.docs.each do |doc|
          next unless doc.extname == '.md' || doc.extname == '.markdown'

          links[doc] = NotesGraph.link(doc, notes, site)
        end
      end

      posts = site.posts.docs.reject { |doc| doc.data['hidden'] }
      posts.each do |doc|
        sources = links.select { |_, targets| targets.include?(doc) }.keys
        doc.data['backlinks'] = sources.map do |src|
          { 'url' => src.url, 'title' => src.data['title'], 'description' => src.data['description'] }
        end
      end

      json = Jekyll::PageWithoutAFile.new(site, site.source, 'assets/data', 'notes-graph.json')
      json.content = JSON.generate(NotesGraph.graph(site, posts, links))
      json.data['layout'] = nil
      json.data['sitemap'] = false
      site.pages << json
    end
  end
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
  next unless doc.output_ext == '.html' && doc.output&.include?('id="panel-wrapper"')
  next if doc.data['panel_graph'] == false # the Graph tab, which shows the graph itself

  html = NotesGraph.render_include(doc.site, 'notes-graph.html', doc)
  html += NotesGraph.render_include(doc.site, 'backlinks.html', doc) unless Array(doc.data['backlinks']).empty?
  doc.output = NotesGraph.prepend_to(doc.output, NotesGraph::ACCESS_MARKER, html, doc.relative_path)
end
