module Redeye
  autoload :Grammar, 'redeye/grammar.kpeg'

  def self.run(document)
    parser = Grammar.new(document)
    parser.raise_error unless parser.parse
    parser.result
  end
end
