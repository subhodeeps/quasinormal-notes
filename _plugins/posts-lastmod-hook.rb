#!/usr/bin/env ruby
#
# Date of the last change of a post, from git.
#
# Sets `last_modified_at` to the date of the last commit that touched the post, for posts with
# more than one commit. Chirpy shows it as "Updated" and uses it in the feed and the sitemap.
# This is the hook of Chirpy's starter template, kept as it is.
#
# Hook: :posts, :post_init. Needs git and the repository history at build time.

Jekyll::Hooks.register :posts, :post_init do |post|

  commit_num = `git rev-list --count HEAD "#{ post.path }"`

  if commit_num.to_i > 1
    lastmod_date = `git log -1 --pretty="%ad" --date=iso "#{ post.path }"`
    post.data['last_modified_at'] = lastmod_date
  end

end
