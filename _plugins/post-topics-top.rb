#!/usr/bin/env ruby
#
# Categories and tags of a post under its byline instead of at its foot.
#
# Chirpy puts them in the footer of a post, above the licence and the share buttons. The hook
# cuts that block out of the footer and sets it at the end of the post's header in
# <div class="post-topics"> (_sass/_post-topics.scss). It finds the footer
# (TAIL), the end of the block (BOTTOM) and the post's header (TITLE, HEADER_END) by their markup.
# If a marker is missing, it prints a build warning and leaves the page as Chirpy renders it.
#
# In the block, Chirpy's list of categories becomes the paths of the note (CategoryTree.trail,
# _plugins/category-tree.rb), such as Physics › Black Holes › Black Hole Shadows, with Chirpy's
# links, and an unpublished note shows its stage (NoteStage, _plugins/draft-category.rb) first.
#
# Hook: :posts, :post_render.

require 'cgi'

# Moves the topics block from the footer to the header. `module_function` methods.
module PostTopics
  TAIL = '<div class="post-tail-wrapper'   # the footer, which opens with the categories and the tags
  BOTTOM = 'post-tail-bottom'              # the licence and the share buttons, which end that block
  TITLE = '<h1'                            # the title, in the header of the post (the sidebar has its own header)
  HEADER_END = '</header>'                 # the end of that header, after the byline
  # Chirpy's categories: the folder icon, the links, and the end of their div
  FOLDER = %r{(<i class="far fa-folder-open[^"]*"></i>)(.*?)(</div>)}m

  module_function

  # @param output [String] the rendered post
  # @param post [Jekyll::Document]
  # @return [String] the page with the block moved, or output itself if a marker is missing
  def moved(output, post)
    tail = output.index(TAIL)
    first = tail && output.index('>', tail)
    bottom = first && output.index(BOTTOM, first)
    stop = bottom && output.rindex('<div', bottom)
    title = output.index(TITLE)
    header = title && output.index(HEADER_END, title)
    unless first && stop && header && header < tail
      Jekyll.logger.warn 'Topics:', "no footer or header marker in #{post.relative_path}; the theme's markup may have changed"
      return output
    end

    block = output[(first + 1)...stop]
    return output if block.strip.empty?

    without = output[0..first] + output[stop..]
    at = without.index(HEADER_END, without.index(TITLE))
    without[0...at] + %(<div class="post-topics">#{with_paths(block, post)}</div>) + without[at..]
  end

  # The block with the categories as paths and the stage first; unchanged if it has no categories.
  # @param block [String] Chirpy's categories and tags
  # @param post [Jekyll::Document]
  # @return [String]
  def with_paths(block, post)
    block.sub(FOLDER) do
      icon, links, close = Regexp.last_match.captures
      named = links.scan(%r{(<a\b[^>]*>(.*?)</a>)}m).to_h { |link, text| [CGI.unescapeHTML(text.strip), link] }
      trail = defined?(CategoryTree) && CategoryTree.trail(post, named)
      stage = NoteStage.stage(post) if defined?(NoteStage)
      pill = stage ? %(<span class="note-stage">#{stage}</span>) : ''
      "#{pill}#{icon}#{trail || links}#{close}"
    end
  end
end

Jekyll::Hooks.register :posts, :post_render do |post|
  next unless post.output_ext == '.html'

  post.output = PostTopics.moved(post.output, post)
end
