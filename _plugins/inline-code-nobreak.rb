#!/usr/bin/env ruby
#
# Keeps a word of inline code from breaking at its hyphens.
#
# Browsers may break a line after any hyphen, which splits a flag such as `-rfbport=5900`.
# The hook wraps each space-free token of inline code that contains a hyphen in
# <span class="code-token">, which does not wrap (_sass/_code-font.scss), so long commands
# still wrap between words. Tokens longer than MAX_TOKEN stay breakable and cannot overflow a
# phone screen. Code blocks and inline code that contains markup are left alone, and the
# copied text is unchanged.
#
# Hook: :documents and :pages, :post_render.

# Longest token, in characters, that is kept in one piece.
MAX_TOKEN = 40
# An inline code element of Rouge, with its opening tag, its body and its closing tag.
INLINE_CODE = %r{(<code class="[^"]*\bhighlighter-rouge\b[^"]*">)(.*?)(</code>)}m

Jekyll::Hooks.register [:documents, :pages], :post_render do |doc|
  next unless doc.output_ext == '.html' && doc.output.include?('highlighter-rouge')

  doc.output = doc.output.gsub(INLINE_CODE) do
    open, body, close = Regexp.last_match.captures
    next Regexp.last_match[0] if body.include?('<') # not plain text: leave it as it is

    tokens = body.gsub(/[^\s]+/) do |token|
      token.include?('-') && token.length <= MAX_TOKEN ? %(<span class="code-token">#{token}</span>) : token
    end
    open + tokens + close
  end
end
