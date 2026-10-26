#!/usr/bin/env ruby
#
# Stage categories of the notes that the site does not publish.
#
# Puts the category Draft on every draft, To Write on every stub in _drafts/to-write/ and
# Private on every note in _drafts/private/, ahead of the note's own categories. The graph
# and the home page colour a note by its subject (its first category after the stage) and mark
# the stage with a dashed outline. Drafts exist only in the local preview (`tools/run.sh -d`),
# since the deployed site builds without --drafts.
#
# Hook: :site, :post_read. Provides NoteStage for notes-graph.rb and home-tiles.rb.

# The stages of unpublished notes. `module_function` methods, called as NoteStage.subject(doc).
module NoteStage
  # Category names that mark a stage and never set a colour.
  STAGES = ['Draft', 'To Write', 'Private'].freeze

  module_function

  # The first category that is not a stage, which sets the colour of the note.
  # @param doc [Jekyll::Document]
  # @return [String] the category, or "" if there is none
  def subject(doc)
    (Array(doc.data['categories']) - STAGES).first.to_s
  end

  # The stage of a note that is not published.
  # @param doc [Jekyll::Document]
  # @return [String, nil] Draft, To Write or Private; nil for a published post
  def stage(doc)
    (Array(doc.data['categories']) & STAGES).first
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
    next unless post.draft?

    kind = note_kind(post)
    post.data['categories'] = [kind] + (Array(post.data['categories']) - [kind])
  end
end
