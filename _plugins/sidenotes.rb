# frozen_string_literal: true

# Margin notes for posts.
#
# 1. Footnotes: kramdown renders [^1] as a <sup> reference plus an endnote list at the
#    bottom. After rendering, a copy of each footnote is placed right after its first
#    reference as <span class="sidenote">, which CSS floats into the right margin on
#    wide screens. The endnote list stays (and is what narrow screens, the feed and RSS
#    show); on wide screens CSS hides the endnotes that have a margin copy.
#    Footnotes containing block content (lists, code, ...) can't live inside a
#    paragraph, so they stay endnote-only.
#
# 2. {% marginnote %}...{% endmarginnote %}: an unnumbered margin note at that point in
#    the text. Inline Markdown and math work inside it. On narrow screens it renders as
#    an indented note in the text flow.

module Sidenotes
  FOOTNOTES = %r{<div class="footnotes" role="doc-endnotes">\s*<ol>(.*?)</ol>\s*</div>}m
  NOTE = %r{<li id="fn:([^"]+)"([^>]*)>\s*(.*?)\s*</li>}m
  BACKLINK = %r{\s*<a href="#fnref:[^"]+" class="reversefootnote"[^>]*>.*?</a>}m
  BLOCK = /<(?:div|ul|ol|li|pre|table|blockquote|h\d|figure|hr)\b/

  def self.process(html)
    section = html[FOOTNOTES, 1]
    return html unless section

    notes = section.scan(NOTE).to_h { |id, _attrs, body| [id, body.gsub(BACKLINK, "")] }
    converted = []

    notes.each do |id, body|
      next if body.match?(BLOCK)

      ref = %r{<sup id="fnref:#{Regexp.escape(id)}"[^>]*><a [^>]*>([^<]*)</a></sup>}
      inline = body.gsub("<p>", %(<span class="sidenote-p">)).gsub("</p>", "</span>")
      replaced = html.sub(ref) do |sup|
        %(#{sup}<span class="sidenote" role="note"><span class="sidenote-number">#{Regexp.last_match(1)}</span>#{inline}</span>)
      end
      next if replaced == html

      html = replaced
      converted << id
    end
    return html if converted.empty?

    html = html.sub(FOOTNOTES) do |block|
      block = block.gsub(%r{<li id="fn:([^"]+)"}) do
        converted.include?(Regexp.last_match(1)) ? %(<li id="fn:#{Regexp.last_match(1)}" class="has-sidenote") : Regexp.last_match(0)
      end
      converted.size == notes.size ? block.sub('class="footnotes"', 'class="footnotes all-sidenotes"') : block
    end
    return html unless converted.size == notes.size

    # Every note is in the margin, so the post's own "Footnotes" heading (and its TOC
    # entry) would head an empty section on wide screens; mark them so CSS can hide them.
    html
      .sub(/<(h[1-6]) id="footnotes"/, '<\1 id="footnotes" class="footnotes-heading"')
      .sub(%r{<li><a href="#footnotes">}, '<li class="footnotes-heading"><a href="#footnotes">')
  end

  class MarginNoteTag < Liquid::Block
    def render(context)
      %(<span class="sidenote marginnote" role="note">#{super.strip}</span>)
    end
  end
end

Liquid::Template.register_tag("marginnote", Sidenotes::MarginNoteTag)

Jekyll::Hooks.register :posts, :post_render do |post|
  post.output = Sidenotes.process(post.output)
end
