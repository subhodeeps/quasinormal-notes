#!/usr/bin/env ruby
#
# Plain text in the <title> of every page.
#
# A post title may contain markup, such as <code>odeint</code>, which Chirpy shows as a chip in
# the heading. The <title> element cannot hold markup, so the hook strips the tags from it and
# leaves the heading as it is. A tab of this site that the theme's locale file does not name
# gets its own title, so that the browser tab does not start with " | Quasinormal Notes".
#
# Hook: :pages and :documents, :post_render.

Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
  next unless doc.output_ext == '.html' && doc.output&.include?('<title>')

  doc.output = doc.output.sub(%r{<title>(.*?)</title>}m) do
    title = Regexp.last_match(1).gsub(/<[^>]+>/, '').strip
    title = "#{doc.data['title']} #{title}" if title.start_with?('|') && doc.respond_to?(:collection) && doc.collection&.label == 'tabs'
    "<title>#{title}</title>"
  end
end
