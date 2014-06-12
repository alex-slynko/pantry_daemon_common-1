require 'spec_helper'
require 'json'
require 'wonga/daemon/subscriber'
require 'wonga/daemon/publisher'
require 'logger'

describe Wonga::Daemon::Subscriber do
  subject { Wonga::Daemon::Subscriber.new(logger, config) }

  let(:processor) { double }
  let(:queue_name) { 'test_queue' }
  let(:message) { { 'test' => 'test' } }
  let(:config) { { 'sns' => { 'error_arn' => 'arn' } } }
  let(:logger) { instance_double(Logger).as_null_object }

  context 'for messages from SNS' do
    let(:message) do
      {
        'Type' => 'Notification',
        'MessageId' => 'messageid',
        'TopicArn' => 'topicarn',
        'Message' => "{\n  \"pantry_request_id\":45,\n  \"name\":\"myhostname\",\n  \"domain\":\"mydomain.tld\",\n  \"ami\":\"ami-hexidstr\",\n  \"size\":\"aws.size1\",\n  \"subnet_id\":\"subnet-hexidstr\",\n  \"security_group_ids\":[\n    \"sg-01234567\",\n    \"sg-89abcdef\",\n    \"sg-7654fedc\"\n  ],\n  \"chef_environment\":\"my_team_ci\",\n  \"run_list\":[\n    \"role[a_common_role]\",\n    \"recipe[git]\",\n    \"role[webserver]\",\n    \"recipe[cookbook_name::specific_recipe]\",\n    \"role[dbserver]\"\n  ]\n}",
        'Timestamp' => 'timestamp',
        'SignatureVersion' => '1',
        'Signature' => 'big sign',
        'SigningCertURL' => 'something.pem',
        'UnsubscribeURL' => 'somethingelse.pem'
      }
    end

    it 'process parsed messages using process' do
      allow(processor).to receive(:handle_message) do |hash|
        expect(hash['pantry_request_id']).to eql 45
      end
      allow(AWS::SQS).to receive_message_chain(:new, :queues, :named, :poll).and_yield(double(body: message.to_json))
      subject.subscribe queue_name, processor
    end
  end

  it 'process parsed messages using processor' do
    expect(processor).to receive(:handle_message).with(message)
    allow(AWS::SQS).to receive_message_chain(:new, :queues, :named, :poll).and_yield(double(body: message.to_json))
    subject.subscribe queue_name, processor
  end

  context 'when the message is not parseble' do
    let(:publisher) { instance_double(Wonga::Daemon::Publisher, publish: true) }
    before(:each) do
      allow(Wonga::Daemon::Publisher).to receive(:new).and_return(publisher)
      allow(AWS::SQS).to receive_message_chain(:new, :queues, :named, :poll).and_yield(double(body: 'test'))
    end

    it 'returns false' do
      expect(subject.subscribe queue_name, processor).to be false
    end

    it 'logs the error' do
      subject.subscribe(queue_name, processor)
      expect(logger).to have_received(:error).with(/Bad message/)
    end
  end
end
