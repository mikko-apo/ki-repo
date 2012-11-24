# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "ki-repo"
  gem.homepage = "http://github.com/mikko-apo/ki-repo"
  gem.license = "Apache License, Version 2.0"
  gem.summary = "Repository for storing packages and metadata - note: not ready for any kind of use"
  gem.description = "A generic repository for storing packages and metadata related to the packages."
#  gem.email = "mikko.apo@reaktor.fi"
  gem.authors = ["Mikko Apo"]
  # dependencies defined in Gemfile
  gem.files = FileList["lib/**/*.rb", "docs/**/*", "README.md"].to_a
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new do |t|
  t.pattern = FileList['spec/**/*_spec.rb','spec-slow/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:coverage) do |t|
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec,rvm,spec-slow']
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
