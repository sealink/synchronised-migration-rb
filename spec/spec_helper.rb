require "pry"
require "timecop"
require "simplecov"
require "simplecov-rcov"

SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.minimum_coverage 100
SimpleCov.start do
  add_filter "/vendor/"
  add_filter "/config/"
  add_filter "/spec/"
  add_group "lib", "lib"
end

require "synchronised_migration"
