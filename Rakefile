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

desc "Generates documentation from code"
task "ki:generate_doc" do
  require_relative 'lib/ki_repo_all'
  include Ki
  pwd = File.dirname(File.expand_path(__FILE__))
  File.safe_write(File.join(pwd, "docs", "ki_commands.md")) do |f|
    f.puts "# Command line utilities for Ki Repository v#{KiHome.ki_version}"
    f.puts
    f.puts "Common parameters:"
    f.puts
    f.puts KiCommand.new.opts
    commands = KiCommand::CommandRegistry.find(KiCommand::CommandPrefix[0..-2])
    commands.each do |id, clazz|
      f.puts
      cmd = clazz.new
      name = id[KiCommand::CommandPrefix.size..-1]
      if cmd.respond_to?(:shell_command=)
        cmd.shell_command="ki #{name}"
      end
      f.puts "## #{name}: #{cmd.summary}"
      f.puts
      help = cmd.help
      f.write help
      if !help.end_with?("\n")
        f.puts
      end
    end
  end
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
