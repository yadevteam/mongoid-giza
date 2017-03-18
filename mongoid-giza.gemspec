# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mongoid/giza/version"

Gem::Specification.new do |spec|
  spec.name          = "mongoid-giza"
  spec.version       = Mongoid::Giza::VERSION
  spec.authors       = ["Maurício Batista"]
  spec.email         = ["eddloschi@gmail.com"]
  spec.description   = "Mongoid layer for the Sphinx fulltext search server " \
                       "that supports block fields and dynamic indexes"
  spec.summary       = %(Mongoid layer for the Sphinx fulltext search server)
  spec.homepage      = "https://github.com/yadevteam/mongoid-giza"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($RS)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 2.14"
  spec.add_development_dependency "mongoid-rspec", ">= 1.9"
  spec.add_development_dependency "yard", ">= 0.8.7"
  spec.add_development_dependency "database_cleaner", ">= 1.2.0"
  spec.add_development_dependency "rubocop", ">= 0.29.0"

  spec.add_runtime_dependency "mongoid", ">= 4.0", "< 5.0"
  spec.add_runtime_dependency "riddle", ">= 1.5.11"
  spec.add_runtime_dependency "builder", ">= 3.0"
  spec.add_runtime_dependency "docile", ">= 1.1"
  spec.add_runtime_dependency "activesupport", ">= 4.0", "< 5.0"
end
