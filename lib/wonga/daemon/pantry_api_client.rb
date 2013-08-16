require 'json'
require 'rest_client'

module Wonga
  module Daemon
    class PantryApiClient
      def initialize(url, api_key, logger, timeout = 300)
        @resource = RestClient::Resource.new(url, timeout: timeout, headers: { :accept => :json, :content_type => :json, :'x-auth-token' => api_key })
        RestClient.log = logger
      end

      def update_ec2_instance(request_id, params)
        params = params.to_json if params.is_a? Hash
        @resource["/aws/ec2_instances/#{request_id}"].put params
      end
    end
  end
end

