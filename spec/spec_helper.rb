require 'pry'
require 'simplecov'
require 'simplecov-rcov'

SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.minimum_coverage 100
SimpleCov.start do
  add_filter %r{^/vendor}
end
