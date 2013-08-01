require "spec_helper"
require "#{Rails.root}/daemons/common/subscriber"

describe Daemons::Subscriber do
  let(:processor) { double }
  let(:queue_name) { "test_queue" }

  it "process parsed messages using processor" do
    expect(processor).to receive(:handle_message).with({'test' => 'test'})
    AWS::SQS.stub_chain(:new, :queues, :named, :poll).and_yield(double(body: "{\"test\":\"test\"}"))
    subject.subscribe queue_name, processor
  end

  it "returns false if message is not parseble" do
    AWS::SQS.stub_chain(:new, :queues, :named, :poll).and_yield(double(body: "test"))
    expect(subject.subscribe queue_name, processor).to be_false
  end
end
