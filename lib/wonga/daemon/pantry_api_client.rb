require 'json'
require 'rest_client'

module Wonga
  module Daemon
    class PantryApiClient
      def initialize(url, api_key, logger, timeout = 300)
        @resource = RestClient::Resource.new(url, timeout: timeout, headers: { :accept => :json, :content_type => :json, 'x-auth-token' => api_key })
        @logger = logger
      end

      def send_get_request(url)
        response = @resource[url].get.body
        @logger.info "GET request to #{url} was sent successfully"
        @logger.debug response
        JSON.parse response
      end

      def send_put_request(url, params)
        @resource[url].put prepared_params(params)
        @logger.info "PUT request to #{url} was sent successfully"
      end

      def send_post_request(url, params)
        @resource[url].post prepared_params(params)
        @logger.info "POST request to #{url} was sent successfully"
      end

      def send_delete_request(url, params = nil)
        @resource[url].delete params: params
        @logger.info "DELETE request to #{url} was sent successfully"
      end

      private

      def prepared_params(params)
        params.is_a?(Hash) ? params.to_json : params
      end
    end
  end
end
