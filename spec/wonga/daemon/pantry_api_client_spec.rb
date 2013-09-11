require 'spec_helper'
require 'wonga/daemon/pantry_api_client'

describe Wonga::Daemon::PantryApiClient do

  let(:logger) { instance_double('Logger').as_null_object }
  let(:url) { 'http://example.com' }
  let(:api_key) { 'api_key' }

  subject { described_class.new(url, api_key, logger) }

  context "#update_ec2_instance" do
    it "sends http request" do
      WebMock.stub_request(:put, "#{url}/aws/ec2_instances/42").
        with(:body => "{\"bootstrapped\":true}", headers: {'X-Auth-Token' => api_key}).
                          to_return(:status => 200, :body => "")
      expect(subject.update_ec2_instance(42, { bootstrapped: true }).code).to be 200
    end
  end

  context "#send_put_request" do
    it "sends http request" do
      WebMock.stub_request(:put, "#{url}/aws").
        with(:body => "{\"bootstrapped\":true}", headers: {'X-Auth-Token' => api_key}).
                          to_return(:status => 200, :body => "")
      expect(subject.send_put_request("aws", { bootstrapped: true }).code).to be 200
    end
  end

  context "#send_post_request" do
    it "sends http request" do
      WebMock.stub_request(:post, "#{url}/aws").
        with(:body => "{\"bootstrapped\":true}", headers: {'X-Auth-Token' => api_key}).
                          to_return(:status => 200, :body => "")
      expect(subject.send_post_request("aws", { bootstrapped: true }).code).to be 200
    end
  end
end

