require 'rubygems'
require 'rspec'
require 'mocha/api'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :mocha
end

require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/spec-slow/"
end

require 'ki_repo_all'
include Ki