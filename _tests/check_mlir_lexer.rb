# frozen_string_literal: true

# Runs the MLIR Rouge lexer over every ```mlir block in _posts and checks it never
# emits Error tokens and recognizes ops, SSA values, types and attributes.
#   bundle exec ruby _tests/check_mlir_lexer.rb

require_relative "../_plugins/rouge_mlir"

root = File.expand_path("..", __dir__)
blocks = Dir[File.join(root, "_posts", "*.md")].sort.flat_map do |path|
  File.read(path).scan(/^\s*```mlir\s*\n(.*?)^\s*```\s*$/m).map { |(code)| [File.basename(path), code] }
end
abort "no ```mlir blocks found" if blocks.empty?

lexer = Rouge::Lexers::MLIR.new
seen = Hash.new(0)
failures = []

blocks.each do |file, code|
  lexer.lex(code).each do |token, value|
    seen[token.qualname] += 1
    failures << "#{file}: Error token #{value.inspect}" if token <= Rouge::Token::Tokens::Error
  end
end

expected = {
  "op" => "Keyword",
  "SSA value" => "Name.Variable",
  "type" => "Keyword.Type",
  "attribute" => "Name.Attribute",
  "number" => "Literal.Number.Integer",
}
expected.each do |what, qualname|
  failures << "never lexed a #{what} (#{qualname})" if seen[qualname].zero?
end

puts "#{blocks.size} blocks; token counts:"
seen.sort_by { |_, n| -n }.each { |name, n| puts format("  %-28s %d", name, n) }

if failures.empty?
  puts "OK"
else
  puts failures
  exit 1
end
