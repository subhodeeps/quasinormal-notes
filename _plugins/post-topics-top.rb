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
# Hook: :posts, :post_render.

# Moves the topics block from the footer to the header. `module_function` methods.
module PostTopics
  TAIL = '<div class="post-tail-wrapper'   # the footer, which opens with the categories and the tags
  BOTTOM = 'post-tail-bottom'              # the licence and the share buttons, which end that block
  TITLE = '<h1'                            # the title, in the header of the post (the sidebar has its own header)
  HEADER_END = '</header>'                 # the end of that header, after the byline

  module_function

  # @param output [String] the rendered post
  # @param where [String] the post, for the warning
  # @return [String] the page with the block moved, or output itself if a marker is missing
  def moved(output, where)
    tail = output.index(TAIL)
    first = tail && output.index('>', tail)
    bottom = first && output.index(BOTTOM, first)
    stop = bottom && output.rindex('<div', bottom)
    title = output.index(TITLE)
    header = title && output.index(HEADER_END, title)
    unless first && stop && header && header < tail
      Jekyll.logger.warn 'Topics:', "no footer or header marker in #{where}; the theme's markup may have changed"
      return output
    end

    block = output[(first + 1)...stop]
    return output if block.strip.empty?

    without = output[0..first] + output[stop..]
    at = without.index(HEADER_END, without.index(TITLE))
    without[0...at] + %(<div class="post-topics">#{block}</div>) + without[at..]
  end
end

Jekyll::Hooks.register :posts, :post_render do |post|
  next unless post.output_ext == '.html'

  post.output = PostTopics.moved(post.output, post.relative_path)
end
