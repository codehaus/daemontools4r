
require 'rubygems'

spec = Gem::Specification.new do | s | 
  s.name       = "Daemontools4r"
  s.version    = "1.0.0"
  s.author     = "The Daemontools4r Project"
  s.email      = "dev@daemontools4r.rubyhaus.org"
  s.homepage   = "http://daemontools4r.rubyhaus.org"
  s.platform   = Gem::Platform::RUBY
  s.summary    = "A Ruby daemontools Binding"
  s.files      = [
    'lib/daemontools4r.rb',
    'Rakefile',
    'daemontools4r.gemspec',
  ]
  s.extensions = [ ]
  s.test_files   = [ 
    'test/daemontools4r_test.rb',
    'test-data/service/service-1',
    'test-data/service/service-2',
    'test-data/service/service-3',
    'test-data/service/nonservice-1',
    'test-data/service-real/service-1',
    'test-data/service-real/service-2',
    'test-data/service-real/nonservice-1',
  ]
end

if $0 == __FILE__
  Gem::manage_gems
  Gem::Builder.new( spec ).build
end
