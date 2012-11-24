require 'rubygems'
require 'rspec'
require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/spec-slow/"
end
require 'ki_all'

