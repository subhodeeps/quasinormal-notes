#!/usr/bin/env ruby
#
# Right panel of a post without "Recently Updated".
#
# The panel of a post shows the note graph (notes-graph.rb) and Chirpy's "Contents". The
# hook removes the section `<section id="access-lastmod">` from the page, so the Contents sit
# right below the graph and stay in view when the reader scrolls. The recent posts remain on the
# pages of the sidebar (home, categories, tags, archives, tabs).
#
# If the theme's markup changes, there is no section to remove and the page stays as Chirpy
# renders it.
#
# Hook: :posts, :post_render.

# Removes "Recently Updated" from the right panel. `module_function` methods.
module PostPanel
  # Opening tag of that section.
  RECENT = '<section id="access-lastmod">'

  module_function

  # The page without the section from RECENT to its closing tag.
  # @param output [String] the rendered page
  # @return [String] output itself if the section is missing
  def without_recent(output)
    start = output.index(RECENT)
    stop = start && output.index('</section>', start)
    return output unless stop

    output[0...start] + output[(stop + '</section>'.length)..]
  end
end

Jekyll::Hooks.register :posts, :post_render do |post|
  next unless post.output_ext == '.html'

  post.output = PostPanel.without_recent(post.output)
end
