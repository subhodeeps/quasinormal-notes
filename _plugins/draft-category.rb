#!/usr/bin/env ruby
#
# Stages of the notes that the site does not publish.
#
# Gives every draft the stage Draft, every stub in _drafts/to-write/ the stage To Write and every
# note in _drafts/private/ the stage Private, in `stage` of its data. The stage stays out of
# `categories`, so that a note has the same categories in the preview and on the deployed site
# (as the first category, a stage would hide Physics from Chirpy's Categories tab). The graph and
# the home page colour a note by its subject, its first category, and mark the stage with a
# dashed outline, and post-topics-top.rb names it in the post's header. Drafts exist only in the
# local preview (`tools/run.sh -d`), since the deployed site builds without --drafts.
#
# Hook: :site, :post_read. Provides NoteStage for notes-graph.rb, home-tiles.rb and
# post-topics-top.rb.

# The subject and the stage of a note. `module_function` methods, called as NoteStage.subject(doc).
module NoteStage
  STAGES = ['Draft', 'To Write', 'Private'].freeze

  module_function

  # The first category, which sets the colour of the note.
  # @param doc [Jekyll::Document]
  # @return [String] the category, or "" if there is none
  def subject(doc)
    Array(doc.data['categories']).first.to_s
  end

  # The stage of a note that is not published.
  # @param doc [Jekyll::Document]
  # @return [String, nil] Draft, To Write or Private; nil for a published post
  def stage(doc)
    doc.data['stage'] if STAGES.include?(doc.data['stage'])
  end
end

# The stage of a draft, from its folder.
# @param post [Jekyll::Document]
# @return [String] Private (_drafts/private/), To Write (_drafts/to-write/) or Draft
def note_kind(post)
  return 'Private' if post.relative_path.start_with?('_drafts/private/')
  return 'To Write' if post.relative_path.start_with?('_drafts/to-write/')

  'Draft'
end

Jekyll::Hooks.register :site, :post_read do |site|
  site.posts.docs.each do |post|
    post.data['stage'] = note_kind(post) if post.draft?
  end
end
