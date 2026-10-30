# frozen_string_literal: true

# Rouge lexer for MLIR (https://mlir.llvm.org/docs/LangRef/), used for ```mlir fences.
# Anything unrecognized falls through to Text, so it never emits Error tokens.

require "rouge"

module Rouge
  module Lexers
    class MLIR < RegexLexer
      title "MLIR"
      desc "Multi-Level Intermediate Representation (mlir.llvm.org)"
      tag "mlir"
      filenames "*.mlir"
      mimetypes "text/x-mlir"

      BUILTIN_TYPES = %w[
        memref tensor vector complex tuple index none
        f16 bf16 f32 f64 f80 f128 tf32
      ].freeze

      BUILTIN_ATTRS = %w[
        affine_map affine_set dense dense_resource sparse array loc unit
        strided distinct
      ].freeze

      KEYWORDS = %w[
        module func return to step iter_args ins outs attributes
        symbol_name sym_name from into
      ].freeze

      state :root do
        rule %r/\s+/, Text
        rule %r{//.*$}, Comment::Single

        rule %r/"(?:\\.|[^"\\])*"/, Str::Double

        # SSA values (%0, %arg0, %res#1) and block labels (^bb0)
        rule %r/%[\w$.\-]+(?:#\d+)?/, Name::Variable
        rule %r/\^[\w$.\-]+/, Name::Label

        # Symbols (@kernel, @"quoted")
        rule %r/@"(?:\\.|[^"\\])*"/, Name::Function
        rule %r/@[\w$.\-]+/, Name::Function

        # Attribute aliases / dialect attributes (#map0, #gpu.address_space)
        rule %r/#[\w$.\-]+/, Name::Attribute

        # Dialect types (!torch.tensor, !llvm.ptr)
        rule %r/![\w$.\-]+/, Keyword::Type

        # Shape prefixes in types: 10x10x, ?x4x
        rule %r/(?:(?:\d+|\?)x)+(?=[a-z!?\d])/, Num::Integer

        # Operation names: dialect.op (func.func, affine.for, torch.aten.view, memref.load);
        # before builtin types so "memref.load" isn't lexed as the type "memref"
        rule %r/\b[a-zA-Z_][\w$]*(?:\.[\w$]+)+\b/, Keyword

        rule %r/\b(?:#{BUILTIN_TYPES.join("|")})\b/, Keyword::Type
        rule %r/\b[su]?i\d+\b/, Keyword::Type
        rule %r/\b(?:#{BUILTIN_ATTRS.join("|")})\b/, Name::Builtin
        rule %r/\b(?:true|false)\b/, Keyword::Constant

        rule %r/\b(?:#{KEYWORDS.join("|")})\b/, Keyword

        rule %r/0x\h+/, Num::Hex
        rule %r/[-+]?\d+\.\d*(?:[eE][-+]?\d+)?/, Num::Float
        rule %r/\d+/, Num::Integer

        rule %r/->|[=:,(){}\[\]<>*+\-]/, Punctuation
        rule %r/[a-zA-Z_][\w$]*/, Name
        rule %r/./, Text
      end
    end
  end
end
