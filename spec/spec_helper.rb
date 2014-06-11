unless ENV['SKIP_COV']
  require 'simplecov'
  require 'simplecov-rcov'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::RcovFormatter
  ]
end
require 'aws-sdk'
require 'webmock/rspec'
require 'pry'

AWS.config access_key_id: 'test', secret_access_key: 'test'
AWS.stub!

RSpec.configure do |config|
  config.order = 'random'
end
