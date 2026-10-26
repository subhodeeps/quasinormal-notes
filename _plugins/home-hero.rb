#!/usr/bin/env ruby
#
# Hero of the home page and the headings of its post list.
#
# Inserts _includes/home-hero.html, with the heading `hero.list_heading` of index.html, above the
# post list of every page of the home list (the first and /page2/ onwards). Chirpy's home layout
# has no place for it, so the hook edits the rendered page and leaves the layout alone. The pinned
# posts and categories open the grid of tiles of the first page (_plugins/home-tiles.rb).
#
# Depends on Chirpy's markup `<div id="post-list"`. If it is missing, the hook prints a build
# warning and leaves the page unchanged.
#
# Hook: :pages, :post_render. Runs before home-tiles.rb splits the list into tiles.

# Chirpy's container of the post list, before which the hero goes.
MARKER = '<div id="post-list"'

Jekyll::Hooks.register :pages, :post_render do |page|
  next unless page.url.to_s.match?(%r{\A/(page\d+/?)?\z}) && page.data['hero'] # every page of the home list

  unless page.output.include?(MARKER)
    Jekyll.logger.warn 'Home hero:', "'#{MARKER}' not found on the home page; the theme's markup may have changed"
    next
  end

  site = page.site
  hero = page.data['hero']
  template = site.liquid_renderer.file('home-hero').parse('{% include home-hero.html %}')
  html = template.render!(
    site.site_payload.merge('page' => page.to_liquid),
    registers: { site: site, page: page.to_liquid }
  )
  page.output = page.output.sub(MARKER) { html + MARKER }
end
