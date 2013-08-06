require 'json'
require "common/subscriber"

describe Daemons::Subscriber do
  let(:processor) { double }
  let(:queue_name) { "test_queue" }
  let(:message) { {'test' => 'test'} }

  context "for messages from SNS" do
    let(:message) {
      {
        "Type" => "Notification",
        "MessageId" => "messageid",
        "TopicArn" => "topicarn",
        "Message" => "{\n  \"pantry_request_id\":45,\n  \"name\":\"myhostname\",\n  \"domain\":\"mydomain.tld\",\n  \"ami\":\"ami-hexidstr\",\n  \"size\":\"aws.size1\",\n  \"subnet_id\":\"subnet-hexidstr\",\n  \"security_group_ids\":[\n    \"sg-01234567\",\n    \"sg-89abcdef\",\n    \"sg-7654fedc\"\n  ],\n  \"chef_environment\":\"my_team_ci\",\n  \"run_list\":[\n    \"role[a_common_role]\",\n    \"recipe[git]\",\n    \"role[webserver]\",\n    \"recipe[cookbook_name::specific_recipe]\",\n    \"role[dbserver]\"\n  ]\n}",
        "Timestamp" => "timestamp",
        "SignatureVersion" => "1",
        "Signature" => "big sign",
        "SigningCertURL" => "something.pem",
        "UnsubscribeURL" => "somethingelse.pem"
      }
    }

    it "process parsed messages using process" do
      processor.stub(:handle_message) do |hash|
        expect(hash["pantry_request_id"]).to eql 45
      end
      AWS::SQS.stub_chain(:new, :queues, :named, :poll).and_yield(double(body: message.to_json))
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
