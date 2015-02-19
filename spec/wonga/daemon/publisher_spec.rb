require 'wonga/daemon/publisher'

RSpec.describe Wonga::Daemon::Publisher do
  let(:topic_name) { 'test' }
  let(:sns_client) { Aws::SNS::Client.new(stub_responses: true) }
  let(:sns_resource) { Aws::SNS::Resource.new client: sns_client }
  subject { Wonga::Daemon::Publisher.new(topic_name, double.as_null_object, sns_resource) }

  context '#publish' do
    let(:message) { { test: :test } }

    it 'publishes event using SNS' do
      sns_client.stub_responses(:publish)
      subject.publish(message)
    end
  end
end
