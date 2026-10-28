#!/usr/bin/env ruby
#
# Schola, the MathJax 4 font in the style of Century Schoolbook, for the math of every page.
#
# Chirpy loads MathJax from the address in its data file _data/origin/cors.yml (mathjax.js), the
# combined component tex-mml-chtml.js, whose default font is New Computer Modern, and its
# assets/js/data/mathjax.js sets no font. The hook points that address at the same component bundled
# with Schola (tex-mml-chtml-mathjax-schola.js of the package @mathjax/mathjax-schola-font), of the
# same version, so that neither Chirpy's data file nor its script is copied. The math sits beside
# the Merriweather of the posts on phones (_sass/mobile/_fonts.scss), whose sturdy, wide letters
# Schola matches.
#
# Depends on site.data['origin']['cors']['mathjax']['js'] from Chirpy's data. If it is missing, the
# hook prints a build warning and MathJax keeps its default font.
#
# Hook: :site, :post_read.

# The address of the Schola bundle of MathJax, of the version that Chirpy's data names (major 4)
SCHOLA_MATHJAX = 'https://cdn.jsdelivr.net/npm/@mathjax/mathjax-schola-font@4.1.3/tex-mml-chtml-mathjax-schola.js'

Jekyll::Hooks.register :site, :post_read do |site|
  mathjax = site.data.dig('origin', 'cors', 'mathjax')
  if mathjax.is_a?(Hash) && mathjax['js'].to_s.include?('mathjax')
    mathjax['js'] = SCHOLA_MATHJAX
  else
    Jekyll.logger.warn 'MathJax font:', "Chirpy's data has no origin.cors.mathjax.js; the math keeps MathJax's default font"
  end
end
