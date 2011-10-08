module Redeye
  require 'redeye/lexer'
  require 'redeye/nodes'
  require 'redeye/grammar.kpeg'

  # Returns the AST
  def self.run(input)
    parser = Grammar.new(input)
    parser.raise_error unless parser.parse
    parser.result
  end

  def self.tokenize(document)
    Lexer.new.tokenize document
  end
end
