module Redeye
  require 'redeye/lexer'
  require 'redeye/grammar.kpeg'

  def self.run(document)
    parser = Grammar.new(document)
    parser.raise_error unless parser.parse
    parser.result
  end

  def self.tokenize(document)
    Lexer.new.tokenize document
  end
end
