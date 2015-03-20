require "bundler"
Bundler.setup

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RuboCop::RakeTask.new(:rubocop)

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

task :build do
  Rake::Task[:rubocop].invoke
  Rake::Task[:spec].invoke
end

task default: :build
