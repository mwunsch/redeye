# Jeremy Says:
# > Some potential ambiguity in the grammar has been avoided by
# pushing some extra smarts into the Lexer.
module Redeye
  class Lexer

    WHITESPACE = /^[^\n\S]+/
    TRAILING_SPACES = /\s+$/

    def tokenize(code)
      @code = code.rstrip!
    end

  end
end
