# frozen_string_literal: true

# Post-render HTML tweaks:
#   - Code blocks get data-lang="<language>" so CSS can show a language tab.
#   - Headings with ids inside posts get a hover "#" anchor link.

module CodeLang
  LABELS = { "cpp" => "c++", "plaintext" => nil, "text" => nil }.freeze

  BLOCK = /<div class="language-([\w+#.\-]+) highlighter-rouge">/
  HEADING = %r{<(h[1-3]) id="([^"]+)"([^>]*)>(.*?)</\1>}m

  def self.process(html, anchors:)
    html = html.gsub(BLOCK) do
      lang = Regexp.last_match(1)
      label = LABELS.fetch(lang, lang)
      label ? %(<div class="language-#{lang} highlighter-rouge" data-lang="#{label}">) : Regexp.last_match(0)
    end
    return html unless anchors

    html.gsub(HEADING) do
      tag, id, attrs, inner = Regexp.last_match.captures
      %(<#{tag} id="#{id}"#{attrs}>#{inner}<a class="anchor" href="##{id}" aria-label="Link to this section">#</a></#{tag}>)
    end
  end
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
  next unless doc.output_ext == ".html"

  doc.output = CodeLang.process(doc.output, anchors: doc.respond_to?(:collection) && doc.collection&.label == "posts")
end
