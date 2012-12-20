# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "ki-repo"
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mikko Apo"]
  s.date = "2012-12-20"
  s.description = "A generic repository for storing packages and metadata related to the packages."
  s.executables = ["ki"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    "LICENSE.txt",
    "README.md",
    "VERSION",
    "docs/backlog.md",
    "docs/development.md",
    "docs/development_setup.md",
    "docs/images/for_git.txt",
    "docs/ki_commands.md",
    "docs/reddit.txt",
    "docs/repository_basics.md",
    "docs/writing_extensions.md",
    "lib/cmd/cmd.rb",
    "lib/cmd/user_pref_cmd.rb",
    "lib/cmd/version_cmd.rb",
    "lib/data_access/repository_finder.rb",
    "lib/data_access/repository_info.rb",
    "lib/data_access/version_helpers.rb",
    "lib/data_access/version_iterators.rb",
    "lib/data_access/version_operations.rb",
    "lib/data_storage/dir_base.rb",
    "lib/data_storage/ki_home.rb",
    "lib/data_storage/ki_json.rb",
    "lib/data_storage/repository.rb",
    "lib/data_storage/version_metadata.rb",
    "lib/ki_repo_all.rb",
    "lib/util/attr_chain.rb",
    "lib/util/exception_catcher.rb",
    "lib/util/hash.rb",
    "lib/util/hash_cache.rb",
    "lib/util/ruby_extensions.rb",
    "lib/util/service_registry.rb",
    "lib/util/simple_optparse.rb",
    "lib/util/test.rb"
  ]
  s.homepage = "http://github.com/mikko-apo/ki-repo"
  s.licenses = ["Apache License, Version 2.0"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "Repository for storing packages and metadata - note: not ready for any kind of use"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<yard>, [">= 0"])
      s.add_development_dependency(%q<bundler>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
      s.add_development_dependency(%q<rdiscount>, [">= 0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<yard>, [">= 0"])
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
      s.add_dependency(%q<simplecov>, [">= 0"])
      s.add_dependency(%q<rdiscount>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<yard>, [">= 0"])
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
    s.add_dependency(%q<simplecov>, [">= 0"])
    s.add_dependency(%q<rdiscount>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
  end
end

