lib = File.expand_path '../lib/redeye/', __FILE__

peg = "#{lib}/grammar.kpeg"
grammar = "#{lib}/grammar.kpeg.rb"

file grammar => peg do |t|
  sh "kpeg -f #{peg} -o #{grammar}"
end

desc "Generate the parser from the grammar"
task :kpeg => grammar
