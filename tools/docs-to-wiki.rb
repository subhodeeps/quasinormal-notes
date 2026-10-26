#!/usr/bin/env ruby
#
# Copies the guides of docs/ into the GitHub wiki of the repository, ready to be committed there.
#
# The wiki is a git repository of its own (quasinormal-notes.wiki.git), cloned into .wiki/ at the
# root of the site, which Git and Jekyll ignore. docs/README.md becomes the page Home, and every
# other docs/<name>.md the page named after its first heading, without that heading, since the
# wiki shows the name as the title. Links between the guides become links between the pages, and
# _Sidebar.md lists the pages beside every page. The script commits and pushes nothing: it prints
# the commands, because a push publishes the pages (the wiki of a public repository is public).
#
# Usage (after `source .venv/bin/activate`): ruby tools/docs-to-wiki.rb

ROOT = File.expand_path('..', __dir__)
DOCS = File.join(ROOT, 'docs')
WIKI = File.join(ROOT, '.wiki')
REMOTE = 'https://github.com/subhodeeps/quasinormal-notes.wiki.git'

if File.directory?(WIKI)
  system('git', '-C', WIKI, 'pull', '--ff-only', '--quiet') || abort('Could not update .wiki; resolve it there first.')
else
  system('git', 'clone', '--quiet', REMOTE, WIKI) || abort("Could not clone #{REMOTE}; does the wiki have a first page?")
end

# docs/<file> => [page name, text without its first heading]
pages = Dir.glob(File.join(DOCS, '*.md')).sort.to_h do |file|
  text = File.read(file)
  title = text[/\A# (.+)$/, 1] || File.basename(file, '.md')
  name = File.basename(file) == 'README.md' ? 'Home' : title.strip.gsub(/[^\w]+/, '-')
  [File.basename(file), [name, text.sub(/\A# .+\n+/, '')]]
end

pages.each_value do |name, text|
  linked = text.gsub(/\]\(([\w.-]+\.md)(#[^)]*)?\)/) { pages[Regexp.last_match(1)] ? "](#{pages[Regexp.last_match(1)][0]}#{Regexp.last_match(2)})" : Regexp.last_match(0) }
  File.write(File.join(WIKI, "#{name}.md"), linked)
end

sidebar = pages.values.map { |name, _| "- [#{name == 'Home' ? 'Home' : name.tr('-', ' ')}](#{name})" }
File.write(File.join(WIKI, '_Sidebar.md'), "#{sidebar.join("\n")}\n\nThese pages mirror `docs/` of the repository; edit them there.\n")

system('git', '-C', WIKI, 'status', '--short')
puts <<~TEXT

  The wiki pages are in .wiki/. To publish them, run:

    git -C .wiki add -A
    git -C .wiki commit -m "Update the guides from docs/"
    git -C .wiki push
TEXT
