#!/usr/bin/env ruby
#
# Prints the category tree of the notes, or the tags with their counts, from the front matter of
# _posts/ and _drafts/, without a build of the site.
#
# The tree follows the rules of _plugins/category-tree.rb: `categories` is a path from the primary
# category down, `also_in` adds paths, and `order` places a note in its own category. A category
# that holds only unpublished notes is marked with an asterisk, and a pinned one with "pinned" after its count.
# Categories follow the order of _data/categories.yml: pinned first, then by `order`, then by name. With --write, the tree replaces
# the part of docs/categories-and-tags.md between `<!-- tree:start -->` and `<!-- tree:end -->`.
#
# Usage (after `source .venv/bin/activate`):
#   ruby tools/categories.rb            the tree, with the number of notes in each category
#   ruby tools/categories.rb --notes    the tree with the notes of each category, in order
#   ruby tools/categories.rb --tags     every tag with the number of its notes
#   ruby tools/categories.rb --write    the tree into docs/categories-and-tags.md

require 'date'
require 'yaml'

ROOT = File.expand_path('..', __dir__)
DOC = File.join(ROOT, 'docs', 'categories-and-tags.md')
META = (File.exist?(File.join(ROOT, '_data', 'categories.yml')) && YAML.safe_load(File.read(File.join(ROOT, '_data', 'categories.yml')))) || {}

# @return [Array] the place of a category among its siblings, as _plugins/category-tree.rb sorts them
def rank(name)
  pin = META.dig(name, 'pin') == true
  order = META.dig(name, 'order')
  [pin ? 0 : 1, order.nil? ? 1 : 0, order.to_f, name.downcase]
end

# A note: its title, its paths, its order, its date and whether it is published.
Note = Struct.new(:title, :paths, :order, :date, :published, :tags)

# @return [Array<Note>] the notes of _posts/ and _drafts/, without the folders Jekyll skips
def notes
  files = Dir.glob(File.join(ROOT, '_posts', '*.md')) +
          Dir.glob(File.join(ROOT, '_drafts', '**', '*.md')).reject { |f| f.sub("#{ROOT}/_drafts/", '').split('/')[0..-2].any? { |d| d.start_with?('_', '.') } }
  files.sort.filter_map do |file|
    text = File.read(file)
    next unless text.start_with?("---\n")

    data = YAML.safe_load(text[4...text.index("\n---", 4)], permitted_classes: [Date, Time]) || {}
    next if data['hidden']

    extra = Array(data['also_in'])
    extra = [extra] unless extra.empty? || extra.first.is_a?(Array)
    paths = [data['categories'], *extra].map { |p| Array(p).map(&:to_s).reject(&:empty?).uniq }.reject(&:empty?)
    Note.new(data['title'].to_s.gsub(/<[^>]+>/, ''), paths, data['order'], data['date'].to_s,
             file.include?('/_posts/'), Array(data['tags']).map(&:to_s))
  end
end

# @return [Hash] the tree: name => { children: Hash, notes: [[Note, main]] }
def tree(all)
  root = {}
  all.each do |note|
    note.paths.each_with_index do |path, i|
      level = root
      path.each_with_index do |name, depth|
        node = (level[name] ||= { children: {}, notes: [] })
        node[:notes] << [note, i.zero?] if depth == path.length - 1
        level = node[:children]
      end
    end
  end
  root
end

# @return [Array<Note>] every note in the subtree, once
def under(node)
  (node[:notes].map(&:first) + node[:children].values.flat_map { |child| under(child) }).uniq
end

# @return [Array<Array(Note, Boolean)>] the notes of a category: ordered ones first, then newest first
def ordered(node)
  first, rest = node[:notes].partition { |note, main| main && !note.order.nil? }
  first.sort_by { |note, _| note.order.to_f } + rest.sort_by { |note, _| note.date }.reverse
end

# @return [Array<String>] the lines of the tree, indented by level
def lines(level, depth = 0, with_notes: false)
  level.sort_by { |name, _| rank(name) }.flat_map do |name, node|
    all = under(node)
    mark = all.none?(&:published) ? ' *' : ''
    pin = META.dig(name, 'pin') == true ? ', pinned' : ''
    head = "#{'  ' * depth}- #{name}#{mark} (#{all.size}#{pin})"
    notes = with_notes ? ordered(node).map { |note, main| "#{'  ' * (depth + 1)}  #{main && note.order ? "#{note.order}. " : '· '}#{note.title}#{note.published ? '' : ' *'}" } : []
    [head, *notes, *lines(node[:children], depth + 1, with_notes: with_notes)]
  end
end

all = notes
if ARGV.include?('--tags')
  all.flat_map(&:tags).tally.sort_by { |tag, n| [-n, tag] }.each { |tag, n| puts format('%4d  %s', n, tag) }
elsif ARGV.include?('--write')
  text = File.read(DOC)
  block = "<!-- tree:start -->\n```text\n#{lines(tree(all)).join("\n")}\n```\n<!-- tree:end -->"
  File.write(DOC, text.sub(/<!-- tree:start -->.*<!-- tree:end -->/m, block))
  puts "Wrote the tree into #{DOC.sub("#{ROOT}/", '')}"
else
  puts lines(tree(all), with_notes: ARGV.include?('--notes'))
  puts "\n* only unpublished notes"
end
