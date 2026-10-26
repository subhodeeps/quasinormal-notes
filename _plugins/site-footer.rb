#!/usr/bin/env ruby
#
# Footer of every page from _includes/site-footer.html.
#
# Replaces the content of Chirpy's `<footer aria-label="Site Info">` after rendering, so that
# the theme's footer.html stays untouched and the element remains where Chirpy's layout expects
# it. The include is rendered once per build (:pre_render) and inserted in every page
# (:post_render). If a page has no such footer, the hook prints a build warning. Styles:
# _sass/_footer.scss.

# Chirpy's footer element, which the hook replaces.
FOOTER = %r{<footer\s+aria-label="Site Info"[^>]*>.*?</footer>}m

Jekyll::Hooks.register :site, :pre_render do |site|
  template = site.liquid_renderer.file('site-footer').parse('{% include site-footer.html %}')
  site.config['site_footer_html'] = template.render!(site.site_payload, registers: { site: site })
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
  next unless doc.output_ext == '.html' && doc.output.include?('<footer')

  html = doc.site.config['site_footer_html']
  footer = %(<footer aria-label="Site Info" class="site-footer">\n#{html}</footer>)
  output = doc.output.sub(FOOTER) { footer }
  if output.equal?(doc.output) || output == doc.output
    Jekyll.logger.warn 'Site footer:', "no Chirpy footer found in #{doc.relative_path}; the theme's markup may have changed"
  end
  doc.output = output
end
