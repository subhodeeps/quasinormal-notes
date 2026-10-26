#!/usr/bin/env ruby
#
# Serves the includes and assets of the drafts from inside _drafts/.
#
# _drafts/ mirrors the root of the site, so a draft uses {% include code/x.py %} and
# /assets/images/... exactly as a published post does, and publishing means moving each file
# to the same path at the root. The hook adds _drafts/_includes to the include paths and
# _drafts/assets/** to the static files. It does nothing without --drafts.
#
# Hook: :site, :post_read. Jekyll does not watch _drafts/assets/, so restart the preview after
# adding a file there.

Jekyll::Hooks.register :site, :post_read do |site|
  next unless site.show_drafts

  drafts = site.in_source_dir('_drafts')

  # Look in _drafts/_includes after _includes, and before the theme
  includes = File.join(drafts, '_includes')
  if File.directory?(includes) && !site.includes_load_paths.include?(includes)
    site.includes_load_paths.insert(1, includes)
  end

  Dir.glob('assets/**/*', base: drafts).sort.each do |path|
    next if File.directory?(File.join(drafts, path)) || File.basename(path).start_with?('.')

    site.static_files << Jekyll::StaticFile.new(site, drafts, File.dirname(path), File.basename(path))
  end
end
