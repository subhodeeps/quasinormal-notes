#!/usr/bin/env ruby
#
# No browser cache in the local preview.
#
# `jekyll serve` sends Cache-Control: no-store with the pages, but with live reload it answers
# requests for other files, such as styles, scripts and the graph data, before it adds the
# header, so a browser may reuse an old stylesheet after a change. The plugin prepends
# PreviewNoCache to Jekyll's servlet and sets the header on every response. After a build it
# also replaces the service worker of a production build with RETIRE_WORKER, which clears the
# caches and unregisters itself.
#
# Active only while serving (`site.config['serving']`); the deployed static site is unaffected.
#
# Hooks: :site, :after_init and :post_write.

# Prepended to Jekyll's WEBrick servlet.
module PreviewNoCache
  # Answers as before and then sets the no-cache header on every response.
  def do_GET(request, response)
    result = super
    # The same key as Jekyll's own header, so that pages carry it once
    response.header.merge!('Cache-Control' => 'private, max-age=0, no-store, no-cache, must-revalidate')
    result
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  next unless site.config['serving']

  require 'jekyll/commands/serve/servlet'
  servlet = Jekyll::Commands::Serve::Servlet
  servlet.prepend(PreviewNoCache) unless servlet.ancestors.include?(PreviewNoCache)
end

# Service worker that deletes the caches, unregisters itself and reloads the open pages.
RETIRE_WORKER = <<~JS
  // The local preview has no offline cache (_plugins/preview-no-cache.rb). This worker
  // replaces one that a production build installed: it deletes the caches, unregisters
  // itself and reloads the open pages.
  self.addEventListener('install', () => self.skipWaiting());
  self.addEventListener('activate', (event) => {
    event.waitUntil((async () => {
      for (const key of await caches.keys()) await caches.delete(key);
      await self.registration.unregister();
      for (const client of await self.clients.matchAll({ type: 'window' })) client.navigate(client.url);
    })());
  });
JS

Jekyll::Hooks.register :site, :post_write do |site|
  next unless site.config['serving']

  worker = File.join(site.dest, 'sw.min.js')
  File.write(worker, RETIRE_WORKER) if File.exist?(worker)
end
