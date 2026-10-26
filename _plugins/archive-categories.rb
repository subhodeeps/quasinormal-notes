#!/usr/bin/env ruby
#
# Category colour and path in the Archives tab.
#
# Each entry of Chirpy's archive list shows the short title of its note (`short_title`, as the graph
# does, when it has one) and gets the colour of its note's subject (`--note`, as on the
# home tiles) on the dot of the timeline, and its category path, muted, after the title (for
# example Physics › Black Holes › Black Hole Shadows). The pairing is by the address of the link.
#
# Depends on Chirpy's `<div id="archives"` with items `<li> ... <a href="...">title</a>`. If they
# are missing, the hook prints a build warning and leaves the page as Chirpy renders it.
#
# Hook: :documents, :post_render (the Archives tab). Styles: _sass/_tag-groups.scss.
# Needs CategoryTree and NoteStage.

require 'cgi'

Jekyll::Hooks.register :documents, :post_render do |doc|
  next unless doc.data['layout'] == 'archives' && doc.output_ext == '.html'

  site = doc.site
  posts = site.posts.docs.to_h { |post| ["#{site.baseurl}#{post.url}", post] }
  count = 0
  doc.output = doc.output.gsub(%r{<li>(\s*<span class="date day".*?<a href="([^"]+)">)(.*?)(</a>)}m) do
    m = Regexp.last_match # later regular expressions would replace it
    post = posts[m[2]]
    next m[0] unless post

    count += 1
    slug = NoteStage.subject(post).downcase.strip.gsub(/[^a-z0-9]+/, '-')
    path = Array(Array(post.data['category_paths']).first).map { |name| CGI.escapeHTML(name) }.join(CategoryTree::SEP)
    # the short title of the note, which the graph uses, in place of its full title
    short = CGI.escapeHTML(post.data['short_title'].to_s.strip)
    %(<li style="--note: var(--graph-node-#{slug}, var(--graph-node))">#{m[1]}#{short.empty? ? m[3] : short}#{m[4]}) +
      (path.empty? ? '' : %( <span class="archive-path">#{path}</span>))
  end
  Jekyll.logger.warn 'Archive categories:', "no Chirpy entries found in #{doc.url}; the theme's markup may have changed" if count.zero?
end
