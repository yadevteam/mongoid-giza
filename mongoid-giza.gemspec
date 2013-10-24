# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongoid/giza/version'

Gem::Specification.new do |spec|
  spec.name          = "mongoid-giza"
  spec.version       = Mongoid::Giza::VERSION
  spec.authors       = ["Maurício Batista"]
  spec.email         = ["eddloschi@gmail.com"]
  spec.description   = %q{Mongoid layer for the Sphinx fulltext search server that supports block fields and dynamic indexes}
  spec.summary       = %q{Mongoid layer for the Sphinx fulltext search server}
  spec.homepage      = "https://github.com/yadevteam/mongoid-giza"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
