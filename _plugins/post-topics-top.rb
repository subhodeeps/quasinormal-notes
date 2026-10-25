#!/usr/bin/env ruby
#
# Author(s): Subhodeep Sarkar
# Affiliation: IIT Gandhinagar and IIIT Allahabad
# Contact: subhodeep.sarkar1@gmail.com
# Date: October 2026
#
# The categories and the tags of a post, after its byline instead of at the foot of the page.
#
# Chirpy puts them in the footer of a post, above the licence and the share buttons. After the
# page is rendered, this hook cuts that block out of the footer and sets it at the end of the
# post's header, under the date and the author, in a div of its own (.post-topics, styled in
# _sass/_post-topics.scss). The theme's layouts are not changed. If a theme update moves one of
# the markers below, the hook prints a build warning and leaves the page as Chirpy renders it.

module PostTopics
  TAIL = '<div class="post-tail-wrapper'   # the footer, which opens with the categories and the tags
  BOTTOM = 'post-tail-bottom'              # the licence and the share buttons, which end that block
  TITLE = '<h1'                            # the title, in the header of the post (the sidebar has its own header)
  HEADER_END = '</header>'                 # the end of that header, after the byline

  module_function

  # The page with the block between the footer's opening tag and the licence moved into the header,
  # or the page unchanged, with a warning, if a marker is missing
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
