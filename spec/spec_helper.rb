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

begin
  require 'pry'
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

RSpec.configure do |config|
  if config.files_to_run.one?
    config.default_formatter = 'doc'
  else
    config.profile_examples = 10
  end

  config.order = 'random'
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end
  config.disable_monkey_patching!
  # config.warnings = true

  config.before(:each) do
    Aws.config[:credentials] = Aws::Credentials.new 'test', 'test'
    Aws.config[:region] = 'eu-west-1'
  end
end
