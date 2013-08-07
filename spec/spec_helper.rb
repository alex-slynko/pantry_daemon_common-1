require 'aws-sdk'
require 'rspec/fire'

AWS.config :access_key_id=>"test", :secret_access_key=>"test"
AWS.stub!

RSpec.configure do |config|
  config.include(RSpec::Fire)

  config.order = "random"
end
