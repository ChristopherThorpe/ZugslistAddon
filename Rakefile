require 'rake'

task :clean do
  sh %{rm -f builds/zugslist.zip}
  sh %{install -d builds}
end

task :build => :clean do
  files = %w{embeds.xml Libs TradeParser.lua Zugslist.lua Zugslist.toc}
  sh %{zip -r builds/zugslist.zip #{files.join ' '}}
end

task :default => :build
