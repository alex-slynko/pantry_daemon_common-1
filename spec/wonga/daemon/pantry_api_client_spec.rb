require 'spec_helper'
require 'wonga/daemon/pantry_api_client'

describe Wonga::Daemon::PantryApiClient do

  let(:logger) { instance_double('Logger').as_null_object }
  let(:url) { 'http://example.com' }
  let(:api_key) { 'api_key' }

  subject { described_class.new(url, api_key, logger) }

  context '#send_put_request' do
    it 'sends http request' do
      expect(logger).to receive(:info).with('PUT request to aws was sent successfully')
      expect(logger).to receive(:debug).with('{:bootstrapped=>true}')
      expect_any_instance_of(RestClient::Resource).to receive(:put).with("{\"bootstrapped\":true}")
      subject.send_put_request('aws', bootstrapped: true)
    end
  end

  context '#send_post_request' do
    it 'sends http request' do
      expect(logger).to receive(:info).with('POST request to aws was sent successfully')
      expect(logger).to receive(:debug).with('{:bootstrapped=>true}')
      expect_any_instance_of(RestClient::Resource).to receive(:post).with("{\"bootstrapped\":true}")
      subject.send_post_request('aws', bootstrapped: true)
    end
  end

  context '#send_delete_request' do
    it 'sends http request' do
      expect(logger).to receive(:info).with('DELETE request to aws was sent successfully')
      expect(logger).to receive(:debug).with('{:user_id=>1}')
      expect_any_instance_of(RestClient::Resource).to receive(:delete).with(params: { user_id: 1 })
      subject.send_delete_request('aws', user_id: 1)
    end
  end
end
