require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the module.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the module.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'RrdTool'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Generate the gem'
task :gem => [:test] do 
  `gem build *.gemspec`
end

desc 'Generate the dist'
task :dist =>[:clean] do
  `cd .. && tar zcvf daemontools4r.tar.gz daemontools4r/`
end

desc 'Deploy gem to Fnokd Heavy Industries'
task :deploy_gem => [:gem] do
  `scp *.gem fnokd.com:public_html/`
end

desc 'Deploy dist to Fnokd Heavy Industries'
task :deploy_dist =>[:dist] do
  `scp ../daemontools4r.tar.gz fnokd.com:public_html/`
end

desc 'Clean'
task :clean do
  `rm -f *.gem`
  `rm -rf tmp`
end
