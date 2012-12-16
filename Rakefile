# encoding: UTF-8

# Copyright 2012 Mikko Apo
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
  t.pattern = FileList['spec/**/*_spec.rb']
  t.ruby_opts = "-w"
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
