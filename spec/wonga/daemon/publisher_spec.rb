require 'spec_helper'
require "wonga/daemon/publisher"

describe Wonga::Daemon::Publisher do
  let(:topic_name) { "test" }
  subject { Wonga::Daemon::Publisher.new(topic_name, double.as_null_object) }

  context "#publish" do
    let(:message) { { test: :test } }
    it "publishes event using SNS" do
      topic = AWS::SNS::Topic.new(topic_name)
      expect(topic).to receive(:publish).with("{\"test\":\"test\"}")
      AWS::SNS.stub_chain(:new, :topics).and_return(topic_name => topic)
      subject.publish(message)
    end
  end
end

