require 'wonga/daemon/publisher'
require 'wonga/daemon/subscriber'
require 'logger'

RSpec.describe Wonga::Daemon::Subscriber do
  subject { Wonga::Daemon::Subscriber.new(logger, error_publisher, sqs_client) }

  let(:sqs_client) { Aws::SQS::Client.new(stub_responses: true) }
  let(:error_publisher) { instance_double(Wonga::Daemon::Publisher) }
  let(:processor) { double(handle_message: true) }
  let(:queue_name) { 'test_queue' }
  let(:message_body) { { 'test' => 'test' } }
  let(:logger) { instance_double(Logger).as_null_object }
  let(:receipt_handle) { 'test-message-id' }
  let(:message) { { body: message_body.to_json, receipt_handle: receipt_handle } }

  before(:each) do
    sqs_client.stub_responses(:get_queue_url, queue_url: 'https://aws.amazon.com/some_url')
    sqs_client.stub_responses(:receive_message, messages: [message])
    sqs_client.stub_responses(:delete_message)
  end

  def run_cycle_one
    expect(subject).to receive(:sleep).and_throw(:in_loop)
    catch :in_loop do
      subject.subscribe(queue_name, processor)
    end
  end

  it 'gets queue_url using name' do
    expect(sqs_client).to receive(:get_queue_url).with(queue_name: queue_name).and_call_original
    run_cycle_one
  end

  it 'deletes message' do
    expect(sqs_client).to receive(:delete_message).with(queue_url: 'https://aws.amazon.com/some_url', receipt_handle: receipt_handle).and_call_original
    run_cycle_one
  end

  it 'reads polls from sqs' do
    expect(sqs_client).to receive(:receive_message).with(queue_url: 'https://aws.amazon.com/some_url').and_call_original
    run_cycle_one
  end

  context 'when there is no message' do
    before(:each) do
      sqs_client.stub_responses(:receive_message)
    end

    it 'does nothing' do
      expect(sqs_client).to receive(:receive_message).with(queue_url: 'https://aws.amazon.com/some_url').and_call_original
      expect(sqs_client).not_to receive(:delete_message)
      run_cycle_one
    end
  end

  context 'for messages from SNS' do
    let(:message_body) do
      {
        'Type' => 'Notification',
        'MessageId' => 'messageid',
        'TopicArn' => 'topicarn',
        'Message' => "{\n  \"pantry_request_id\":45,\n  \"name\":\"myhostname\",\n  \"domain\":\"mydomain.tld\",
          \"ami\":\"ami-hexidstr\",\n  \"size\":\"aws.size1\",\n  \"subnet_id\":\"subnet-hexidstr\",
          \"security_group_ids\":[\n    \"sg-01234567\",\n    \"sg-89abcdef\",\n    \"sg-7654fedc\"\n  ],
          \"chef_environment\":\"my_team_ci\",\n  \"run_list\":[\n    \"role[a_common_role]\",\n    \"recipe[git]\",
          \"role[webserver]\",\n    \"recipe[cookbook_name::specific_recipe]\",\n    \"role[dbserver]\"\n  ]\n}",
        'Timestamp' => 'timestamp',
        'SignatureVersion' => '1',
        'Signature' => 'big sign',
        'SigningCertURL' => 'something.pem',
        'UnsubscribeURL' => 'somethingelse.pem'
      }
    end

    it 'deletes message' do
      expect(sqs_client).to receive(:delete_message).with(queue_url: 'https://aws.amazon.com/some_url', receipt_handle: receipt_handle).and_call_original
      run_cycle_one
    end
  end

  context 'when processor raises exception' do
    context 'to rerun process' do
      it 'keeps message' do
        expect(processor).to receive(:handle_message).and_raise RuntimeError
        expect(sqs_client).not_to receive(:delete_message)
        run_cycle_one
      end
    end

    context 'due to some error in processing' do
      it 'keeps message' do
        expect(processor).to receive(:handle_message).and_raise ZeroDivisionError
        expect(sqs_client).not_to receive(:delete_message)
        run_cycle_one
      end
    end
  end

  context 'when the message is not parseble' do
    let(:error_publisher) { instance_double(Wonga::Daemon::Publisher, publish: true) }
    let(:message_body) { 'text' }

    it 'deletes messages' do
      expect(sqs_client).to receive(:delete_message).with(queue_url: 'https://aws.amazon.com/some_url', receipt_handle: receipt_handle).and_call_original
      run_cycle_one
    end

    it 'logs the error' do
      expect(logger).to receive(:error)
      run_cycle_one
    end
  end
end
