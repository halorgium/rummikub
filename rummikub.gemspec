# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rummikub/version'

Gem::Specification.new do |gem|
  gem.name          = "rummikub"
  gem.version       = Rummikub::VERSION
  gem.authors       = ["Tim Carey-Smith"]
  gem.email         = ["tim@spork.in"]
  gem.description   = "Rummikub game using Celluloid+Reel+Websockets"
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/halorgium/rummikub"

  gem.add_runtime_dependency 'reel'
  gem.add_runtime_dependency 'json'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
