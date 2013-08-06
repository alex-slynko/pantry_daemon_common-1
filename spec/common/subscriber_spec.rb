require 'json'
require "common/subscriber"

describe Daemons::Subscriber do
  let(:processor) { double }
  let(:queue_name) { "test_queue" }
  let(:message) { {'test' => 'test'} }

  context "for messages from SNS" do
    it "process parsed messages using process" do
      expect(processor).to receive(:handle_message).with(message)
      AWS::SQS.stub_chain(:new, :queues, :named, :poll).and_yield(double(body: {message: message.to_json}.to_json))
      subject.subscribe queue_name, processor
    end
  end

  it "process parsed messages using processor" do
    expect(processor).to receive(:handle_message).with(message)
    AWS::SQS.stub_chain(:new, :queues, :named, :poll).and_yield(double(body: message.to_json))
    subject.subscribe queue_name, processor
  end

  it "returns false if message is not parseble" do
    AWS::SQS.stub_chain(:new, :queues, :named, :poll).and_yield(double(body: "test"))
    expect(subject.subscribe queue_name, processor).to be_false
  end
end
