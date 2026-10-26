#!/usr/bin/env ruby
#
# Hero of the home page and the headings of its post list.
#
# Inserts _includes/home-hero.html above the post list and, when the front matter of
# index.html gives `hero.pinned_heading` and `hero.list_heading`, folds the pinned posts under the
# first heading (<details class="home-pinned">, open at first) and puts the second after them.
# Chirpy's home layout lists pinned and other posts as one run of cards, so the hook edits the
# rendered page and leaves the layout alone.
#
# Depends on Chirpy's markup `<div id="post-list"` and `<article class="card-wrapper card">`.
# If either is missing, the hook prints a build warning and leaves the page unchanged.
#
# Hook: :pages, :post_render. Runs before home-tiles.rb splits the list into tiles.

# Chirpy's container of the post list, before which the hero goes.
MARKER = '<div id="post-list"'
# Opening tag of a post card, which separates the pinned posts from the rest.
CARD = '<article class="card-wrapper card">'

Jekyll::Hooks.register :pages, :post_render do |page|
  next unless page.url == '/' && page.data['hero']

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

  # Chirpy shows the pinned posts first; put the "latest" heading after them
  pinned = [site.posts.docs.count { |post| post.data['pin'] }, site.config['paginate'] || 10].min
  next unless pinned.positive? && hero['pinned_heading'] && hero['list_heading']

  cards = page.output.split(CARD, -1) # cards[0] is everything before the first card
  if cards.size - 1 <= pinned
    Jekyll.logger.warn 'Home hero:', "found #{cards.size - 1} '#{CARD}' for #{pinned} pinned posts" if cards.size == 1
    next
  end

  # The pinned posts fold under their heading; assets/js/home-tiles.js remembers the choice
  cards[0] += %(<details class="home-pinned" open><summary class="home-list-heading">#{hero['pinned_heading']}) +
              %(<i class="fas fa-angle-right"></i></summary>\n)
  cards[pinned] += %(</details>\n<h2 class="home-list-heading">#{hero['list_heading']}</h2>\n)
  page.output = cards.join(CARD)
end
